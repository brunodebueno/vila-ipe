extends Node3D
## Cena inicial: ilha renderizada ao vivo como fundo, título e navegação. Não possui Player.

const WORLD_SEED := 20260410
const SAVE_PATH := "user://saves/slot1.json"

var _fade: ColorRect
var _orbit: Node3D
var _camera: Camera3D
var _options: OptionsPanel
var _credits: PanelContainer


func _ready() -> void:
	_build_world()
	_build_ui()
	if OS.get_cmdline_user_args().has("--menu-shot"):
		_auto_shot()


func _build_world() -> void:
	var data := TerrainData.new()
	WorldGenerator.generate(data, WORLD_SEED)
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(data)
	var props := PropManager.new()
	props.name = "Props"
	add_child(props)
	props.setup(data, WORLD_SEED)
	WorldGenerator.populate(data, props, WORLD_SEED)
	var day_night := DayNight.new()
	day_night.name = "DayNight"
	day_night.hour = 17.3
	day_night.fast_forward = 0.0
	add_child(day_night)
	day_night.set_process(false)
	var center := Vector3(WorldConst.MAP_SIZE.x * 0.5, WorldConst.level_to_y(5), WorldConst.MAP_SIZE.y * 0.5)
	_orbit = Node3D.new()
	_orbit.name = "CameraOrbit"
	_orbit.position = center
	add_child(_orbit)
	var arm := Node3D.new()
	arm.position = Vector3(26.0, 10.0, 0.0)
	_orbit.add_child(arm)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 48.0
	_camera.far = 400.0
	arm.add_child(_camera)
	_camera.look_at(center, Vector3.UP)
	_orbit.rotation.y = deg_to_rad(20.0)


func _process(delta: float) -> void:
	if _orbit:
		_orbit.rotation.y += delta * 0.035
		var arm := _orbit.get_child(0) as Node3D
		if arm and _camera:
			_camera.look_at_from_position(arm.global_position, _orbit.position, Vector3.UP)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var vignette := ColorRect.new()
	vignette.color = Color(0.03, 0.02, 0.01, 0.35)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	_build_bunting(root)
	_build_title(root)
	_build_buttons(root)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.8)


func _build_bunting(root: Control) -> void:
	var colors: Array[Color] = [Color("#009c3b"), Color("#ffdf00"), Color("#002776"), Color("#ffffff"), Color("#009c3b"), Color("#ffdf00")]
	var count := 16
	var spacing := 1.0 / float(count)
	var bunting := Control.new()
	bunting.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bunting.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bunting.custom_minimum_size = Vector2(0, 90)
	root.add_child(bunting)
	for i in count:
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.set_anchors_preset(Control.PRESET_TOP_WIDE)
		holder.anchor_left = (i + 0.5) * spacing
		holder.anchor_right = (i + 0.5) * spacing
		holder.offset_top = 18
		bunting.add_child(holder)
		var flag := Polygon2D.new()
		flag.color = colors[i % colors.size()]
		flag.polygon = PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(0, 34)])
		holder.add_child(flag)
		var tw := create_tween().set_loops()
		var sway := deg_to_rad(10.0) * (1.0 if i % 2 == 0 else -1.0)
		tw.tween_property(holder, "rotation", sway, 1.2 + (i % 3) * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(holder, "rotation", -sway, 1.2 + (i % 3) * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var wire := ColorRect.new()
	wire.color = Color("#5a4126")
	wire.custom_minimum_size = Vector2(0, 2)
	wire.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wire.offset_top = 18
	wire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bunting.add_child(wire)


func _build_title(root: Control) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_top = 150
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(box)
	var title := Label.new()
	title.text = "Vila Ipê"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	title.add_theme_color_override("font_outline_color", Color("#3d1f0c"))
	title.add_theme_constant_override("outline_size", 14)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Refunde a vila. Plante o Brasil."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("#f4ead0"))
	subtitle.add_theme_color_override("font_outline_color", Color("#2a1608"))
	subtitle.add_theme_constant_override("outline_size", 8)
	box.add_child(subtitle)


func _build_buttons(root: Control) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_bottom = -90
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 12)
	root.add_child(box)
	if FileAccess.file_exists(SAVE_PATH):
		box.add_child(_button("Continuar", _on_continue))
	box.add_child(_button("Novo Jogo", _on_new_game))
	box.add_child(_button("Opções", _on_options))
	box.add_child(_button("Créditos", _on_credits))
	box.add_child(_button("Sair", _on_quit))


func _button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 48)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	return btn


func _on_new_game() -> void:
	Engine.set_meta(&"vila_start", "new")
	_goto_game()


func _on_continue() -> void:
	Engine.set_meta(&"vila_start", "continue")
	_goto_game()


func _goto_game() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))


func _on_options() -> void:
	if _options:
		return
	_options = OptionsPanel.new()
	_options.set_anchors_preset(Control.PRESET_CENTER)
	_options.closed.connect(func() -> void: _options.queue_free(); _options = null)
	get_tree().root.get_child(get_tree().root.get_child_count() - 1).add_child(_options)


func _on_credits() -> void:
	if _credits:
		return
	_credits = PanelContainer.new()
	_credits.set_anchors_preset(Control.PRESET_CENTER)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	style.border_color = Color("#ffc928")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_credits.add_theme_stylebox_override("panel", style)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	_credits.add_child(list)
	var title := Label.new()
	title.text = "Vila Ipê — feito com Godot 4.7 e Mixar"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#ffe27a"))
	list.add_child(title)
	var body := Label.new()
	body.text = "Obrigado por visitar a vila! Projeto de fã, feito com carinho pela cultura brasileira.\nTodo o conteúdo (modelos, texturas, música) é original ou procedural, criado para este jogo.\nSem afiliação com marcas ou entidades reais."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(420, 0)
	list.add_child(body)
	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(func() -> void: _credits.queue_free(); _credits = null)
	list.add_child(close_btn)
	get_tree().root.get_child(get_tree().root.get_child_count() - 1).add_child(_credits)


func _on_quit() -> void:
	get_tree().quit()


## Uso: godot --path . -- --menu-shot  (salva uma foto do menu após 2 s e fecha; QA)
func _auto_shot() -> void:
	await get_tree().create_timer(2.0).timeout
	var image := get_viewport().get_texture().get_image()
	var path := "user://vila_ipe_menu.png"
	image.save_png(path)
	print("Foto do menu salva em ", ProjectSettings.globalize_path(path))
	get_tree().quit()
