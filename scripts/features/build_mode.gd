class_name BuildMode
extends Feature
## Modo de construção: barra lateral de itens colocáveis, ghost de posicionamento (verde/vermelho),
## rotação (Z/X), colocação (clique esquerdo) e remoção (clique direito/Delete).
##
## Ativa com a tecla 'build_mode' (B) ou ao selecionar o item com tool == &"build" (martelo).
## Enquanto ativo: ctx.tools.enabled = false. Objetos colocados ficam registrados em
## BuildRegistry (consultado por PropManager.is_blocked/can_plant) e em group 'saveable_build'
## para persistência (serialize()/deserialize(), chamados pelo módulo de Sistema).

const GHOST_VALID := Color(0.3, 1.0, 0.4, 0.55)
const GHOST_INVALID := Color(1.0, 0.25, 0.25, 0.55)

var _ctx: GameContext
var _active := false
var _selected_id: StringName = &""
var _yaw := 0.0
var _ghost: Node3D
var _ghost_mesh_mats: Array[StandardMaterial3D] = []
var _hover_cell := Vector2i(-1, -1)
var _hover_valid := false

var _panel: Control
var _list: VBoxContainer
var _placed: Dictionary = {} ## cell(Vector2i, só a âncora) -> Placeable

var _seated: Placeable = null


func install(ctx: GameContext) -> void:
	_ctx = ctx
	add_to_group(&"saveable_build")
	_build_ui()
	set_process(true)
	set_process_unhandled_input(true)
	EventBus.hour_changed.connect(_on_hour_changed)
	if OS.get_cmdline_user_args().has("--demo-build"):
		call_deferred(&"_run_demo_build")


## Uso: godot --path . -- --demo-build (combine com --shot para a foto de QA).
## Coloca um conjunto de placeáveis perto do spawn do jogador, sem gastar inventário.
func _run_demo_build() -> void:
	await get_tree().process_frame
	var center := WorldConst.world_to_cell(_ctx.player.global_position)
	var layout := [
		[&"build_house", Vector2i(4, 4), 0.0],
		[&"build_bench", Vector2i(1, 4), 0.0],
		[&"build_hammock", Vector2i(-2, 3), PI * 0.5],
		[&"build_campfire", Vector2i(0, 2), 0.0],
		[&"build_lamp", Vector2i(-2, 1), 0.0],
		[&"build_lamp", Vector2i(2, 1), 0.0],
		[&"build_flags", Vector2i(-3, -1), PI * 0.5],
		[&"build_planter", Vector2i(3, 2), 0.0],
		[&"build_bromelia", Vector2i(4, 1), 0.0],
		[&"build_tall_grass", Vector2i(5, 0), 0.0],
		[&"build_pond_stone", Vector2i(-4, -2), 0.0],
	]
	for i in range(-3, 4):
		layout.append([&"build_fence", Vector2i(i, -3), 0.0])
	for entry: Array in layout:
		var id: StringName = entry[0]
		var offset: Vector2i = entry[1]
		var yaw: float = entry[2]
		var cell := center + offset
		if not _is_placement_valid(cell, id, yaw):
			continue
		_place_loaded(id, cell, yaw)
	print("Demo de construção pronta: %d objetos." % layout.size())


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.offset_left = 18
	_panel.offset_top = -220
	_panel.custom_minimum_size = Vector2(230, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.07, 0.85)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(210, 420)
	_panel.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)
	var title := Label.new()
	title.text = "Construção (B)"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	vbox.add_child(title)
	var hint := Label.new()
	hint.text = "Z/X gira · clique coloca\nclique direito/Del remove"
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	vbox.add_child(_list)
	GameState.inventory.changed.connect(_refresh_list)


func _refresh_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	for id: StringName in BuildCatalog.placeable_ids():
		var owned := GameState.inventory.count(id)
		var btn := Button.new()
		btn.text = "%s  x%d" % [ItemDB.display_name(id), owned]
		btn.disabled = owned <= 0
		btn.toggle_mode = true
		btn.button_pressed = id == _selected_id
		btn.pressed.connect(_on_item_selected.bind(id))
		_list.add_child(btn)


func _on_item_selected(id: StringName) -> void:
	_selected_id = id
	_yaw = 0.0
	_refresh_list()
	_spawn_ghost()


func _enter_build_mode() -> void:
	if _active:
		return
	_active = true
	_panel.visible = true
	_ctx.tools.enabled = false
	GameState.ui_blocking += 1
	_refresh_list()


func _exit_build_mode() -> void:
	if not _active:
		return
	_active = false
	_panel.visible = false
	_ctx.tools.enabled = true
	GameState.ui_blocking = maxi(0, GameState.ui_blocking - 1)
	_clear_ghost()
	_selected_id = &""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		_try_interact()
		return
	var item := GameState.selected_item()
	var def := ItemDB.get_def(item) if item != &"" else null
	var wants_build := def != null and def.tool == &"build"
	if event.is_action_pressed(&"build_mode") or (wants_build and not _active):
		if _active:
			_exit_build_mode()
		else:
			_enter_build_mode()
		get_viewport().set_input_as_handled()
		return
	if not _active:
		return
	if event.is_action_pressed(&"rotate_left"):
		_yaw = fposmod(_yaw - PI * 0.5, TAU)
		_update_ghost_transform()
	elif event.is_action_pressed(&"rotate_right"):
		_yaw = fposmod(_yaw + PI * 0.5, TAU)
		_update_ghost_transform()
	elif event.is_action_pressed(&"use_tool"):
		if not _mouse_over_ui():
			_try_place()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		_try_remove_at_hover()
	elif event.is_action_pressed(&"ui_text_delete") or (event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_DELETE and (event as InputEventKey).pressed):
		_try_remove_at_hover()


func _mouse_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _process(delta: float) -> void:
	if not _active or _selected_id == &"":
		if _ghost:
			_ghost.visible = false
	else:
		_update_hover()
		_update_ghost_transform()
	if not _active:
		_update_interact_prompt()
	if _seated and _seated.interaction == &"lie":
		_tick_hammock(delta)


func _update_hover() -> void:
	var camera := _ctx.rig.camera
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var to := from + camera.project_ray_normal(mouse) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_viewport().get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_hover_valid = false
		return
	var position: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	_hover_cell = WorldConst.world_to_cell(position - normal * 0.05)
	_hover_valid = _is_placement_valid(_hover_cell, _selected_id, _yaw)


func _is_placement_valid(cell: Vector2i, id: StringName, yaw: float) -> bool:
	var data := _ctx.terrain.data
	var cells := BuildCatalog.footprint_cells(id, cell, yaw)
	if cells.is_empty():
		return false
	var base_height := data.get_height(cells[0])
	for c in cells:
		if not data.in_bounds(c):
			return false
		if BuildRegistry.is_occupied(c) or _ctx.props.is_blocked(c):
			return false
		if WorldConst.is_underwater(data.get_height(c)):
			return false
		if data.get_height(c) != base_height:
			return false
	return true


func _spawn_ghost() -> void:
	_clear_ghost()
	if _selected_id == &"":
		return
	_ghost = BuildingModels.create(_selected_id)
	_ghost_mesh_mats.clear()
	_apply_ghost_material(_ghost)
	add_child(_ghost)
	_ghost.top_level = true


func _apply_ghost_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = GHOST_VALID
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost_mesh_mats.append(mat)
	for child in node.get_children():
		_apply_ghost_material(child)


func _clear_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	_ghost_mesh_mats.clear()


func _update_ghost_transform() -> void:
	if _ghost == null:
		return
	_ghost.visible = _active
	if not _active:
		return
	var data := _ctx.terrain.data
	var y := WorldConst.level_to_y(data.get_height(_hover_cell))
	_ghost.global_position = Vector3(_hover_cell.x + 0.5, y, _hover_cell.y + 0.5)
	_ghost.rotation.y = _yaw
	var color := GHOST_VALID if _hover_valid else GHOST_INVALID
	for mat in _ghost_mesh_mats:
		mat.albedo_color = color


func _try_place() -> void:
	if _selected_id == &"" or not _hover_valid:
		return
	if not GameState.inventory.has(_selected_id, 1):
		EventBus.notify.emit("Você não tem mais esse item.", _selected_id)
		return
	var cells := BuildCatalog.footprint_cells(_selected_id, _hover_cell, _yaw)
	var data := _ctx.terrain.data
	var base_height := data.get_height(cells[0])
	for c in cells:
		data.set_height(c, base_height)
	GameState.inventory.remove(_selected_id, 1)
	var node := BuildingModels.create(_selected_id)
	var y := WorldConst.level_to_y(base_height)
	node.position = Vector3(_hover_cell.x + 0.5, y, _hover_cell.y + 0.5)
	node.rotation.y = _yaw
	node.scale = Vector3.ONE * 0.08
	add_child(node)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_puff(Vector3(_hover_cell.x + 0.5, y + 0.1, _hover_cell.y + 0.5))
	var placeable := Placeable.new()
	placeable.id = _selected_id
	placeable.cell = _hover_cell
	placeable.yaw = _yaw
	placeable.footprint = cells
	placeable.interaction = BuildCatalog.interaction_kind(_selected_id)
	var seat_offset: Vector3 = node.get_meta("seat_offset", Vector3(0, 0.5, 0)) if node.has_meta("seat_offset") else Vector3(0, 0.5, 0)
	placeable.seat_point = node.position + seat_offset.rotated(Vector3.UP, _yaw)
	placeable.seat_facing = _yaw
	node.add_child(placeable)
	placeable.name = "Placeable"
	for c in cells:
		_ctx.props.register_blocker(c)
		_placed[c] = placeable
	_placed[_hover_cell] = placeable
	EventBus.structure_built.emit(_selected_id, _hover_cell)
	GameState.add_stat(&"structures_built")
	if _selected_id == &"build_house":
		GameState.add_stat(&"houses_built")
	if String(_selected_id) == "build_fence":
		_refresh_fence_connections()
	_refresh_list()
	if not GameState.inventory.has(_selected_id, 1):
		_clear_ghost()
		_selected_id = &""


func _refresh_fence_connections() -> void:
	var dirs := {&"north": Vector2i(0, -1), &"south": Vector2i(0, 1), &"east": Vector2i(1, 0), &"west": Vector2i(-1, 0)}
	for cell: Vector2i in _placed.keys():
		var placeable: Placeable = _placed[cell]
		if placeable.id != &"build_fence" or placeable.cell != cell:
			continue
		var fence := placeable.get_parent() as Node3D
		var visual := _find_fence_visual(fence)
		if visual == null:
			continue
		var connections := {}
		for dir: StringName in dirs:
			var neighbor_cell: Vector2i = cell + dirs[dir]
			var neighbor: Placeable = _placed.get(neighbor_cell)
			connections[dir] = neighbor != null and neighbor.id == &"build_fence"
		visual.set_connections(connections)


func _find_fence_visual(node: Node) -> FenceVisual:
	if node is FenceVisual:
		return node
	for child in node.get_children():
		if child is FenceVisual:
			return child
	return null


func _try_remove_at_hover() -> void:
	if not _active:
		return
	var placeable: Placeable = _placed.get(_hover_cell)
	if placeable == null:
		return
	_remove_placeable(placeable)


func _remove_placeable(placeable: Placeable) -> void:
	for c in placeable.footprint:
		_placed.erase(c)
		_ctx.props.unregister_blocker(c)
	GameState.give(placeable.id, 1)
	var node := placeable.get_parent() as Node3D
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3.ONE * 0.01, 0.2)
	tw.tween_callback(node.queue_free)
	if String(placeable.id) == "build_fence":
		_refresh_fence_connections()
	_refresh_list()


func _puff(world_pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
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
	p.mesh = mesh
	p.color = Color("#d3cbb8")
	p.global_position = world_pos
	add_child(p)
	p.emitting = true
	var t := get_tree().create_timer(0.6)
	t.timeout.connect(p.queue_free)


## --------- Interação (F) ----------

func _nearest_interactable(max_dist: float = 2.2) -> Placeable:
	var best: Placeable = null
	var best_dist := max_dist
	for c: Vector2i in _placed.keys():
		var placeable: Placeable = _placed[c]
		if placeable.interaction == &"":
			continue
		var d := placeable.seat_point.distance_to(_ctx.player.global_position)
		if d < best_dist:
			best_dist = d
			best = placeable
	return best


func _update_interact_prompt() -> void:
	if GameState.is_ui_blocking():
		return
	var prompt := get_tree().get_first_node_in_group(&"ui_prompt")
	if prompt == null:
		return
	if _seated:
		if prompt.has_method("show_prompt"):
			prompt.show_prompt("Levantar", "F")
		return
	var target := _nearest_interactable()
	if target == null:
		if prompt.has_method("hide_prompt"):
			prompt.hide_prompt()
		return
	var label := "Sentar"
	if target.interaction == &"lie":
		label = "Deitar na rede"
	elif target.interaction == &"warm":
		label = "Aquecer-se"
	if prompt.has_method("show_prompt"):
		prompt.show_prompt(label, "F")


func _try_interact() -> void:
	if GameState.is_ui_blocking():
		return
	if _seated:
		_stand_up()
		return
	var best := _nearest_interactable()
	if best == null:
		return
	match best.interaction:
		&"sit", &"lie":
			_sit_on(best)
		&"warm":
			var fx_node := best.get_parent()
			if fx_node and fx_node.has_meta("fx"):
				(fx_node.get_meta("fx") as CampfireFx).warm()


func _sit_on(placeable: Placeable) -> void:
	_seated = placeable
	_ctx.player.global_position = placeable.seat_point
	_ctx.player.velocity = Vector3.ZERO
	_ctx.player.set_physics_process(false)
	if placeable.interaction == &"lie":
		EventBus.notify.emit("Deitado na rede. Pressione F para levantar.", placeable.id)
	else:
		EventBus.notify.emit("Sentado. Pressione F para levantar.", placeable.id)


func _stand_up() -> void:
	if _seated == null:
		return
	_ctx.player.set_physics_process(true)
	_seated = null
	var prompt := get_tree().get_first_node_in_group(&"ui_prompt")
	if prompt and prompt.has_method("hide_prompt"):
		prompt.hide_prompt()


func _tick_hammock(delta: float) -> void:
	if _ctx.day_night == null:
		return
	_ctx.day_night.hour = fposmod(_ctx.day_night.hour + delta * 24.0 / _ctx.day_night.day_length_seconds * 7.0, 24.0)


func _on_hour_changed(_hour: float) -> void:
	pass


## --------- Persistência (chamado pelo módulo de Sistema) ----------

func serialize() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for cell: Vector2i in _placed.keys():
		var placeable: Placeable = _placed[cell]
		if seen.has(placeable):
			continue
		seen[placeable] = true
		out.append({
			"id": String(placeable.id),
			"cell_x": placeable.cell.x,
			"cell_y": placeable.cell.y,
			"yaw": placeable.yaw,
		})
	return out


func deserialize(data: Array) -> void:
	for cell: Vector2i in _placed.keys():
		_ctx.props.unregister_blocker(cell)
	_placed.clear()
	for child in get_children():
		if child is Node3D and child != _ghost:
			child.queue_free()
	for entry: Dictionary in data:
		var id := StringName(entry.get("id", ""))
		if id == &"":
			continue
		var cell := Vector2i(int(entry.get("cell_x", 0)), int(entry.get("cell_y", 0)))
		var yaw := float(entry.get("yaw", 0.0))
		_place_loaded(id, cell, yaw)


func _place_loaded(id: StringName, cell: Vector2i, yaw: float) -> void:
	var cells := BuildCatalog.footprint_cells(id, cell, yaw)
	var data := _ctx.terrain.data
	var y := WorldConst.level_to_y(data.get_height(cell))
	var node := BuildingModels.create(id)
	node.position = Vector3(cell.x + 0.5, y, cell.y + 0.5)
	node.rotation.y = yaw
	add_child(node)
	var placeable := Placeable.new()
	placeable.id = id
	placeable.cell = cell
	placeable.yaw = yaw
	placeable.footprint = cells
	placeable.interaction = BuildCatalog.interaction_kind(id)
	var seat_offset: Vector3 = node.get_meta("seat_offset", Vector3(0, 0.5, 0)) if node.has_meta("seat_offset") else Vector3(0, 0.5, 0)
	placeable.seat_point = node.position + seat_offset.rotated(Vector3.UP, yaw)
	placeable.seat_facing = yaw
	node.add_child(placeable)
	placeable.name = "Placeable"
	for c in cells:
		_ctx.props.register_blocker(c)
		_placed[c] = placeable
	if String(id) == "build_fence":
		_refresh_fence_connections()
