class_name UiTheme
extends RefCounted
## Paleta e estilos compartilhados pela UI (papel kraft, madeira quente, verde e amarelo ipê).

const COLOR_WOOD := Color("#8a5a35")
const COLOR_WOOD_DARK := Color("#5a2d12")
const COLOR_WOOD_LIGHT := Color("#b0783f")
const COLOR_PAPER := Color("#f1e3bf")
const COLOR_PAPER_DARK := Color("#d8c495")
const COLOR_GREEN := Color("#5fa84a")
const COLOR_YELLOW := Color("#ffc928")
const COLOR_TERRACOTTA := Color("#c4623a")
const COLOR_TEXT_DARK := Color("#432a14")


static func panel_style(bg: Color, border: Color, border_width: int = 3, radius: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	return sb


static func slot_style(highlighted: bool) -> StyleBoxFlat:
	if highlighted:
		return panel_style(COLOR_YELLOW.darkened(0.15), COLOR_YELLOW, 4, 10)
	return panel_style(COLOR_WOOD_LIGHT, COLOR_WOOD_DARK, 2, 10)
