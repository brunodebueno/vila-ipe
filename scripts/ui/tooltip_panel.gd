class_name UiTooltipPanel
extends PanelContainer
## Tooltip flutuante com nome, descrição e preço de um ItemDef. Posição livre (top_level).

var _name_label: Label
var _desc_label: Label
var _price_label: Label


func _ready() -> void:
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	custom_minimum_size = Vector2(220, 0)
	add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_PAPER, UiTheme.COLOR_WOOD_DARK, 2, 10))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_DARK)
	vbox.add_child(_name_label)
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 13)
	_desc_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_DARK)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(_desc_label)
	_price_label = Label.new()
	_price_label.add_theme_font_size_override("font_size", 13)
	_price_label.add_theme_color_override("font_color", UiTheme.COLOR_TERRACOTTA)
	vbox.add_child(_price_label)


func show_for(id: StringName, at: Vector2) -> void:
	var def := ItemDB.get_def(id)
	if def == null:
		visible = false
		return
	_name_label.text = def.display_name
	_desc_label.text = def.description
	_price_label.text = ("Preço: %d moedas" % def.price) if def.price > 0 else ""
	global_position = at
	visible = true


func hide_tooltip() -> void:
	visible = false
