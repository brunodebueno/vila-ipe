class_name BuildingModels
extends RefCounted
## Fábrica de modelos procedurais dos objetos colocáveis do modo construção, estilo
## "brinquedo de madeira pintado" com paleta quente brasileira. Usa .glb em
## res://assets/models/props/<id>.glb quando existir (mesma convenção do PropLibrary),
## senão monta um modelo procedural.

const MODEL_DIR := "res://assets/models/props/"

const HOUSE_PALETTE: Array[Color] = [
	Color("#7fb8e0"), Color("#f2a7b8"), Color("#f6d36b"), Color("#8fd19a"),
	Color("#e9825a"), Color("#c6a3e0"),
]
const FLAG_COLORS: Array[Color] = [
	Color("#ff5a5a"), Color("#ffd84a"), Color("#4ad0ff"), Color("#6adf6a"), Color("#c875ff"), Color("#ff9d4a"),
]


static func create(id: StringName) -> Node3D:
	var path := "%s%s.glb" % [MODEL_DIR, id]
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			return scene.instantiate() as Node3D
	return _fallback(id)


static func _fallback(id: StringName) -> Node3D:
	match String(id):
		"build_bench":
			return _bench()
		"build_hammock":
			return _hammock()
		"build_campfire":
			return _campfire()
		"build_lamp":
			return _lamp()
		"build_flags":
			return _flags()
		"build_fence":
			return _fence()
		"build_house":
			return _house()
		"build_planter":
			return _planter()
		"build_bromelia":
			return _bromelia()
		"build_tall_grass":
			return _tall_grass()
		"build_pond_stone":
			return _pond_stone()
		_:
			return Node3D.new()


static func _mi(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot_deg
	parent.add_child(m)
	return m


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func _cyl(top: float, bottom: float, h: float, segs: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 6
	return s


static func _prism(size: Vector3) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = size
	return p


## ---------- Banco de praça ----------
static func _bench() -> Node3D:
	var n := Node3D.new()
	var wood := Color("#c98a4e")
	_mi(n, _box(Vector3(0.9, 0.08, 0.38)), wood, Vector3(0, 0.46, 0))
	_mi(n, _box(Vector3(0.9, 0.42, 0.08)), wood.darkened(0.05), Vector3(0, 0.67, -0.17))
	for sx in [-0.38, 0.38]:
		_mi(n, _box(Vector3(0.08, 0.46, 0.38)), Color("#7a5230"), Vector3(sx, 0.23, 0))
	n.set_meta("seat_offset", Vector3(0, 0.5, 0.08))
	return n


## ---------- Rede de dormir ----------
static func _hammock() -> Node3D:
	var n := Node3D.new()
	var post := Color("#8a5a35")
	for sx in [-1.1, 1.1]:
		_mi(n, _cyl(0.07, 0.09, 1.6), post, Vector3(sx, 0.8, 0))
		_mi(n, _sphere(0.1), post.darkened(0.1), Vector3(sx, 1.6, 0))
	var cloth := Color("#e8584a")
	var mesh := _box(Vector3(2.0, 0.05, 0.75))
	var sag := _mi(n, mesh, cloth, Vector3(0, 0.75, 0))
	sag.rotation_degrees = Vector3(0, 0, 0)
	for i in 5:
		var t := (i / 4.0) * 2.0 - 1.0
		_mi(n, _box(Vector3(0.03, 0.03, 0.78)), cloth.darkened(0.15), Vector3(t * 0.95, 0.76 - (1.0 - t * t) * 0.12, 0))
	n.set_meta("seat_offset", Vector3(0, 0.7, 0))
	return n


## ---------- Fogueira ----------
static func _campfire() -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 6:
		var a := i * TAU / 6.0
		var log_mesh := _cyl(0.07, 0.09, 0.7)
		var holder := _mi(n, log_mesh, Color("#5a3a22"), Vector3(cos(a) * 0.12, 0.1, sin(a) * 0.12))
		holder.rotation_degrees = Vector3(80.0, rad_to_deg(a), 0)
	for i in 5:
		_mi(n, _sphere(0.12), Color("#9a9a9a"), Vector3.ZERO).position = Vector3(cos(i * TAU / 5.0) * 0.45, 0.08, sin(i * TAU / 5.0) * 0.45)
	var particles := CPUParticles3D.new()
	particles.position = Vector3(0, 0.25, 0)
	particles.amount = 24
	particles.lifetime = 0.9
	particles.emitting = true
	particles.direction = Vector3.UP
	particles.spread = 18.0
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.3
	particles.gravity = Vector3(0, 1.2, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	var pmesh := _sphere(0.08)
	particles.mesh = pmesh
	particles.color_ramp = _fire_gradient()
	n.add_child(particles)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.4, 0)
	light.light_color = Color("#ff9a4a")
	light.light_energy = 1.8
	light.omni_range = 6.0
	n.add_child(light)
	var fx := CampfireFx.new()
	fx.setup(light)
	n.add_child(fx)
	n.set_meta("fx", fx)
	return n


static func _fire_gradient() -> Gradient:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.5, 1.0))
	grad.add_point(0.5, Color(1.0, 0.5, 0.1, 0.8))
	grad.set_color(1, Color(0.6, 0.1, 0.05, 0.0))
	return grad


## ---------- Poste de luz ----------
static func _lamp() -> Node3D:
	var n := Node3D.new()
	var metal := Color("#3d4a52")
	_mi(n, _cyl(0.05, 0.08, 2.4), metal, Vector3(0, 1.2, 0))
	_mi(n, _cyl(0.1, 0.02, 0.22), metal, Vector3(0, 2.3, 0))
	var glass := MeshInstance3D.new()
	glass.mesh = _sphere(0.18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ffe27a")
	mat.emission_enabled = true
	mat.emission = Color("#ffe27a")
	mat.emission_energy_multiplier = 0.0
	glass.material_override = mat
	glass.position = Vector3(0, 2.45, 0)
	n.add_child(glass)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.45, 0)
	light.light_color = Color("#ffe8a0")
	light.light_energy = 0.0
	light.omni_range = 7.0
	light.visible = false
	n.add_child(light)
	var glow := NightGlow.new()
	glow.lights = [light]
	glow.glow_materials = [mat]
	glow.light_energy = 2.2
	glow.emission_energy = 2.0
	n.add_child(glow)
	return n


## ---------- Bandeirinhas de festa junina ----------
static func _flags() -> Node3D:
	var n := Node3D.new()
	var post := Color("#8a5a35")
	for sx in [-1.5, 1.5]:
		_mi(n, _cyl(0.05, 0.07, 2.2), post, Vector3(sx, 1.1, 0))
	var count := 9
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(0, 0)) # variação determinística por instância não é crítica aqui
	for i in count:
		var t := float(i) / float(count - 1)
		var x := lerpf(-1.4, 1.4, t)
		var sag := sin(t * PI) * 0.35
		var flag := MeshInstance3D.new()
		var tri := PrismMesh.new()
		tri.size = Vector3(0.22, 0.26, 0.02)
		flag.mesh = tri
		var mat := StandardMaterial3D.new()
		mat.albedo_color = FLAG_COLORS[i % FLAG_COLORS.size()]
		mat.roughness = 1.0
		flag.material_override = mat
		flag.position = Vector3(x, 1.9 - sag, 0)
		flag.rotation_degrees = Vector3(0, 0, 180)
		n.add_child(flag)
	return n


## ---------- Cerca ----------
static func _fence() -> Node3D:
	var fence := FenceVisual.new()
	fence.setup(Color("#a0693a"))
	return fence


## ---------- Casa colonial ----------
static func _house() -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wall := HOUSE_PALETTE[rng.randi_range(0, HOUSE_PALETTE.size() - 1)]
	_mi(n, _box(Vector3(2.8, 1.9, 2.8)), wall, Vector3(0, 0.95, 0))
	var roof := _prism(Vector3(3.3, 1.15, 3.3))
	_mi(n, roof, Color("#c4623a"), Vector3(0, 2.5, 0))
	for i in 5:
		var strip := _mi(n, _box(Vector3(3.3, 0.06, 0.18)), Color("#a84e2e"), Vector3(0, 2.0 + i * 0.1, 1.5 - i * 0.3))
		strip.rotation_degrees.x = -32.0
	_mi(n, _box(Vector3(0.65, 1.2, 0.08)), Color("#6b4226"), Vector3(0, 0.6, 1.42))
	var door_knob := _mi(n, _sphere(0.04), Color("#ffe27a"), Vector3(0.22, 0.6, 1.46))
	var window_mat_l := StandardMaterial3D.new()
	window_mat_l.albedo_color = Color("#dff3ff")
	window_mat_l.emission_enabled = true
	window_mat_l.emission = Color("#ffcf7a")
	window_mat_l.emission_energy_multiplier = 0.0
	var win_l := MeshInstance3D.new()
	win_l.mesh = _box(Vector3(0.55, 0.55, 0.08))
	win_l.material_override = window_mat_l
	win_l.position = Vector3(-0.95, 1.15, 1.42)
	n.add_child(win_l)
	var window_mat_r := StandardMaterial3D.new()
	window_mat_r.albedo_color = Color("#dff3ff")
	window_mat_r.emission_enabled = true
	window_mat_r.emission = Color("#ffcf7a")
	window_mat_r.emission_energy_multiplier = 0.0
	var win_r := MeshInstance3D.new()
	win_r.mesh = _box(Vector3(0.55, 0.55, 0.08))
	win_r.material_override = window_mat_r
	win_r.position = Vector3(0.95, 1.15, 1.42)
	n.add_child(win_r)
	_mi(n, _box(Vector3(3.0, 0.1, 1.0)), wall.darkened(0.2), Vector3(0, 0.35, 1.9))
	for sx in [-1.45, 1.45]:
		_mi(n, _cyl(0.06, 0.08, 1.2), Color("#f2e3c2"), Vector3(sx, 0.95, 2.3))
	var glow := NightGlow.new()
	glow.glow_materials = [window_mat_l, window_mat_r]
	glow.emission_energy = 1.6
	n.add_child(glow)
	return n


## ---------- Canteiro ----------
static func _planter() -> Node3D:
	var n := Node3D.new()
	_mi(n, _box(Vector3(0.9, 0.22, 0.9)), Color("#6b4226"), Vector3(0, 0.11, 0))
	var colors := [Color("#ff5a5a"), Color("#ffd84a"), Color("#c875ff")]
	for i in 5:
		var a := i * TAU / 5.0
		_mi(n, _sphere(0.1), colors[i % colors.size()], Vector3(cos(a) * 0.3, 0.3, sin(a) * 0.3))
		_mi(n, _cyl(0.02, 0.03, 0.22), Color("#3aa04f"), Vector3(cos(a) * 0.3, 0.18, sin(a) * 0.3))
	return n


## ---------- Bromélia ----------
static func _bromelia() -> Node3D:
	var n := Node3D.new()
	var colors := [Color("#e84a6a"), Color("#ff9d4a"), Color("#c875ff")]
	for i in 6:
		var a := i * TAU / 6.0
		var leaf := _mi(n, _prism(Vector3(0.1, 0.5, 0.05)), colors[i % colors.size()].darkened(float(i) * 0.03), Vector3(cos(a) * 0.08, 0.25, sin(a) * 0.08))
		leaf.rotation_degrees = Vector3(0, rad_to_deg(a), 20)
	_mi(n, _sphere(0.08), Color("#ffd84a"), Vector3(0, 0.55, 0))
	return n


## ---------- Capim alto ----------
static func _tall_grass() -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 7:
		var blade := _mi(n, _prism(Vector3(0.05, 0.55, 0.02)), Color("#8fd05a").darkened(rng.randf_range(0.0, 0.15)), Vector3(rng.randf_range(-0.25, 0.25), 0.27, rng.randf_range(-0.25, 0.25)))
		blade.rotation_degrees = Vector3(0, rng.randf_range(0, 360), rng.randf_range(-10, 10))
	return n


## ---------- Pedra de lago ----------
static func _pond_stone() -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var grey := Color("#8aa0a8")
	for i in 3:
		var s := _mi(n, _sphere(0.22 - i * 0.04), grey.lightened(float(i) * 0.05), Vector3(rng.randf_range(-0.12, 0.12), 0.08 + i * 0.1, rng.randf_range(-0.12, 0.12)))
		s.scale = Vector3(1.3, 0.7, 1.1)
	return n
