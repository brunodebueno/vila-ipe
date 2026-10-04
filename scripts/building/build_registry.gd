class_name BuildRegistry
extends RefCounted
## Registro global (estático) das células ocupadas por objetos colocados no modo construção.
## PropManager consulta isto em is_blocked()/can_plant() para respeitar os placeáveis,
## e BuildMode usa para saber onde já existe algo e para localizar o que remover.

static var _occupied: Dictionary = {}


static func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


static func occupant_at(cell: Vector2i) -> StringName:
	return _occupied.get(cell, &"")


static func register(cell: Vector2i, id: StringName) -> void:
	_occupied[cell] = id


static func unregister(cell: Vector2i) -> void:
	_occupied.erase(cell)


## Limpa todo o registro (novo jogo / antes de carregar um save).
static func clear() -> void:
	_occupied.clear()
