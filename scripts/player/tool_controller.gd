class_name ToolController
extends Node3D
## Usa o item selecionado na barra rápida. Cuida do cursor, do pincel e da terraformação.
## Outros sistemas registram ferramentas novas com register_tool().
##
## Handler: func(cell: Vector2i, hit: Dictionary, item_id: StringName) -> void
## `hit` é o resultado do raycast (position, normal, collider) — collider pode ser um
## objeto na camada 4 (interagíveis).

const BRUSH_SIZES: Array[int] = [1, 3, 5]
const REPEAT_SECONDS := 0.16
## Ferramentas que repetem enquanto o botão está pressionado.
const REPEATING: Array[StringName] = [&"terraform_raise", &"terraform_lower", &"terraform_flatten", &"terraform_path", &"terraform_grass"]

var terrain: Terrain
var props: PropManager
var camera: Camera3D
var hover_cell := Vector2i(-1, -1)
var hover_hit: Dictionary = {}
var has_hover := false
var brush_index := 1

var _handlers: Dictionary = {}
var _cursor: MeshInstance3D
var _repeat := 0.0
var _flatten_level := -1
var _dust: CPUParticles3D
## Quando false, o cursor fica escondido e nenhuma ferramenta age (ex.: modo construção).
var enabled := true


func setup(p_terrain: Terrain, p_props: PropManager, p_camera: Camera3D) -> void:
	terrain = p_terrain
	props = p_props
	camera = p_camera
	_register_terraform()
	_cursor = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	_cursor.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.95, 0.4, 0.45)
	mat.no_depth_test = true
	_cursor.material_override = mat
	_cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cursor)
	_cursor.top_level = true
	_dust = _make_dust()
	add_child(_dust)
	_dust.top_level = true
	_refresh_cursor()
	EventBus.brush_changed.emit(BRUSH_SIZES[brush_index])


func register_tool(tool_name: StringName, handler: Callable) -> void:
	_handlers[tool_name] = handler


func brush_size() -> int:
	return BRUSH_SIZES[brush_index]


func _process(delta: float) -> void:
	var active := enabled and not GameState.is_ui_blocking() and not _mouse_over_ui()
	_update_hover(active)
	var item := GameState.selected_item()
	var def := ItemDB.get_def(item) if item != &"" else null
	var tool_name: StringName = def.tool if def else &""
	_cursor.visible = active and has_hover and tool_name.begins_with("terraform")
	if active and has_hover and Input.is_action_pressed(&"use_tool") and REPEATING.has(tool_name):
		_repeat -= delta
		if _repeat <= 0.0:
			_repeat = REPEAT_SECONDS
			_dispatch(tool_name, item)
	else:
		_repeat = 0.0


func _unhandled_input(event: InputEvent) -> void:
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed(StringName("hotbar_%d" % (i + 1))):
			GameState.select_slot(i)
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP and Input.is_key_pressed(KEY_CTRL):
			GameState.select_slot((GameState.selected_slot - 1 + Inventory.HOTBAR_SIZE) % Inventory.HOTBAR_SIZE)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed(&"brush_up"):
		_set_brush(brush_index + 1)
	elif event.is_action_pressed(&"brush_down"):
		_set_brush(brush_index - 1)
	if not event.is_action_pressed(&"use_tool") or not enabled or GameState.is_ui_blocking() or _mouse_over_ui() or not has_hover:
		return
	var item := GameState.selected_item()
	var def := ItemDB.get_def(item) if item != &"" else null
	if def == null or def.tool == &"":
		return
	if def.tool == &"terraform_flatten":
		_flatten_level = terrain.data.get_height(hover_cell)
	if not REPEATING.has(def.tool):
		_dispatch(def.tool, item)


func _dispatch(tool_name: StringName, item: StringName) -> void:
	if _handlers.has(tool_name):
		(_handlers[tool_name] as Callable).call(hover_cell, hover_hit, item)


func _mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _register_terraform() -> void:
	register_tool(&"terraform_raise", func(c: Vector2i, _h: Dictionary, _i: StringName) -> void: _terraform(c, 1))
	register_tool(&"terraform_lower", func(c: Vector2i, _h: Dictionary, _i: StringName) -> void: _terraform(c, -1))
	register_tool(&"terraform_flatten", func(c: Vector2i, _h: Dictionary, _i: StringName) -> void: _terraform(c, 0))
	register_tool(&"terraform_path", func(c: Vector2i, _h: Dictionary, _i: StringName) -> void: _paint(c, TerrainData.Tile.PATH))
	register_tool(&"terraform_grass", func(c: Vector2i, _h: Dictionary, _i: StringName) -> void: _paint(c, TerrainData.Tile.GRASS))
	register_tool(&"plant", func(c: Vector2i, _h: Dictionary, item: StringName) -> void: _plant(c, item, &"tree_ipe_yellow" if randf() > 0.4 else &"tree_ipe_purple"))
	register_tool(&"plant_palm", func(c: Vector2i, _h: Dictionary, item: StringName) -> void: _plant(c, item, &"tree_palm"))


func _set_brush(index: int) -> void:
	brush_index = clampi(index, 0, BRUSH_SIZES.size() - 1)
	_refresh_cursor()
	EventBus.brush_changed.emit(BRUSH_SIZES[brush_index])


func _refresh_cursor() -> void:
	var s := float(BRUSH_SIZES[brush_index])
	(_cursor.mesh as QuadMesh).size = Vector2(s, s)


func _update_hover(active: bool) -> void:
	if not active:
		has_hover = false
		return
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var to := from + camera.project_ray_normal(mouse) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	has_hover = not hit.is_empty()
	hover_hit = hit
	if not has_hover:
		return
	var position: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	hover_cell = WorldConst.world_to_cell(position - normal * 0.05)
	var top := WorldConst.level_to_y(terrain.data.get_height(hover_cell)) + 0.04
	_cursor.global_position = Vector3(hover_cell.x + 0.5, top, hover_cell.y + 0.5)


func brush_cells(center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r := BRUSH_SIZES[brush_index] / 2
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			out.append(center + Vector2i(dx, dz))
	return out


## mode: +1 sobe, -1 desce, 0 nivela até _flatten_level.
func _terraform(center: Vector2i, mode: int) -> void:
	var data := terrain.data
	for cell in brush_cells(center):
		if not data.in_bounds(cell) or props.is_building_cell(cell):
			continue
		if mode == 0:
			if _flatten_level >= 0:
				_set_level(cell, _flatten_level)
		else:
			_set_level(cell, data.get_height(cell) + mode)
		EventBus.terrain_edited.emit(cell)
	_puff(center)


func _paint(center: Vector2i, tile: int) -> void:
	var data := terrain.data
	for cell in brush_cells(center):
		if data.in_bounds(cell) and not props.is_building_cell(cell) and not WorldConst.is_underwater(data.get_height(cell)):
			data.set_tile(cell, tile)
			EventBus.terrain_edited.emit(cell)
	_puff(center)


func _plant(cell: Vector2i, item: StringName, tree_id: StringName) -> void:
	if not GameState.inventory.has(item):
		EventBus.notify.emit("Sem mudas! Colete flores e frutos.", item)
		return
	if props.plant_tree(cell, tree_id, randf_range(0.9, 1.15)):
		GameState.inventory.remove(item, 1)
		GameState.add_stat(&"trees_planted")
		EventBus.terrain_edited.emit(cell)
		_puff(cell)


func _set_level(cell: Vector2i, level: int) -> void:
	var data := terrain.data
	data.set_height(cell, level)
	var h := data.get_height(cell)
	var tile := data.get_tile(cell)
	if h <= WorldConst.WATER_LEVEL + 1:
		data.set_tile(cell, TerrainData.Tile.SAND)
	elif tile == TerrainData.Tile.SAND and h >= WorldConst.WATER_LEVEL + 3:
		data.set_tile(cell, TerrainData.Tile.GRASS)


func _puff(cell: Vector2i) -> void:
	_dust.global_position = Vector3(cell.x + 0.5, WorldConst.level_to_y(terrain.data.get_height(cell)) + 0.2, cell.y + 0.5)
	_dust.color = WorldConst.tile_color(terrain.data.get_tile(cell)).lightened(0.2)
	_dust.restart()
	_dust.emitting = true


func _make_dust() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 14
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.2
	p.gravity = Vector3(0, -6, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 6
	mesh.rings = 3
	p.mesh = mesh
	return p
