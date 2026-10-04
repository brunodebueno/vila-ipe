class_name Terrain
extends Node3D
## Gerencia os chunks do terreno e a água. Reconstrói só os chunks sujos.

const WATER_SHADER := preload("res://assets/shaders/water.gdshader")

var data: TerrainData
var _chunks: Dictionary = {}
var _dirty: Dictionary = {}
var _material: StandardMaterial3D


func build(p_data: TerrainData) -> void:
	data = p_data
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 1.0
	_material.metallic_specular = 0.1
	var chunk_count := Vector2i(ceili(float(data.size.x) / WorldConst.CHUNK_SIZE), ceili(float(data.size.y) / WorldConst.CHUNK_SIZE))
	for cz in chunk_count.y:
		for cx in chunk_count.x:
			var chunk := TerrainChunk.new()
			add_child(chunk)
			chunk.setup(Vector2i(cx, cz), _material)
			chunk.rebuild(data)
			_chunks[chunk.coord] = chunk
	data.cell_changed.connect(_on_cell_changed)
	_build_water()


func top_y(cell: Vector2i) -> float:
	return WorldConst.level_to_y(data.get_height(cell))


func _process(_delta: float) -> void:
	if _dirty.is_empty():
		return
	for coord: Vector2i in _dirty:
		(_chunks[coord] as TerrainChunk).rebuild(data)
	_dirty.clear()


func _on_cell_changed(cell: Vector2i) -> void:
	_mark_dirty(cell)
	for dir in TerrainChunk.NEIGHBORS:
		_mark_dirty(cell + dir)


func _mark_dirty(cell: Vector2i) -> void:
	if not data.in_bounds(cell):
		return
	var coord := cell / WorldConst.CHUNK_SIZE
	if _chunks.has(coord):
		_dirty[coord] = true


func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(500.0, 500.0)
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.material_override = mat
	water.position = Vector3(data.size.x * 0.5, WorldConst.WATER_Y, data.size.y * 0.5)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
