extends Feature
## Configurações: carrega user://settings.cfg e aplica áudio/vídeo/câmera/dia ao iniciar.

func install(ctx: GameContext) -> void:
	var data := SettingsStore.load_settings()
	SettingsStore.apply_audio(data)
	SettingsStore.apply_video(data)
	SettingsStore.apply_graphics(data, ctx.main.get_tree())
	if ctx.rig:
		ctx.rig.sensitivity = 0.005 * float(data["camera"]["sensitivity"])
	if ctx.day_night:
		ctx.day_night.day_length_seconds = float(data["gameplay"]["day_length"])
