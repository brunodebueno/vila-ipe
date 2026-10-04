class_name Pickup
extends Node3D
## Item solto no chão: gira, pulsa levemente, brilha com a cor do ItemDef.
## Quando o jogador se aproxima (raio MAGNET_RADIUS) é atraído e coletado automaticamente
## via GameState.give. Se o inventário estiver cheio, não coleta e avisa (com um intervalo).

const MAGNET_RADIUS := 1.6
const GRAB_RADIUS := 0.45
const BOB_HEIGHT := 0.1
const BOB_SPEED := 2.6
const SPIN_SPEED := 1.7
const WARN_COOLDOWN := 2.5

var item_id: StringName
var count: int = 1

var _visual: Node3D
var _t := 0.0
var _collected := false
var _warn_timer := 0.0


## Cria e adiciona o pickup na cena atual. API pública usada por outros módulos.
static func spawn_at(world_pos: Vector3, id: StringName, amount: int = 1) -> Pickup:
	var ctx := GameContext.current
	if ctx == null or ctx.main == null:
		return null
	var p := Pickup.new()
	p.item_id = id
	p.count = amount
	ctx.main.add_child(p)
	p.global_position = world_pos
	p.add_to_group(&"pickups")
	return p


func _ready() -> void:
	_t = randf() * TAU
	var def := ItemDB.get_def(item_id)
	var color := def.color if def else Color.WHITE
	_visual = Node3D.new()
	add_child(_visual)
	_visual.position.y = 0.3
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.16
	shape.height = 0.32
	shape.radial_segments = 10
	shape.rings = 6
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color.lightened(0.2)
	mat.emission_energy_multiplier = 0.7
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(mesh)


func _process(delta: float) -> void:
	if _collected:
		return
	_t += delta * BOB_SPEED
	_visual.position.y = 0.3 + sin(_t) * BOB_HEIGHT
	_visual.rotation.y += delta * SPIN_SPEED
	_warn_timer = maxf(0.0, _warn_timer - delta)
	var ctx := GameContext.current
	if ctx == null or ctx.player == null:
		return
	var player_pos: Vector3 = ctx.player.global_position
	var dist := global_position.distance_to(player_pos)
	if dist > MAGNET_RADIUS:
		return
	if dist > GRAB_RADIUS:
		var dir := player_pos - global_position
		dir.y = 0.0
		if dir.length() > 0.001:
			var pull := lerpf(2.0, 9.0, 1.0 - dist / MAGNET_RADIUS)
			global_position += dir.normalized() * pull * delta
	else:
		_try_collect()


func _try_collect() -> void:
	if _collected:
		return
	if not GameState.inventory.can_add(item_id, count):
		if _warn_timer <= 0.0:
			EventBus.notify.emit("Inventário cheio! Abra espaço para coletar.", item_id)
			_warn_timer = WARN_COOLDOWN
		return
	_collected = true
	GameState.give(item_id, count)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.5, 0.35, 1.5), 0.07)
	tw.tween_property(_visual, "scale", Vector3.ZERO, 0.1)
	tw.tween_callback(queue_free)
