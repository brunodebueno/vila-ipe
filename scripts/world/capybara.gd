class_name Capybara
extends Node3D
## Capivara dócil: vaga pelo terreno, para para "pastar" e evita água funda e desníveis grandes.

const SPEED := 0.9

var data: TerrainData
var _target := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_data: TerrainData, id: int) -> void:
	data = p_data
	_rng.seed = id * 7919
	add_child(PropLibrary.create(&"capybara"))
	_target = position
	_wait = _rng.randf_range(0.0, 3.0)


func _process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
		return
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < 0.15:
		_wait = _rng.randf_range(2.0, 6.0)
		return
	var step := to_target.normalized() * SPEED * delta
	var next := position + step
	var here := data.get_height(WorldConst.world_to_cell(position))
	var there := data.get_height(WorldConst.world_to_cell(next))
	if absi(there - here) > 1 or WorldConst.is_underwater(there):
		_wait = 0.5
		return
	position.x = next.x
	position.z = next.z
	position.y = lerpf(position.y, WorldConst.level_to_y(there), 1.0 - exp(-10.0 * delta))
	rotation.y = lerp_angle(rotation.y, atan2(to_target.x, to_target.z) + PI, 1.0 - exp(-6.0 * delta))


func _pick_target() -> void:
	var angle := _rng.randf() * TAU
	var dist := _rng.randf_range(1.5, 5.0)
	_target = position + Vector3(cos(angle), 0.0, sin(angle)) * dist
