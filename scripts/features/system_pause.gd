extends Feature
## Pausa (Esc): modal Continuar / Opções / Salvar / Menu principal / Sair.
## Só abre se GameState.ui_blocking == 0 (outros módulos fecham suas janelas com Esc primeiro).

var _ctx: GameContext
var _layer: CanvasLayer
var _panel: PanelContainer
var _options: OptionsPanel
var _open := false


func install(ctx: GameContext) -> void:
	_ctx = ctx
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	ctx.main.add_child(_layer)
	_build_panel()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.08, 0.94)
	style.border_color = Color("#ffc928")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", style)
	_layer.add_child(_panel)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(280, 0)
	list.add_theme_constant_override("separation", 10)
	_panel.add_child(list)
	var title := Label.new()
	title.text = "Pausado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	list.add_child(title)
	list.add_child(_button("Continuar", _close))
	list.add_child(_button("Opções", _open_options))
	list.add_child(_button("Salvar", _save_now))
	list.add_child(_button("Menu principal", _to_main_menu))
	list.add_child(_button("Sair", _quit))


func _button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 42)
	btn.pressed.connect(callback)
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if _open:
		_close()
		get_viewport().set_input_as_handled()
	elif GameState.ui_blocking == 0:
		_show()
		get_viewport().set_input_as_handled()


func _show() -> void:
	_open = true
	_panel.visible = true
	GameState.ui_blocking += 1
	get_tree().paused = true


func _close() -> void:
	if _options:
		_options.queue_free()
		_options = null
	_open = false
	_panel.visible = false
	GameState.ui_blocking = maxi(0, GameState.ui_blocking - 1)
	get_tree().paused = false


func _open_options() -> void:
	if _options:
		return
	_options = OptionsPanel.new()
	_options.ctx = _ctx
	_options.process_mode = Node.PROCESS_MODE_ALWAYS
	_options.set_anchors_preset(Control.PRESET_CENTER)
	_options.position += Vector2(0, -40)
	_options.closed.connect(func() -> void: _options.queue_free(); _options = null)
	_layer.add_child(_options)


func _save_now() -> void:
	var saver := get_tree().get_first_node_in_group(&"system_save") as Node
	if saver and saver.has_method("save_game"):
		saver.call("save_game")


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()
