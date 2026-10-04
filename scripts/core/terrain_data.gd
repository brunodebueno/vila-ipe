class_name TerrainData
extends RefCounted
## Dados puros do terreno: nível de altura e tipo de piso por célula.

signal cell_changed(cell: Vector2i)

enum Tile { GRASS, SAND, DIRT, PATH }

var size: Vector2i
var _heights: PackedInt32Array = PackedInt32Array()
var _tiles: PackedByteArray = PackedByteArray()


func _init(p_size: Vector2i = WorldConst.MAP_SIZE) -> void:
	size = p_size
	_heights.resize(size.x * size.y)
	_tiles.resize(size.x * size.y)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func get_height(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return WorldConst.VOID_LEVEL
	return _heights[_index(cell)]


func get_tile(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return Tile.SAND
	return _tiles[_index(cell)]


func set_height(cell: Vector2i, level: int) -> void:
	if not in_bounds(cell):
		return
	level = clampi(level, WorldConst.MIN_LEVEL, WorldConst.MAX_LEVEL)
	if _heights[_index(cell)] == level:
		return
	_heights[_index(cell)] = level
	cell_changed.emit(cell)


func set_tile(cell: Vector2i, tile: int) -> void:
	if not in_bounds(cell) or _tiles[_index(cell)] == tile:
		return
	_tiles[_index(cell)] = tile
	cell_changed.emit(cell)


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x
