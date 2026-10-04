class_name Weather
extends Feature
## Clima dinâmico: sol, nublado, garoa, pancada de verão, neblina matinal, arco-íris.
## Integra com DayNight (cloud_amount/extra_fog_density) sem editar sua lógica solar.

enum Kind { SUN, CLOUDY, DRIZZLE, STORM, FOG }

const CHECK_INTERVAL := 25.0
const STORM_CHANCE := 0.15  ## ~15% dos dias, fim de tarde.
const TRANSITION := 4.0

var _ctx: GameContext
var _rng := RandomNumberGenerator.new()
var _kind := Kind.SUN
var _target_kind := Kind.SUN
var _blend := 0.0
var _timer := 0.0
var _storm_rolled_for_day := -1
var _rain_particles: GPUParticles3D
var _fog_particles: GPUParticles3D
var _rainbow: MeshInstance3D
var _rainbow_alpha := 0.0
var _wind_time := 0.0
var _puddle_mesh: MeshInstance3D
var _audio_targets: Array = []


func install(ctx: GameContext) -> void:
	_ctx = ctx
	add_to_group(&"weather_system")
	_rng.randomize()
	_apply_cmdline_override()
	_build_rain()
	_build_puddles()
	_build_rainbow()
	set_process(true)


func _apply_cmdline_override() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			var h := arg.get_slice("=", 1).to_float()
			if _ctx and _ctx.day_night:
				_ctx.day_night.set_hour(h)
		if arg.begins_with("--weather="):
			var value := arg.get_slice("=", 1)
			match value:
				"rain", "storm":
					_kind = Kind.STORM
					_target_kind = Kind.STORM
					_blend = 1.0
				"drizzle":
					_kind = Kind.DRIZZLE
					_target_kind = Kind.DRIZZLE
					_blend = 1.0
				"fog":
					_kind = Kind.FOG
					_target_kind = Kind.FOG
					_blend = 1.0
				"cloudy":
					_kind = Kind.CLOUDY
					_target_kind = Kind.CLOUDY
					_blend = 1.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = CHECK_INTERVAL
		_roll_weather()
	_blend = clampf(_blend + delta / TRANSITION, 0.0, 1.0)
	if _blend >= 1.0 and _kind != _target_kind:
		_kind = _target_kind
	_wind_time += delta
	_apply_to_day_night()
	_apply_rain(delta)
	_apply_rainbow(delta)
	_follow_player()


func _roll_weather() -> void:
	if _ctx == null or _ctx.day_night == null:
		return
	var hour := _ctx.day_night.hour
	var day_index := int(Time.get_ticks_msec() / 600000.0)
	var is_late_afternoon := hour >= 15.5 and hour <= 18.5
	var is_morning := hour >= 5.0 and hour <= 7.5
	if is_late_afternoon and _storm_rolled_for_day != day_index:
		_storm_rolled_for_day = day_index
		if _rng.randf() < STORM_CHANCE:
			_set_target(Kind.STORM)
			return
	if _kind == Kind.STORM and _blend >= 1.0:
		_set_target(Kind.SUN)
		return
	if is_morning and _rng.randf() < 0.35:
		_set_target(Kind.FOG)
		return
	if _kind in [Kind.FOG]:
		_set_target(Kind.SUN)
		return
	var roll := _rng.randf()
	if roll < 0.12:
		_set_target(Kind.DRIZZLE)
	elif roll < 0.3:
		_set_target(Kind.CLOUDY)
	else:
		_set_target(Kind.SUN)


func _set_target(kind: int) -> void:
	if kind == _target_kind:
		return
	_kind = _target_kind
	_target_kind = kind
	_blend = 0.0


func _current_cloud_amount() -> float:
	return _blend_value({Kind.SUN: 0.0, Kind.CLOUDY: 0.55, Kind.DRIZZLE: 0.7, Kind.STORM: 0.95, Kind.FOG: 0.3})


func _current_fog_amount() -> float:
	return _blend_value({Kind.SUN: 0.0, Kind.CLOUDY: 0.0, Kind.DRIZZLE: 0.0, Kind.STORM: 0.0, Kind.FOG: 0.045})


func _current_rain_amount() -> float:
	return _blend_value({Kind.SUN: 0.0, Kind.CLOUDY: 0.0, Kind.DRIZZLE: 0.35, Kind.STORM: 1.0, Kind.FOG: 0.0})


func _blend_value(table: Dictionary) -> float:
	var a: float = table.get(_kind, 0.0)
	var b: float = table.get(_target_kind, 0.0)
	return lerpf(a, b, _blend)


func _apply_to_day_night() -> void:
	var dn := _ctx.day_night
	if dn == null:
		return
	dn.cloud_amount = _current_cloud_amount()
	dn.extra_fog_density = _current_fog_amount()


func _apply_rain(delta: float) -> void:
	var rain_amount := _current_rain_amount()
	_rain_particles.emitting = rain_amount > 0.02
	_rain_particles.amount_ratio = clampf(rain_amount, 0.0, 1.0)
	if _puddle_mesh:
		var mat := _puddle_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = clampf(rain_amount * 0.5, 0.0, 0.5)
	_sway_trees(delta, 0.3 + rain_amount * 0.7)
	_notify_audio(rain_amount)


func _notify_audio(rain_amount: float) -> void:
	for node in get_tree().get_nodes_in_group(&"audio_manager"):
		if node.has_method("set_rain_amount"):
			node.call("set_rain_amount", rain_amount)


func _sway_trees(_delta: float, strength: float) -> void:
	if _ctx == null or _ctx.props == null:
		return
	## Leve: só ajusta o shader de vento global via RenderingServer não é necessário aqui;
	## grass_decor.gd lê este valor através do grupo "weather" para balançar a grama/árvores.
	set_meta("wind_strength", strength + sin(_wind_time * 0.6) * 0.15)


## API para outros sistemas (grass_decor.gd) lerem a intensidade do vento atual.
func wind_strength() -> float:
	return get_meta("wind_strength", 0.3) as float


func _apply_rainbow(delta: float) -> void:
	var hour := _ctx.day_night.hour if _ctx and _ctx.day_night else 12.0
	var sun_up := hour > 7.0 and hour < 18.0
	var just_after_rain := _kind == Kind.STORM and _blend > 0.6 and _target_kind == Kind.SUN
	var show := sun_up and just_after_rain
	var target_alpha := 0.55 if show else 0.0
	_rainbow_alpha = lerpf(_rainbow_alpha, target_alpha, 1.0 - exp(-2.0 * delta))
	_rainbow.visible = _rainbow_alpha > 0.01
	var mat := _rainbow.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"alpha", _rainbow_alpha)


func _follow_player() -> void:
	if _ctx == null or _ctx.player == null:
		return
	var p := _ctx.player.global_position
	_rain_particles.global_position = p + Vector3(0, 8.0, 0)
	_rainbow.global_position = p + Vector3(0, 0.0, -18.0)


func _build_rain() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.amount = 500
	_rain_particles.lifetime = 1.2
	_rain_particles.emitting = false
	_rain_particles.draw_pass_1 = _rain_mesh()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 4.0
	mat.gravity = Vector3(0, -22.0, 0)
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 4.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(16.0, 0.2, 16.0)
	mat.scale_min = 0.6
	mat.scale_max = 1.1
	_rain_particles.process_material = mat
	_rain_particles.top_level = true
	add_child(_rain_particles)


func _rain_mesh() -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.015, 0.35, 0.015)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.82, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	return mesh


func _build_puddles() -> void:
	_puddle_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	_puddle_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.25, 0.3, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.6
	mat.roughness = 0.05
	_puddle_mesh.material_override = mat
	_puddle_mesh.top_level = true
	_puddle_mesh.position = Vector3(WorldConst.MAP_SIZE.x * 0.5, WorldConst.WATER_Y + 0.02, WorldConst.MAP_SIZE.y * 0.5)
	add_child(_puddle_mesh)


const RAINBOW_SHADER_CODE := """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
uniform float alpha : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	float band = UV.y;
	vec3 col = mix(vec3(0.7,0.1,0.9), vec3(1.0,0.2,0.2), band);
	col = mix(col, vec3(0.2,1.0,0.3), abs(band-0.5)*1.4);
	float edge_fade = smoothstep(0.0, 0.12, band) * smoothstep(1.0, 0.88, band);
	ALBEDO = col;
	ALPHA = edge_fade * alpha * 0.6;
}
"""


func _build_rainbow() -> void:
	_rainbow = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 11.0
	torus.outer_radius = 13.0
	torus.rings = 48
	torus.ring_segments = 8
	_rainbow.mesh = torus
	_rainbow.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var shader := Shader.new()
	shader.code = RAINBOW_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_rainbow.material_override = mat
	_rainbow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rainbow.visible = false
	_rainbow.top_level = true
	add_child(_rainbow)
