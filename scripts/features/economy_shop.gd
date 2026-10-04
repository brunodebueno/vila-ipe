class_name EconomyShop
extends Feature
## Barraca de feira do Seu Nenê: loja com abas COMPRAR / VENDER.
## Placeada perto da praça em center + (8, -2).

const OFFSET := Vector2i(8, -2)

var _ctx: GameContext
var _layer: CanvasLayer
var _panel: Panel
var _tab_buy: Button
var _tab_sell: Button
var _buy_list: VBoxContainer
var _sell_list: VBoxContainer
var _is_open := false
var _showing_buy := true


func install(ctx: GameContext) -> void:
	_ctx = ctx
	var center := Vector2i(WorldConst.MAP_SIZE) / 2
	var cell := center + OFFSET
	var stall := ShopStall.create()
	stall.position = Vector3(cell.x + 0.5, ctx.terrain.top_y(cell), cell.y + 0.5)
	ctx.main.add_child(stall)

	var zone := InteractZone.new()
	zone.setup(1.6, "Loja do Seu Nenê")
	zone.position = stall.position
	ctx.main.add_child(zone)
	zone.activated.connect(_toggle)

	_build_ui()
	EventBus.hour_changed.connect(EconomyApi.on_hour_changed)

	if OS.get_cmdline_user_args().has("--open-shop"):
		_open()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.name = "ShopUI"
	_ctx.main.add_child(_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	_layer.add_child(dim)
	_panel = Panel.new()
	dim.add_child(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -310
	_panel.offset_right = 310
	_panel.offset_top = -230
	_panel.offset_bottom = 230
	_dim_ref = dim

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Loja do Seu Nenê"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tabs)
	_tab_buy = Button.new()
	_tab_buy.text = "COMPRAR"
	_tab_buy.toggle_mode = true
	_tab_buy.button_pressed = true
	_tab_buy.pressed.connect(func() -> void: _switch_tab(true))
	tabs.add_child(_tab_buy)
	_tab_sell = Button.new()
	_tab_sell.text = "VENDER"
	_tab_sell.toggle_mode = true
	_tab_sell.pressed.connect(func() -> void: _switch_tab(false))
	tabs.add_child(_tab_sell)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(580, 340)
	vbox.add_child(scroll)
	_buy_list = VBoxContainer.new()
	_buy_list.add_theme_constant_override("separation", 4)
	_sell_list = VBoxContainer.new()
	_sell_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_buy_list)
	scroll.add_child(_sell_list)

	var close := Button.new()
	close.text = "Fechar (F/Esc)"
	close.pressed.connect(_close)
	vbox.add_child(close)


var _dim_ref: ColorRect


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
	_dim_ref.visible = true
	_refresh_buy()
	_refresh_sell()
	_switch_tab(true)


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	GameState.ui_blocking -= 1
	_dim_ref.visible = false


func _switch_tab(buy: bool) -> void:
	_showing_buy = buy
	_tab_buy.button_pressed = buy
	_tab_sell.button_pressed = not buy
	_buy_list.visible = buy
	_sell_list.visible = not buy
	if buy:
		_refresh_buy()
	else:
		_refresh_sell()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause"):
		_close()
		get_viewport().set_input_as_handled()


func _refresh_buy() -> void:
	for child in _buy_list.get_children():
		child.queue_free()
	for cat: Dictionary in ShopDB.categories():
		var header := Label.new()
		header.text = cat["name"]
		header.add_theme_color_override("font_color", Color("#ffe27a"))
		_buy_list.add_child(header)
		for entry: Dictionary in cat["items"]:
			var id := StringName(entry["id"])
			var price := int(entry["price"])
			_buy_list.add_child(_make_buy_row(id, price))


func _make_buy_row(id: StringName, price: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s — T$ %d" % [ItemDB.display_name(id), price]
	label.custom_minimum_size.x = 400
	row.add_child(label)
	var buy_btn := Button.new()
	buy_btn.text = "Comprar"
	buy_btn.pressed.connect(func() -> void: _buy(id, price))
	row.add_child(buy_btn)
	return row


func _buy(id: StringName, price: int) -> void:
	if not GameState.spend_coins(price):
		EventBus.notify.emit("Tostões insuficientes para %s." % ItemDB.display_name(id), id)
		return
	var left := GameState.give(id, 1)
	if left > 0:
		GameState.add_coins(price)
		EventBus.notify.emit("Inventário cheio!", id)
		return
	EventBus.notify.emit("Comprou %s por T$ %d." % [ItemDB.display_name(id), price], id)
	CoinPopup.show(_layer, "-T$%d" % price, Color("#ff8a65"))


func _refresh_sell() -> void:
	for child in _sell_list.get_children():
		child.queue_free()
	var seen: Dictionary = {}
	for slot in GameState.inventory.slots:
		if slot.is_empty():
			continue
		var id: StringName = slot["id"]
		if seen.has(id) or not EconomyApi.can_sell(id):
			continue
		seen[id] = true
		var count := GameState.inventory.count(id)
		_sell_list.add_child(_make_sell_row(id, count))
	if seen.is_empty():
		var empty := Label.new()
		empty.text = "Nada vendável no inventário."
		_sell_list.add_child(empty)


func _make_sell_row(id: StringName, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var price := EconomyApi.sell_value(id)
	var label := Label.new()
	label.text = "%s ×%d — T$ %d cada" % [ItemDB.display_name(id), count, price]
	label.custom_minimum_size.x = 340
	row.add_child(label)
	var one := Button.new()
	one.text = "Vender 1"
	one.pressed.connect(func() -> void: _sell(id, 1))
	row.add_child(one)
	var all_btn := Button.new()
	all_btn.text = "Vender tudo"
	all_btn.pressed.connect(func() -> void: _sell(id, GameState.inventory.count(id)))
	row.add_child(all_btn)
	return row


func _sell(id: StringName, amount: int) -> void:
	if amount <= 0 or not GameState.inventory.has(id, amount):
		return
	var unit := EconomyApi.sell_value(id)
	var total := unit * amount
	GameState.inventory.remove(id, amount)
	GameState.add_coins(total)
	EconomyApi.register_sale(id, amount)
	EventBus.notify.emit("Vendeu %d× %s por T$ %d." % [amount, ItemDB.display_name(id), total], id)
	CoinPopup.show(_layer, "+T$%d" % total, Color("#8fd19a"))
	_refresh_sell()
