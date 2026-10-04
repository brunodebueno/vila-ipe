class_name HarvestRocks
extends Feature
## Picareta: quebra rochas (2-3 golpes) com tremor, rendendo pedra e, às vezes, argila.
## Também entrega o kit inicial de coleta (picareta + puçá) uma única vez.

const HITS_SMALL := 2
const HITS_BIG := 3
const CLAY_CHANCE := 0.3

var _ctx: GameContext
var _hits: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_rng.randomize()
	ctx.tools.register_tool(&"pickaxe", _on_pickaxe)
	_give_starter_kit()


func _give_starter_kit() -> void:
	if GameState.get_flag(&"harvest_starter"):
		return
	GameState.set_flag(&"harvest_starter", true)
	GameState.give(&"tool_pickaxe", 1)
	GameState.give(&"tool_net", 1)
	EventBus.notify.emit("Kit de coleta: picareta e puçá!", &"tool_pickaxe")


func _on_pickaxe(cell: Vector2i, _hit: Dictionary, _item: StringName) -> void:
	if not _ctx.props.has_rock_at(cell):
		return
	var id := _ctx.props.rock_id_at(cell)
	var rock := _ctx.props.get_rock_at(cell)
	var needed := HITS_BIG if id == &"rock_big" else HITS_SMALL
	var hits: int = int(_hits.get(cell, 0)) + 1
	_hits[cell] = hits
	_ctx.props.shake_prop(rock)
	_spawn_chip_burst(rock.global_position)
	EventBus.object_harvested.emit(&"rock", cell)
	if hits < needed:
		return
	_hits.erase(cell)
	var pos := rock.global_position
	_ctx.props.remove_rock(cell)
	_drop_rock_rewards(id, pos)
	GameState.add_stat(&"rocks_broken")


func _drop_rock_rewards(id: StringName, pos: Vector3) -> void:
	var amount := _rng.randi_range(2, 4) if id == &"rock_big" else _rng.randi_range(1, 2)
	Pickup.spawn_at(pos, &"stone", amount)
	if _rng.randf() < CLAY_CHANCE:
		Pickup.spawn_at(pos + Vector3(0.25, 0.1, -0.2), &"clay", _rng.randi_range(1, 2))


func _spawn_chip_burst(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	_ctx.main.add_child(p)
	p.global_position = pos + Vector3(0.0, 0.5, 0.0)
	p.one_shot = true
	p.emitting = false
	p.amount = 10
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0.0, -8.0, 0.0)
	p.color = Color("#9a9aa2")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.08)
	p.mesh = mesh
	p.emitting = true
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)
