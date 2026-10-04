class_name AmbienceSynth
extends RefCounted
## Paisagens sonoras contínuas (loops) geradas por síntese: insetos, sapos, ondas, vento, chuva.

const RATE := 22050


## Cigarras/grilos de dia: zumbido de alta frequência com tremolo irregular.
static func cicadas(dur: float = 5.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := AudioSynth.make(n)
	for i in n:
		var t := i / float(RATE)
		var carrier := sin(TAU * 5200.0 * t) * 0.6 + sin(TAU * 7600.0 * t) * 0.4
		var tremolo := 0.5 + 0.5 * sin(TAU * 26.0 * t + sin(t * 2.3) * 2.0)
		out[i] = carrier * tremolo * 0.1
	return AudioSynth.to_wav(out, RATE, true)


## Grilos + sapos noturnos: pulsos agudos (grilo) e "blup" graves (sapo) espalhados.
static func night_chorus(dur: float = 6.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := AudioSynth.make(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var t := 0.0
	while t < dur - 0.05:
		var chirp := AudioSynth.sine(4300.0 + rng.randf_range(-150, 150), 0.045, RATE, 0.16)
		AudioSynth.apply_envelope(chirp, AudioSynth.adsr(chirp.size(), RATE, 0.002, 0.03, 0.0, 0.01))
		AudioSynth.mix_into(out, chirp, int(t * RATE))
		t += rng.randf_range(0.12, 0.35)
	t = rng.randf_range(0.2, 0.9)
	while t < dur - 0.3:
		var frog := AudioSynth.sine_sweep(260.0, 170.0, 0.16, RATE, 0.22)
		AudioSynth.apply_envelope(frog, AudioSynth.adsr(frog.size(), RATE, 0.004, 0.1, 0.0, 0.05))
		AudioSynth.mix_into(out, frog, int(t * RATE))
		t += rng.randf_range(0.8, 2.2)
	AudioSynth.normalize(out, 0.5)
	return AudioSynth.to_wav(out, RATE, true)


## Ondas perto da água: ruído filtrado grave com respiração lenta (sobe e desce).
static func waves(dur: float = 7.0) -> AudioStreamWAV:
	var base := AudioSynth.brown_noise(dur, RATE, 0.55, 33)
	AudioSynth.lowpass(base, 0.06)
	var n := base.size()
	for i in n:
		var t := i / float(RATE)
		var swell := 0.55 + 0.45 * sin(TAU * (1.0 / 4.5) * t)
		base[i] *= swell
	AudioSynth.normalize(base, 0.5)
	return AudioSynth.to_wav(base, RATE, true)


## Vento: ruído marrom filtrado com variação lenta de intensidade.
static func wind(dur: float = 6.0) -> AudioStreamWAV:
	var base := AudioSynth.brown_noise(dur, RATE, 0.5, 44)
	AudioSynth.lowpass(base, 0.1)
	var n := base.size()
	for i in n:
		var t := i / float(RATE)
		var gust := 0.6 + 0.4 * sin(TAU * (1.0 / 6.0) * t + sin(t * 0.5))
		base[i] *= gust
	AudioSynth.normalize(base, 0.4)
	return AudioSynth.to_wav(base, RATE, true)


## Chuva: ruído branco filtrado em médios-agudos, com "pingos" ocasionais.
static func rain(dur: float = 5.0, heavy: bool = false) -> AudioStreamWAV:
	var base := AudioSynth.white_noise(dur, RATE, 0.3 if not heavy else 0.5, 55)
	AudioSynth.bandpass(base, 0.2, 0.75 if not heavy else 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var drops := int(dur * (14.0 if heavy else 5.0))
	for i in drops:
		var t := rng.randf() * dur
		var drop := AudioSynth.sine(rng.randf_range(2200.0, 3400.0), 0.02, RATE, 0.12)
		AudioSynth.apply_envelope(drop, AudioSynth.adsr(drop.size(), RATE, 0.001, 0.015, 0.0, 0.004))
		AudioSynth.mix_into(base, drop, int(t * RATE))
	AudioSynth.normalize(base, 0.55 if not heavy else 0.75)
	return AudioSynth.to_wav(base, RATE, true)
