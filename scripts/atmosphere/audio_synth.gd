class_name AudioSynth
extends RefCounted
## Caixa de ferramentas de síntese digital: gera PackedFloat32Array de áudio em código
## (osciladores, ruído, filtros, envelopes, Karplus-Strong) e converte para AudioStreamWAV.
## Nenhum arquivo de áudio externo é usado — tudo é sintetizado em tempo de instalação.

const TAU_F := TAU


static func to_wav(samples: PackedFloat32Array, rate: int = 44100, loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := clampf(samples[i], -1.0, 1.0)
		var s := int(round(v * 32767.0))
		bytes.encode_s16(i * 2, s)
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size() - 1
	return wav


static func make(n: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n)
	return a


static func sine(freq: float, dur: float, rate: int, amp: float = 0.4, phase: float = 0.0) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := make(n)
	for i in n:
		out[i] = sin(TAU_F * freq * (i / float(rate)) + phase) * amp
	return out


## Varredura exponencial de frequência (chirp) — útil para splash, pop, sino.
static func sine_sweep(freq_from: float, freq_to: float, dur: float, rate: int, amp: float = 0.4) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := make(n)
	var phase := 0.0
	for i in n:
		var t := i / float(rate)
		var k := t / dur
		var f := lerpf(freq_from, freq_to, k)
		phase += TAU_F * f / rate
		out[i] = sin(phase) * amp
	return out


static func white_noise(dur: float, rate: int, amp: float = 0.3, rng_seed: int = 1) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var n := int(dur * rate)
	var out := make(n)
	for i in n:
		out[i] = rng.randf_range(-1.0, 1.0) * amp
	return out


## Ruído marrom (integrado) — bom para vento e ondas, mais grave e macio que o branco.
static func brown_noise(dur: float, rate: int, amp: float = 0.3, rng_seed: int = 2) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var n := int(dur * rate)
	var out := make(n)
	var last := 0.0
	for i in n:
		last = clampf(last + rng.randf_range(-0.08, 0.08), -1.0, 1.0)
		out[i] = last * amp
	return out


## Filtro passa-baixa de um polo, in-place. cutoff01 em [0,1] (fração do nyquist, aprox.).
static func lowpass(samples: PackedFloat32Array, cutoff01: float) -> void:
	var a := clampf(cutoff01, 0.001, 1.0)
	var y := 0.0
	for i in samples.size():
		y += a * (samples[i] - y)
		samples[i] = y


## Filtro passa-alta de um polo, in-place.
static func highpass(samples: PackedFloat32Array, cutoff01: float) -> void:
	var a := clampf(cutoff01, 0.001, 1.0)
	var y := 0.0
	var last_in := 0.0
	for i in samples.size():
		y = a * (y + samples[i] - last_in)
		last_in = samples[i]
		samples[i] = y


static func bandpass(samples: PackedFloat32Array, low01: float, high01: float) -> void:
	highpass(samples, low01)
	lowpass(samples, high01)


## Envelope ADSR (segundos), devolve array com o mesmo tamanho de n amostras.
static func adsr(n: int, rate: int, attack: float, decay: float, sustain_level: float, release: float) -> PackedFloat32Array:
	var env := make(n)
	var a_n := int(attack * rate)
	var d_n := int(decay * rate)
	var r_n := int(release * rate)
	var s_n := maxi(0, n - a_n - d_n - r_n)
	var idx := 0
	for i in a_n:
		if idx >= n:
			break
		env[idx] = float(i) / maxf(1.0, a_n)
		idx += 1
	for i in d_n:
		if idx >= n:
			break
		env[idx] = lerpf(1.0, sustain_level, float(i) / maxf(1.0, d_n))
		idx += 1
	for i in s_n:
		if idx >= n:
			break
		env[idx] = sustain_level
		idx += 1
	for i in r_n:
		if idx >= n:
			break
		env[idx] = lerpf(sustain_level, 0.0, float(i) / maxf(1.0, r_n))
		idx += 1
	return env


static func apply_envelope(samples: PackedFloat32Array, env: PackedFloat32Array) -> void:
	var n := mini(samples.size(), env.size())
	for i in n:
		samples[i] *= env[i]


## Corda dedilhada por Karplus-Strong: base de violão/baixo/pandeiro percussivo.
static func karplus_strong(freq: float, dur: float, rate: int, damping: float = 0.996, brightness: float = 0.5, rng_seed: int = 7) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var delay_len := maxi(2, int(round(rate / maxf(freq, 20.0))))
	var buf := PackedFloat32Array()
	buf.resize(delay_len)
	for i in delay_len:
		buf[i] = rng.randf_range(-1.0, 1.0)
	var n := int(dur * rate)
	var out := make(n)
	var prev := 0.0
	for i in n:
		var idx := i % delay_len
		var nxt := (idx + 1) % delay_len
		var sample := buf[idx]
		var averaged := damping * 0.5 * (buf[idx] + buf[nxt])
		buf[idx] = lerpf(averaged, prev, 1.0 - brightness)
		prev = sample
		out[i] = sample
	return out


## Soma `src` dentro de `dst` a partir de start_sample, com ganho — usada pelo sequenciador.
static func mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, start_sample: int, gain: float = 1.0) -> void:
	var limit := dst.size()
	for i in src.size():
		var j := start_sample + i
		if j < 0 or j >= limit:
			continue
		dst[j] += src[i] * gain


static func normalize(samples: PackedFloat32Array, peak: float = 0.9) -> void:
	var m := 0.0001
	for v in samples:
		m = maxf(m, absf(v))
	if m <= 0.0001:
		return
	var g := peak / m
	for i in samples.size():
		samples[i] *= g
