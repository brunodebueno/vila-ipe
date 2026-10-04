class_name Placeable
extends Node3D
## Wrapper de um objeto colocado pelo modo construção. Guarda metadados (id, célula âncora,
## rotação, footprint) usados por BuildMode para persistência, remoção e interação (F).

var id: StringName
var cell: Vector2i
var yaw: float
var footprint: Array[Vector2i] = []
var interaction: StringName = &""

## Referências úteis preenchidas pelo BuildMode ao criar, para as interações F.
var seat_point: Vector3 = Vector3.ZERO
var seat_facing: float = 0.0
