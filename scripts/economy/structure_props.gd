class_name EconomyStructures
extends RefCounted
## Estruturas procedurais do módulo de economia: bancada de carpintaria e caixa de entregas.

static func create_bench() -> Node3D:
	var n := Node3D.new()
	n.name = "CraftingBench"
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(1.6, 0.75, 0.8)), Color("#8a5a35"), Vector3(0.0, 0.375, 0.0))
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(1.7, 0.08, 0.9)), Color("#6b4226"), Vector3(0.0, 0.78, 0.0))
	for x in [-0.7, 0.7]:
		for z in [-0.35, 0.35]:
			EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.1, 0.72, 0.1)), Color("#6b4226"), Vector3(x, 0.0, z))
	EconomyMesh.mi(n, EconomyMesh.cyl(0.08, 0.08, 0.3), Color("#9a9aa2"), Vector3(-0.4, 0.95, 0.0), Vector3(0.0, 0.0, 90.0))
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.3, 0.05, 0.2)), Color("#a0693a"), Vector3(0.4, 0.84, 0.1))
	return n


static func create_mailbox() -> Node3D:
	var n := Node3D.new()
	n.name = "DeliveryChest"
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.9, 0.55, 0.6)), Color("#a0693a"), Vector3(0.0, 0.3, 0.0))
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.95, 0.12, 0.65)), Color("#7a4d2a"), Vector3(0.0, 0.6, 0.0))
	EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.1, 0.1, 0.08)), Color("#e8c875"), Vector3(0.0, 0.42, 0.31))
	for x in [-0.3, 0.3]:
		EconomyMesh.mi(n, EconomyMesh.box(Vector3(0.06, 0.6, 0.06)), Color("#5a2d12"), Vector3(x, 0.3, 0.0))
	return n
