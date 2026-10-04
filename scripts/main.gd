extends Node3D
## Raiz do jogo: monta mundo, jogador, câmera, interface e ciclo dia/noite.

const WORLD_SEED := 20260410
const CAPYBARA_COUNT := 5
const FEATURES_DIR := "res://scripts/features/"

var _terrain: Terrain
var _props: PropManager
var _player: Player
var _rig: CameraRig
var _hud_visible := true


func _ready() -> void:
	var data := TerrainData.new()
	WorldGenerator.generate(data, WORLD_SEED)

	_terrain = Terrain.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	_terrain.build(data)

	_props = PropManager.new()
	_props.name = "Props"
	add_child(_props)
	_props.setup(data, WORLD_SEED)
	WorldGenerator.populate(data, _props, WORLD_SEED)

	var day_night := DayNight.new()
	day_night.name = "DayNight"
	add_child(day_night)

	var spawn := Vector2i(WorldConst.MAP_SIZE) / 2 + Vector2i(0, 3)
	_player = Player.new()
	_player.name = "Player"
	add_child(_player)
	_player.global_position = Vector3(spawn.x + 0.5, _terrain.top_y(spawn) + 0.3, spawn.y + 0.5)

	_rig = CameraRig.new()
	_rig.name = "CameraRig"
	add_child(_rig)
	_rig.global_position = _player.global_position
	_rig.camera.current = true
	_player.camera_rig = _rig

	var tools := ToolController.new()
	tools.name = "ToolController"
	add_child(tools)
	tools.setup(_terrain, _props, _rig.camera)

	var ctx := GameContext.new()
	ctx.main = self
	ctx.terrain = _terrain
	ctx.props = _props
	ctx.player = _player
	ctx.rig = _rig
	ctx.tools = tools
	ctx.day_night = day_night
	GameContext.current = ctx

	add_child(Hud.new())
	_spawn_capybaras(data, spawn)
	_install_features(ctx)
	if OS.get_cmdline_user_args().has("--shot"):
		_auto_shot()


func _install_features(ctx: GameContext) -> void:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(FEATURES_DIR):
		var clean := file.trim_suffix(".remap")
		if clean.ends_with(".gd"):
			files.append(clean)
	files.sort()
	for file in files:
		var script := load(FEATURES_DIR + file) as GDScript
		var feature := script.new() as Feature
		if feature == null:
			push_error("Feature inválida: " + file)
			continue
		feature.name = file.get_basename().to_pascal_case()
		add_child(feature)
		feature.install(ctx)


func _spawn_capybaras(data: TerrainData, center: Vector2i) -> void:
	var offsets: Array[Vector2i] = [Vector2i(-9, 8), Vector2i(-8, 9), Vector2i(-10, 7), Vector2i(10, 10), Vector2i(11, 9)]
	for i in CAPYBARA_COUNT:
		var cell := center + offsets[i]
		var capy := Capybara.new()
		add_child(capy)
		capy.position = Vector3(cell.x + 0.5, _terrain.top_y(cell), cell.y + 0.5)
		capy.setup(data, i + 1)


func _physics_process(delta: float) -> void:
	_rig.follow(_player.global_position, delta)


func _unhandled_input(event: InputEvent) -> void:
	_rig.handle_input(event)
	if event.is_action_pressed(&"toggle_hud"):
		_hud_visible = not _hud_visible
		EventBus.hud_toggled.emit(_hud_visible)
	elif event.is_action_pressed(&"cinematic"):
		_rig.cinematic = not _rig.cinematic
	elif event.is_action_pressed(&"screenshot"):
		_take_screenshot()


func _take_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://vila_ipe_%s.png" % stamp
	image.save_png(path)
	print("Foto salva em ", ProjectSettings.globalize_path(path))


## Uso: godot --path . -- --shot  (salva uma foto após 2 s e fecha; útil para QA e trailer)
func _auto_shot() -> void:
	await get_tree().create_timer(2.0).timeout
	_take_screenshot()
	get_tree().quit()
