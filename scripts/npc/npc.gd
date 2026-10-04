class_name Npc
extends Node3D
## Um morador da vila: rotina por hora, caminha evitando água/desníveis (como Capybara),
## acena perto do jogador e conversa (F). Dados vêm de data/npcs.json e data/dialogues.json.

signal talked_to(npc: Npc)
signal gift_received(npc: Npc, item_id: StringName)

const SPEED := 1.25
const WAVE_RADIUS := 3.0
const ARRIVE_SPEED := 2.6

var id: StringName
var def: Dictionary
var lines: Dictionary
var friendship: int = 0
var home_cell: Vector2i
var work_cell: Vector2i
var square_cell: Vector2i

var _terrain_data: TerrainData
var _props: PropManager
var _target := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()
var _visual: Node3D
var _speech: Label3D
var _player_near := false
var _wave_time := 0.0
var _ambient_timer := 0.0
var _arriving := false
var _player_ref: Node3D


func setup(p_id: StringName, p_def: Dictionary, p_lines: Dictionary, data: TerrainData, props: PropManager, player: Node3D, seed_offset: int) -> void:
	id = p_id
	def = p_def
	lines = p_lines
	_terrain_data = data
	_props = props
	_player_ref = player
	_rng.seed = seed_offset * 7919 + 13
	var center := WorldConst.MAP_SIZE / 2
	home_cell = center + Vector2i(def.get("home_offset", [0, 0])[0], def.get("home_offset", [0, 0])[1])
	work_cell = center + Vector2i(def.get("work_offset", [0, 0])[0], def.get("work_offset", [0, 0])[1])
	square_cell = center + Vector2i(def.get("square_offset", [0, 0])[0], def.get("square_offset", [0, 0])[1])
	_visual = NpcModel.create(id, def)
	add_child(_visual)
	_speech = NpcModel.make_speech_label()
	add_child(_speech)
	_build_area()
	_target = position
	_ambient_timer = _rng.randf_range(6.0, 14.0)
	EventBus.hour_changed.connect(_on_hour_changed)


func place_at_home() -> void:
	var p := _cell_pos(home_cell)
	position = p
	_target = p


func arrive_from(edge_cell: Vector2i) -> void:
	position = _cell_pos(edge_cell)
	_arriving = true
	_target = _cell_pos(home_cell)


func _build_area() -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = WAVE_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(_b: Node3D) -> void: _player_near = true)
	area.body_exited.connect(func(_b: Node3D) -> void: _player_near = false)


func _cell_pos(cell: Vector2i) -> Vector3:
	var h := _terrain_data.get_height(cell) if _terrain_data else WorldConst.WATER_LEVEL + 2
	return Vector3(cell.x + 0.5, WorldConst.level_to_y(h), cell.y + 0.5)


func _on_hour_changed(hour: float) -> void:
	if _arriving:
		return
	var target_cell := home_cell
	if hour >= 6.0 and hour < 12.0:
		target_cell = square_cell
	elif hour >= 12.0 and hour < 18.5:
		target_cell = work_cell
	_target = _cell_pos(target_cell) + Vector3(_rng.randf_range(-0.6, 0.6), 0.0, _rng.randf_range(-0.6, 0.6))


func _process(delta: float) -> void:
	_move(delta)
	_update_wave(delta)
	_update_ambient_speech(delta)


func _move(delta: float) -> void:
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < 0.2:
		return
	var speed := ARRIVE_SPEED if _arriving else SPEED
	var step := to_target.normalized() * speed * delta
	var next := position + step
	if _terrain_data:
		var here := _terrain_data.get_height(WorldConst.world_to_cell(position))
		var there := _terrain_data.get_height(WorldConst.world_to_cell(next))
		if absi(there - here) > 1 or WorldConst.is_underwater(there):
			_arriving = false
			return
	position.x = next.x
	position.z = next.z
	if _terrain_data:
		var h := _terrain_data.get_height(WorldConst.world_to_cell(position))
		position.y = lerpf(position.y, WorldConst.level_to_y(h), 1.0 - exp(-10.0 * delta))
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(to_target.x, to_target.z) + PI, 1.0 - exp(-6.0 * delta))
	if _arriving and to_target.length() < 0.5:
		_arriving = false


func _update_wave(delta: float) -> void:
	if _player_near:
		_wave_time += delta * 8.0
		_visual.rotation.z = sin(_wave_time) * 0.12
	else:
		_wave_time = 0.0
		_visual.rotation.z = lerpf(_visual.rotation.z, 0.0, 1.0 - exp(-8.0 * delta))


func _update_ambient_speech(delta: float) -> void:
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		_ambient_timer = _rng.randf_range(10.0, 20.0)
		if _player_near and not GameState.is_ui_blocking():
			var pool: Array = lines.get("ambiente", [])
			if not pool.is_empty():
				say(pool[_rng.randi() % pool.size()])


func say(text: String, duration: float = 3.0) -> void:
	_speech.text = text
	_speech.visible = true
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func() -> void: _speech.visible = false)


func is_player_near() -> bool:
	return _player_near


func display_name() -> String:
	return String(def.get("name", String(id)))


func gain_friendship(amount: int) -> void:
	friendship = clampi(friendship + amount, 0, 10)
