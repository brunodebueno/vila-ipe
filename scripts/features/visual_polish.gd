class_name VisualPolish
extends Feature
## Polimento visual leve: ajusta glow/SSAO/sombras suaves no Environment existente (DayNight)
## e aplica vinheta + grading quente via CanvasLayer com shader (post_process.gdshader).

const POST_SHADER := preload("res://assets/shaders/post_process.gdshader")

var _ctx: GameContext
var _post_rect: ColorRect
var _post_mat: ShaderMaterial


func install(ctx: GameContext) -> void:
	_ctx = ctx
	add_to_group(&"visual_polish")
	_tune_environment()
	_build_post_layer()
	EventBus.hour_changed.connect(_on_hour_changed)


func _tune_environment() -> void:
	var env := _ctx.day_night.get_environment() if _ctx.day_night else null
	if env == null:
		return
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	var sun := _ctx.day_night.get_sun()
	if sun:
		sun.shadow_blur = 2.2
		sun.directional_shadow_max_distance = 95.0


func _build_post_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_post_rect = ColorRect.new()
	_post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = POST_SHADER
	_post_mat.set_shader_parameter(&"vignette_strength", 0.3)
	_post_mat.set_shader_parameter(&"warmth", 0.04)
	_post_mat.set_shader_parameter(&"letterbox", 0.0)
	_post_rect.material = _post_mat
	layer.add_child(_post_rect)


## Usado por trailer_camera.gd para abrir/fechar as barras pretas de letterbox.
func set_letterbox(amount: float) -> void:
	if _post_mat:
		_post_mat.set_shader_parameter(&"letterbox", amount)


func _on_hour_changed(hour: float) -> void:
	if _post_mat == null:
		return
	var sunset := 1.0 - smoothstep(0.0, 1.5, absf(hour - 17.5))
	_post_mat.set_shader_parameter(&"warmth", lerpf(0.04, 0.12, sunset))
	var env := _ctx.day_night.get_environment() if _ctx.day_night else null
	if env:
		env.glow_intensity = lerpf(0.6, 1.0, sunset)
