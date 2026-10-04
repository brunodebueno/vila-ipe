class_name PropLibrary
extends RefCounted
## Fábrica de props. Usa o .glb gerado no Mixar quando existir em
## res://assets/models/<categoria>/<id>.glb; senão usa um modelo procedural provisório.

const MODEL_DIR := "res://assets/models/"
const CATEGORIES := {
	"tree_": "trees",
	"house_": "buildings",
	"capybara": "animals",
	"player": "characters",
}


static func create(id: StringName) -> Node3D:
	var path := "%s%s/%s.glb" % [MODEL_DIR, _category(id), id]
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene.instantiate() as Node3D
	return _fallback(id)


static func _category(id: StringName) -> String:
	for prefix: String in CATEGORIES:
		if String(id).begins_with(prefix):
			return CATEGORIES[prefix]
	return "props"


static func _fallback(id: StringName) -> Node3D:
	var s := String(id)
	if s == "tree_ipe_yellow":
		return _tree(Color("#ffc928"), 1.0)
	if s == "tree_ipe_purple":
		return _tree(Color("#b85fd9"), 1.0)
	if s == "tree_palm":
		return _palm()
	if s == "tree_fruit_jabuticaba":
		return _fruit_tree(Color("#2f7a3a"), Color("#4a1a4a"), 0.03)
	if s == "tree_fruit_caju":
		return _fruit_tree(Color("#3a8f4f"), Color("#f28a2e"), 0.06)
	if s == "tree_fruit_pitanga":
		return _fruit_tree(Color("#2f8f4a"), Color("#d6281e"), 0.045)
	if s.begins_with("tree_"):
		return _tree(Color("#2f8f4a"), 1.1)
	if s.begins_with("house_colonial_"):
		return _house(s.trim_prefix("house_colonial_"))
	if s == "capybara":
		return _capybara()
	if s == "rock_small":
		return _rock(0.45)
	if s == "rock_big":
		return _rock(0.9)
	return _player()


static func _mi(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO) -> MeshInstance3D:
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


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 10
	return c


static func _tree(bloom: Color, scale: float) -> Node3D:
	var n := Node3D.new()
	_mi(n, _cyl(0.1, 0.18, 1.4), Color("#7a5230"), Vector3(0, 0.7, 0))
	_mi(n, _sphere(0.85), bloom, Vector3(0, 1.9, 0))
	_mi(n, _sphere(0.6), bloom.lightened(0.12), Vector3(0.5, 1.6, 0.2))
	_mi(n, _sphere(0.55), bloom.darkened(0.1), Vector3(-0.45, 1.65, -0.25))
	n.scale = Vector3.ONE * scale
	return n


static func _palm() -> Node3D:
	var n := Node3D.new()
	_mi(n, _cyl(0.1, 0.16, 2.4), Color("#8d6a43"), Vector3(0, 1.2, 0))
	for i in 6:
		var yaw := i * 60.0
		var holder := Node3D.new()
		holder.rotation_degrees = Vector3(0, yaw, 0)
		holder.position = Vector3(0, 2.4, 0)
		n.add_child(holder)
		_mi(holder, _box(Vector3(0.25, 0.05, 1.5)), Color("#3aa04f"), Vector3(0, -0.15, -0.65), Vector3(-25, 0, 0))
	return n


static func _house(variant: String) -> Node3D:
	var wall := {"blue": "#7fb8e0", "pink": "#f2a7b8", "yellow": "#f6d36b", "green": "#8fd19a"}.get(variant, "#f2e3c2") as String
	var n := Node3D.new()
	_mi(n, _box(Vector3(2.6, 1.7, 2.6)), Color(wall), Vector3(0, 0.85, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(3.1, 1.1, 3.1)
	_mi(n, roof, Color("#c4623a"), Vector3(0, 2.25, 0))
	_mi(n, _box(Vector3(0.6, 1.1, 0.08)), Color("#6b4226"), Vector3(0, 0.55, 1.32))
	_mi(n, _box(Vector3(0.5, 0.5, 0.08)), Color("#dff3ff"), Vector3(-0.85, 1.1, 1.32))
	_mi(n, _box(Vector3(0.5, 0.5, 0.08)), Color("#dff3ff"), Vector3(0.85, 1.1, 1.32))
	return n


static func _capybara() -> Node3D:
	var n := Node3D.new()
	var fur := Color("#9a6b43")
	_mi(n, _box(Vector3(0.5, 0.42, 0.95)), fur, Vector3(0, 0.38, 0))
	_mi(n, _box(Vector3(0.34, 0.32, 0.42)), fur.lightened(0.05), Vector3(0, 0.5, -0.6))
	_mi(n, _box(Vector3(0.2, 0.14, 0.12)), fur.darkened(0.25), Vector3(0, 0.46, -0.84))
	for sx in [-0.18, 0.18]:
		for sz in [-0.3, 0.3]:
			_mi(n, _box(Vector3(0.12, 0.2, 0.12)), fur.darkened(0.2), Vector3(sx, 0.1, sz))
	return n


static func _player() -> Node3D:
	var n := Node3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.3
	body.height = 1.0
	_mi(n, body, Color("#2f7fd1"), Vector3(0, 0.55, 0))
	_mi(n, _sphere(0.32), Color("#b8805a"), Vector3(0, 1.3, 0))
	_mi(n, _cyl(0.55, 0.55, 0.05), Color("#e8c875"), Vector3(0, 1.5, 0))
	_mi(n, _cyl(0.24, 0.28, 0.22), Color("#e8c875"), Vector3(0, 1.62, 0))
	return n


static func _fruit_tree(foliage: Color, fruit: Color, fruit_r: float) -> Node3D:
	var n := Node3D.new()
	_mi(n, _cyl(0.1, 0.16, 1.3), Color("#7a5230"), Vector3(0, 0.65, 0))
	_mi(n, _sphere(0.75), foliage, Vector3(0, 1.7, 0))
	_mi(n, _sphere(0.5), foliage.lightened(0.1), Vector3(0.45, 1.5, 0.15))
	_mi(n, _sphere(0.48), foliage.darkened(0.08), Vector3(-0.4, 1.5, -0.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(fruit.to_rgba32())
	for i in 10:
		var yaw := rng.randf() * TAU
		var pitch := rng.randf_range(-0.6, 0.6)
		var r := rng.randf_range(0.55, 0.85)
		var pos := Vector3(cos(yaw) * r, 1.7 + pitch, sin(yaw) * r)
		_mi(n, _sphere(fruit_r), fruit, pos)
	return n


static func _rock(scale: float) -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scale * 1000.0)
	var base := Color("#8a8a92")
	_mi(n, _box(Vector3(1.0, 0.7, 0.9) * scale), base, Vector3(0, 0.35 * scale, 0), Vector3(0, 18, 4))
	_mi(n, _box(Vector3(0.6, 0.5, 0.65) * scale), base.lightened(0.08), Vector3(0.25 * scale, 0.45 * scale, -0.15 * scale), Vector3(0, -22, -6))
	_mi(n, _box(Vector3(0.45, 0.35, 0.4) * scale), base.darkened(0.1), Vector3(-0.3 * scale, 0.28 * scale, 0.2 * scale), Vector3(0, 40, 10))
	return n
