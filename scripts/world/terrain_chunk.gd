class_name TerrainChunk
extends MeshInstance3D
## Um pedaço 16x16 do terreno em blocos: topo colorido por piso + paredes onde há desnível.

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var coord: Vector2i
var _shape: CollisionShape3D


func setup(p_coord: Vector2i, material: Material) -> void:
	coord = p_coord
	material_override = material
	name = "Chunk_%d_%d" % [coord.x, coord.y]
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_shape = CollisionShape3D.new()
	body.add_child(_shape)
	add_child(body)


func rebuild(data: TerrainData) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var origin := coord * WorldConst.CHUNK_SIZE
	for z in range(origin.y, origin.y + WorldConst.CHUNK_SIZE):
		for x in range(origin.x, origin.x + WorldConst.CHUNK_SIZE):
			var cell := Vector2i(x, z)
			if data.in_bounds(cell):
				_add_cell(st, data, cell)
	var new_mesh := st.commit()
	mesh = new_mesh
	_shape.shape = new_mesh.create_trimesh_shape()


func _add_cell(st: SurfaceTool, data: TerrainData, cell: Vector2i) -> void:
	var level := data.get_height(cell)
	var tile := data.get_tile(cell)
	var y := WorldConst.level_to_y(level)
	var x := float(cell.x)
	var z := float(cell.y)
	var shade := _cell_shade(cell)
	var top_color := _shade(WorldConst.tile_color(tile), shade)
	_quad(st, Vector3(x, y, z), Vector3(x + 1.0, y, z), Vector3(x + 1.0, y, z + 1.0), Vector3(x, y, z + 1.0), Vector3.UP, top_color)
	var wall_color := _shade(WorldConst.wall_color(tile), shade)
	for dir in NEIGHBORS:
		var neighbor_level := data.get_height(cell + dir)
		if neighbor_level >= level:
			continue
		var low := WorldConst.level_to_y(neighbor_level)
		var center := Vector2(x + 0.5, z + 0.5) + Vector2(dir) * 0.5
		var tangent := Vector2(-dir.y, dir.x) * 0.5
		var p0 := center - tangent
		var p1 := center + tangent
		_quad(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p1.x, low, p1.y), Vector3(p0.x, low, p0.y), Vector3(dir.x, 0.0, dir.y), wall_color)


## Emite um quad com a ordem de vértices correta para a normal informada.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	if (c - a).cross(b - a).dot(normal) < 0.0:
		var swap := b
		b = d
		d = swap
	for v: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.set_color(color)
		st.add_vertex(v)


func _cell_shade(cell: Vector2i) -> float:
	var h := ((cell.x * 73856093) ^ (cell.y * 19349663)) & 0xff
	return 0.96 + (h / 255.0) * 0.08


func _shade(c: Color, s: float) -> Color:
	return Color(c.r * s, c.g * s, c.b * s)
