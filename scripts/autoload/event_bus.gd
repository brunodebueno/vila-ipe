extends Node
## Sinais globais desacoplados entre sistemas. Novos sistemas podem acrescentar sinais aqui.

signal tool_changed(tool_index: int, tool_label: String)
signal brush_changed(brush_size: int)
signal hour_changed(hour: float)
signal hud_toggled(is_visible: bool)

## Gameplay
signal item_gained(id: StringName, amount: int)
signal object_harvested(kind: StringName, cell: Vector2i)
signal item_crafted(id: StringName)
signal structure_built(id: StringName, cell: Vector2i)
signal creature_arrived(id: StringName)
signal terrain_edited(cell: Vector2i)
signal notify(text: String, icon_item: StringName)
signal day_phase_changed(phase: StringName)

## Vila viva
signal village_star_changed(stars: int)
signal npc_talked(id: StringName)
signal gift_given(npc_id: StringName, item_id: StringName)
