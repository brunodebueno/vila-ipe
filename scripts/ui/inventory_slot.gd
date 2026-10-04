class_name InventorySlotControl
extends PanelContainer
## Um slot (hotbar ou inventário): ícone, contagem, número da tecla e destaque de seleção.
## Suporta arrastar-e-soltar (Inventory.move_slot) e emite sinais para tooltip/clique direito.

signal slot_clicked(index: int, button: int)
signal slot_hovered(index: int, hovering: bool)

var slot_index := -1
var is_hotbar := false

var _icon: ItemIcon
var _count_label: Label
var _key_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	_icon = ItemIcon.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_icon)
	_count_label = Label.new()
	_count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_count_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_count_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_count_label.offset_right = -4
	_count_label.offset_bottom = -2
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_count_label.add_theme_constant_override("outline_size", 5)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)
	_key_label = Label.new()
	_key_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_key_label.offset_left = 3
	_key_label.offset_top = 1
	_key_label.add_theme_font_size_override("font_size", 13)
	_key_label.add_theme_color_override("font_color", UiTheme.COLOR_PAPER)
	_key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_key_label.add_theme_constant_override("outline_size", 4)
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_key_label)
	mouse_entered.connect(func() -> void: slot_hovered.emit(slot_index, true))
	mouse_exited.connect(func() -> void: slot_hovered.emit(slot_index, false))
	gui_input.connect(_on_gui_input)
	refresh(&"", 0, false)


func setup(index: int, hotbar: bool) -> void:
	slot_index = index
	is_hotbar = hotbar
	custom_minimum_size = Vector2(64, 64)
	if is_node_ready():
		_key_label.text = str(index + 1) if hotbar else ""


func refresh(id: StringName, count: int, selected: bool) -> void:
	_icon.setup(id)
	_count_label.text = str(count) if count > 1 else ""
	_key_label.text = str(slot_index + 1) if is_hotbar else ""
	add_theme_stylebox_override("panel", UiTheme.slot_style(selected))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		slot_clicked.emit(slot_index, (event as InputEventMouseButton).button_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if GameState.inventory.slot_id(slot_index) == &"":
		return null
	var preview := ItemIcon.new()
	preview.custom_minimum_size = Vector2(56, 56)
	preview.setup(GameState.inventory.slot_id(slot_index))
	set_drag_preview(preview)
	return {"from": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("from")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	GameState.inventory.move_slot(int(data["from"]), slot_index)
