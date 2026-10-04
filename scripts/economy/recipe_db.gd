class_name RecipeDB
extends RefCounted
## Banco de receitas (orientado a dados). Dados em res://data/recipes.json.

const PATH := "res://data/recipes.json"

static var _recipes: Dictionary = {}
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("recipes.json não encontrado")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("recipes"):
		for entry: Dictionary in (parsed as Dictionary)["recipes"]:
			var r := RecipeDef.from_dict(entry)
			_recipes[r.id] = r


static func get_recipe(id: StringName) -> RecipeDef:
	_ensure_loaded()
	return _recipes.get(id) as RecipeDef


static func all() -> Array[RecipeDef]:
	_ensure_loaded()
	var out: Array[RecipeDef] = []
	for v in _recipes.values():
		out.append(v as RecipeDef)
	return out


static func portable_recipes() -> Array[RecipeDef]:
	var out: Array[RecipeDef] = []
	for r in all():
		if r.portable:
			out.append(r)
	return out


static func for_station(station: StringName) -> Array[RecipeDef]:
	var out: Array[RecipeDef] = []
	for r in all():
		if r.station == station:
			out.append(r)
	return out
