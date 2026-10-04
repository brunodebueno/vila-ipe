class_name TrailerCamera
extends Feature
## Câmera de trailer cinematográfica (~40 s): tecla F4 ('trailer_cam'). Percorre pontos de
## interesse (praça, rio, praia, mata de ipês) ao pôr do sol dourado, com letterbox e título.
## Esconde HUD, desativa ferramentas/UI do jogador e cancela com Esc.

const SEQUENCE_DURATION := 40.0
const TARGET_HOUR := 17.5
const TITLE_TEXT := "VILA IPÊ"

## Cada ponto: posição relativa ao centro do mapa (x,z) + altura da câmera + alvo (lookat offset) + duração.
var _shots: Array[Dictionary] = []

var _ctx: GameContext
var _active := false
var _elapsed := 0.0
var _trailer_camera: Camera3D
var _canvas: CanvasLayer
var _title_label: Label
var _prev_hour_scale := 1.0
var _was_tools_enabled := true


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_build_shots()
	_build_overlay()
	set_process(true)


func _build_shots() -> void:
	var center := Vector2(WorldConst.MAP_SIZE) * 0.5
	var river_x := center.x + 19.0
	_shots = [
		{"pos": Vector3(center.x, 10.0, center.y - 16.0), "look": Vector3(center.x, 1.5, center.y), "dur": 9.0},
		{"pos": Vector3(river_x - 10.0, 7.0, center.y + 20.0), "look": Vector3(river_x, 0.5, center.y + 24.0), "dur": 9.0},
		{"pos": Vector3(center.x - 20.0, 5.0, center.y - 10.0), "look": Vector3(center.x - 24.0, 1.0, center.y - 6.0), "dur": 9.0},
		{"pos": Vector3(center.x + 14.0, 13.0, center.y + 14.0), "look": Vector3(center.x, 7.0, center.y), "dur": 13.0},
	]


func _build_overlay() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 30
	_canvas.visible = false
	add_child(_canvas)
	_title_label = Label.new()
	_title_label.text = TITLE_TEXT
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.5))
	_title_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
	_title_label.add_theme_constant_override("outline_size", 12)
	_title_label.set_anchors_preset(Control.PRESET_CENTER)
	_title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate.a = 0.0
	_canvas.add_child(_title_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"trailer_cam") and not _active:
		_start()
	elif _active and event.is_action_pressed(&"pause"):
		_stop()


func _start() -> void:
	if _ctx.day_night == null or _ctx.rig == null:
		return
	_active = true
	_elapsed = 0.0
	GameState.ui_blocking += 1
	_was_tools_enabled = _ctx.tools.enabled
	_ctx.tools.enabled = false
	_ctx.rig.camera.current = false
	_trailer_camera = Camera3D.new()
	_trailer_camera.fov = 45.0
	add_child(_trailer_camera)
	_trailer_camera.current = true
	_ctx.day_night.set_hour(TARGET_HOUR)
	_ctx.day_night.time_scale = 0.0001
	EventBus.hud_toggled.emit(false)
	_canvas.visible = true
	_title_label.modulate.a = 0.0
	_set_letterbox(0.0)
	_place_shot(0)


func _stop() -> void:
	_active = false
	GameState.ui_blocking = maxi(0, GameState.ui_blocking - 1)
	_ctx.tools.enabled = _was_tools_enabled
	_ctx.day_night.time_scale = 1.0
	if _trailer_camera:
		_trailer_camera.queue_free()
		_trailer_camera = null
	_ctx.rig.camera.current = true
	_canvas.visible = false
	EventBus.hud_toggled.emit(true)
	_set_letterbox(0.0)


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= SEQUENCE_DURATION:
		_stop()
		return
	var letterbox_t := clampf(minf(_elapsed, SEQUENCE_DURATION - _elapsed) / 1.5, 0.0, 1.0)
	_set_letterbox(lerpf(0.0, 0.12, letterbox_t))
	_title_label.modulate.a = clampf(1.0 - absf(_elapsed - 4.0) / 3.5, 0.0, 1.0) if _elapsed < 8.0 else 0.0
	_update_shot()


func _update_shot() -> void:
	var t := 0.0
	for i in _shots.size():
		var shot: Dictionary = _shots[i]
		var dur: float = shot["dur"]
		if _elapsed < t + dur:
			var local_t := (_elapsed - t) / dur
			var next_shot: Dictionary = _shots[(i + 1) % _shots.size()]
			var pos: Vector3 = (shot["pos"] as Vector3).lerp(shot["pos"] as Vector3 + Vector3(0, 0.6, 0), smoothstep(0.0, 1.0, local_t))
			_trailer_camera.global_position = pos
			var look: Vector3 = shot["look"]
			_trailer_camera.look_at(look, Vector3.UP)
			return
		t += dur


func _place_shot(index: int) -> void:
	if index >= _shots.size():
		return
	var shot: Dictionary = _shots[index]
	_trailer_camera.global_position = shot["pos"]
	_trailer_camera.look_at(shot["look"], Vector3.UP)


func _set_letterbox(amount: float) -> void:
	for node in get_tree().get_nodes_in_group(&"visual_polish"):
		if node.has_method("set_letterbox"):
			node.call("set_letterbox", amount)
