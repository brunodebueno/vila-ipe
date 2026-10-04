extends Feature
## Save/Load em user://saves/slot1.json. Autosave (dormir/5 min/sair), 3 backups rotativos.
## Delega a outros módulos via grupos 'saveable', 'saveable_build', 'saveable_village'
## (qualquer nó nesses grupos com serialize()/deserialize() é salvo em save['modules'][nome]).

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves/"
const SLOT_PATH := SAVE_DIR + "slot1.json"
const BACKUP_COUNT := 3
const AUTOSAVE_INTERVAL := 300.0
const MODULE_GROUPS := [&"saveable", &"saveable_build", &"saveable_village"]

var _ctx: GameContext
var _autosave_timer := 0.0


func install(ctx: GameContext) -> void:
	_ctx = ctx
	add_to_group(&"system_save")
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	EventBus.day_phase_changed.connect(_on_day_phase_changed)

	var args := OS.get_cmdline_user_args()
	if args.has("--save-test"):
		call_deferred("_run_save_test")
		return

	var start := String(Engine.get_meta(&"vila_start", "new"))
	if start == "continue":
		await ctx.main.get_tree().process_frame
		await ctx.main.get_tree().process_frame
		load_game()


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()


func _on_day_phase_changed(phase: StringName) -> void:
	if phase == &"night" or phase == &"sleep":
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		save_game()


## --- API pública ---

func save_game() -> void:
	var save := _build_save()
	_rotate_backups()
	var text := JSON.stringify(save)
	var f := FileAccess.open(SLOT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Falha ao salvar: " + str(FileAccess.get_open_error()))
		return
	f.store_string(text)
	f.close()
	EventBus.notify.emit("Jogo salvo", &"")


func load_game() -> bool:
	if not FileAccess.file_exists(SLOT_PATH):
		return false
	var f := FileAccess.open(SLOT_PATH, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save corrompido.")
		return false
	var save: Dictionary = migrate(parsed)
	_apply_save(save)
	return true


## Migração de versão: ajuste os dados antigos antes de aplicar. Hoje só existe a v1.
func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 1))
	if version < SAVE_VERSION:
		data["version"] = SAVE_VERSION
	return data


## --- Construção do save ---

func _build_save() -> Dictionary:
	var save := {
		"version": SAVE_VERSION,
		"game_state": {
			"inventory": GameState.inventory.to_array(),
			"coins": GameState.coins,
			"flags": GameState.flags,
			"stats": GameState.stats,
			"selected_slot": GameState.selected_slot,
		},
		"hour": _ctx.day_night.hour if _ctx.day_night else 12.0,
		"player": _player_save(),
		"terrain": _terrain_save(),
		"trees": _ctx.props.serialize_trees() if _ctx.props else [],
		"modules": _modules_save(),
	}
	return save


func _player_save() -> Dictionary:
	if _ctx.player == null:
		return {}
	var p := _ctx.player.global_position
	return {"x": p.x, "y": p.y, "z": p.z}


func _terrain_save() -> Dictionary:
	if _ctx.terrain == null or _ctx.terrain.data == null:
		return {}
	var data: TerrainData = _ctx.terrain.data
	var heights := PackedByteArray()
	heights.resize(data.size.x * data.size.y * 4)
	var tiles := PackedByteArray()
	tiles.resize(data.size.x * data.size.y)
	var i := 0
	for z in data.size.y:
		for x in data.size.x:
			var cell := Vector2i(x, z)
			var h := data.get_height(cell)
			heights.encode_s32(i * 4, h)
			tiles[i] = data.get_tile(cell)
			i += 1
	return {
		"size": [data.size.x, data.size.y],
		"heights": Marshalls.raw_to_base64(heights.compress(FileAccess.COMPRESSION_GZIP)),
		"tiles": Marshalls.raw_to_base64(tiles.compress(FileAccess.COMPRESSION_GZIP)),
	}


func _modules_save() -> Dictionary:
	var out := {}
	var seen := {}
	for group: StringName in MODULE_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if seen.has(node) or not node.has_method("serialize"):
				continue
			seen[node] = true
			out[node.name] = node.call("serialize")
	return out


## --- Aplicação do save ---

func _apply_save(save: Dictionary) -> void:
	var gs: Dictionary = save.get("game_state", {})
	GameState.inventory.from_array(gs.get("inventory", []))
	GameState.coins = int(gs.get("coins", GameState.coins))
	GameState.flags = gs.get("flags", {})
	GameState.stats = gs.get("stats", {})
	GameState.selected_slot = int(gs.get("selected_slot", 0))
	GameState.coins_changed.emit(GameState.coins)
	GameState.selected_slot_changed.emit(GameState.selected_slot)

	if _ctx.day_night and save.has("hour"):
		_ctx.day_night.hour = float(save["hour"])

	_apply_terrain(save.get("terrain", {}))

	if _ctx.props and save.has("trees"):
		_ctx.props.restore_trees(save["trees"])

	var player_data: Dictionary = save.get("player", {})
	if _ctx.player and not player_data.is_empty():
		_ctx.player.global_position = Vector3(float(player_data["x"]), float(player_data["y"]), float(player_data["z"]))

	var modules: Dictionary = save.get("modules", {})
	for group: StringName in MODULE_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			if modules.has(node.name) and node.has_method("deserialize"):
				node.call("deserialize", modules[node.name])


func _apply_terrain(terrain_save: Dictionary) -> void:
	if terrain_save.is_empty() or _ctx.terrain == null or _ctx.terrain.data == null:
		return
	var data: TerrainData = _ctx.terrain.data
	var size := Vector2i(int(terrain_save["size"][0]), int(terrain_save["size"][1]))
	var heights := Marshalls.base64_to_raw(terrain_save["heights"]).decompress(size.x * size.y * 4, FileAccess.COMPRESSION_GZIP)
	var tiles := Marshalls.base64_to_raw(terrain_save["tiles"]).decompress(size.x * size.y, FileAccess.COMPRESSION_GZIP)
	var i := 0
	for z in size.y:
		for x in size.x:
			var cell := Vector2i(x, z)
			data.set_height(cell, heights.decode_s32(i * 4))
			data.set_tile(cell, tiles[i])
			i += 1


## --- Backups ---

func _rotate_backups() -> void:
	for i in range(BACKUP_COUNT, 1, -1):
		var src := "%sslot1.bak%d" % [SAVE_DIR, i - 1]
		var dst := "%sslot1.bak%d" % [SAVE_DIR, i]
		if FileAccess.file_exists(src):
			var bytes := FileAccess.get_file_as_bytes(src)
			var out := FileAccess.open(dst, FileAccess.WRITE)
			if out:
				out.store_buffer(bytes)
				out.close()
	if FileAccess.file_exists(SLOT_PATH):
		var bytes := FileAccess.get_file_as_bytes(SLOT_PATH)
		var out := FileAccess.open("%sslot1.bak1" % SAVE_DIR, FileAccess.WRITE)
		if out:
			out.store_buffer(bytes)
			out.close()


## --- Teste automático de ida e volta ---
## Uso: godot --path . -- --save-test  (salva → altera → carrega → compara → imprime OK/FALHA e sai)
func _run_save_test() -> void:
	await _ctx.main.get_tree().process_frame
	await _ctx.main.get_tree().process_frame
	var before := _build_save()
	save_game()
	GameState.add_coins(777)
	GameState.set_flag(&"__save_test_dirty", true)
	if _ctx.day_night:
		_ctx.day_night.hour = 3.33
	var ok := load_game()
	var after := _build_save()
	var passed: bool = ok and after.get("game_state", {}).get("coins", -1) == before.get("game_state", {}).get("coins", -2) \
		and not GameState.get_flag(&"__save_test_dirty", false) \
		and absf(float(after.get("hour", -1.0)) - float(before.get("hour", -2.0))) < 0.01
	if passed:
		print("SAVE_TEST: OK")
	else:
		print("SAVE_TEST: FALHA")
		print("antes=", before.get("game_state"), " depois=", after.get("game_state"))
	_ctx.main.get_tree().quit()
