class_name Quests
extends Feature
## Rastreia missões (cadeia principal + pedidos do Pedrinho + pedidos diários do quadro).
## Dados em data/quests.json. HUD: rastreador esquerda-meio. Diário (aba Missões) é
## desenhado por village_progress.gd, que lê get_active_summaries()/get_completed_chain_ids().

const DATA_PATH := "res://data/quests.json"
const DAILY_RESET_HOUR := 6.0

var chains: Array = []
var daily_pool: Array = []
var _active: Dictionary = {}
var _completed_steps: Dictionary = {}
var _completed_chains: Dictionary = {}
var _active_daily: Array = []
var _completed_today: Dictionary = {}
var _last_hour := 0.0
var _tracker: Control
var _tracker_label: Label
var _root: CanvasLayer


func install(_ctx: GameContext) -> void:
	add_to_group(&"quests_feature")
	add_to_group(&"saveable_village")
	_load_data()
	EventBus.npc_talked.connect(_on_npc_talked)
	GameState.stat_changed.connect(_on_stat_changed)
	EventBus.item_gained.connect(_on_item_gained)
	EventBus.structure_built.connect(_on_structure_built)
	GameState.coins_changed.connect(_on_coins_changed)
	EventBus.terrain_edited.connect(_on_terrain_edited)
	EventBus.hour_changed.connect(_on_hour_changed)
	_build_tracker()
	_activate_step(&"chegada", 0)
	_activate_step(&"pedrinho_borboletas", 0)
	_refresh_daily(true)
	_refresh_tracker()


func _load_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		chains = (parsed as Dictionary).get("chains", [])
		daily_pool = (parsed as Dictionary).get("daily_pool", [])


func _find_chain(chain_id: StringName) -> Dictionary:
	for c: Dictionary in chains:
		if StringName(c.get("id", "")) == chain_id:
			return c
	return {}


func _activate_step(chain_id: StringName, step_index: int) -> void:
	var chain := _find_chain(chain_id)
	var steps: Array = chain.get("steps", [])
	if step_index >= steps.size():
		_completed_chains[chain_id] = true
		return
	var step: Dictionary = steps[step_index]
	var runtime := {
		"chain_id": chain_id,
		"step_index": step_index,
		"step": step,
		"progress": 0,
		"done": false,
	}
	var objective: Dictionary = step.get("objective", {})
	if objective.get("type", "") == "stat_delta":
		runtime["baseline"] = GameState.get_stat(StringName(objective.get("stat", "")))
	_active[String(chain_id) + ":" + String(step.get("id", ""))] = runtime
	if objective.get("type", "") == "coins_reach" and GameState.coins >= int(objective.get("amount", 0)):
		_complete_runtime(runtime)


func _runtime_key(r: Dictionary) -> String:
	return String(r.get("chain_id", "")) + ":" + String((r.get("step", {}) as Dictionary).get("id", ""))


func _complete_runtime(r: Dictionary) -> void:
	if r.get("done", false):
		return
	r["done"] = true
	var step: Dictionary = r.get("step", {})
	var reward: Dictionary = step.get("reward", {})
	_grant_reward(reward)
	_completed_steps[_runtime_key(r)] = true
	EventBus.notify.emit("Missão concluída: %s" % String(step.get("title", "")), &"")
	_active.erase(_runtime_key(r))
	var chain_id: StringName = r.get("chain_id", &"")
	var next_index: int = int(r.get("step_index", 0)) + 1
	_activate_step(chain_id, next_index)
	_refresh_tracker()


func _grant_reward(reward: Dictionary) -> void:
	if reward.has("coins"):
		GameState.add_coins(int(reward["coins"]))
	for item: Dictionary in reward.get("items", []):
		GameState.give(StringName(item.get("id", "")), int(item.get("amount", 1)))
	for flag in reward.get("flags", []):
		GameState.set_flag(StringName(flag))


func _refresh_daily(force: bool) -> void:
	if daily_pool.is_empty():
		return
	if not force and GameState.get_flag(&"daily_quests_date", -1) == _day_key():
		return
	GameState.set_flag(&"daily_quests_date", _day_key())
	_active_daily.clear()
	_completed_today.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _day_key() * 31 + 7
	var picks := daily_pool.duplicate()
	picks.shuffle()
	for i in mini(3, picks.size()):
		var step: Dictionary = picks[i]
		var runtime := {"chain_id": &"__daily__", "step_index": i, "step": step, "progress": 0, "done": false}
		var objective: Dictionary = step.get("objective", {})
		if objective.get("type", "") == "stat_delta":
			runtime["baseline"] = GameState.get_stat(StringName(objective.get("stat", "")))
		_active_daily.append(runtime)
	EventBus.notify.emit("Novos pedidos no quadro de avisos!", &"")
	_refresh_tracker()


func _day_key() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func _on_hour_changed(hour: float) -> void:
	if _last_hour < DAILY_RESET_HOUR and hour >= DAILY_RESET_HOUR:
		_refresh_daily(false)
	_last_hour = hour


func _all_runtimes() -> Array:
	var out: Array = _active.values()
	out.append_array(_active_daily)
	return out


func _on_npc_talked(id: StringName) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "talk" and StringName(obj.get("npc", "")) == id:
			_finish_daily_or_chain(r)
	_refresh_tracker()


func _on_stat_changed(stat: StringName, value: int) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "stat_delta" and StringName(obj.get("stat", "")) == stat:
			var baseline: int = int(r.get("baseline", 0))
			var progress := value - baseline
			r["progress"] = progress
			if progress >= int(obj.get("amount", 1)):
				_finish_daily_or_chain(r)
	_refresh_tracker()


func _on_item_gained(id: StringName, amount: int) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "item_delta" and StringName(obj.get("item", "")) == id:
			r["progress"] = int(r.get("progress", 0)) + amount
			if int(r["progress"]) >= int(obj.get("amount", 1)):
				_finish_daily_or_chain(r)
		elif obj.get("type", "") == "any_of":
			for opt: Dictionary in obj.get("options", []):
				if opt.get("type", "") == "item_delta" and StringName(opt.get("item", "")) == id and amount >= int(opt.get("amount", 1)):
					_finish_daily_or_chain(r)
	_refresh_tracker()


func _on_structure_built(id: StringName, _cell: Vector2i) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "structure" and StringName(obj.get("structure", "")) == id:
			_finish_daily_or_chain(r)
	_refresh_tracker()


func _on_coins_changed(value: int) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "coins_reach" and value >= int(obj.get("amount", 0)):
			_finish_daily_or_chain(r)
		elif obj.get("type", "") == "any_of":
			for opt: Dictionary in obj.get("options", []):
				if opt.get("type", "") == "coins_reach" and value >= int(opt.get("amount", 0)):
					_finish_daily_or_chain(r)
	_refresh_tracker()


func _on_terrain_edited(_cell: Vector2i) -> void:
	for r: Dictionary in _all_runtimes():
		if r.get("done", false):
			continue
		var obj: Dictionary = (r.get("step", {}) as Dictionary).get("objective", {})
		if obj.get("type", "") == "event_count" and StringName(obj.get("event", "")) == &"terrain_edited":
			r["progress"] = int(r.get("progress", 0)) + 1
			if int(r["progress"]) >= int(obj.get("amount", 1)):
				_finish_daily_or_chain(r)
	_refresh_tracker()


func _finish_daily_or_chain(r: Dictionary) -> void:
	if r.get("chain_id", "") == &"__daily__":
		if r.get("done", false):
			return
		r["done"] = true
		_grant_reward((r.get("step", {}) as Dictionary).get("reward", {}))
		_completed_today[(r.get("step", {}) as Dictionary).get("id", "")] = true
		EventBus.notify.emit("Pedido do quadro concluído: %s" % String((r.get("step", {}) as Dictionary).get("title", "")), &"")
	else:
		_complete_runtime(r)


## API pública (lida por village_progress.gd / HUD).
func get_active_summaries() -> Array:
	var out: Array = []
	for r: Dictionary in _active.values():
		var step: Dictionary = r.get("step", {})
		var obj: Dictionary = step.get("objective", {})
		var target: int = int(obj.get("amount", 1)) if obj.has("amount") else 1
		out.append({"title": step.get("title", ""), "desc": step.get("desc", ""), "progress": int(r.get("progress", 0)), "target": target})
	return out


func get_daily_summaries() -> Array:
	var out: Array = []
	for r: Dictionary in _active_daily:
		var step: Dictionary = r.get("step", {})
		var obj: Dictionary = step.get("objective", {})
		var target: int = int(obj.get("amount", 1)) if obj.has("amount") else 1
		out.append({"title": step.get("title", ""), "done": r.get("done", false), "progress": int(r.get("progress", 0)), "target": target})
	return out


func chain_progress(chain_id: StringName) -> Vector2i:
	var chain := _find_chain(chain_id)
	var steps: Array = chain.get("steps", [])
	var done := 0
	for step: Dictionary in steps:
		if _completed_steps.has(String(chain_id) + ":" + String(step.get("id", ""))):
			done += 1
	return Vector2i(done, steps.size())


func _build_tracker() -> void:
	_root = CanvasLayer.new()
	_root.layer = 9
	add_child(_root)
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	wrap.offset_left = 24
	wrap.offset_top = -90
	wrap.offset_bottom = 90
	_root.add_child(wrap)
	_tracker = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.06, 0.55)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_tracker.add_theme_stylebox_override("panel", style)
	wrap.add_child(_tracker)
	_tracker_label = Label.new()
	_tracker_label.add_theme_font_size_override("font_size", 15)
	_tracker_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_tracker_label.add_theme_constant_override("outline_size", 5)
	_tracker.add_child(_tracker_label)


func _refresh_tracker() -> void:
	var lines: PackedStringArray = []
	lines.append("MISSÕES")
	var shown := 0
	for s: Dictionary in get_active_summaries():
		if shown >= 3:
			break
		lines.append("• %s (%d/%d)" % [String(s["title"]), int(s["progress"]), int(s["target"])])
		shown += 1
	if shown == 0:
		lines.append("Nenhuma pendente")
	_tracker_label.text = "\n".join(lines)


func serialize() -> Dictionary:
	return {
		"completed_steps": _completed_steps.keys(),
		"completed_chains": _completed_chains.keys(),
	}


func deserialize(d: Dictionary) -> void:
	for k in d.get("completed_steps", []):
		_completed_steps[k] = true
	for k in d.get("completed_chains", []):
		_completed_chains[StringName(k)] = true
