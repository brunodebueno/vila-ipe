extends Node
## Autoload: estado da partida (inventário, dinheiro, flags, estatísticas, UI aberta).

signal coins_changed(coins: int)
signal selected_slot_changed(index: int)
signal stat_changed(stat: StringName, value: int)
signal flag_changed(flag: StringName, value: Variant)

const START_COINS := 50

var inventory := Inventory.new()
var coins := 0
var selected_slot := 0
var flags: Dictionary = {}
var stats: Dictionary = {}
## Quantas janelas/menus estão abertas. Enquanto > 0, ferramentas e câmera ignoram o mouse.
var ui_blocking := 0


func _ready() -> void:
	new_game()


func new_game() -> void:
	inventory = Inventory.new()
	coins = START_COINS
	selected_slot = 0
	flags.clear()
	stats.clear()
	for id: StringName in [&"tool_axe", &"tool_raise", &"tool_lower", &"tool_flatten", &"tool_path", &"tool_grass", &"tool_hammer", &"tool_rod"]:
		inventory.add(id, 1)
	inventory.add(&"sapling_ipe", 6)
	inventory.add(&"wood", 10)
	inventory.add(&"stone", 6)
	coins_changed.emit(coins)
	selected_slot_changed.emit(selected_slot)


func is_ui_blocking() -> bool:
	return ui_blocking > 0


func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, Inventory.HOTBAR_SIZE - 1)
	selected_slot_changed.emit(selected_slot)


func selected_item() -> StringName:
	return inventory.slot_id(selected_slot)


## Entrega item ao jogador. Retorna quantos não couberam.
func give(id: StringName, amount: int = 1) -> int:
	var left := inventory.add(id, amount)
	if left < amount:
		EventBus.item_gained.emit(id, amount - left)
	return left


func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	add_coins(-amount)
	return true


func add_stat(stat: StringName, amount: int = 1) -> void:
	stats[stat] = int(stats.get(stat, 0)) + amount
	stat_changed.emit(stat, stats[stat])


func get_stat(stat: StringName) -> int:
	return int(stats.get(stat, 0))


func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)
