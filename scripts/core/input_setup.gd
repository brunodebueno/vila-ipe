class_name InputSetup
extends RefCounted
## Registra o mapa de entrada por código (teclado/mouse). Mantém o project.godot limpo.

const KEYS := {
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"run": [KEY_SHIFT],
	&"jump": [KEY_SPACE],
	&"hotbar_1": [KEY_1],
	&"hotbar_2": [KEY_2],
	&"hotbar_3": [KEY_3],
	&"hotbar_4": [KEY_4],
	&"hotbar_5": [KEY_5],
	&"hotbar_6": [KEY_6],
	&"hotbar_7": [KEY_7],
	&"hotbar_8": [KEY_8],
	&"brush_up": [KEY_BRACKETRIGHT, KEY_E],
	&"brush_down": [KEY_BRACKETLEFT, KEY_Q],
	&"toggle_hud": [KEY_F1],
	&"screenshot": [KEY_F2],
	&"cinematic": [KEY_F3],
	&"inventory": [KEY_TAB, KEY_I],
	&"crafting": [KEY_R],
	&"interact": [KEY_F],
	&"build_mode": [KEY_B],
	&"quest_log": [KEY_J],
	&"pause": [KEY_ESCAPE],
	&"time_fast": [KEY_T],
	&"gift": [KEY_G],
	&"rotate_left": [KEY_Z],
	&"rotate_right": [KEY_X],
	&"trailer_cam": [KEY_F4],
}


static func register() -> void:
	for action: StringName in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode as Key
			InputMap.action_add_event(action, ev)
	_add_mouse(&"use_tool", MOUSE_BUTTON_LEFT)
	_add_mouse(&"orbit", MOUSE_BUTTON_RIGHT)


static func _add_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
