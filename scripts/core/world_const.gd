class_name WorldConst
extends RefCounted
## Constantes do mundo: grade, alturas discretas e paleta brasileira.

const CELL := 1.0
const STEP := 0.5
const MAP_SIZE := Vector2i(64, 64)
const CHUNK_SIZE := 16
const MIN_LEVEL := 0
const MAX_LEVEL := 12
const VOID_LEVEL := -4
const WATER_LEVEL := 3
const WATER_Y := WATER_LEVEL * STEP + 0.25


static func level_to_y(level: int) -> float:
	return level * STEP


static func is_underwater(level: int) -> bool:
	return level <= WATER_LEVEL


static func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.z / CELL))


static func tile_color(tile: int) -> Color:
	match tile:
		TerrainData.Tile.SAND:
			return Color("#f0d79c")
		TerrainData.Tile.DIRT:
			return Color("#b0683a")
		TerrainData.Tile.PATH:
			return Color("#d3cbb8")
		_:
			return Color("#6dbf4f")


static func wall_color(tile: int) -> Color:
	match tile:
		TerrainData.Tile.SAND:
			return Color("#d6b97c")
		TerrainData.Tile.DIRT:
			return Color("#8c522c")
		TerrainData.Tile.PATH:
			return Color("#a39b88")
		_:
			return Color("#8a5a35")
