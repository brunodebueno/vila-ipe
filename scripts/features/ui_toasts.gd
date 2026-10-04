extends Feature
## Avisos empilháveis (até 5, canto direito): ganho de item (EventBus.item_gained) e avisos
## genéricos (EventBus.notify). Cada toast nasce com fade-in, soma alguns segundos e some.

const MAX_TOASTS := 5
const LIFETIME := 3.2

var _list: VBoxContainer


func install(_ctx: GameContext) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 16
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	root.offset_top = 150
	root.offset_right = -24
	root.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", 8)
	root.add_child(_list)
	EventBus.item_gained.connect(_on_item_gained)
	EventBus.notify.connect(_on_notify)


func _on_item_gained(id: StringName, amount: int) -> void:
	_push("+%d %s" % [amount, ItemDB.display_name(id)], id)


func _on_notify(text: String, icon_item: StringName) -> void:
	_push(text, icon_item)


func _push(text: String, icon_item: StringName) -> void:
	if _list.get_child_count() >= MAX_TOASTS:
		_list.get_child(0).queue_free()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_PAPER, UiTheme.COLOR_WOOD_DARK, 2, 12))
	panel.modulate = Color(1, 1, 1, 0)
	_list.add_child(panel)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)
	if icon_item != &"" and ItemDB.exists(icon_item):
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.setup(icon_item)
		hbox.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_DARK)
	hbox.add_child(label)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(LIFETIME)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func() -> void:
		if is_instance_valid(panel):
			panel.queue_free())
