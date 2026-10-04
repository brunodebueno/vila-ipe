extends Node
## Autoload: banco de itens (orientado a dados). Outros sistemas usam ItemDB.get_def(id).

const ITEMS_PATH := "res://data/items.json"
const ITEMS_DIR := "res://data/items/"

var _items: Dictionary = {}


func _ready() -> void:
	_load_file(ITEMS_PATH)
	for file in DirAccess.get_files_at(ITEMS_DIR):
		if file.ends_with(".json"):
			_load_file(ITEMS_DIR + file)


func _load_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Arquivo de itens não encontrado: " + path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "JSON de itens inválido: " + path)
	for entry: Dictionary in (parsed as Dictionary)["items"]:
		var def := ItemDef.from_dict(entry)
		_items[def.id] = def


func exists(id: StringName) -> bool:
	return _items.has(id)


func get_def(id: StringName) -> ItemDef:
	return _items.get(id) as ItemDef


func display_name(id: StringName) -> String:
	var def := get_def(id)
	return def.display_name if def else String(id)


func all_ids() -> Array:
	return _items.keys()


func ids_in_category(category: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for def: ItemDef in _items.values():
		if def.category == category:
			out.append(def.id)
	return out
