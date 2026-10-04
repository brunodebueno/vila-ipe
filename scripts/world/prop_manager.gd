class_name PropManager
extends Node3D
## Árvores e construções sobre o terreno. Mantém os props alinhados quando o terreno muda.

var _data: TerrainData
var _trees: Dictionary = {}
var _buildings: Dictionary = {}
var _rocks: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func setup(data: TerrainData, world_seed: int) -> void:
	_data = data
	_rng.seed = world_seed + 99
	_data.cell_changed.connect(_on_cell_changed)


func is_building_cell(cell: Vector2i) -> bool:
	return _buildings.has(cell)


func is_blocked(cell: Vector2i) -> bool:
	return _buildings.has(cell) or _trees.has(cell) or _rocks.has(cell) or BuildRegistry.is_occupied(cell)


## Gancho para o módulo de Construção marcar células ocupadas por objetos colocados
## (bancos, cercas, casas…), sem que PropManager precise conhecer o BuildRegistry em detalhe.
func register_blocker(cell: Vector2i) -> void:
	BuildRegistry.register(cell, &"")


func unregister_blocker(cell: Vector2i) -> void:
	BuildRegistry.unregister(cell)


func can_plant(cell: Vector2i) -> bool:
	if not _data.in_bounds(cell) or is_blocked(cell):
		return false
	if WorldConst.is_underwater(_data.get_height(cell)):
		return false
	var tile := _data.get_tile(cell)
	return tile == TerrainData.Tile.GRASS or tile == TerrainData.Tile.DIRT or tile == TerrainData.Tile.SAND and _data.get_height(cell) > WorldConst.WATER_LEVEL + 1


func plant_tree(cell: Vector2i, id: StringName, scale: float = 1.0, animate: bool = true) -> bool:
	if not can_plant(cell):
		return false
	var tree := PropLibrary.create(id)
	tree.set_meta(&"prop_id", id)
	tree.position = _cell_origin(cell) + Vector3(_rng.randf_range(-0.15, 0.15), 0.0, _rng.randf_range(-0.15, 0.15))
	tree.rotation.y = _rng.randf() * TAU
	add_child(tree)
	_trees[cell] = tree
	var final_scale := tree.scale * scale
	if animate:
		tree.scale = final_scale * 0.1
		var tw := create_tween()
		tw.tween_property(tree, "scale", final_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tree.scale = final_scale
	return true


func remove_tree(cell: Vector2i) -> void:
	if not _trees.has(cell):
		return
	var tree: Node3D = _trees[cell]
	_trees.erase(cell)
	var tw := create_tween()
	tw.tween_property(tree, "scale", Vector3.ONE * 0.01, 0.2)
	tw.tween_callback(tree.queue_free)


## Constrói num footprint de (2*radius+1)² células centrado em `cell`.
func place_building(cell: Vector2i, id: StringName, yaw: float, radius: int) -> void:
	var building := PropLibrary.create(id)
	building.position = _cell_origin(cell)
	building.rotation.y = yaw
	add_child(building)
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			_buildings[cell + Vector2i(dx, dz)] = building


func _cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, WorldConst.level_to_y(_data.get_height(cell)), cell.y + 0.5)


func _on_cell_changed(cell: Vector2i) -> void:
	if not _trees.has(cell):
		return
	var tile := _data.get_tile(cell)
	if WorldConst.is_underwater(_data.get_height(cell)) or tile == TerrainData.Tile.PATH:
		remove_tree(cell)
		return
	(_trees[cell] as Node3D).position.y = WorldConst.level_to_y(_data.get_height(cell))


## API usada pelo sistema de save (agente Sistema): serializa/restaura as árvores plantadas.
func serialize_trees() -> Array:
	var out: Array = []
	for cell: Vector2i in _trees:
		var tree: Node3D = _trees[cell]
		out.append({
			"cell": [cell.x, cell.y],
			"id": String(tree.get_meta(&"prop_id", &"tree_generic")),
			"scale": tree.scale.x,
			"rotation_y": tree.rotation.y,
		})
	return out


func restore_trees(arr: Array) -> void:
	for cell: Vector2i in _trees.keys().duplicate():
		remove_tree(cell)
	for entry: Dictionary in arr:
		var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
		var id := StringName(entry["id"])
		if plant_tree(cell, id, float(entry.get("scale", 1.0)), false):
			var tree: Node3D = _trees[cell]
			tree.rotation.y = float(entry.get("rotation_y", 0.0))


## Nó 3D da árvore na célula, ou null se não houver.
func get_tree_at(cell: Vector2i) -> Node3D:
	return _trees.get(cell) as Node3D


## Id usado em PropLibrary.create() para a árvore na célula, ou "" se vazio.
func tree_id_at(cell: Vector2i) -> StringName:
	if not _trees.has(cell):
		return &""
	var tree: Node3D = _trees[cell]
	return StringName(tree.get_meta(&"prop_id", &""))


func has_tree_at(cell: Vector2i) -> bool:
	return _trees.has(cell)


## Derruba a árvore com uma animação de queda (tomba e encolhe) antes de remover.
func fell_tree(cell: Vector2i) -> void:
	if not _trees.has(cell):
		return
	var tree: Node3D = _trees[cell]
	_trees.erase(cell)
	var axis := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(tree, "rotation", tree.rotation + Vector3(axis.x, 0.0, axis.z) * (PI * 0.5), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(tree, "position", tree.position + Vector3(axis.x, -0.1, axis.z) * 0.6, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(tree, "scale", Vector3.ONE * 0.01, 0.25)
	tw.chain().tween_callback(tree.queue_free)


## Pequeno tremor instantâneo (golpe de machado/picareta sem derrubar ainda).
func shake_prop(node: Node3D) -> void:
	if node == null:
		return
	var base_pos := node.position
	var tw := create_tween()
	for _i in 3:
		tw.tween_property(node, "position", base_pos + Vector3(randf_range(-0.08, 0.08), 0.0, randf_range(-0.08, 0.08)), 0.05)
	tw.tween_property(node, "position", base_pos, 0.06)


## --- Rochas ---

func place_rock(cell: Vector2i, id: StringName, scale: float = 1.0) -> bool:
	if not _data.in_bounds(cell) or is_blocked(cell) or WorldConst.is_underwater(_data.get_height(cell)):
		return false
	var rock := PropLibrary.create(id)
	rock.set_meta(&"prop_id", id)
	rock.position = _cell_origin(cell) + Vector3(_rng.randf_range(-0.2, 0.2), 0.0, _rng.randf_range(-0.2, 0.2))
	rock.rotation.y = _rng.randf() * TAU
	rock.scale = Vector3.ONE * scale
	add_child(rock)
	_rocks[cell] = rock
	return true


func get_rock_at(cell: Vector2i) -> Node3D:
	return _rocks.get(cell) as Node3D


func rock_id_at(cell: Vector2i) -> StringName:
	if not _rocks.has(cell):
		return &""
	var rock: Node3D = _rocks[cell]
	return StringName(rock.get_meta(&"prop_id", &""))


func has_rock_at(cell: Vector2i) -> bool:
	return _rocks.has(cell)


func remove_rock(cell: Vector2i) -> void:
	if not _rocks.has(cell):
		return
	var rock: Node3D = _rocks[cell]
	_rocks.erase(cell)
	var tw := create_tween()
	tw.tween_property(rock, "position", rock.position + Vector3(0.0, -0.3, 0.0), 0.3)
	tw.parallel().tween_property(rock, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(rock.queue_free)
