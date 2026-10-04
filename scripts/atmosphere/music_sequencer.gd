class_name MusicSequencer
extends RefCounted
## Sequenciador simples: monta loops de MPB/bossa/choro dedilhados (Karplus-Strong) a partir
## de progressões de acordes com sétimas, baixo e shaker. Tudo sintetizado, sem samples.

const RATE := 22050

## Cada acorde: nota raiz (MIDI) + intervalos (semitons) da tétrade usada nos dedilhados.
const DAY_CHORDS := [
	{"root": 60, "ints": [0, 4, 7, 11]},  ## Cmaj7  (I)
	{"root": 57, "ints": [0, 3, 7, 10]},  ## Am7    (vi)
	{"root": 62, "ints": [0, 3, 7, 10]},  ## Dm7    (ii)
	{"root": 55, "ints": [0, 4, 7, 10]},  ## G7     (V)
]
const NIGHT_CHORDS := DAY_CHORDS


static func _midi_to_freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Loop diurno: bossa alegre, ~112 bpm, violão em corcheias + baixo + shaker.
static func build_day_loop() -> AudioStreamWAV:
	var bpm := 112.0
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var total := bar * DAY_CHORDS.size()
	var out := AudioSynth.make(int(total * RATE) + RATE)
	var arpeggio_order := [0, 2, 1, 3, 2, 1, 3, 0]
	for bar_i in DAY_CHORDS.size():
		var chord: Dictionary = DAY_CHORDS[bar_i]
		var root: int = chord.root
		var ints: Array = chord.ints
		var bar_start := bar_i * bar
		var bass := AudioSynth.karplus_strong(_midi_to_freq(root - 24), bar * 0.95, RATE, 0.9965, 0.35, root + 1)
		AudioSynth.apply_envelope(bass, AudioSynth.adsr(bass.size(), RATE, 0.004, bar * 0.5, 0.3, bar * 0.3))
		AudioSynth.mix_into(out, bass, int(bar_start * RATE), 0.32)
		for step in 8:
			var note_interval: int = ints[arpeggio_order[step] % ints.size()]
			var freq := _midi_to_freq(root + 12 + note_interval)
			var t0 := bar_start + step * beat * 0.5
			var pluck := AudioSynth.karplus_strong(freq, beat * 0.55, RATE, 0.995, 0.55, root * 3 + step)
			AudioSynth.apply_envelope(pluck, AudioSynth.adsr(pluck.size(), RATE, 0.002, beat * 0.2, 0.15, beat * 0.2))
			AudioSynth.mix_into(out, pluck, int(t0 * RATE), 0.22)
			var shaker := AudioSynth.white_noise(0.05, RATE, 0.3, step + bar_i * 8 + 1)
			AudioSynth.bandpass(shaker, 0.35, 0.85)
			AudioSynth.apply_envelope(shaker, AudioSynth.adsr(shaker.size(), RATE, 0.001, 0.03, 0.0, 0.015))
			AudioSynth.mix_into(out, shaker, int(t0 * RATE), 0.08)
	AudioSynth.normalize(out, 0.55)
	return AudioSynth.to_wav(out, RATE, true)


## Loop noturno: bossa calma e lenta, ~66 bpm, dedilhado espaçado e mais suave.
static func build_night_loop() -> AudioStreamWAV:
	var bpm := 66.0
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var total := bar * NIGHT_CHORDS.size()
	var out := AudioSynth.make(int(total * RATE) + RATE)
	var arpeggio_order := [0, 2, 3, 1]
	for bar_i in NIGHT_CHORDS.size():
		var chord: Dictionary = NIGHT_CHORDS[bar_i]
		var root: int = chord.root
		var ints: Array = chord.ints
		var bar_start := bar_i * bar
		var bass := AudioSynth.karplus_strong(_midi_to_freq(root - 24), bar * 0.98, RATE, 0.998, 0.25, root + 11)
		AudioSynth.apply_envelope(bass, AudioSynth.adsr(bass.size(), RATE, 0.01, bar * 0.6, 0.25, bar * 0.35))
		AudioSynth.mix_into(out, bass, int(bar_start * RATE), 0.26)
		for step in 4:
			var note_interval: int = ints[arpeggio_order[step] % ints.size()]
			var freq := _midi_to_freq(root + 12 + note_interval)
			var t0 := bar_start + step * beat
			var pluck := AudioSynth.karplus_strong(freq, beat * 1.2, RATE, 0.9975, 0.4, root * 5 + step)
			AudioSynth.apply_envelope(pluck, AudioSynth.adsr(pluck.size(), RATE, 0.006, beat * 0.5, 0.2, beat * 0.5))
			AudioSynth.mix_into(out, pluck, int(t0 * RATE), 0.18)
		var brush := AudioSynth.white_noise(bar * 0.6, RATE, 0.1, bar_i + 300)
		AudioSynth.bandpass(brush, 0.15, 0.4)
		AudioSynth.apply_envelope(brush, AudioSynth.adsr(brush.size(), RATE, bar * 0.1, bar * 0.3, 0.0, bar * 0.2))
		AudioSynth.mix_into(out, brush, int(bar_start * RATE), 0.05)
	AudioSynth.normalize(out, 0.45)
	return AudioSynth.to_wav(out, RATE, true)
