class_name ShopStall
extends RefCounted
## Barraca de feira do Seu Nenê: toldo listrado, balcão com frutas e o vendedor.
## Modelo procedural — não depende de prop_library.gd.

const STRIPE_COLORS: Array[Color] = [Color("#ff5a5a"), Color("#ffe27a")]


static func create() -> Node3D:
	var n := Node3D.new()
	n.name = "ShopStall"
	_build_counter(n)
	_build_awning(n)
	_build_fruit(n)
	var vendor := create_vendor()
	vendor.position = Vector3(0.0, 0.0, 0.55)
	vendor.rotation.y = PI
	n.add_child(vendor)
	return n


static func _build_counter(n: Node3D) -> void:
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(2.2, 0.9, 0.7)), Color("#a0693a"), Vector3(0.0, 0.45, 0.0))
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(2.3, 0.08, 0.78)), Color("#7a4d2a"), Vector3(0.0, 0.92, 0.0))
	for x in [-1.0, 1.0]:
		EconomyMesh.mi(n, EconomyMesh.cyl(0.05, 0.05, 2.4), Color("#7a4d2a"), Vector3(x, 1.5, 0.3))


static func _build_awning(n: Node3D) -> void:
	var roof := Node3D.new()
	roof.position = Vector3(0.0, 2.6, 0.0)
	n.add_child(roof)
	var stripes := 6
	var width := 2.6 / float(stripes)
	for i in stripes:
		var color := STRIPE_COLORS[i % 2]
		EconomyMesh.mi(roof, EconomyMesh.box(Vector3(width, 0.08, 1.4)), color, Vector3(-1.3 + width * (i + 0.5), 0.0, 0.1), Vector3(0.0, 0.0, -8.0))
	for x in [-1.0, 1.0]:
		for z in [-0.4, 0.75]:
			EconomyMesh.mi(n, EconomyMesh.cyl(0.04, 0.04, 2.6), Color("#8a5a35"), Vector3(x, 1.3, z))
	for i in stripes + 1:
		var color := STRIPE_COLORS[i % 2]
		EconomyMesh.mi(roof, EconomyMesh.box(Vector3(0.04, 0.3, 0.04)), color.darkened(0.1), Vector3(-1.3 + width * i, -0.3, 0.75))


static func _build_fruit(n: Node3D) -> void:
	var fruit_colors: Array[Color] = [Color("#f28a2e"), Color("#d6281e"), Color("#4a1a4a"), Color("#ffd84a")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 14:
		var color := fruit_colors[i % fruit_colors.size()]
		var pos := Vector3(rng.randf_range(-1.0, 1.0), 0.98 + rng.randf_range(0.0, 0.1), rng.randf_range(-0.25, 0.25))
		EconomyMesh.mi(n, EconomyMesh.sphere(0.09), color, pos)
	var basket := Node3D.new()
	basket.position = Vector3(0.75, 0.98, 0.0)
	n.add_child(basket)
	EconomyMesh.mi(basket, EconomyMesh.cyl(0.22, 0.16, 0.22), Color("#c9a06a"), Vector3.ZERO)


## Vendedor simples e procedural: o Seu Nenê, de chapéu de palha.
static func create_vendor() -> Node3D:
	var n := Node3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.3
	body.height = 1.0
	EconomyMesh.mi(n, body, Color("#d9823b"), Vector3(0.0, 0.55, 0.0))
	EconomyMesh.mi(n, EconomyMesh.sphere(0.32), Color("#c48c5e"), Vector3(0.0, 1.3, 0.0))
	EconomyMesh.mi(n, EconomyMesh.cyl(0.46, 0.46, 0.06), Color("#e8d39a"), Vector3(0.0, 1.5, 0.0))
	EconomyMesh.mi(n, EconomyMesh.cyl(0.22, 0.26, 0.26), Color("#e8d39a"), Vector3(0.0, 1.64, 0.0))
	EconomyMesh.mi(n, EconomyMesh.cyl(0.16, 0.16, 0.08), Color("#8a5a35"), Vector3(0.0, 1.77, 0.0))
	return n
