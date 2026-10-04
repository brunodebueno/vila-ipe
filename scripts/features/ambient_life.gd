class_name AmbientLife
extends Feature
## Fauna e flora ambiente leve: bando de araras ao pôr do sol, garças perto do rio,
## sabiás nas árvores, peixinhos saltando no rio, pétalas/folhas caindo perto dos ipês.
## Tudo em Node3D + poucos meshes/partículas — sem IA pesada, sem física extra.

var _ctx: GameContext
var _macaws: Node3D
var _herons: Array[Node3D] = []
var _songbirds: Array[Node3D] = []
var _fish_particles: GPUParticles3D
var _petal_emitters: Array[GPUParticles3D] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func install(ctx: GameContext) -> void:
	_ctx = ctx
	_rng.seed = 2026
	_build_macaw_flock()
	_build_herons()
	_build_songbirds()
	_build_fish()
	_build_petals()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_update_macaws(delta)
	_update_herons(delta)
	_update_songbirds(delta)
	_update_fish()


## --- Araras: cruzam o céu em V ao pôr do sol (hora ~16.5-19.0) ---
func _build_macaw_flock() -> void:
	_macaws = Node3D.new()
	add_child(_macaws)
	var colors := [Color(0.85, 0.1, 0.1), Color(0.85, 0.1, 0.1), Color(0.1, 0.35, 0.85), Color(0.85, 0.1, 0.1), Color(0.1, 0.35, 0.85)]
	var offsets := [Vector3(0, 0, 0), Vector3(-1.4, -0.3, -1.0), Vector3(1.4, -0.3, -1.0), Vector3(-2.6, -0.5, -2.0), Vector3(2.6, -0.5, -2.0)]
	for i in colors.size():
		var bird := _make_bird(colors[i], 0.55)
		bird.position = offsets[i]
		_macaws.add_child(bird)
	_macaws.visible = false


func _update_macaws(delta: float) -> void:
	var hour := _ctx.day_night.hour if _ctx.day_night else 12.0
	var active := hour >= 16.3 and hour <= 19.0
	_macaws.visible = active
	if not active:
		return
	var span := 70.0
	var progress := fmod(_time * 0.035, 1.0)
	var center := Vector3(WorldConst.MAP_SIZE.x * 0.5, 26.0, WorldConst.MAP_SIZE.y * 0.5)
	var x := lerpf(-span, span, progress)
	_macaws.global_position = center + Vector3(x, sin(progress * PI) * 4.0, -10.0)
	_macaws.rotation.y = PI * 0.5
	for i in _macaws.get_child_count():
		var bird := _macaws.get_child(i) as Node3D
		bird.rotation.x = sin(_time * 9.0 + i) * 0.35


## --- Garças perto do rio: paradas, de vez em quando dão um pequeno voo curto. ---
func _build_herons() -> void:
	var river_x := WorldConst.MAP_SIZE.x * 0.5 + 19.0
	var positions := [Vector3(river_x - 1.0, 0.0, 14.0), Vector3(river_x + 1.5, 0.0, 40.0)]
	for pos in positions:
		var heron := _make_heron()
		heron.position = pos + Vector3(0, WorldConst.WATER_Y + 0.05, 0)
		add_child(heron)
		_herons.append(heron)


func _update_herons(delta: float) -> void:
	for i in _herons.size():
		var heron := _herons[i]
		var bob := sin(_time * 1.2 + i * 2.0) * 0.03
		heron.position.y = heron.position.y
		heron.rotation.y = sin(_time * 0.15 + i) * 0.1 + float(i)


## --- Sabiás nas árvores: pequenos pássaros saltitando perto do centro da vila. ---
func _build_songbirds() -> void:
	var center := Vector2(WorldConst.MAP_SIZE) * 0.5
	for i in 6:
		var angle := _rng.randf() * TAU
		var radius := _rng.randf_range(6.0, 14.0)
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var bird := _make_bird(Color(0.75, 0.55, 0.3), 0.18)
		bird.position = Vector3(pos.x, 2.4 + _rng.randf_range(0.0, 1.5), pos.y)
		add_child(bird)
		_songbirds.append(bird)


func _update_songbirds(delta: float) -> void:
	for i in _songbirds.size():
		var bird := _songbirds[i]
		bird.rotation.x = sin(_time * 3.0 + i * 1.7) * 0.15
		bird.position.y += sin(_time * 2.0 + i) * 0.0003


## --- Peixinhos saltando no rio: partículas simples simulando splashes e arcos. ---
func _build_fish() -> void:
	_fish_particles = GPUParticles3D.new()
	_fish_particles.amount = 10
	_fish_particles.lifetime = 1.0
	_fish_particles.explosiveness = 0.0
	_fish_particles.randomness = 0.8
	_fish_particles.preprocess = 2.0
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.22
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.65, 0.75)
	mat.metallic = 0.4
	mesh.material = mat
	_fish_particles.draw_pass_1 = mesh
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 20.0
	pmat.gravity = Vector3(0, -14.0, 0)
	pmat.initial_velocity_min = 2.5
	pmat.initial_velocity_max = 4.0
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(2.0, 0.05, 20.0)
	_fish_particles.process_material = pmat
	var river_x := WorldConst.MAP_SIZE.x * 0.5 + 19.0
	_fish_particles.position = Vector3(river_x, WorldConst.WATER_Y, WorldConst.MAP_SIZE.y * 0.5)
	add_child(_fish_particles)


func _update_fish() -> void:
	pass


## --- Pétalas de ipê caindo perto de áreas altas (onde a vegetação costuma ter ipês). ---
func _build_petals() -> void:
	var center := Vector2(WorldConst.MAP_SIZE) * 0.5
	var spots := [center + Vector2(0, 0), center + Vector2(14, -10), center + Vector2(-16, 12), center + Vector2(18, 16)]
	var colors := [Color(1.0, 0.79, 0.16), Color(0.72, 0.37, 0.85)]
	for i in spots.size():
		var emitter := GPUParticles3D.new()
		emitter.amount = 18
		emitter.lifetime = 5.0
		emitter.preprocess = 5.0
		emitter.draw_pass_1 = _petal_mesh(colors[i % colors.size()])
		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 40.0
		mat.gravity = Vector3(0, -0.4, 0)
		mat.initial_velocity_min = 0.1
		mat.initial_velocity_max = 0.3
		mat.angular_velocity_min = -90.0
		mat.angular_velocity_max = 90.0
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(2.0, 0.1, 2.0)
		mat.turbulence_enabled = true
		mat.turbulence_noise_strength = 0.6
		mat.turbulence_noise_scale = 1.5
		emitter.process_material = mat
		emitter.position = Vector3(spots[i].x, 6.0, spots[i].y)
		add_child(emitter)
		_petal_emitters.append(emitter)


func _petal_mesh(color: Color) -> Mesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	return mesh


func _make_bird(color: Color, scale: float) -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 0.4) * scale
	mesh.orientation = PlaneMesh.FACE_Z
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	body.mesh = mesh
	n.add_child(body)
	return n


func _make_heron() -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.92, 0.9)
	body.mesh = mesh
	body.material_override = mat
	body.rotation_degrees.x = 80.0
	body.position.y = 0.35
	n.add_child(body)
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.02
	neck_mesh.bottom_radius = 0.035
	neck_mesh.height = 0.35
	neck.mesh = neck_mesh
	neck.material_override = mat
	neck.position = Vector3(0, 0.55, 0.08)
	n.add_child(neck)
	var legs := MeshInstance3D.new()
	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.015
	leg_mesh.bottom_radius = 0.015
	leg_mesh.height = 0.35
	legs.mesh = leg_mesh
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.9, 0.6, 0.3)
	legs.material_override = leg_mat
	legs.position.y = 0.17
	n.add_child(legs)
	return n
