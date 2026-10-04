extends Feature
## Barra rápida (8 slots) ligada a GameState.inventory/selected_slot. Nome do item selecionado
## acima e moedas no canto superior direito (abaixo do relógio do Hud).

var _slots: Array[InventorySlotControl] = []
var _name_label: Label


func install(_ctx: GameContext) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_build_coins(root)
	_build_bar(root)
	GameState.inventory.changed.connect(_refresh)
	GameState.selected_slot_changed.connect(func(_i: int) -> void: _refresh())
	_refresh()


func _build_coins(root: Control) -> void:
	var coins := CoinsDisplay.new()
	coins.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coins.offset_top = 96
	coins.offset_right = -28
	coins.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(coins)


func _build_bar(root: Control) -> void:
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor.offset_bottom = -26
	anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	anchor.grow_horizontal = Control.GROW_DIRECTION_BOTH
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(anchor)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(vbox)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", UiTheme.COLOR_YELLOW)
	_name_label.add_theme_color_override("font_outline_color", UiTheme.COLOR_WOOD_DARK)
	_name_label.add_theme_constant_override("outline_size", 7)
	vbox.add_child(_name_label)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_WOOD, UiTheme.COLOR_WOOD_DARK, 4, 20))
	vbox.add_child(panel)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)
	for i in Inventory.HOTBAR_SIZE:
		var slot := InventorySlotControl.new()
		slot.setup(i, true)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(slot)
		_slots.append(slot)


func _refresh() -> void:
	for i in _slots.size():
		var id := GameState.inventory.slot_id(i)
		var count := GameState.inventory.slot_count(i)
		_slots[i].refresh(id, count, i == GameState.selected_slot)
	var sel := GameState.selected_item()
	_name_label.visible = sel != &""
	_name_label.text = ItemDB.display_name(sel) if sel != &"" else ""
