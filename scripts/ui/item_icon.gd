class_name ItemIcon
extends PanelContainer
## Quadradinho colorido com a cor do ItemDef e a inicial do nome (sem depender de sprites).

var item_id: StringName = &""

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh()


func setup(id: StringName) -> void:
	item_id = id
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	if item_id == &"":
		sb.bg_color = Color(0, 0, 0, 0.12)
		_label.text = ""
	else:
		var def := ItemDB.get_def(item_id)
		var color := def.color if def else Color.WHITE
		sb.bg_color = color
		sb.border_color = color.darkened(0.35)
		sb.set_border_width_all(2)
		var name_str := ItemDB.display_name(item_id)
		_label.text = name_str.substr(0, 1).to_upper() if name_str.length() > 0 else "?"
		_label.add_theme_color_override("font_color", Color.WHITE if color.get_luminance() < 0.6 else Color("#2b1a0a"))
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
		_label.add_theme_constant_override("outline_size", 3)
	add_theme_stylebox_override("panel", sb)
