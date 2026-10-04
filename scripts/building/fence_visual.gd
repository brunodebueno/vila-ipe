class_name FenceVisual
extends Node3D
## Cerca que se conecta automaticamente às vizinhas: sempre tem um poste central e
## acrescenta travessas nas direções (norte/sul/leste/oeste) onde há outra cerca vizinha.

var _rails_holder: Node3D
var _color: Color


func setup(color: Color) -> void:
	_color = color
	_build_post()
	_rails_holder = Node3D.new()
	add_child(_rails_holder)


## dirs: Dictionary com chaves &"north", &"south", &"east", &"west" -> bool.
func set_connections(dirs: Dictionary) -> void:
	for child in _rails_holder.get_children():
		child.queue_free()
	var offsets := {
		&"north": Vector3(0, 0, -0.5),
		&"south": Vector3(0, 0, 0.5),
		&"east": Vector3(0.5, 0, 0),
		&"west": Vector3(-0.5, 0, 0),
	}
	var rotations := {
		&"north": 0.0, &"south": 0.0, &"east": 90.0, &"west": 90.0,
	}
	for dir: StringName in dirs:
		if not dirs[dir]:
			continue
		var rail := _mesh(_box(Vector3(0.42, 0.1, 0.06)), _color.darkened(0.05), offsets[dir] + Vector3(0, 0.55, 0), _rails_holder)
		rail.rotation_degrees.y = rotations[dir]
		var rail2 := _mesh(_box(Vector3(0.42, 0.1, 0.06)), _color.darkened(0.12), offsets[dir] + Vector3(0, 0.28, 0), _rails_holder)
		rail2.rotation_degrees.y = rotations[dir]


func _build_post() -> void:
	_mesh(_box(Vector3(0.14, 0.9, 0.14)), _color, Vector3(0, 0.45, 0))
	_mesh(_cone(0.1, 0.16), _color.darkened(0.1), Vector3(0, 0.95, 0))


func _mesh(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cone(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 8
	return c
