class_name Fishing
extends Feature
## Vara de pescar: clicar em água perto (<=8 m) lança a linha. Espera aleatória, depois a boia
## afunda e alerta "!"; clicar na janela de 1,2 s inicia um minijogo de tensão (manter o clique/
## espaço para acompanhar o peixe). Sucesso dá o peixe sorteado por raridade/hora/profundidade.

enum State { IDLE, WAITING, BITE, MINIGAME }

const CAST_MAX_DIST := 8.0
const BITE_WINDOW := 1.2
const MINIGAME_DURATION := 8.0
const MINIGAME_ZONE_SIZE := 0.22
const MARKER_RISE := 1.6
const MARKER_FALL := 1.1
const PROGRESS_GAIN := 0.5
const PROGRESS_LOSS := 0.22

var _ctx: GameContext
var _fish_table := FishTable.new()
var _state: State = State.IDLE
var _bobber: Node3D
var _line: MeshInstance3D
var _alert: Label3D
var _cell := Vector2i.ZERO
var _wait_timer := 0.0
var _bite_timer := 0.0
var _depth := 0

var _minigame_layer: CanvasLayer
var _bar: Control
var _zone_rect: ColorRect
var _marker_rect: ColorRect
var _progress_rect: ColorRect
var _marker_pos := 0.5
var _marker_vel := 0.0
var _zone_center := 0.5
var _zone_phase := 0.0
var _progress := 0.0
var _minigame_time := 0.0


func install(ctx: GameContext) -> void:
	_ctx = ctx
	ctx.tools.register_tool(&"fishing", _on_cast)
	_build_minigame_ui()


func _process(delta: float) -> void:
	match _state:
		State.WAITING:
			_sway_bobber(delta)
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				_start_bite()
		State.BITE:
			_sway_alert(delta)
			_bite_timer -= delta
			if _bite_timer <= 0.0:
				_fail_cast("O peixe escapou antes de você puxar!")
		State.MINIGAME:
			_process_minigame(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.BITE and (event.is_action_pressed(&"use_tool") or event.is_action_pressed(&"interact")):
		_start_minigame()
		get_viewport().set_input_as_handled()


func _on_cast(cell: Vector2i, hit: Dictionary, _item: StringName) -> void:
	if _state != State.IDLE:
		return
	var data := _ctx.terrain.data
	if not data.in_bounds(cell) or not WorldConst.is_underwater(data.get_height(cell)):
		EventBus.notify.emit("Jogue a linha na água!", &"tool_rod")
		return
	var player_pos: Vector3 = _ctx.player.global_position
	var target: Vector3 = hit.get("position", Vector3(cell.x + 0.5, WorldConst.WATER_Y, cell.y + 0.5))
	if player_pos.distance_to(target) > CAST_MAX_DIST:
		EventBus.notify.emit("Muito longe! Aproxime-se da água.", &"tool_rod")
		return
	_cell = cell
	_depth = WorldConst.WATER_LEVEL - data.get_height(cell)
	_spawn_bobber(Vector3(cell.x + 0.5, WorldConst.WATER_Y, cell.y + 0.5))
	_state = State.WAITING
	_wait_timer = randf_range(2.0, 6.0)


func _spawn_bobber(pos: Vector3) -> void:
	_bobber = Node3D.new()
	_ctx.main.add_child(_bobber)
	_bobber.global_position = pos
	var float_mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.09
	shape.height = 0.18
	float_mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e84a3a")
	mat.roughness = 0.3
	float_mesh.material_override = mat
	_bobber.add_child(float_mesh)
	var top := MeshInstance3D.new()
	var top_shape := CylinderMesh.new()
	top_shape.top_radius = 0.015
	top_shape.bottom_radius = 0.06
	top_shape.height = 0.12
	top.mesh = top_shape
	top.position.y = 0.12
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color("#f5e8c0")
	top.material_override = top_mat
	_bobber.add_child(top)
	_line = MeshInstance3D.new()
	_ctx.main.add_child(_line)
	var line_mesh := CylinderMesh.new()
	line_mesh.top_radius = 0.004
	line_mesh.bottom_radius = 0.004
	line_mesh.height = 1.0
	_line.mesh = line_mesh
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6)
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = line_mat


func _sway_bobber(delta: float) -> void:
	if _bobber == null:
		return
	_bobber.global_position.y = WorldConst.WATER_Y + sin(Time.get_ticks_msec() * 0.003) * 0.05
	_update_line()


func _update_line() -> void:
	if _bobber == null or _line == null or _ctx.player == null:
		return
	var rod_tip: Vector3 = _ctx.player.global_position + Vector3(0.0, 1.3, 0.0)
	var bobber_pos: Vector3 = _bobber.global_position
	var mid := (rod_tip + bobber_pos) * 0.5
	_line.global_position = mid
	var diff := bobber_pos - rod_tip
	var dist := diff.length()
	(_line.mesh as CylinderMesh).height = maxf(dist, 0.01)
	if dist > 0.001:
		_line.look_at(bobber_pos, Vector3.UP if absf(diff.normalized().y) < 0.99 else Vector3.RIGHT)
		_line.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _start_bite() -> void:
	_state = State.BITE
	_bite_timer = BITE_WINDOW
	var tw := create_tween()
	tw.tween_property(_bobber, "global_position:y", WorldConst.WATER_Y - 0.25, 0.2)
	_alert = Label3D.new()
	_alert.text = "!"
	_alert.font_size = 72
	_alert.modulate = Color("#ffcf3f")
	_alert.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_alert.no_depth_test = true
	_ctx.main.add_child(_alert)
	_alert.global_position = _bobber.global_position + Vector3(0.0, 0.6, 0.0)


func _sway_alert(delta: float) -> void:
	if _alert == null:
		return
	_alert.global_position.y += sin(Time.get_ticks_msec() * 0.02) * delta * 0.4


func _fail_cast(message: String) -> void:
	EventBus.notify.emit(message, &"tool_rod")
	_cleanup_cast()


func _cleanup_cast() -> void:
	if _bobber:
		_bobber.queue_free()
		_bobber = null
	if _line:
		_line.queue_free()
		_line = null
	if _alert:
		_alert.queue_free()
		_alert = null
	_state = State.IDLE


func _start_minigame() -> void:
	_state = State.MINIGAME
	if _alert:
		_alert.queue_free()
		_alert = null
	GameState.ui_blocking += 1
	_marker_pos = 0.5
	_marker_vel = 0.0
	_zone_center = 0.5
	_zone_phase = randf() * TAU
	_progress = 0.0
	_minigame_time = 0.0
	_minigame_layer.visible = true


func _process_minigame(delta: float) -> void:
	_minigame_time += delta
	_zone_center = 0.5 + sin(_minigame_time * 1.4 + _zone_phase) * 0.32
	var holding := Input.is_action_pressed(&"use_tool") or Input.is_action_pressed(&"interact")
	_marker_vel += (MARKER_RISE if holding else -MARKER_FALL) * delta
	_marker_vel = clampf(_marker_vel, -2.0, 2.0)
	_marker_pos = clampf(_marker_pos + _marker_vel * delta, 0.0, 1.0)
	var in_zone := absf(_marker_pos - _zone_center) <= MINIGAME_ZONE_SIZE * 0.5
	_progress = clampf(_progress + (PROGRESS_GAIN if in_zone else -PROGRESS_LOSS) * delta, 0.0, 1.0)
	_refresh_minigame_ui(in_zone)
	if _progress >= 1.0:
		_finish_minigame(true)
	elif _minigame_time >= MINIGAME_DURATION:
		_finish_minigame(false)


func _finish_minigame(success: bool) -> void:
	GameState.ui_blocking -= 1
	_minigame_layer.visible = false
	var pos := _bobber.global_position if _bobber else _ctx.player.global_position
	_cleanup_cast()
	if not success:
		EventBus.notify.emit("O peixe fugiu da linha!", &"tool_rod")
		return
	var day_night := _ctx.day_night
	var hour := day_night.hour if day_night else 12.0
	var fish_id := _fish_table.roll(hour, _depth)
	GameState.give(fish_id, 1)
	GameState.add_stat(&"fish_caught")
	EventBus.notify.emit("Pescou: %s!" % ItemDB.display_name(fish_id), fish_id)
	_animate_catch(pos, fish_id)


func _animate_catch(pos: Vector3, fish_id: StringName) -> void:
	var def := ItemDB.get_def(fish_id)
	var color := def.color if def else Color.WHITE
	var fish := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.1
	body.height = 0.32
	fish.mesh = body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	fish.material_override = mat
	_ctx.main.add_child(fish)
	fish.global_position = pos
	fish.rotation_degrees.z = 90.0
	var tw := create_tween()
	tw.tween_property(fish, "global_position", pos + Vector3(0.0, 1.2, 0.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fish, "rotation_degrees:y", 360.0, 0.6)
	tw.tween_property(fish, "global_position", pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(fish.queue_free)


func _build_minigame_ui() -> void:
	_minigame_layer = CanvasLayer.new()
	_minigame_layer.layer = 20
	_minigame_layer.visible = false
	_ctx.main.add_child(_minigame_layer)
	_bar = Control.new()
	_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.position = Vector2(-160, -140)
	_bar.custom_minimum_size = Vector2(320, 40)
	_minigame_layer.add_child(_bar)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.1, 0.75)
	bg.size = Vector2(320, 40)
	_bar.add_child(bg)
	_zone_rect = ColorRect.new()
	_zone_rect.color = Color("#6dbf4f")
	_zone_rect.size = Vector2(320 * MINIGAME_ZONE_SIZE, 40)
	_bar.add_child(_zone_rect)
	_progress_rect = ColorRect.new()
	_progress_rect.color = Color(0.3, 0.8, 1.0, 0.4)
	_progress_rect.size = Vector2(0, 8)
	_progress_rect.position = Vector2(0, -12)
	_bar.add_child(_progress_rect)
	_marker_rect = ColorRect.new()
	_marker_rect.color = Color("#ffe27a")
	_marker_rect.size = Vector2(6, 48)
	_marker_rect.position.y = -4
	_bar.add_child(_marker_rect)
	var hint := Label.new()
	hint.text = "Mantenha clique/espaço para acompanhar o peixe!"
	hint.position = Vector2(0, -32)
	_bar.add_child(hint)


func _refresh_minigame_ui(_in_zone: bool) -> void:
	_zone_rect.position.x = clampf(_zone_center * 320.0 - _zone_rect.size.x * 0.5, 0.0, 320.0 - _zone_rect.size.x)
	_marker_rect.position.x = clampf(_marker_pos * 320.0 - _marker_rect.size.x * 0.5, 0.0, 320.0 - _marker_rect.size.x)
	_progress_rect.size.x = 320.0 * _progress
