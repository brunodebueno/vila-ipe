class_name ShopDB
extends RefCounted
## Catálogo da loja (orientado a dados). Dados em res://data/shop.json.

const PATH := "res://data/shop.json"

static var _categories: Array = []
static var _loaded := false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("shop.json não encontrado")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("categories"):
		_categories = (parsed as Dictionary)["categories"]


## [{name: String, items: [{id, price}]}]
static func categories() -> Array:
	_ensure_loaded()
	return _categories


static func buy_price(id: StringName) -> int:
	_ensure_loaded()
	for cat: Dictionary in _categories:
		for entry: Dictionary in cat["items"]:
			if StringName(entry["id"]) == id:
				return int(entry["price"])
	return 0
