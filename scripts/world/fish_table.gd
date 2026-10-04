class_name FishTable
extends RefCounted
## Carrega res://data/fish.json e sorteia peixes respeitando raridade, hora do dia e profundidade.

const PATH := "res://data/fish.json"

var _fish: Array[Dictionary] = []


func _init() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("fish"):
		for entry: Dictionary in (parsed as Dictionary)["fish"]:
			_fish.append(entry)


## depth: quantos níveis abaixo da linha d'água (0 = rasa, 2+ = funda).
func roll(hour: float, depth: int) -> StringName:
	var candidates: Array[Dictionary] = []
	var total_weight := 0.0
	for entry in _fish:
		if int(entry.get("min_depth", 0)) > depth:
			continue
		var hours: Array = entry.get("hours", [0, 24])
		if not _hour_in_window(hour, float(hours[0]), float(hours[1])):
			continue
		candidates.append(entry)
		total_weight += float(entry.get("weight", 1))
	if candidates.is_empty():
		return &"fish_tilapia"
	var roll_value := randf() * total_weight
	var acc := 0.0
	for entry in candidates:
		acc += float(entry.get("weight", 1))
		if roll_value <= acc:
			return StringName(entry.get("id", "fish_tilapia"))
	return StringName(candidates.back().get("id", "fish_tilapia"))


func _hour_in_window(hour: float, from_h: float, to_h: float) -> bool:
	if from_h <= to_h:
		return hour >= from_h and hour <= to_h
	return hour >= from_h or hour <= to_h
