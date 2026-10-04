class_name WorldGenerator
extends RefCounted
## Gera a Ilha do Ipê: ilha de ruído, platô da vila no centro e um rio a leste.

const VILLAGE_LEVEL := 5
const VILLAGE_RADIUS := 9.0
const VILLAGE_BLEND := 6.0
const HOUSE_IDS: Array[StringName] = [&"house_colonial_blue", &"house_colonial_pink", &"house_colonial_yellow", &"house_colonial_green"]
const HOUSE_OFFSETS: Array[Vector2i] = [Vector2i(-6, -5), Vector2i(6, -5), Vector2i(-6, 5), Vector2i(6, 5)]


static func generate(data: TerrainData, world_seed: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	var patches := FastNoiseLite.new()
	patches.seed = world_seed + 7
	patches.frequency = 0.09
	var center := Vector2(data.size) / 2.0
	var half := data.size.x / 2.0
	for z in data.size.y:
		for x in data.size.x:
			var cell := Vector2i(x, z)
			var p := Vector2(x + 0.5, z + 0.5)
			var dist := p.distance_to(center)
			var falloff := clampf(1.0 - pow(dist / (half * 0.95), 2.4), 0.0, 1.0)
			var level := roundi((falloff * 0.78 + noise.get_noise_2d(x, z) * 0.22) * 10.0)
			if dist < VILLAGE_RADIUS + VILLAGE_BLEND:
				var t := smoothstep(VILLAGE_RADIUS, VILLAGE_RADIUS + VILLAGE_BLEND, dist)
				level = roundi(lerpf(float(VILLAGE_LEVEL), float(level), t))
			var river_x := center.x + 19.0 + 4.0 * sin(z * 0.14)
			var bank := smoothstep(3.6, 1.4, absf(p.x - river_x))
			level = roundi(lerpf(float(level), 1.0, bank))
			data.set_height(cell, level)
			data.set_tile(cell, _pick_tile(data.get_height(cell), p, center, patches))


static func _pick_tile(level: int, p: Vector2, center: Vector2, patches: FastNoiseLite) -> int:
	var offset := p - center
	if offset.length() < VILLAGE_RADIUS - 0.5:
		if absf(offset.x) < 1.5 or absf(offset.y) < 1.5 or offset.length() < 3.2:
			return TerrainData.Tile.PATH
	if level <= WorldConst.WATER_LEVEL + 1:
		return TerrainData.Tile.SAND
	if patches.get_noise_2d(p.x, p.y) > 0.45:
		return TerrainData.Tile.DIRT
	return TerrainData.Tile.GRASS


## Vila inicial (casas coloniais + ipê da praça) e mata espalhada.
static func populate(data: TerrainData, props: PropManager, world_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	var center := data.size / 2
	for i in HOUSE_OFFSETS.size():
		var cell := center + HOUSE_OFFSETS[i]
		var to_center := Vector2(center - cell)
		var yaw := roundf(atan2(to_center.x, to_center.y) / (PI / 2.0)) * (PI / 2.0)
		props.place_building(cell, HOUSE_IDS[i], yaw, 1)
	props.plant_tree(center + Vector2i(0, 0), &"tree_ipe_yellow", 1.9, false)
	var planted := 0
	var attempts := 0
	while planted < 260 and attempts < 4000:
		attempts += 1
		var cell := Vector2i(rng.randi_range(0, data.size.x - 1), rng.randi_range(0, data.size.y - 1))
		if Vector2(cell - center).length() < VILLAGE_RADIUS + 2.0 or not props.can_plant(cell):
			continue
		var level := data.get_height(cell)
		var roll := rng.randf()
		var id: StringName = &"tree_generic"
		if level >= 7 and roll < 0.35:
			id = &"tree_ipe_purple" if roll < 0.15 else &"tree_ipe_yellow"
		elif level <= WorldConst.WATER_LEVEL + 2 and roll < 0.6:
			id = &"tree_palm"
		elif roll > 0.92:
			id = &"tree_ipe_yellow"
		if props.plant_tree(cell, id, rng.randf_range(0.85, 1.2), false):
			planted += 1
	var fruit_ids: Array[StringName] = [&"tree_fruit_jabuticaba", &"tree_fruit_caju", &"tree_fruit_pitanga"]
	var fruit_planted := 0
	var fruit_attempts := 0
	while fruit_planted < 24 and fruit_attempts < 2000:
		fruit_attempts += 1
		var cell := Vector2i(rng.randi_range(0, data.size.x - 1), rng.randi_range(0, data.size.y - 1))
		if Vector2(cell - center).length() < VILLAGE_RADIUS + 4.0 or not props.can_plant(cell):
			continue
		var id: StringName = fruit_ids[rng.randi_range(0, fruit_ids.size() - 1)]
		if props.plant_tree(cell, id, rng.randf_range(0.9, 1.1), false):
			fruit_planted += 1
	var rock_ids: Array[StringName] = [&"rock_small", &"rock_big"]
	var rocks_placed := 0
	var rock_attempts := 0
	while rocks_placed < 40 and rock_attempts < 3000:
		rock_attempts += 1
		var cell := Vector2i(rng.randi_range(0, data.size.x - 1), rng.randi_range(0, data.size.y - 1))
		if Vector2(cell - center).length() < VILLAGE_RADIUS + 2.0:
			continue
		var level := data.get_height(cell)
		var near_hill := level >= 7
		var near_beach := level <= WorldConst.WATER_LEVEL + 2
		if not near_hill and not near_beach:
			continue
		var id: StringName = rock_ids[0] if rng.randf() < 0.65 else rock_ids[1]
		if props.place_rock(cell, id, rng.randf_range(0.85, 1.25)):
			rocks_placed += 1
