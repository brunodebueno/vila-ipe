class_name Hud
extends CanvasLayer
## Interface do MVP: barra de ferramentas, relógio e dicas. F1 esconde tudo (modo trailer).
## H colapsa/expande a dica de controles (fica discreta por padrão).

var _root: Control
var _clock: Label
var _brush: Label
var _hint: Label
var _hint_collapsed := true


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_title()
	_build_clock()
	_build_hint()
	EventBus.brush_changed.connect(_on_brush_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.hud_toggled.connect(func(v: bool) -> void: _root.visible = v)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).physical_keycode == KEY_H:
			_hint_collapsed = not _hint_collapsed
			_update_hint_text()


func _build_title() -> void:
	var title := Label.new()
	title.text = "Vila Ipê"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	title.add_theme_color_override("font_outline_color", Color("#5a2d12"))
	title.add_theme_constant_override("outline_size", 10)
	title.position = Vector2(24, 14)
	_root.add_child(title)


func _build_clock() -> void:
	_clock = Label.new()
	_clock.add_theme_font_size_override("font_size", 26)
	_clock.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_clock.add_theme_constant_override("outline_size", 8)
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_clock.offset_top = 18
	_clock.offset_right = -28
	_root.add_child(_clock)
	_brush = Label.new()
	_brush.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_brush.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_brush.offset_top = 56
	_brush.offset_right = -28
	_brush.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_brush.add_theme_constant_override("outline_size", 6)
	_root.add_child(_brush)


func _build_hint() -> void:
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.position = Vector2(24, 54)
	_root.add_child(_hint)
	_update_hint_text()


func _update_hint_text() -> void:
	if _hint_collapsed:
		_hint.text = "[H] controles"
	else:
		_hint.text = "[H] esconder · WASD andar · Shift correr · Espaço pular · Botão direito gira câmera · Roda zoom\n1-8 hotbar · Tab inventário · F interagir · B construção · R bancada · J missões · Esc pausa\nClique esquerdo usa a ferramenta · Q/E tamanho do pincel · T acelera o tempo · F3 câmera cinema · F1 esconde interface · F2 foto"


func _on_brush_changed(size: int) -> void:
	_brush.text = "Pincel %d×%d" % [size, size]


func _on_hour_changed(hour: float) -> void:
	_clock.text = "%02d:%02d" % [int(hour), int(fposmod(hour, 1.0) * 60.0)]
