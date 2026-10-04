class_name NightGlow
extends Node3D
## Componente reutilizável: liga luzes/emissão à noite (hora >= 18 ou < 6) e apaga de dia,
## com transição suave. Usado pelo poste de luz e pelas janelas da casa colonial.

const FADE_SPEED := 1.6

var lights: Array[Light3D] = []
var glow_materials: Array[StandardMaterial3D] = []
var light_energy: float = 2.4
var emission_energy: float = 1.8

var _target := 0.0
var _level := 0.0


func _ready() -> void:
	EventBus.hour_changed.connect(_on_hour_changed)
	_on_hour_changed(GameContext.current.day_night.hour if GameContext.current and GameContext.current.day_night else 12.0)
	_level = _target
	_apply()


func _process(delta: float) -> void:
	if is_equal_approx(_level, _target):
		return
	_level = move_toward(_level, _target, delta * FADE_SPEED)
	_apply()


func _on_hour_changed(hour: float) -> void:
	var is_night := hour >= 18.0 or hour < 6.0
	_target = 1.0 if is_night else 0.0


func _apply() -> void:
	for light in lights:
		light.light_energy = light_energy * _level
		light.visible = _level > 0.01
	for mat in glow_materials:
		mat.emission_energy_multiplier = emission_energy * _level
