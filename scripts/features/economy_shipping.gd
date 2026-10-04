class_name EconomyShipping
extends Feature
## Caixa de Entregas: baú de madeira ao lado da praça. Itens colocados dentro são
## vendidos à noite (quando o relógio cruza 20:00) — loja secundária e mais simples.

const OFFSET := Vector2i(-6, -2)
const SELL_HOUR := 20.0
const SLOT_COUNT := 8

var _ctx: GameContext
var _layer: CanvasLayer
var _dim: ColorRect
var _slots: Array[Dictionary] = []
var _is_open := false
var _grid: GridContainer
var _last_hour := -1.0


func install(ctx: GameContext) -> void:
	_ctx = ctx
	for i in SLOT_COUNT:
		_slots.append({})
	var center := Vector2i(WorldConst.MAP_SIZE) / 2
	var cell := center + OFFSET
	var chest := EconomyStructures.create_mailbox()
	chest.position = Vector3(cell.x + 0.5, ctx.terrain.top_y(cell), cell.y + 0.5)
	ctx.main.add_child(chest)

	var zone := InteractZone.new()
	zone.setup(1.4, "Caixa de Entregas")
	zone.position = chest.position
	ctx.main.add_child(zone)
	zone.activated.connect(_toggle)

	_build_ui()
	EventBus.hour_changed.connect(_on_hour_changed)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.name = "ShippingUI"
	_ctx.main.add_child(_layer)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	_layer.add_child(_dim)

	var panel := Panel.new()
	_dim.add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = -180
	panel.offset_bottom = 180

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Caixa de Entregas"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Coloque itens vendáveis aqui. Tudo é vendido às 20h."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(_grid)

	var add_row := HBoxContainer.new()
	vbox.add_child(add_row)
	var add_label := Label.new()
	add_label.text = "Adicionar item selecionado:"
	add_row.add_child(add_label)
	var add_btn := Button.new()
	add_btn.text = "Colocar 1"
	add_btn.pressed.connect(_add_selected)
	add_row.add_child(add_btn)

	var close := Button.new()
	close.text = "Fechar (F/Esc)"
	close.pressed.connect(_close)
	vbox.add_child(close)


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
	_refresh()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	GameState.ui_blocking -= 1
	_dim.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause"):
		_close()
		get_viewport().set_input_as_handled()


func _add_selected() -> void:
	var id := GameState.selected_item()
	if id == &"" or not EconomyApi.can_sell(id):
		EventBus.notify.emit("Esse item não pode ser vendido na caixa.", id)
		return
	if not GameState.inventory.has(id, 1):
		return
	for i in _slots.size():
		if _slots[i].is_empty():
			GameState.inventory.remove(id, 1)
			_slots[i] = {"id": id, "count": 1}
			_refresh()
			return
		elif _slots[i]["id"] == id:
			GameState.inventory.remove(id, 1)
			_slots[i]["count"] += 1
			_refresh()
			return
	EventBus.notify.emit("Caixa de Entregas cheia.", id)


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for slot in _slots:
		var cell := Panel.new()
		cell.custom_minimum_size = Vector2(90, 70)
		if not slot.is_empty():
			var label := Label.new()
			label.text = "%s\n×%d" % [ItemDB.display_name(slot["id"]), slot["count"]]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			cell.add_child(label)
		_grid.add_child(cell)


func _on_hour_changed(hour: float) -> void:
	if _last_hour >= 0.0 and _last_hour < SELL_HOUR and hour >= SELL_HOUR:
		_sell_all()
	_last_hour = hour


func _sell_all() -> void:
	var total := 0
	var count := 0
	for i in _slots.size():
		var slot := _slots[i]
		if slot.is_empty():
			continue
		var unit := EconomyApi.sell_value(slot["id"])
		total += unit * int(slot["count"])
		count += int(slot["count"])
		EconomyApi.register_sale(slot["id"], slot["count"])
		_slots[i] = {}
	if total <= 0:
		return
	GameState.add_coins(total)
	EventBus.notify.emit("Caixa de Entregas: vendeu %d itens à noite por T$ %d." % [count, total], &"")
	CoinPopup.show(_layer, "+T$%d" % total, Color("#8fd19a"))
	if _is_open:
		_refresh()
