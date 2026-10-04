class_name SettingsStore
extends RefCounted
## Persistência e aplicação das configurações do jogador em user://settings.cfg.

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"audio": {"music": 0.8, "sfx": 0.9, "ambience": 0.8},
	"camera": {"sensitivity": 1.0},
	"video": {"fullscreen": false, "vsync": true, "shadows": true, "msaa": true},
	"gameplay": {"day_length": 300.0},
	"language": {"id": "pt-BR"},
}

const AUDIO_BUSES := {"music": "Music", "sfx": "SFX", "ambience": "Ambience"}


static func load_settings() -> Dictionary:
	var out: Dictionary = DEFAULTS.duplicate(true)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return out
	for section: String in out.keys():
		var values: Dictionary = out[section]
		for key: String in values.keys():
			values[key] = cfg.get_value(section, key, values[key])
	return out


static func save_settings(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for section: String in data.keys():
		var values: Dictionary = data[section]
		for key: String in values.keys():
			cfg.set_value(section, key, values[key])
	cfg.save(PATH)


## Volume dos buses de áudio, se existirem (ignora os que o projeto não tiver criado ainda).
static func apply_audio(data: Dictionary) -> void:
	var audio: Dictionary = data.get("audio", {})
	for key: String in AUDIO_BUSES:
		var bus_name: String = AUDIO_BUSES[key]
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			continue
		var linear: float = clampf(float(audio.get(key, 1.0)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0001)


static func apply_video(data: Dictionary) -> void:
	var video: Dictionary = data.get("video", {})
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if bool(video.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(video.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	)


## Sombras e MSAA, aplicados na viewport/luzes da cena atual (chamar após o mundo existir).
static func apply_graphics(data: Dictionary, tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var video: Dictionary = data.get("video", {})
	tree.root.msaa_3d = Viewport.MSAA_4X if bool(video.get("msaa", true)) else Viewport.MSAA_DISABLED
	var shadows_on: bool = bool(video.get("shadows", true))
	_toggle_shadows(tree.root, shadows_on)


static func _toggle_shadows(node: Node, on: bool) -> void:
	if node is DirectionalLight3D:
		(node as DirectionalLight3D).shadow_enabled = on
	for child in node.get_children():
		_toggle_shadows(child, on)
