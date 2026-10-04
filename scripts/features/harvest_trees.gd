class_name HarvestTrees
extends Feature
## Machado: golpeia árvores (3 golpes derruba, com tremor e folhas) e rende madeira/fibra,
## mudas e flores. Também cuida do cultivo e colheita das árvores frutíferas (jabuticabeira,
## cajueiro, pitangueira): tecla F ou clique sem ferramenta adequada sacode a árvore e as
## frutas caem como pickups; as frutas voltam com a virada do dia.

const FELL_HITS := 3
const SAPLING_CHANCE := 0.35
const FLOWER_CHANCE := 0.25

const SAPLING_MAP := {
	&"tree_ipe_yellow": &"sapling_ipe",
	&"tree_ipe_purple": &"sapling_ipe",
	&"tree_palm": &"sapling_palm",
	&"tree_fruit_jabuticaba": &"sapling_fruit_jabuticaba",
	&"tree_fruit_caju": &"sapling_fruit_caju",
	&"tree_fruit_pitanga": &"sapling_fruit_pitanga",
}
const FRUIT_MAP := {
	&"tree_fruit_jabuticaba": &"fruit_jabuticaba",
	&"tree_fruit_caju": &"fruit_caju",
	&"tree_fruit_pitanga": &"fruit_pitanga",
}
const SAPLING_TOOLS := {
	&"sapling_fruit_jabuticaba": &"tree_fruit_jabuticaba",
	&"sapling_fruit_caju": &"tree_fruit_caju",
	&"sapling_fruit_pitanga": &"tree_fruit_pitanga",
}

var _ctx: GameContext
var _hits: Dictionary = {}
var _fruit_ready: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _last_hour := 12.0


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_rng.randomize()
	ctx.tools.register_tool(&"axe", _on_axe)
	for sapling: StringName in SAPLING_TOOLS:
		var def := ItemDB.get_def(sapling)
		if def and def.tool != &"":
			ctx.tools.register_tool(def.tool, _make_planter(SAPLING_TOOLS[sapling]))
	EventBus.hour_changed.connect(_on_hour_changed)


func _make_planter(tree_id: StringName) -> Callable:
	return func(cell: Vector2i, _hit: Dictionary, item: StringName) -> void:
		_plant_fruit(cell, item, tree_id)


func _unhandled_input(event: InputEvent) -> void:
	if _ctx == null or not _ctx.tools.enabled or GameState.is_ui_blocking():
		return
	if not _ctx.tools.has_hover:
		return
	var is_interact := event.is_action_pressed(&"interact")
	var is_click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if not is_interact and not is_click:
		return
	if is_click:
		var item := GameState.selected_item()
		var def := ItemDB.get_def(item) if item != &"" else null
		if def != null and def.tool == &"axe":
			return
	_try_shake_fruit(_ctx.tools.hover_cell)


func _on_axe(cell: Vector2i, _hit: Dictionary, _item: StringName) -> void:
	if not _ctx.props.has_tree_at(cell):
		return
	var id := _ctx.props.tree_id_at(cell)
	var tree := _ctx.props.get_tree_at(cell)
	var hits: int = int(_hits.get(cell, 0)) + 1
	_hits[cell] = hits
	_ctx.props.shake_prop(tree)
	_spawn_leaf_burst(tree.global_position)
	EventBus.object_harvested.emit(&"tree", cell)
	if hits < FELL_HITS:
		return
	_hits.erase(cell)
	var pos := tree.global_position
	_ctx.props.fell_tree(cell)
	_drop_tree_rewards(id, pos)
	GameState.add_stat(&"trees_felled")


func _drop_tree_rewards(id: StringName, pos: Vector3) -> void:
	var s := String(id)
	if s == "tree_palm":
		Pickup.spawn_at(pos, &"fiber", _rng.randi_range(2, 4))
	else:
		Pickup.spawn_at(pos, &"wood", _rng.randi_range(2, 4))
	var sapling: StringName = SAPLING_MAP.get(id, &"")
	if sapling != &"" and _rng.randf() < SAPLING_CHANCE:
		Pickup.spawn_at(pos + Vector3(0.3, 0.15, 0.2), sapling, 1)
	if (s == "tree_ipe_yellow" or s == "tree_ipe_purple") and _rng.randf() < FLOWER_CHANCE:
		Pickup.spawn_at(pos + Vector3(-0.3, 0.15, -0.2), &"flower_ipe", 1)


func _plant_fruit(cell: Vector2i, item: StringName, tree_id: StringName) -> void:
	if not GameState.inventory.has(item):
		EventBus.notify.emit("Sem mudas! Colete sementes primeiro.", item)
		return
	if _ctx.props.plant_tree(cell, tree_id, _rng.randf_range(0.85, 1.1)):
		GameState.inventory.remove(item, 1)
		GameState.add_stat(&"trees_planted")
		EventBus.terrain_edited.emit(cell)


func _try_shake_fruit(cell: Vector2i) -> void:
	if not _ctx.props.has_tree_at(cell):
		return
	var id := _ctx.props.tree_id_at(cell)
	if not FRUIT_MAP.has(id):
		return
	if not bool(_fruit_ready.get(cell, true)):
		EventBus.notify.emit("Sem frutas agora. Volte outro dia.", &"")
		return
	var tree := _ctx.props.get_tree_at(cell)
	_ctx.props.shake_prop(tree)
	_drop_fruit(cell, id, tree)
	_fruit_ready[cell] = false


func _drop_fruit(cell: Vector2i, id: StringName, tree: Node3D) -> void:
	var fruit_id: StringName = FRUIT_MAP[id]
	var count := _rng.randi_range(1, 3)
	for i in count:
		var offset := Vector3(_rng.randf_range(-0.4, 0.4), 1.1 + _rng.randf_range(0.0, 0.3), _rng.randf_range(-0.4, 0.4))
		Pickup.spawn_at(tree.global_position + offset, fruit_id, 1)
	if id == &"tree_fruit_caju" and _rng.randf() < 0.5:
		Pickup.spawn_at(tree.global_position + Vector3(0.2, 1.0, -0.2), &"castanha_caju", 1)
	EventBus.object_harvested.emit(&"fruit_tree", cell)
	GameState.add_stat(&"fruit_harvested")


func _on_hour_changed(hour: float) -> void:
	if hour < _last_hour:
		for cell in _fruit_ready.keys():
			_fruit_ready[cell] = true
	_last_hour = hour


func _spawn_leaf_burst(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	_ctx.main.add_child(p)
	p.global_position = pos + Vector3(0.0, 1.6, 0.0)
	p.one_shot = true
	p.emitting = false
	p.amount = 14
	p.lifetime = 0.8
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	p.gravity = Vector3(0.0, -4.0, 0.0)
	p.color = Color("#5fae3f")
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	p.mesh = mesh
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
