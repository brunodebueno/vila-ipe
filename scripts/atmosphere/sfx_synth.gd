class_name SfxSynth
extends RefCounted
## Gera os efeitos sonoros curtos do jogo 100% por código (sem arquivos externos).

const RATE := 44100


static func footstep(tile: int) -> AudioStreamWAV:
	match tile:
		TerrainData.Tile.SAND:
			return _footstep_sand()
		TerrainData.Tile.PATH, TerrainData.Tile.DIRT:
			return _footstep_path()
		_:
			return _footstep_grass()


static func _footstep_grass() -> AudioStreamWAV:
	var n := AudioSynth.white_noise(0.09, RATE, 0.5, 101)
	AudioSynth.lowpass(n, 0.18)
	var env := AudioSynth.adsr(n.size(), RATE, 0.004, 0.03, 0.2, 0.05)
	AudioSynth.apply_envelope(n, env)
	AudioSynth.normalize(n, 0.6)
	return AudioSynth.to_wav(n, RATE)


static func _footstep_sand() -> AudioStreamWAV:
	var n := AudioSynth.white_noise(0.1, RATE, 0.5, 102)
	AudioSynth.bandpass(n, 0.12, 0.65)
	var env := AudioSynth.adsr(n.size(), RATE, 0.002, 0.045, 0.1, 0.05)
	AudioSynth.apply_envelope(n, env)
	AudioSynth.normalize(n, 0.55)
	return AudioSynth.to_wav(n, RATE)


static func _footstep_path() -> AudioStreamWAV:
	var n := AudioSynth.white_noise(0.08, RATE, 0.4, 103)
	AudioSynth.lowpass(n, 0.35)
	var knock := AudioSynth.sine(95.0, 0.08, RATE, 0.35)
	AudioSynth.apply_envelope(knock, AudioSynth.adsr(knock.size(), RATE, 0.001, 0.03, 0.0, 0.03))
	AudioSynth.apply_envelope(n, AudioSynth.adsr(n.size(), RATE, 0.001, 0.02, 0.1, 0.04))
	var out := AudioSynth.make(maxi(n.size(), knock.size()))
	AudioSynth.mix_into(out, n, 0, 1.0)
	AudioSynth.mix_into(out, knock, 0, 1.0)
	AudioSynth.normalize(out, 0.6)
	return AudioSynth.to_wav(out, RATE)


## "Plim" de coleta de item: duas notas ascendentes suaves.
static func pickup() -> AudioStreamWAV:
	var a := AudioSynth.sine(880.0, 0.08, RATE, 0.35)
	AudioSynth.apply_envelope(a, AudioSynth.adsr(a.size(), RATE, 0.004, 0.06, 0.0, 0.02))
	var b := AudioSynth.sine(1318.0, 0.14, RATE, 0.3)
	AudioSynth.apply_envelope(b, AudioSynth.adsr(b.size(), RATE, 0.004, 0.1, 0.0, 0.05))
	var out := AudioSynth.make(a.size() + int(0.05 * RATE))
	AudioSynth.mix_into(out, a, 0)
	AudioSynth.mix_into(out, b, int(0.05 * RATE))
	AudioSynth.normalize(out, 0.55)
	return AudioSynth.to_wav(out, RATE)


## Moeda: arpejo brilhante de três tons.
static func coin() -> AudioStreamWAV:
	var freqs := [988.0, 1318.0, 1760.0]
	var out := AudioSynth.make(int(0.26 * RATE))
	var offset := 0
	for f in freqs:
		var tone := AudioSynth.sine(f, 0.12, RATE, 0.3)
		AudioSynth.apply_envelope(tone, AudioSynth.adsr(tone.size(), RATE, 0.002, 0.08, 0.0, 0.04))
		AudioSynth.mix_into(out, tone, offset)
		offset += int(0.045 * RATE)
	AudioSynth.normalize(out, 0.6)
	return AudioSynth.to_wav(out, RATE)


static func craft() -> AudioStreamWAV:
	var freqs := [523.25, 659.25, 784.0]
	var out := AudioSynth.make(int(0.3 * RATE))
	var offset := 0
	for f in freqs:
		var tone := AudioSynth.karplus_strong(f, 0.22, RATE, 0.993, 0.6, int(f))
		AudioSynth.apply_envelope(tone, AudioSynth.adsr(tone.size(), RATE, 0.002, 0.18, 0.0, 0.05))
		AudioSynth.mix_into(out, tone, offset, 0.5)
		offset += int(0.03 * RATE)
	AudioSynth.normalize(out, 0.55)
	return AudioSynth.to_wav(out, RATE)


## Clique de UI: tique seco e curto.
static func ui_click() -> AudioStreamWAV:
	var n := AudioSynth.white_noise(0.018, RATE, 0.5, 55)
	AudioSynth.bandpass(n, 0.3, 0.9)
	var t := AudioSynth.sine(1500.0, 0.018, RATE, 0.2)
	var out := AudioSynth.make(n.size())
	AudioSynth.mix_into(out, n, 0)
	AudioSynth.mix_into(out, t, 0)
	AudioSynth.apply_envelope(out, AudioSynth.adsr(out.size(), RATE, 0.001, 0.012, 0.0, 0.004))
	AudioSynth.normalize(out, 0.5)
	return AudioSynth.to_wav(out, RATE)


## Corte (machado): impacto seco com clique de madeira.
static func chop() -> AudioStreamWAV:
	var thump := AudioSynth.sine_sweep(180.0, 70.0, 0.07, RATE, 0.5)
	var crack := AudioSynth.white_noise(0.05, RATE, 0.6, 61)
	AudioSynth.bandpass(crack, 0.2, 0.8)
	AudioSynth.apply_envelope(crack, AudioSynth.adsr(crack.size(), RATE, 0.001, 0.03, 0.0, 0.02))
	AudioSynth.apply_envelope(thump, AudioSynth.adsr(thump.size(), RATE, 0.002, 0.05, 0.0, 0.03))
	var out := AudioSynth.make(thump.size())
	AudioSynth.mix_into(out, thump, 0)
	AudioSynth.mix_into(out, crack, 0, 0.8)
	AudioSynth.normalize(out, 0.65)
	return AudioSynth.to_wav(out, RATE)


## Cavar/terraformar: thump de terra grave e seco.
static func dig() -> AudioStreamWAV:
	var thump := AudioSynth.sine(85.0, 0.14, RATE, 0.5)
	AudioSynth.apply_envelope(thump, AudioSynth.adsr(thump.size(), RATE, 0.002, 0.1, 0.0, 0.04))
	var n := AudioSynth.white_noise(0.09, RATE, 0.3, 71)
	AudioSynth.lowpass(n, 0.12)
	AudioSynth.apply_envelope(n, AudioSynth.adsr(n.size(), RATE, 0.002, 0.07, 0.0, 0.03))
	var out := AudioSynth.make(thump.size())
	AudioSynth.mix_into(out, thump, 0)
	AudioSynth.mix_into(out, n, 0, 0.7)
	AudioSynth.normalize(out, 0.6)
	return AudioSynth.to_wav(out, RATE)


## Plantar: thump terroso macio + mini sino de vida.
static func plant() -> AudioStreamWAV:
	var thump := AudioSynth.sine(140.0, 0.1, RATE, 0.3)
	AudioSynth.apply_envelope(thump, AudioSynth.adsr(thump.size(), RATE, 0.002, 0.08, 0.0, 0.03))
	var chime := AudioSynth.sine(988.0, 0.2, RATE, 0.18)
	AudioSynth.apply_envelope(chime, AudioSynth.adsr(chime.size(), RATE, 0.01, 0.15, 0.0, 0.08))
	var out := AudioSynth.make(chime.size())
	AudioSynth.mix_into(out, thump, 0)
	AudioSynth.mix_into(out, chime, int(0.03 * RATE))
	AudioSynth.normalize(out, 0.55)
	return AudioSynth.to_wav(out, RATE)


## Pesca: splash com ruído e varredura aquosa.
static func fish_splash() -> AudioStreamWAV:
	var n := AudioSynth.white_noise(0.3, RATE, 0.6, 81)
	AudioSynth.bandpass(n, 0.08, 0.5)
	AudioSynth.apply_envelope(n, AudioSynth.adsr(n.size(), RATE, 0.001, 0.22, 0.0, 0.08))
	var sweep := AudioSynth.sine_sweep(600.0, 90.0, 0.22, RATE, 0.3)
	AudioSynth.apply_envelope(sweep, AudioSynth.adsr(sweep.size(), RATE, 0.001, 0.18, 0.0, 0.03))
	var out := AudioSynth.make(n.size())
	AudioSynth.mix_into(out, n, 0)
	AudioSynth.mix_into(out, sweep, 0, 0.6)
	AudioSynth.normalize(out, 0.65)
	return AudioSynth.to_wav(out, RATE)


## Construção: "pop" alegre e curto.
static func build_pop() -> AudioStreamWAV:
	var sweep := AudioSynth.sine_sweep(260.0, 700.0, 0.12, RATE, 0.4)
	AudioSynth.apply_envelope(sweep, AudioSynth.adsr(sweep.size(), RATE, 0.002, 0.09, 0.0, 0.03))
	AudioSynth.normalize(sweep, 0.6)
	return AudioSynth.to_wav(sweep, RATE)
