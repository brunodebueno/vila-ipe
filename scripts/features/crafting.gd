class_name CraftingUI
extends Feature
## Bancada de carpintaria (estrutura no mundo, abre com F) e menu de receitas portáteis
## (tecla R, só receitas com `portable: true`).

const BENCH_OFFSET := Vector2i(6, -4)
const PROGRESS_SECONDS := 0.6

var _ctx: GameContext
var _layer: CanvasLayer
var _dim: ColorRect
var _panel: Panel
var _recipe_list: VBoxContainer
var _detail_box: VBoxContainer
var _title_label: Label
var _ingredients_box: VBoxContainer
var _craft_btn: Button
var _progress: ProgressBar
var _qty_buttons: Array[Button] = []

var _is_open := false
var _portable_mode := false
var _current_recipe: RecipeDef
var _qty := 1
var _crafting := false


func install(ctx: GameContext) -> void:
	_ctx = ctx
	var center := Vector2i(WorldConst.MAP_SIZE) / 2
	var cell := center + BENCH_OFFSET
	var bench := EconomyStructures.create_bench()
	bench.position = Vector3(cell.x + 0.5, ctx.terrain.top_y(cell), cell.y + 0.5)
	ctx.main.add_child(bench)

	var zone := InteractZone.new()
	zone.setup(1.4, "Bancada de Carpintaria")
	zone.position = bench.position
	ctx.main.add_child(zone)
	zone.activated.connect(func() -> void: _toggle(false))

	_build_ui()

	if OS.get_cmdline_user_args().has("--open-craft"):
		_open(false)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.name = "CraftingUI"
	_ctx.main.add_child(_layer)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	_layer.add_child(_dim)

	_panel = Panel.new()
	_dim.add_child(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -380
	_panel.offset_right = 380
	_panel.offset_top = -240
	_panel.offset_bottom = 240

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(320, 0)
	root.add_child(left)
	_title_label = Label.new()
	_title_label.text = "Receitas"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color("#ffe27a"))
	left.add_child(_title_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	_recipe_list = VBoxContainer.new()
	_recipe_list.add_theme_constant_override("separation", 3)
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 6)
	right.add_child(_detail_box)
	_ingredients_box = VBoxContainer.new()
	right.add_child(_ingredients_box)

	var qty_row := HBoxContainer.new()
	right.add_child(qty_row)
	for q in [1, 5]:
		var btn := Button.new()
		btn.text = "×%d" % q
		btn.toggle_mode = true
		btn.button_pressed = q == 1
		btn.pressed.connect(func() -> void: _set_qty(q))
		qty_row.add_child(btn)
		_qty_buttons.append(btn)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	right.add_child(_progress)

	_craft_btn = Button.new()
	_craft_btn.text = "Fabricar"
	_craft_btn.pressed.connect(_do_craft)
	right.add_child(_craft_btn)

	var close := Button.new()
	close.text = "Fechar (R/F/Esc)"
	close.pressed.connect(_close)
	right.add_child(close)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		if event.is_action_pressed(&"crafting"):
			_toggle(true)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"crafting") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause"):
		_close()
		get_viewport().set_input_as_handled()


func _toggle(portable: bool) -> void:
	if _is_open:
		_close()
	else:
		_open(portable)


func _open(portable: bool) -> void:
	if _is_open:
		return
	_is_open = true
	_portable_mode = portable
	GameState.ui_blocking += 1
	_dim.visible = true
	_title_label.text = "Receitas Portáteis" if portable else "Bancada de Carpintaria"
	_current_recipe = null
	_refresh_list()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	GameState.ui_blocking -= 1
	_dim.visible = false


func _recipes_for_mode() -> Array[RecipeDef]:
	if _portable_mode:
		return RecipeDB.portable_recipes()
	return RecipeDB.all()


func _refresh_list() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()
	var recipes := _recipes_for_mode()
	recipes.sort_custom(func(a: RecipeDef, b: RecipeDef) -> bool: return a.display_name() < b.display_name())
	for r in recipes:
		_recipe_list.add_child(_make_recipe_button(r))
	if not recipes.is_empty() and _current_recipe == null:
		_select_recipe(recipes[0])


func _make_recipe_button(r: RecipeDef) -> Button:
	var btn := Button.new()
	var unlocked := r.is_unlocked()
	btn.text = r.display_name() if unlocked else "??? (bloqueada)"
	btn.disabled = not unlocked
	var can := unlocked and EconomyApi.can_craft(r.id, 1)
	btn.add_theme_color_override("font_color", Color("#ffffff") if can else Color("#8a8a8a"))
	if unlocked:
		btn.pressed.connect(func() -> void: _select_recipe(r))
	return btn


func _select_recipe(r: RecipeDef) -> void:
	_current_recipe = r
	_set_qty(1)
	_refresh_detail()


func _set_qty(q: int) -> void:
	_qty = q
	for btn in _qty_buttons:
		btn.button_pressed = (btn.text == "×%d" % q)
	_refresh_detail()


func _refresh_detail() -> void:
	for child in _detail_box.get_children():
		child.queue_free()
	for child in _ingredients_box.get_children():
		child.queue_free()
	if _current_recipe == null:
		return
	var r := _current_recipe
	var name_label := Label.new()
	name_label.text = "%s ×%d (%s)" % [r.display_name(), r.result_amount * _qty, r.station]
	name_label.add_theme_font_size_override("font_size", 22)
	_detail_box.add_child(name_label)
	for ing_id: StringName in r.ingredients:
		var need := int(r.ingredients[ing_id]) * _qty
		var have := GameState.inventory.count(ing_id)
		var row := Label.new()
		var ok := have >= need
		row.text = "%s: %d/%d" % [ItemDB.display_name(ing_id), have, need]
		row.add_theme_color_override("font_color", Color("#8fd19a") if ok else Color("#e8584a"))
		_ingredients_box.add_child(row)
	_craft_btn.disabled = _crafting or not EconomyApi.can_craft(r.id, _qty)


func _do_craft() -> void:
	if _current_recipe == null or _crafting:
		return
	if not EconomyApi.can_craft(_current_recipe.id, _qty):
		return
	_crafting = true
	_craft_btn.disabled = true
	_progress.value = 0.0
	var tw := create_tween()
	tw.tween_property(_progress, "value", 1.0, PROGRESS_SECONDS)
	await tw.finished
	EconomyApi.craft(_current_recipe.id, _qty)
	EventBus.notify.emit("Fabricou %s." % _current_recipe.display_name(), _current_recipe.result_id)
	_crafting = false
	_progress.value = 0.0
	_refresh_list()
	_refresh_detail()
