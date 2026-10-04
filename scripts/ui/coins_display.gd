class_name CoinsDisplay
extends HBoxContainer
## Mostra GameState.coins com um ícone de moeda desenhado por código; anima ao mudar.

var _coin_icon: PanelContainer
var _label: Label
var _tween: Tween


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_coin_icon = PanelContainer.new()
	_coin_icon.custom_minimum_size = Vector2(26, 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTheme.COLOR_YELLOW
	sb.border_color = Color("#a8790a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(13)
	_coin_icon.add_theme_stylebox_override("panel", sb)
	_coin_icon.pivot_offset = Vector2(13, 13)
	add_child(_coin_icon)
	var cifrao := Label.new()
	cifrao.text = "$"
	cifrao.add_theme_font_size_override("font_size", 15)
	cifrao.add_theme_color_override("font_color", Color("#6b4a08"))
	cifrao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cifrao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cifrao.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coin_icon.add_child(cifrao)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 6)
	_label.text = str(GameState.coins)
	add_child(_label)
	GameState.coins_changed.connect(_on_coins_changed)


func _on_coins_changed(coins: int) -> void:
	_label.text = str(coins)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_coin_icon, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_coin_icon, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
