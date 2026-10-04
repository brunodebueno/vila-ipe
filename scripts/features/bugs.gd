class_name Bugs
extends Feature
## Insetos ambiente: borboletas morpho (dia, perto de flores/árvores) voam em curvas suaves;
## vaga-lumes (noite) piscam com uma luz fraca. O puçá ('tool_net') captura o inseto mais
## próximo do alvo do mouse, dentro de CAPTURE_RADIUS, virando bug_morpho/bug_firefly.

const BUTTERFLY_COUNT := 8
const FIREFLY_COUNT := 7
const CAPTURE_RADIUS := 2.5
const SPAWN_RADIUS := 22.0

var _ctx: GameContext
var _butterflies: Array[Node3D] = []
var _fireflies: Array[Node3D] = []
var _is_day := true


func install(ctx: GameContext) -> void:
	_ctx = ctx
	ctx.tools.register_tool(&"net", _on_net)
	_spawn_butterflies()
	_spawn_fireflies()
	EventBus.hour_changed.connect(_on_hour_changed)
	_on_hour_changed(ctx.day_night.hour if ctx.day_night else 12.0)


func _spawn_butterflies() -> void:
	var center := Vector3(WorldConst.MAP_SIZE.x, 0.0, WorldConst.MAP_SIZE.y) * 0.5
	for i in BUTTERFLY_COUNT:
		var b := _make_butterfly()
		_ctx.main.add_child(b)
		var angle := randf() * TAU
		var r := randf_range(4.0, SPAWN_RADIUS)
		b.position = center + Vector3(cos(angle) * r, randf_range(1.6, 3.2), sin(angle) * r)
		b.set_meta(&"bug_id", &"bug_morpho")
		b.set_meta(&"anchor", b.position)
		b.set_meta(&"phase", randf() * TAU)
		b.set_meta(&"speed", randf_range(0.6, 1.1))
		_butterflies.append(b)


func _spawn_fireflies() -> void:
	var center := Vector3(WorldConst.MAP_SIZE.x, 0.0, WorldConst.MAP_SIZE.y) * 0.5
	for i in FIREFLY_COUNT:
		var f := _make_firefly()
		_ctx.main.add_child(f)
		var angle := randf() * TAU
		var r := randf_range(4.0, SPAWN_RADIUS)
		f.position = center + Vector3(cos(angle) * r, randf_range(0.8, 1.8), sin(angle) * r)
		f.set_meta(&"bug_id", &"bug_firefly")
		f.set_meta(&"anchor", f.position)
		f.set_meta(&"phase", randf() * TAU)
		f.set_meta(&"speed", randf_range(0.4, 0.8))
		f.visible = false
		_fireflies.append(f)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for b in _butterflies:
		_fly_curve(b, delta, t)
		_flap_wings(b, t)
	for f in _fireflies:
		if f.visible:
			_fly_curve(f, delta, t)
			_blink(f, t)


func _fly_curve(node: Node3D, delta: float, t: float) -> void:
	var anchor: Vector3 = node.get_meta(&"anchor")
	var phase: float = node.get_meta(&"phase")
	var speed: float = node.get_meta(&"speed")
	var local := Vector3(sin(t * speed + phase) * 2.2, sin(t * speed * 1.7 + phase) * 0.6, cos(t * speed * 0.8 + phase) * 2.2)
	var target := anchor + local
	var dir := target - node.position
	node.position += dir * minf(1.0, delta * 2.0)
	if dir.length() > 0.05:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(dir.x, dir.z), delta * 4.0)


func _flap_wings(node: Node3D, t: float) -> void:
	var wings: Array = node.get_meta(&"wings", [])
	var flap := sin(t * 14.0) * 0.9
	for w: MeshInstance3D in wings:
		var side: float = w.get_meta(&"side", 1.0)
		w.rotation.z = flap * side


func _blink(node: Node3D, t: float) -> void:
	var light: OmniLight3D = node.get_meta(&"light")
	var phase: float = node.get_meta(&"phase")
	light.light_energy = clampf(sin(t * 2.0 + phase) * 1.5, 0.0, 1.0)


func _on_hour_changed(hour: float) -> void:
	_is_day = hour >= 6.0 and hour <= 18.0
	for b in _butterflies:
		b.visible = _is_day
	for f in _fireflies:
		f.visible = not _is_day


func _on_net(_cell: Vector2i, hit: Dictionary, _item: StringName) -> void:
	var target_pos: Vector3 = hit.get("position", Vector3.ZERO)
	var pool: Array[Node3D] = _butterflies if _is_day else _fireflies
	var closest: Node3D = null
	var closest_dist := INF
	for bug in pool:
		if not bug.visible:
			continue
		var d := bug.global_position.distance_to(target_pos)
		if d < closest_dist:
			closest_dist = d
			closest = bug
	if closest == null or closest_dist > CAPTURE_RADIUS:
		EventBus.notify.emit("Aproxime o mouse de uma borboleta ou vaga-lume.", &"tool_net")
		return
	_capture(closest, pool)


func _capture(bug: Node3D, pool: Array[Node3D]) -> void:
	var bug_id: StringName = bug.get_meta(&"bug_id")
	GameState.give(bug_id, 1)
	GameState.add_stat(&"bugs_caught")
	EventBus.notify.emit("Capturou: %s!" % ItemDB.display_name(bug_id), bug_id)
	pool.erase(bug)
	var tw := create_tween()
	tw.tween_property(bug, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(bug.queue_free)
	_respawn_later(bug_id)


func _respawn_later(bug_id: StringName) -> void:
	await get_tree().create_timer(randf_range(8.0, 16.0)).timeout
	if bug_id == &"bug_morpho":
		var b := _make_butterfly()
		_ctx.main.add_child(b)
		var center := Vector3(WorldConst.MAP_SIZE.x, 0.0, WorldConst.MAP_SIZE.y) * 0.5
		var angle := randf() * TAU
		b.position = center + Vector3(cos(angle) * randf_range(4.0, SPAWN_RADIUS), randf_range(1.6, 3.2), sin(angle) * randf_range(4.0, SPAWN_RADIUS))
		b.set_meta(&"bug_id", &"bug_morpho")
		b.set_meta(&"anchor", b.position)
		b.set_meta(&"phase", randf() * TAU)
		b.set_meta(&"speed", randf_range(0.6, 1.1))
		b.visible = _is_day
		_butterflies.append(b)
	else:
		var f := _make_firefly()
		_ctx.main.add_child(f)
		var center := Vector3(WorldConst.MAP_SIZE.x, 0.0, WorldConst.MAP_SIZE.y) * 0.5
		var angle := randf() * TAU
		f.position = center + Vector3(cos(angle) * randf_range(4.0, SPAWN_RADIUS), randf_range(0.8, 1.8), sin(angle) * randf_range(4.0, SPAWN_RADIUS))
		f.set_meta(&"bug_id", &"bug_firefly")
		f.set_meta(&"anchor", f.position)
		f.set_meta(&"phase", randf() * TAU)
		f.set_meta(&"speed", randf_range(0.4, 0.8))
		f.visible = not _is_day
		_fireflies.append(f)


func _make_butterfly() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.03
	body_mesh.height = 0.12
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color("#1a1a2a")
	body.material_override = body_mat
	body.rotation_degrees.x = 90.0
	n.add_child(body)
	var wings: Array = []
	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wm := QuadMesh.new()
		wm.size = Vector2(0.18, 0.14)
		wing.mesh = wm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#2f7fff")
		mat.emission_enabled = true
		mat.emission = Color("#2f7fff")
		mat.emission_energy_multiplier = 0.3
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		wing.material_override = mat
		wing.position = Vector3(0.09 * side, 0.0, 0.0)
		wing.set_meta(&"side", side)
		n.add_child(wing)
		wings.append(wing)
	n.set_meta(&"wings", wings)
	return n


func _make_firefly() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#2a2a1a")
	body.material_override = mat
	n.add_child(body)
	var light := OmniLight3D.new()
	light.light_color = Color("#d8ff6a")
	light.light_energy = 0.0
	light.omni_range = 1.5
	light.omni_attenuation = 2.0
	light.shadow_enabled = false
	n.add_child(light)
	n.set_meta(&"light", light)
	return n
