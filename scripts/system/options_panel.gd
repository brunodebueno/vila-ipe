class_name OptionsPanel
extends PanelContainer
## Painel de opções reutilizável (menu principal e pausa). Edita e persiste SettingsStore.

signal closed

var ctx: GameContext
var _data: Dictionary


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_data = SettingsStore.load_settings()
	custom_minimum_size = Vector2(460, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	style.border_color = Color("#ffc928")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	add_child(list)
	_title(list, "Opções")
	_slider(list, "Música", "audio", "music")
	_slider(list, "Efeitos", "audio", "sfx")
	_slider(list, "Ambiente", "audio", "ambience")
	_slider(list, "Sensibilidade da câmera", "camera", "sensitivity", 0.2, 2.0)
	_slider(list, "Duração do dia (s)", "gameplay", "day_length", 60.0, 1200.0)
	_check(list, "Tela cheia", "video", "fullscreen")
	_check(list, "V-Sync", "video", "vsync")
	_check(list, "Sombras", "video", "shadows")
	_check(list, "MSAA (antialiasing)", "video", "msaa")
	var lang := Label.new()
	lang.text = "Idioma: Português (Brasil)"
	list.add_child(lang)
	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(_on_close)
	list.add_child(close_btn)


func _title(list: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("#ffe27a"))
	list.add_child(label)


func _slider(list: VBoxContainer, label_text: String, section: String, key: String, min_v: float = 0.0, max_v: float = 1.0) -> void:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = (max_v - min_v) / 100.0
	slider.value = float(_data[section][key])
	slider.value_changed.connect(func(v: float) -> void: _on_changed(section, key, v))
	row.add_child(slider)
	list.add_child(row)


func _check(list: VBoxContainer, label_text: String, section: String, key: String) -> void:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = bool(_data[section][key])
	check.toggled.connect(func(v: bool) -> void: _on_changed(section, key, v))
	list.add_child(check)


func _on_changed(section: String, key: String, value: Variant) -> void:
	_data[section][key] = value
	SettingsStore.save_settings(_data)
	SettingsStore.apply_audio(_data)
	SettingsStore.apply_video(_data)
	SettingsStore.apply_graphics(_data, get_tree())
	if ctx:
		if ctx.rig:
			ctx.rig.sensitivity = 0.005 * float(_data["camera"]["sensitivity"])
		if ctx.day_night:
			ctx.day_night.day_length_seconds = float(_data["gameplay"]["day_length"])


func _on_close() -> void:
	closed.emit()
