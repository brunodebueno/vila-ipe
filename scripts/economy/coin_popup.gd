class_name CoinPopup
extends RefCounted
## Pequena animação de "moeda" para acompanhar vendas e compras.

static func show(layer: CanvasLayer, text: String, color: Color = Color("#ffe27a")) -> void:
	if layer == null:
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 8)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(-40, 120)
	layer.add_child(label)
	var tw := label.create_tween()
	label.scale = Vector2(0.4, 0.4)
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "position:y", label.position.y - 50.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tw.tween_callback(label.queue_free)
