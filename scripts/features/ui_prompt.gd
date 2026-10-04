class_name UiPrompt
extends Feature
## Prompt de interação "[F] Ação" acima da hotbar. Qualquer módulo pode chamar sem referência
## direta, via grupo: get_tree().get_first_node_in_group(&"ui_prompt").show_prompt("Falar", "F")

var _panel: PanelContainer
var _label: Label
var _key_badge: Label


func install(_ctx: GameContext) -> void:
	add_to_group(&"ui_prompt")
	var layer := CanvasLayer.new()
	layer.layer = 17
	add_child(layer)
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor.offset_bottom = -150
	anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	anchor.grow_horizontal = Control.GROW_DIRECTION_BOTH
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(anchor)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_WOOD_DARK, UiTheme.COLOR_YELLOW, 3, 16))
	_panel.visible = false
	anchor.add_child(_panel)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_panel.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	var badge_bg := PanelContainer.new()
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_bg.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_YELLOW, UiTheme.COLOR_WOOD_DARK, 2, 8))
	hbox.add_child(badge_bg)
	_key_badge = Label.new()
	_key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_badge.add_theme_font_size_override("font_size", 20)
	_key_badge.add_theme_color_override("font_color", UiTheme.COLOR_WOOD_DARK)
	badge_bg.add_child(_key_badge)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", UiTheme.COLOR_PAPER)
	hbox.add_child(_label)


func show_prompt(text: String, key: String = "F") -> void:
	_key_badge.text = key
	_label.text = text
	_panel.visible = true


func hide_prompt() -> void:
	_panel.visible = false
