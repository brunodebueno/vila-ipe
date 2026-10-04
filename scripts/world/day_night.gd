class_name DayNight
extends Node
## Ciclo dia/noite: sol, céu procedural, névoa e ambiente por hora do dia.

const HOURS: Array[float] = [0.0, 5.0, 6.5, 8.0, 12.0, 16.5, 18.0, 19.5, 21.0, 24.0]
const SKY_TOP: Array[Color] = [
	Color(0.02, 0.03, 0.09), Color(0.04, 0.05, 0.16), Color(0.30, 0.42, 0.72), Color(0.28, 0.58, 0.95), Color(0.22, 0.52, 0.95),
	Color(0.25, 0.55, 0.93), Color(0.32, 0.38, 0.72), Color(0.10, 0.10, 0.30), Color(0.03, 0.04, 0.12), Color(0.02, 0.03, 0.09)]
const SKY_HORIZON: Array[Color] = [
	Color(0.05, 0.06, 0.14), Color(0.18, 0.16, 0.30), Color(1.0, 0.66, 0.46), Color(0.78, 0.90, 1.0), Color(0.80, 0.92, 1.0),
	Color(0.98, 0.88, 0.68), Color(1.0, 0.52, 0.32), Color(0.50, 0.30, 0.42), Color(0.07, 0.08, 0.17), Color(0.05, 0.06, 0.14)]
const SUN_COLOR: Array[Color] = [
	Color(0.5, 0.6, 1.0), Color(0.5, 0.6, 1.0), Color(1.0, 0.62, 0.40), Color(1.0, 0.93, 0.82), Color(1.0, 0.97, 0.92),
	Color(1.0, 0.85, 0.60), Color(1.0, 0.55, 0.32), Color(1.0, 0.40, 0.30), Color(0.5, 0.6, 1.0), Color(0.5, 0.6, 1.0)]

@export var day_length_seconds := 300.0
@export var fast_forward := 12.0

var hour := 16.0
## Controlados por weather.gd (0 = céu limpo). Escurece o céu e aumenta a névoa sem o
## clima precisar tocar na lógica solar.
var cloud_amount := 0.0
var extra_fog_density := 0.0
var time_scale := 1.0
var _sun: DirectionalLight3D
var _env: Environment
var _sky: ProceduralSkyMaterial
var _last_minute := -1


## Ambiente ativo, para outros sistemas (clima, polimento visual) ajustarem glow/SSAO/etc.
func get_environment() -> Environment:
	return _env


func get_sun() -> DirectionalLight3D:
	return _sun


func _ready() -> void:
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 90.0
	_sun.shadow_blur = 1.5
	add_child(_sun)
	_sky = ProceduralSkyMaterial.new()
	_sky.sun_angle_max = 25.0
	var sky := Sky.new()
	sky.sky_material = _sky
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.glow_enabled = true
	_env.glow_intensity = 0.6
	_env.ssao_enabled = true
	_env.fog_enabled = true
	_env.fog_density = 0.004
	_env.fog_aerial_perspective = 0.4
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)
	_apply()


func _process(delta: float) -> void:
	var speed := (fast_forward if Input.is_action_pressed(&"time_fast") else 1.0) * time_scale
	hour = fposmod(hour + delta * 24.0 / day_length_seconds * speed, 24.0)
	_apply()
	var minute := int(hour * 60.0)
	if minute != _last_minute:
		_last_minute = minute
		EventBus.hour_changed.emit(hour)


## Define a hora diretamente (usado por weather.gd/trailer_camera.gd), sem acionar hour_changed extra.
func set_hour(value: float) -> void:
	hour = fposmod(value, 24.0)
	_apply()
	EventBus.hour_changed.emit(hour)


func _apply() -> void:
	var sun_angle := (hour - 6.0) / 12.0 * PI
	var elevation := sin(sun_angle)
	_sun.rotation = Vector3(-sun_angle, deg_to_rad(-35.0), 0.0)
	_sun.light_energy = clampf(elevation * 1.6, 0.0, 1.3) * lerpf(1.0, 0.35, cloud_amount)
	_sun.light_color = _sample(SUN_COLOR)
	_sun.shadow_enabled = elevation > 0.05
	var top := _sample(SKY_TOP).lerp(Color(0.5, 0.52, 0.55), cloud_amount * 0.7)
	var horizon := _sample(SKY_HORIZON).lerp(Color(0.55, 0.56, 0.58), cloud_amount * 0.6)
	_sky.sky_top_color = top
	_sky.sky_horizon_color = horizon
	_sky.ground_horizon_color = horizon
	_sky.ground_bottom_color = horizon.darkened(0.6)
	_env.fog_light_color = horizon
	_env.fog_density = 0.004 + extra_fog_density
	_env.ambient_light_energy = lerpf(0.35, 1.0, clampf(elevation * 1.5, 0.0, 1.0)) * lerpf(1.0, 0.55, cloud_amount)


func _sample(values: Array[Color]) -> Color:
	for i in HOURS.size() - 1:
		if hour <= HOURS[i + 1]:
			return values[i].lerp(values[i + 1], inverse_lerp(HOURS[i], HOURS[i + 1], hour))
	return values[values.size() - 1]
