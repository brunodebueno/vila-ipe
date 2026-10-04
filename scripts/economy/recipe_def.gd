class_name RecipeDef
extends RefCounted
## Definição de receita de crafting carregada de res://data/recipes.json.

var id: StringName
var result_id: StringName
var result_amount: int
var ingredients: Dictionary = {}
var station: StringName
var portable: bool
var unlock_flag: StringName


static func from_dict(d: Dictionary) -> RecipeDef:
	var r := RecipeDef.new()
	r.id = StringName(d.get("id", ""))
	r.result_id = StringName(d.get("result", ""))
	r.result_amount = int(d.get("amount", 1))
	var ing: Dictionary = d.get("ingredients", {})
	for key in ing:
		r.ingredients[StringName(key)] = int(ing[key])
	r.station = StringName(d.get("station", "bench"))
	r.portable = bool(d.get("portable", false))
	r.unlock_flag = StringName(d.get("unlock_flag", ""))
	return r


func is_unlocked() -> bool:
	if unlock_flag == &"":
		return true
	return bool(GameState.get_flag(unlock_flag, false))


func display_name() -> String:
	return ItemDB.display_name(result_id)
