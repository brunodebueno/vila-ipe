extends Feature
## Inventário modal (tecla inventory = Tab/I): grade 8x4, os 8 primeiros slots são a hotbar.
## Arrastar-e-soltar (Inventory.move_slot), clique direito descarta 1, tooltip com
## nome/descrição/preço, mostra moedas. Controla GameState.ui_blocking; fecha com Esc ou a
## mesma tecla que abriu. Linha de comando: --open-inventory abre a janela já no início (QA).

const COLUMNS := 8
const ROWS := 4

var _dim: ColorRect
var _modal: PanelContainer
var _slots: Array[InventorySlotControl] = []
var _tooltip: UiTooltipPanel
var _is_open := false


func install(_ctx: GameContext) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	root.add_child(_dim)
	_modal = PanelContainer.new()
	_modal.set_anchors_preset(Control.PRESET_CENTER)
	_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	_modal.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.COLOR_WOOD, UiTheme.COLOR_WOOD_DARK, 5, 22))
	_modal.visible = false
	root.add_child(_modal)
	_build_modal_content()
	_tooltip = UiTooltipPanel.new()
	root.add_child(_tooltip)
	GameState.inventory.changed.connect(_refresh_slots)
	GameState.selected_slot_changed.connect(func(_i: int) -> void: _refresh_slots())
	_refresh_slots()
	if OS.get_cmdline_user_args().has("--open-inventory"):
		call_deferred("_open")


func _build_modal_content() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	_modal.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	vbox.add_child(header)
	var title := Label.new()
	title.text = "Inventário"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UiTheme.COLOR_YELLOW)
	title.add_theme_color_override("font_outline_color", UiTheme.COLOR_WOOD_DARK)
	title.add_theme_constant_override("outline_size", 8)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(CoinsDisplay.new())
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	for i in COLUMNS * ROWS:
		var slot := InventorySlotControl.new()
		slot.setup(i, i < Inventory.HOTBAR_SIZE)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		grid.add_child(slot)
		_slots.append(slot)
	var hint := Label.new()
	hint.text = "Arraste para organizar · Clique direito descarta 1 · Tab/Esc fecha"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_DARK)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif _is_open and event.is_action_pressed(&"pause"):
		_close()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	GameState.ui_blocking += 1
	_dim.visible = true
	_modal.visible = true
	_modal.pivot_offset = _modal.size / 2.0
	_modal.scale = Vector2(0.85, 0.85)
	_modal.modulate = Color(1, 1, 1, 0)
	_dim.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_modal, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_modal, "modulate:a", 1.0, 0.18)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.18)
	_refresh_slots()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	GameState.ui_blocking = maxi(0, GameState.ui_blocking - 1)
	_tooltip.hide_tooltip()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_modal, "scale", Vector2(0.9, 0.9), 0.14)
	tween.tween_property(_modal, "modulate:a", 0.0, 0.14)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(func() -> void:
		_dim.visible = false
		_modal.visible = false)


func _refresh_slots() -> void:
	for i in _slots.size():
		var id := GameState.inventory.slot_id(i)
		var count := GameState.inventory.slot_count(i)
		var selected := i < Inventory.HOTBAR_SIZE and i == GameState.selected_slot
		_slots[i].refresh(id, count, selected)


func _on_slot_clicked(index: int, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT and index < Inventory.HOTBAR_SIZE:
		GameState.select_slot(index)
	elif button == MOUSE_BUTTON_RIGHT:
		_drop_one(index)


func _drop_one(index: int) -> void:
	var slot: Dictionary = GameState.inventory.slots[index]
	if slot.is_empty():
		return
	slot["count"] = int(slot["count"]) - 1
	if slot["count"] <= 0:
		GameState.inventory.slots[index] = {}
	GameState.inventory.changed.emit()


func _on_slot_hovered(index: int, hovering: bool) -> void:
	if not hovering:
		_tooltip.hide_tooltip()
		return
	var id := GameState.inventory.slot_id(index)
	if id == &"":
		_tooltip.hide_tooltip()
		return
	var rect := _slots[index].get_global_rect()
	var vp_size := get_viewport().get_visible_rect().size
	var pos := rect.position + Vector2(rect.size.x + 8, 0)
	pos.x = minf(pos.x, vp_size.x - 230)
	pos.y = minf(pos.y, vp_size.y - 100)
	_tooltip.show_for(id, pos)
