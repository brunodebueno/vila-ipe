class_name Player
extends CharacterBody3D
## Prefeito(a)-fundador(a): anda pelo mapa relativo à câmera, corre, pula e sobe degraus de 0,5 m.

@export var walk_speed := 5.0
@export var run_speed := 8.5
@export var jump_velocity := 6.0
@export var gravity := 20.0

const STEP_HEIGHT := 0.55

var camera_rig: CameraRig
var _visual: Node3D
var _bob_time := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	_visual = PropLibrary.create(&"player")
	add_child(_visual)
	floor_snap_length = 0.3


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var dir := Vector3.ZERO
	if camera_rig:
		dir = camera_rig.planar_basis() * Vector3(input.x, 0.0, input.y)
	var speed := run_speed if Input.is_action_pressed(&"run") else walk_speed
	velocity.x = lerpf(velocity.x, dir.x * speed, 1.0 - exp(-14.0 * delta))
	velocity.z = lerpf(velocity.z, dir.z * speed, 1.0 - exp(-14.0 * delta))
	if is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = jump_velocity
		else:
			_try_step_up(delta)
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	_animate(delta, dir)
	if global_position.y < -10.0:
		global_position = Vector3(WorldConst.MAP_SIZE.x * 0.5, 8.0, WorldConst.MAP_SIZE.y * 0.5)
		velocity = Vector3.ZERO


func _try_step_up(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z) * delta
	if horizontal.length_squared() < 0.000001:
		return
	if not test_move(global_transform, horizontal):
		return
	var raised := global_transform.translated(Vector3.UP * STEP_HEIGHT)
	if not test_move(raised, horizontal):
		global_position.y += STEP_HEIGHT


func _animate(delta: float, dir: Vector3) -> void:
	var moving := dir.length() > 0.1
	if moving:
		var target_yaw := atan2(dir.x, dir.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 1.0 - exp(-14.0 * delta))
		_bob_time += delta * (14.0 if Input.is_action_pressed(&"run") else 10.0)
		_visual.position.y = absf(sin(_bob_time)) * 0.08
		_visual.rotation.z = sin(_bob_time) * 0.06
	else:
		_visual.position.y = lerpf(_visual.position.y, 0.0, 1.0 - exp(-10.0 * delta))
		_visual.rotation.z = lerpf(_visual.rotation.z, 0.0, 1.0 - exp(-10.0 * delta))
