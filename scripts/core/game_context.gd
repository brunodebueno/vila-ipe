class_name GameContext
extends RefCounted
## Referências compartilhadas do jogo em execução. Features recebem isto em install().

static var current: GameContext

var main: Node3D
var terrain: Terrain
var props: PropManager
var player: Player
var rig: CameraRig
var tools: ToolController
var day_night: DayNight
