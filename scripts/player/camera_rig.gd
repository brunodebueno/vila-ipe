class_name CameraRig
extends Node3D
## Câmera orbital em terceira pessoa (botão direito gira, roda do mouse dá zoom) + modo cinematográfico.

@export var min_distance := 4.0
@export var max_distance := 28.0
@export var sensitivity := 0.005

var cinematic := false
var camera: Camera3D
var _pitch_pivot: Node3D
var _arm: SpringArm3D
var _yaw := deg_to_rad(35.0)
var _pitch := deg_to_rad(-38.0)
var _distance := 11.0
var _target_distance := 11.0


func _ready() -> void:
	top_level = true
	_pitch_pivot = Node3D.new()
	add_child(_pitch_pivot)
	_arm = SpringArm3D.new()
	_arm.shape = SphereShape3D.new()
	(_arm.shape as SphereShape3D).radius = 0.25
	_arm.collision_mask = 1
	_arm.margin = 0.3
	_pitch_pivot.add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.far = 400.0
	_arm.add_child(camera)


func follow(target_pos: Vector3, delta: float) -> void:
	global_position = global_position.lerp(target_pos + Vector3(0, 1.2, 0), 1.0 - exp(-12.0 * delta))
	if cinematic:
		_yaw += delta * 0.12
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-8.0 * delta))
	rotation.y = _yaw
	_pitch_pivot.rotation.x = _pitch
	_arm.spring_length = _distance


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_action_pressed(&"orbit"):
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * sensitivity
		_pitch = clampf(_pitch - motion.relative.y * sensitivity, deg_to_rad(-80.0), deg_to_rad(-8.0))
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = clampf(_target_distance - 1.0, min_distance, max_distance)
		elif button == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = clampf(_target_distance + 1.0, min_distance, max_distance)


## Direção no plano XZ relativa ao yaw da câmera.
func planar_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)
