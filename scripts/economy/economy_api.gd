class_name EconomyApi
extends RefCounted
## API pública do módulo de economia e crafting, para uso de outros sistemas.

## Vendas do dia por item, para o preço dinâmico leve da loja/caixa de entregas.
static var _sold_today: Dictionary = {}
static var _last_hour := -1.0


## Preço de venda atual do item (já considerando a queda por vendas do dia).
static func sell_value(id: StringName) -> int:
	var def := ItemDB.get_def(id)
	if def == null or def.price <= 0:
		return 0
	var sold := int(_sold_today.get(id, 0))
	var factor := maxf(0.7, 1.0 - 0.03 * float(sold))
	return maxi(1, int(round(def.price * factor)))


## Ferramentas e itens sem preço (chave) não podem ser vendidos.
static func can_sell(id: StringName) -> bool:
	var def := ItemDB.get_def(id)
	if def == null:
		return false
	if def.category == &"tool":
		return false
	return def.price > 0


static func register_sale(id: StringName, amount: int) -> void:
	_sold_today[id] = int(_sold_today.get(id, 0)) + amount


## Chamado pelo módulo a cada troca de hora para resetar o desconto quando o dia virar.
static func on_hour_changed(hour: float) -> void:
	if _last_hour >= 0.0 and hour < _last_hour:
		_sold_today.clear()
	_last_hour = hour


static func can_craft(recipe_id: StringName, times: int = 1) -> bool:
	var r := RecipeDB.get_recipe(recipe_id)
	if r == null or times <= 0 or not r.is_unlocked():
		return false
	for ing_id: StringName in r.ingredients:
		if not GameState.inventory.has(ing_id, int(r.ingredients[ing_id]) * times):
			return false
	return true


## Consome os ingredientes e entrega o resultado. Retorna false se não puder fabricar.
static func craft(recipe_id: StringName, times: int = 1) -> bool:
	if not can_craft(recipe_id, times):
		return false
	var r := RecipeDB.get_recipe(recipe_id)
	for ing_id: StringName in r.ingredients:
		GameState.inventory.remove(ing_id, int(r.ingredients[ing_id]) * times)
	var total := r.result_amount * times
	GameState.give(r.result_id, total)
	EventBus.item_crafted.emit(r.result_id)
	GameState.add_stat(&"items_crafted", total)
	return true
