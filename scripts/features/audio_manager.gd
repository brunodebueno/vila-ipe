class_name AudioManager
extends Feature
## Áudio 100% procedural (sem arquivos externos): música por hora do dia, ambiências e SFX.
## Grupo "audio_manager". API: play_sfx(name, pos), set_volume(bus, v).
## Escuta EventBus para tocar efeitos automaticamente conforme o jogo acontece.

const MUSIC_FADE := 2.5
const WEATHER_FADE := 1.5

var _ctx: GameContext
var _sfx_players: Array[AudioStreamPlayer3D] = []
var _sfx_next := 0

var _music_day: AudioStreamPlayer
var _music_night: AudioStreamPlayer
var _music_mix := 0.0  ## 0 = dia, 1 = noite

var _amb_cicadas: AudioStreamPlayer
var _amb_night: AudioStreamPlayer
var _amb_waves: AudioStreamPlayer
var _amb_wind: AudioStreamPlayer
var _amb_rain: AudioStreamPlayer

var _sfx_cache: Dictionary = {}
var _volumes: Dictionary = {"Music": 0.55, "SFX": 0.9, "Ambience": 0.7}

var _weather_rain_amount := 0.0  ## 0..1, controlado externamente (weather.gd via grupo)


func install(ctx: GameContext) -> void:
	_ctx = ctx
	add_to_group(&"audio_manager")
	_setup_buses()
	_build_sfx_cache()
	_build_sfx_pool()
	_build_music()
	_build_ambience()
	EventBus.item_gained.connect(func(_id: StringName, _n: int) -> void: play_sfx(&"pickup"))
	EventBus.structure_built.connect(func(_id: StringName, _c: Vector2i) -> void: play_sfx(&"build"))
	EventBus.terrain_edited.connect(func(_c: Vector2i) -> void: play_sfx(&"dig"))
	EventBus.item_crafted.connect(func(_id: StringName) -> void: play_sfx(&"craft"))
	EventBus.notify.connect(func(_t: String, _i: StringName) -> void: play_sfx(&"ui_click"))
	EventBus.hour_changed.connect(_on_hour_changed)
	set_process(true)


func _setup_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	for bus_name: String in _volumes:
		set_volume(bus_name, _volumes[bus_name])


## API pública: toca um SFX pelo nome em pos (ou 2D "ambiente" se ZERO e sem câmera).
func play_sfx(sfx_name: StringName, pos: Vector3 = Vector3.ZERO) -> void:
	if not _sfx_cache.has(sfx_name):
		return
	var player := _next_sfx_player()
	player.stream = _sfx_cache[sfx_name]
	if pos != Vector3.ZERO:
		player.global_position = pos
	elif _ctx and _ctx.player:
		player.global_position = _ctx.player.global_position
	player.play()


func set_volume(bus_name: String, linear: float) -> void:
	_volumes[bus_name] = clampf(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))


## Chamado por weather.gd (via grupo "audio_manager") para cross-fade de ambiência de chuva.
func set_rain_amount(amount: float) -> void:
	_weather_rain_amount = clampf(amount, 0.0, 1.0)


func _build_sfx_cache() -> void:
	_sfx_cache[&"footstep_grass"] = SfxSynth.footstep(TerrainData.Tile.GRASS)
	_sfx_cache[&"footstep_sand"] = SfxSynth.footstep(TerrainData.Tile.SAND)
	_sfx_cache[&"footstep_path"] = SfxSynth.footstep(TerrainData.Tile.PATH)
	_sfx_cache[&"pickup"] = SfxSynth.pickup()
	_sfx_cache[&"coin"] = SfxSynth.coin()
	_sfx_cache[&"ui_click"] = SfxSynth.ui_click()
	_sfx_cache[&"chop"] = SfxSynth.chop()
	_sfx_cache[&"dig"] = SfxSynth.dig()
	_sfx_cache[&"plant"] = SfxSynth.plant()
	_sfx_cache[&"fish_splash"] = SfxSynth.fish_splash()
	_sfx_cache[&"build"] = SfxSynth.build_pop()
	_sfx_cache[&"craft"] = SfxSynth.craft()


## Efeito de passo por tipo de piso, chamado por outros sistemas (ex.: player.gd futuro) via grupo.
func play_footstep(tile: int, pos: Vector3) -> void:
	match tile:
		TerrainData.Tile.SAND:
			play_sfx(&"footstep_sand", pos)
		TerrainData.Tile.PATH, TerrainData.Tile.DIRT:
			play_sfx(&"footstep_path", pos)
		_:
			play_sfx(&"footstep_grass", pos)


func _build_sfx_pool() -> void:
	for i in 8:
		var p := AudioStreamPlayer3D.new()
		p.bus = "SFX"
		p.max_distance = 40.0
		p.unit_size = 4.0
		add_child(p)
		_sfx_players.append(p)


func _next_sfx_player() -> AudioStreamPlayer3D:
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	return p


func _build_music() -> void:
	_music_day = AudioStreamPlayer.new()
	_music_day.bus = "Music"
	_music_day.stream = MusicSequencer.build_day_loop()
	_music_day.volume_db = linear_to_db(0.001)
	add_child(_music_day)
	_music_night = AudioStreamPlayer.new()
	_music_night.bus = "Music"
	_music_night.stream = MusicSequencer.build_night_loop()
	_music_night.volume_db = linear_to_db(0.001)
	add_child(_music_night)
	_music_day.play()
	_music_night.play()


func _build_ambience() -> void:
	_amb_cicadas = _amb_player(AmbienceSynth.cicadas())
	_amb_night = _amb_player(AmbienceSynth.night_chorus())
	_amb_waves = _amb_player(AmbienceSynth.waves())
	_amb_wind = _amb_player(AmbienceSynth.wind())
	_amb_rain = _amb_player(AmbienceSynth.rain())
	for p in [_amb_cicadas, _amb_night, _amb_waves, _amb_wind, _amb_rain]:
		p.play()


func _amb_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Ambience"
	p.stream = stream
	p.volume_db = linear_to_db(0.001)
	add_child(p)
	return p


func _on_hour_changed(hour: float) -> void:
	## Dia claro ~6h-18h, transição suave nas bordas.
	var day_amount := clampf(1.0 - smoothstep(16.5, 19.5, hour) - smoothstep(0.0, 5.5, 6.0 - hour), 0.0, 1.0)
	if hour > 19.5 or hour < 5.5:
		day_amount = 0.0
	elif hour > 16.5:
		day_amount = 1.0 - smoothstep(16.5, 19.5, hour)
	elif hour < 6.5:
		day_amount = smoothstep(5.0, 6.5, hour)
	else:
		day_amount = 1.0
	_music_mix = 1.0 - day_amount
	_apply_music_volumes()
	_apply_ambience_volumes(day_amount)


func _apply_music_volumes() -> void:
	var day_v: float = (1.0 - _music_mix) * _volumes.get("Music", 0.55)
	var night_v: float = _music_mix * _volumes.get("Music", 0.55)
	_music_day.volume_db = linear_to_db(maxf(day_v, 0.0001))
	_music_night.volume_db = linear_to_db(maxf(night_v, 0.0001))


func _apply_ambience_volumes(day_amount: float) -> void:
	var amb_v: float = _volumes.get("Ambience", 0.7)
	_amb_cicadas.volume_db = linear_to_db(maxf(day_amount * amb_v * (1.0 - _weather_rain_amount * 0.6), 0.0001))
	_amb_night.volume_db = linear_to_db(maxf((1.0 - day_amount) * amb_v * (1.0 - _weather_rain_amount * 0.6), 0.0001))
	_amb_waves.volume_db = linear_to_db(maxf(amb_v * 0.35, 0.0001))
	_amb_wind.volume_db = linear_to_db(maxf(amb_v * 0.2 * (1.0 + _weather_rain_amount * 0.5), 0.0001))
	_amb_rain.volume_db = linear_to_db(maxf(amb_v * _weather_rain_amount, 0.0001))
