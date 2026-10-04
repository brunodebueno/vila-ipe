class_name BuildCatalog
extends RefCounted
## Dados estáticos do modo construção: tamanho do footprint e metadados de cada placeável.
## Os itens em si (nome, preço, ícone) continuam em data/items.json (categoria "placeable").

## Tamanho em células (largura x profundidade) quando o objeto está com yaw = 0.
const FOOTPRINTS: Dictionary = {
	&"build_house": Vector2i(3, 3),
	&"build_bench": Vector2i(1, 2),
}
const DEFAULT_FOOTPRINT := Vector2i(1, 1)

## Objetos com os quais o jogador pode interagir com F.
const INTERACTIVE: Dictionary = {
	&"build_bench": &"sit",
	&"build_hammock": &"lie",
	&"build_campfire": &"warm",
}


static func footprint(id: StringName) -> Vector2i:
	return FOOTPRINTS.get(id, DEFAULT_FOOTPRINT)


static func interaction_kind(id: StringName) -> StringName:
	return INTERACTIVE.get(id, &"")


static func placeable_ids() -> Array[StringName]:
	var out := ItemDB.ids_in_category(&"placeable")
	out.sort()
	return out


## Lista de células ocupadas por `id` ancorado em `cell`, já considerando a rotação `yaw`
## (múltiplos de 90°, em radianos).
static func footprint_cells(id: StringName, cell: Vector2i, yaw: float) -> Array[Vector2i]:
	var fp := footprint(id)
	var steps := int(round(fposmod(yaw, TAU) / (PI * 0.5))) % 2
	var size := fp if steps == 0 else Vector2i(fp.y, fp.x)
	var out: Array[Vector2i] = []
	var half_x := size.x / 2
	var half_y := size.y / 2
	for dz in range(size.y):
		for dx in range(size.x):
			out.append(cell + Vector2i(dx - half_x, dz - half_y))
	return out
