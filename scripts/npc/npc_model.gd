class_name NpcModel
extends RefCounted
## Fábrica de modelos de NPC. Usa .glb em res://assets/models/characters/npc_<id>.glb
## quando existir; senão monta uma silhueta procedural com chapéu/avental/bengala/violão
## conforme os dados de data/npcs.json. Não depende de PropLibrary (mantido intocado).

const MODEL_DIR := "res://assets/models/characters/"


static func create(id: StringName, def: Dictionary) -> Node3D:
	var path := "%snpc_%s.glb" % [MODEL_DIR, id]
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene.instantiate() as Node3D
	return _build(def)


static func _build(def: Dictionary) -> Node3D:
	var n := Node3D.new()
	var skin := Color(String(def.get("skin", "#c98a5e")))
	var hair := Color(String(def.get("hair", "#2b1c14")))
	var shirt := Color(String(def.get("shirt", "#6dbf4f")))
	var accent := Color(String(def.get("accent", "#ffe27a")))
	var body := CapsuleMesh.new()
	body.radius = 0.3
	body.height = 1.0
	_mi(n, body, shirt, Vector3(0, 0.55, 0))
	_mi(n, _sphere(0.32), skin, Vector3(0, 1.3, 0))
	_mi(n, _sphere(0.34), hair, Vector3(0, 1.42, -0.02))
	match String(def.get("accessory", "")):
		"hat":
			_mi(n, _cyl(0.4, 0.4, 0.04), accent, Vector3(0, 1.58, 0))
			_mi(n, _cyl(0.2, 0.22, 0.2), accent.darkened(0.1), Vector3(0, 1.68, 0))
		"turban":
			_mi(n, _sphere(0.36), accent, Vector3(0, 1.48, 0))
		"cane":
			var cane := _mi(n, _cyl(0.025, 0.025, 1.0), Color("#8a5a35"), Vector3(0.38, 0.5, 0.1))
			cane.rotation_degrees = Vector3(0, 0, 8)
		"apron":
			_mi(n, _box(Vector3(0.42, 0.7, 0.1)), Color("#8a5a35"), Vector3(0, 0.5, 0.2))
		"net":
			var handle := _mi(n, _cyl(0.02, 0.02, 0.6), Color("#8a5a35"), Vector3(0.3, 0.75, 0.1))
			handle.rotation_degrees = Vector3(0, 0, -30)
			_mi(n, _ring(0.18), accent, Vector3(0.45, 1.05, 0.1))
		"violao":
			var body_g := _mi(n, _box(Vector3(0.22, 0.4, 0.1)), Color("#c9a24a"), Vector3(-0.35, 0.75, 0.12))
			body_g.rotation_degrees = Vector3(0, 0, 18)
	n.scale = Vector3.ONE * float(def.get("scale", 1.0))
	return n


static func make_speech_label() -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.0065
	l.outline_size = 10
	l.font_size = 42
	l.position = Vector3(0, 2.15, 0)
	l.visible = false
	return l


static func initials(name: String) -> String:
	var parts := name.split(" ", false)
	var out := ""
	for p in parts:
		if p.length() > 0 and p[0].to_upper() == p[0].to_upper() and not p.to_lower() in ["de", "da", "do"]:
			out += p[0].to_upper()
		if out.length() >= 2:
			break
	return out if out != "" else name.substr(0, 1).to_upper()


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


static func _ring(r: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = r * 0.75
	t.outer_radius = r
	return t
