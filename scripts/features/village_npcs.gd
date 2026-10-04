class_name VillageNpcs
extends Feature
## Spawna e administra os moradores da vila (NPCs), diálogo (F), amizade e presentes (G).
## Dados em data/npcs.json e data/dialogues.json. NPCs chegam conforme VillageProgress emite
## EventBus.creature_arrived(id). Deixa lines/friendship acessíveis a quests.gd via grupo.

const NPCS_PATH := "res://data/npcs.json"
const DIALOGUES_PATH := "res://data/dialogues.json"
const INTERACT_RADIUS := 3.0
const ROAD_SOUTH_OFFSET := Vector2i(0, 26)

var _npc_defs: Dictionary = {}
var _dialogue_lines: Dictionary = {}
var _npcs: Dictionary = {}
var _dialogue_ui: DialogueUi
var _ctx: GameContext
var _nearest: Npc
var _prompt_shown := false
var _last_talk_day: Dictionary = {}


func install(ctx: GameContext) -> void:
	add_to_group(&"saveable_village")
	_ctx = ctx
	_load_defs()
	_dialogue_ui = DialogueUi.new()
	add_child(_dialogue_ui)
	for id: StringName in _npc_defs:
		var def: Dictionary = _npc_defs[id]
		if int(def.get("arrival_star", 0)) == 0:
			_spawn_npc(id, def, false)
	EventBus.creature_arrived.connect(_on_creature_arrival)
	if OS.get_cmdline_user_args().has("--open-dialogue"):
		call_deferred("_debug_open_cida")


func _load_defs() -> void:
	var nfile := FileAccess.open(NPCS_PATH, FileAccess.READ)
	if nfile:
		var parsed: Variant = JSON.parse_string(nfile.get_as_text())
		if parsed is Dictionary:
			for entry: Dictionary in (parsed as Dictionary).get("npcs", []):
				_npc_defs[StringName(entry.get("id", ""))] = entry
	var dfile := FileAccess.open(DIALOGUES_PATH, FileAccess.READ)
	if dfile:
		var parsed2: Variant = JSON.parse_string(dfile.get_as_text())
		if parsed2 is Dictionary:
			_dialogue_lines = parsed2


func _spawn_npc(id: StringName, def: Dictionary, animate_arrival: bool) -> void:
	var npc := Npc.new()
	npc.name = "Npc_" + String(id)
	add_child(npc)
	npc.setup(id, def, _dialogue_lines.get(id, {}), _ctx.terrain.data, _ctx.props, _ctx.player, _npcs.size() + 1)
	if animate_arrival:
		var edge := WorldConst.MAP_SIZE / 2 + ROAD_SOUTH_OFFSET
		edge.x = clampi(edge.x, 1, WorldConst.MAP_SIZE.x - 2)
		edge.y = clampi(edge.y, 1, WorldConst.MAP_SIZE.y - 2)
		npc.arrive_from(edge)
	else:
		npc.place_at_home()
	_npcs[id] = npc


func _on_creature_arrival(id: StringName) -> void:
	if _npcs.has(id) or not _npc_defs.has(id):
		return
	_spawn_npc(id, _npc_defs[id], true)
	EventBus.notify.emit("%s chegou à vila!" % String(_npc_defs[id].get("name", String(id))), &"")


func _process(_delta: float) -> void:
	_update_nearest()
	_update_prompt()
	if Input.is_action_just_pressed(&"interact") and _nearest and not _dialogue_ui.is_open() and not GameState.is_ui_blocking():
		_start_dialogue(_nearest)
	elif Input.is_action_just_pressed(&"gift") and _nearest and not GameState.is_ui_blocking():
		_try_gift(_nearest)


func _update_nearest() -> void:
	_nearest = null
	if _ctx.player == null:
		return
	var best: float = INF
	for id: StringName in _npcs:
		var npc: Npc = _npcs[id]
		var d := npc.global_position.distance_to(_ctx.player.global_position)
		if d <= INTERACT_RADIUS and d < best:
			best = d
			_nearest = npc


func _update_prompt() -> void:
	var prompts := get_tree().get_nodes_in_group("ui_prompt")
	var want := _nearest != null and not _dialogue_ui.is_open() and not GameState.is_ui_blocking()
	if want == _prompt_shown and not want:
		return
	_prompt_shown = want
	for p in prompts:
		if not is_instance_valid(p):
			continue
		if want and p.has_method("show_prompt"):
			p.call("show_prompt", "Conversar com %s" % _nearest.display_name(), "F")
		elif not want and p.has_method("hide_prompt"):
			p.call("hide_prompt")


func _start_dialogue(npc: Npc) -> void:
	var pages := _pick_lines(npc)
	var choices := _pick_choices(npc)
	var color: Color = Color(String(npc.def.get("accent", "#ffe27a")))
	_dialogue_ui.open(npc.display_name(), color, NpcModel.initials(npc.display_name()), pages, choices)
	EventBus.npc_talked.emit(npc.id)
	_grant_daily_friendship(npc)


func _pick_lines(npc: Npc) -> Array:
	var quest_key := _quest_line_key(npc)
	if quest_key != "" and npc.lines.has(quest_key):
		return (npc.lines[quest_key] as Array).duplicate()
	var phase := _day_phase()
	var pool: Array = npc.lines.get(phase, npc.lines.get("ambiente", ["..."]))
	if npc.friendship >= 7 and npc.lines.has("amizade_alta") and randf() < 0.4:
		pool = npc.lines["amizade_alta"]
	if pool.is_empty():
		pool = ["..."]
	return [pool[randi() % pool.size()]]


func _pick_choices(npc: Npc) -> Array:
	var key := _quest_line_key(npc) + "_choices"
	return npc.lines.get(key, [])


func _quest_line_key(npc: Npc) -> String:
	if npc.id == &"dona_cida" and not GameState.get_flag(&"talked_cida_intro", false):
		GameState.set_flag(&"talked_cida_intro", true)
		return "quest_chegada_1"
	if npc.id == &"pedrinho" and not GameState.get_flag(&"talked_pedrinho_intro", false):
		GameState.set_flag(&"talked_pedrinho_intro", true)
		return "quest_pedrinho_1"
	return ""


func _day_phase() -> String:
	var hour := _ctx.day_night.hour if _ctx.day_night else 12.0
	if hour >= 6.0 and hour < 12.0:
		return "manha"
	if hour >= 12.0 and hour < 18.5:
		return "tarde"
	return "noite"


func _grant_daily_friendship(npc: Npc) -> void:
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	if int(_last_talk_day.get(npc.id, -1)) == today:
		return
	_last_talk_day[npc.id] = today
	npc.gain_friendship(1)


func _try_gift(npc: Npc) -> void:
	var item := GameState.selected_item()
	if item == &"":
		EventBus.notify.emit("Selecione um item na hotbar pra dar de presente.", &"")
		return
	if not GameState.inventory.has(item):
		return
	GameState.inventory.remove(item, 1)
	var liked := StringName(npc.def.get("gift_like", "")) == item
	npc.gain_friendship(2 if liked else 1)
	EventBus.gift_given.emit(npc.id, item)
	var msg := "%s amou o presente!" % npc.display_name() if liked else "%s agradeceu o presente." % npc.display_name()
	npc.say(msg)
	EventBus.notify.emit(msg, item)


func friendship_summaries() -> Array:
	var out: Array = []
	for id: StringName in _npcs:
		var npc: Npc = _npcs[id]
		out.append({"name": npc.display_name(), "hearts": npc.friendship})
	return out


func npc_count() -> int:
	return _npcs.size()


func _debug_open_cida() -> void:
	await get_tree().create_timer(0.3).timeout
	if _npcs.has(&"dona_cida"):
		_start_dialogue(_npcs[&"dona_cida"])


func serialize() -> Dictionary:
	var friendships := {}
	var arrived: Array = []
	for id: StringName in _npcs:
		var npc: Npc = _npcs[id]
		friendships[String(id)] = npc.friendship
		arrived.append(String(id))
	return {"friendships": friendships, "arrived": arrived, "last_talk_day": _last_talk_day}


func deserialize(d: Dictionary) -> void:
	for id_str: String in d.get("arrived", []):
		var id := StringName(id_str)
		if not _npcs.has(id) and _npc_defs.has(id):
			_spawn_npc(id, _npc_defs[id], false)
	var friendships: Dictionary = d.get("friendships", {})
	for id_str: String in friendships:
		var id := StringName(id_str)
		if _npcs.has(id):
			(_npcs[id] as Npc).friendship = int(friendships[id_str])
