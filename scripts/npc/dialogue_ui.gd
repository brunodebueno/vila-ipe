class_name DialogueUi
extends CanvasLayer
## Caixa de diálogo modal reutilizável: retrato (círculo com iniciais), nome, efeito de
## digitação, escolhas de resposta. Usada por village_npcs.gd e tutorial.gd.
## Mantém GameState.ui_blocking enquanto aberta. Avança com clique/F/Espaço.

signal finished

const CHAR_SPEED := 0.018

var _root: Control
var _panel: PanelContainer
var _portrait: ColorRect
var _portrait_label: Label
var _name_label: Label
var _text_label: RichTextLabel
var _choices_box: VBoxContainer
var _continue_hint: Label

var _pages: Array = []
var _choices_by_page: Dictionary = {}
var _page_index := 0
var _full_text := ""
var _char_index := 0
var _char_timer := 0.0
var _typing := false
var _open := false


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	add_child(_root)
	_build_panel()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 140
	_panel.offset_right = -140
	_panel.offset_bottom = -40
	_panel.offset_top = -260
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.92)
	style.border_color = Color("#e8c875")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	_panel.add_child(h)

	var portrait_wrap := Control.new()
	portrait_wrap.custom_minimum_size = Vector2(84, 84)
	h.add_child(portrait_wrap)
	_portrait = ColorRect.new()
	_portrait.size = Vector2(84, 84)
	_portrait.color = Color("#e8c875")
	portrait_wrap.add_child(_portrait)
	_portrait_label = Label.new()
	_portrait_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 30)
	_portrait_label.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	portrait_wrap.add_child(_portrait_label)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color("#ffe27a"))
	v.add_child(_name_label)
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(0, 90)
	_text_label.add_theme_font_size_override("normal_font_size", 19)
	_text_label.add_theme_color_override("default_color", Color(0.96, 0.95, 0.9))
	v.add_child(_text_label)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 6)
	v.add_child(_choices_box)
	_continue_hint = Label.new()
	_continue_hint.text = "[F / Espaço / clique] continuar"
	_continue_hint.add_theme_font_size_override("font_size", 13)
	_continue_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75, 0.8))
	v.add_child(_continue_hint)

	var gui := Control.new()
	gui.set_anchors_preset(Control.PRESET_FULL_RECT)
	gui.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(gui)
	gui.gui_input.connect(_on_gui_input)


## pages: Array[String]. choices (opcional): Array de {"text":String,"reply":String},
## aparecem só depois da última página.
func open(speaker_name: String, color: Color, initials: String, pages: Array, choices: Array = []) -> void:
	if _open:
		return
	_open = true
	GameState.ui_blocking += 1
	_root.visible = true
	_name_label.text = speaker_name
	_portrait.color = color
	_portrait_label.text = initials
	_pages = pages.duplicate()
	_choices_by_page[_pages.size() - 1] = choices
	_page_index = 0
	_show_page()


func _show_page() -> void:
	_choices_box.visible = false
	for c in _choices_box.get_children():
		c.queue_free()
	_full_text = String(_pages[_page_index]) if _page_index < _pages.size() else ""
	_char_index = 0
	_char_timer = 0.0
	_typing = true
	_text_label.text = ""
	_continue_hint.visible = true


func _process(delta: float) -> void:
	if not _open or not _typing:
		return
	_char_timer -= delta
	while _char_timer <= 0.0 and _char_index < _full_text.length():
		_char_index += 1
		_text_label.text = _full_text.substr(0, _char_index)
		_char_timer += CHAR_SPEED
	if _char_index >= _full_text.length():
		_typing = false
		_maybe_show_choices()


func _maybe_show_choices() -> void:
	var choices: Array = _choices_by_page.get(_page_index, [])
	if _page_index == _pages.size() - 1 and not choices.is_empty():
		_continue_hint.visible = false
		_choices_box.visible = true
		for choice: Dictionary in choices:
			var btn := Button.new()
			btn.text = String(choice.get("text", "..."))
			btn.pressed.connect(_on_choice_picked.bind(choice))
			_choices_box.add_child(btn)


func _on_choice_picked(choice: Dictionary) -> void:
	_pages = [String(choice.get("reply", "..."))]
	_choices_by_page.clear()
	_page_index = 0
	_show_page()


func _advance() -> void:
	if not _open:
		return
	if _typing:
		_char_index = _full_text.length()
		_text_label.text = _full_text
		_typing = false
		_maybe_show_choices()
		return
	if _choices_box.visible:
		return
	_page_index += 1
	if _page_index >= _pages.size():
		close()
	else:
		_show_page()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	GameState.ui_blocking = maxi(0, GameState.ui_blocking - 1)
	finished.emit()


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"jump") or event.is_action_pressed(&"pause"):
		if event.is_action_pressed(&"pause"):
			close()
		else:
			_advance()
		get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_advance()
