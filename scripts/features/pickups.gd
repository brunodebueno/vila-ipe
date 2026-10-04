class_name Pickups
extends Feature
## Pontos de coleta passiva: cogumelos espalhados pela mata, que voltam a nascer depois de
## colhidos. O grosso da lógica de pickup fica em scripts/world/pickup.gd (classe Pickup),
## com API estática Pickup.spawn_at(world_pos, item_id, amount) usada por outros módulos.

const MUSHROOM_COUNT := 14
const RESPAWN_MIN := 20.0
const RESPAWN_MAX := 45.0

var _ctx: GameContext
var _rng := RandomNumberGenerator.new()


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_rng.randomize()
	for i in MUSHROOM_COUNT:
		_spawn_mushroom_somewhere()


func _spawn_mushroom_somewhere() -> void:
	var data := _ctx.terrain.data
	var center := data.size / 2
	for _attempt in 60:
		var cell := Vector2i(_rng.randi_range(0, data.size.x - 1), _rng.randi_range(0, data.size.y - 1))
		if Vector2(cell - center).length() < 14.0:
			continue
		if WorldConst.is_underwater(data.get_height(cell)) or _ctx.props.is_blocked(cell):
			continue
		var pos := Vector3(cell.x + 0.5, WorldConst.level_to_y(data.get_height(cell)) + 0.1, cell.y + 0.5)
		var pickup := Pickup.spawn_at(pos, &"cogumelo", 1)
		if pickup:
			pickup.tree_exiting.connect(_on_mushroom_gone, CONNECT_ONE_SHOT)
		return


func _on_mushroom_gone() -> void:
	await get_tree().create_timer(_rng.randf_range(RESPAWN_MIN, RESPAWN_MAX)).timeout
	_spawn_mushroom_somewhere()
