class_name CampfireFx
extends Node3D
## Chamas (partículas) + luz tremulante de uma fogueira. warm() toca um efeito de "aquecer".

var _light: OmniLight3D
var _noise := FastNoiseLite.new()
var _t := 0.0


func setup(light: OmniLight3D) -> void:
	_light = light
	_noise.frequency = 3.0


func _process(delta: float) -> void:
	_t += delta
	if _light == null:
		return
	var flick := 0.75 + _noise.get_noise_1d(_t * 18.0) * 0.5
	_light.light_energy = 1.8 * flick
	_light.omni_range = 5.5 + flick * 1.2


func warm() -> void:
	EventBus.notify.emit("Você se aqueceu na fogueira. Ahh...", &"build_campfire")
