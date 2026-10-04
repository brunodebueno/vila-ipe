class_name EconomyMesh
extends RefCounted
## Helpers de malha procedural compartilhados pelos props do módulo de economia
## (barraca, bancada, caixa de entregas). Não depende de PropLibrary.

static func mi(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot_deg
	parent.add_child(m)
	return m


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 10
	return c


static func sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s
