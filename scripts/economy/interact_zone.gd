class_name InteractZone
extends Area3D
## Zona de interação por proximidade: mostra o prompt "[F] ..." via grupo 'ui_prompt'
## (outro agente implementa esse grupo) e emite `activated` quando o jogador aperta F dentro dela.

signal activated

var prompt_text: String
var _inside := false


func setup(radius: float, text: String) -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	add_child(shape)
	prompt_text = text
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body is Player:
		_inside = true
		_set_prompt(true)


func _on_exit(body: Node3D) -> void:
	if body is Player:
		_inside = false
		_set_prompt(false)


func _unhandled_input(event: InputEvent) -> void:
	if _inside and not GameState.is_ui_blocking() and event.is_action_pressed(&"interact"):
		activated.emit()
		get_viewport().set_input_as_handled()


func _set_prompt(visible_now: bool) -> void:
	for node in get_tree().get_nodes_in_group("ui_prompt"):
		if not is_instance_valid(node):
			continue
		if visible_now and node.has_method("show_prompt"):
			node.show_prompt(prompt_text, "F")
		elif not visible_now and node.has_method("hide_prompt"):
			node.hide_prompt()


func _exit_tree() -> void:
	if _inside:
		_set_prompt(false)
