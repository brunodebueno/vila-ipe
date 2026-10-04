class_name Inventory
extends RefCounted
## Inventário em slots. Os primeiros HOTBAR_SIZE slots formam a barra rápida.

signal changed

const HOTBAR_SIZE := 8
const DEFAULT_SIZE := 32

## Cada slot é {} (vazio) ou {"id": StringName, "count": int}.
var slots: Array[Dictionary] = []


func _init(size: int = DEFAULT_SIZE) -> void:
	for i in size:
		slots.append({})


func slot_id(index: int) -> StringName:
	var slot := slots[index]
	return slot["id"] if not slot.is_empty() else &""


func slot_count(index: int) -> int:
	var slot := slots[index]
	return slot["count"] if not slot.is_empty() else 0


func count(id: StringName) -> int:
	var total := 0
	for slot in slots:
		if not slot.is_empty() and slot["id"] == id:
			total += slot["count"]
	return total


func has(id: StringName, amount: int = 1) -> bool:
	return count(id) >= amount


## Retorna quantos itens NÃO couberam.
func add(id: StringName, amount: int = 1) -> int:
	var def := ItemDB.get_def(id)
	var stack_max := def.stack_max if def else 99
	var left := amount
	for slot in slots:
		if left <= 0:
			break
		if not slot.is_empty() and slot["id"] == id and slot["count"] < stack_max:
			var put := mini(left, stack_max - slot["count"])
			slot["count"] += put
			left -= put
	for i in slots.size():
		if left <= 0:
			break
		if slots[i].is_empty():
			var put := mini(left, stack_max)
			slots[i] = {"id": id, "count": put}
			left -= put
	if left != amount:
		changed.emit()
	return left


func can_add(id: StringName, amount: int = 1) -> bool:
	var def := ItemDB.get_def(id)
	var stack_max := def.stack_max if def else 99
	var room := 0
	for slot in slots:
		if slot.is_empty():
			room += stack_max
		elif slot["id"] == id:
			room += stack_max - slot["count"]
	return room >= amount


func remove(id: StringName, amount: int = 1) -> bool:
	if not has(id, amount):
		return false
	var left := amount
	for i in range(slots.size() - 1, -1, -1):
		var slot := slots[i]
		if left <= 0:
			break
		if not slot.is_empty() and slot["id"] == id:
			var take := mini(left, slot["count"])
			slot["count"] -= take
			left -= take
			if slot["count"] <= 0:
				slots[i] = {}
	changed.emit()
	return true


func clear_slot(index: int) -> void:
	slots[index] = {}
	changed.emit()


## Troca/une dois slots (arrastar e soltar na UI).
func move_slot(from: int, to: int) -> void:
	if from == to:
		return
	var a := slots[from]
	var b := slots[to]
	if not a.is_empty() and not b.is_empty() and a["id"] == b["id"]:
		var def := ItemDB.get_def(a["id"])
		var room: int = (def.stack_max if def else 99) - int(b["count"])
		var moved: int = mini(room, int(a["count"]))
		b["count"] += moved
		a["count"] -= moved
		if a["count"] <= 0:
			slots[from] = {}
	else:
		slots[from] = b
		slots[to] = a
	changed.emit()


func to_array() -> Array:
	var out: Array = []
	for slot in slots:
		out.append({} if slot.is_empty() else {"id": String(slot["id"]), "count": slot["count"]})
	return out


func from_array(data: Array) -> void:
	for i in slots.size():
		slots[i] = {}
	for i in mini(data.size(), slots.size()):
		var entry: Dictionary = data[i]
		if not entry.is_empty():
			slots[i] = {"id": StringName(entry["id"]), "count": int(entry["count"])}
	changed.emit()
