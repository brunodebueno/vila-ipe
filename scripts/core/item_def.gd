class_name ItemDef
extends RefCounted
## Definição de item carregada de res://data/items.json.

var id: StringName
var display_name: String
var category: StringName
var tool: StringName
var stack_max: int
var price: int
var color: Color
var description: String


static func from_dict(d: Dictionary) -> ItemDef:
	var def := ItemDef.new()
	def.id = StringName(d.get("id", ""))
	def.display_name = d.get("name", "?")
	def.category = StringName(d.get("category", "resource"))
	def.tool = StringName(d.get("tool", ""))
	def.stack_max = int(d.get("stack", 99))
	def.price = int(d.get("price", 0))
	def.color = Color(d.get("color", "#ffffff"))
	def.description = d.get("desc", "")
	return def


func is_tool() -> bool:
	return category == &"tool"
