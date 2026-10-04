class_name GrassDecor
extends Feature
## Tufos de grama via MultiMesh por chunk de terreno (tiles GRASS), com vento no shader.
## Reconstrói o chunk afetado quando EventBus.terrain_edited dispara.

const GRASS_SHADER := preload("res://assets/shaders/grass_blade.gdshader")
const TUFTS_PER_CELL := 3
const MAX_DISTANCE := 42.0

var _ctx: GameContext
var _data: TerrainData
var _multimeshes: Dictionary = {}  ## Vector2i chunk coord -> MultiMeshInstance3D
var _material: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var _dirty_chunks: Dictionary = {}
var _weather: Node


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_data = ctx.terrain.data
	_rng.seed = 555
	_material = ShaderMaterial.new()
	_material.shader = GRASS_SHADER
	var chunk_count := Vector2i(ceili(float(_data.size.x) / WorldConst.CHUNK_SIZE), ceili(float(_data.size.y) / WorldConst.CHUNK_SIZE))
	for cz in chunk_count.y:
		for cx in chunk_count.x:
			_build_chunk(Vector2i(cx, cz))
	EventBus.terrain_edited.connect(_on_terrain_edited)
	set_process(true)


func _process(delta: float) -> void:
	if not _dirty_chunks.is_empty():
		for coord: Vector2i in _dirty_chunks:
			_build_chunk(coord)
		_dirty_chunks.clear()
	if _material:
		var wind := 0.3
		for node in get_tree().get_nodes_in_group(&"weather_system"):
			if node.has_method("wind_strength"):
				wind = node.call("wind_strength")
		_material.set_shader_parameter(&"wind_strength", wind)


func _on_terrain_edited(cell: Vector2i) -> void:
	var coord := cell / WorldConst.CHUNK_SIZE
	_dirty_chunks[coord] = true


func _build_chunk(coord: Vector2i) -> void:
	var origin := coord * WorldConst.CHUNK_SIZE
	var transforms: Array[Transform3D] = []
	for z in range(origin.y, origin.y + WorldConst.CHUNK_SIZE):
		for x in range(origin.x, origin.x + WorldConst.CHUNK_SIZE):
			var cell := Vector2i(x, z)
			if not _data.in_bounds(cell):
				continue
			if _data.get_tile(cell) != TerrainData.Tile.GRASS:
				continue
			if WorldConst.is_underwater(_data.get_height(cell)):
				continue
			var base_y := WorldConst.level_to_y(_data.get_height(cell))
			for i in TUFTS_PER_CELL:
				var jitter := Vector2(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.4, 0.4))
				var pos := Vector3(x + 0.5 + jitter.x, base_y, z + 0.5 + jitter.y)
				var yaw := _rng.randf() * TAU
				var scale_xy := _rng.randf_range(0.7, 1.15)
				var t := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(scale_xy, scale_xy, scale_xy)), pos)
				transforms.append(t)
	var instance: MultiMeshInstance3D = _multimeshes.get(coord)
	if transforms.is_empty():
		if instance:
			instance.multimesh.instance_count = 0
		return
	if instance == null:
		instance = MultiMeshInstance3D.new()
		instance.name = "GrassChunk_%d_%d" % [coord.x, coord.y]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _blade_mesh()
		instance.multimesh = mm
		instance.material_override = _material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		_multimeshes[coord] = instance
	var mm := instance.multimesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])


func _blade_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.035
	var h := 0.32
	var verts := [
		Vector3(-w, 0.0, 0.0), Vector3(w, 0.0, 0.0), Vector3(0.0, h, 0.0),
	]
	var uvs := [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.5, 1.0)]
	for i in 3:
		st.set_uv(uvs[i])
		st.set_normal(Vector3.UP)
		st.add_vertex(verts[i])
	st.generate_tangents()
	return st.commit()
