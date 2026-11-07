extends AudioStreamPlayer

# Makes the game's sounds in code, as the arcade's sound circuits do. Main switches them on and off, as the arcade's program does.

const LIFE_HZ: float = 3000.0 # the arcade's extra ship tone: a 3 kHz square wave, taken from the board's clock
const LIFE_VOLUME: float = 0.2 # a fraction of full volume, set by ear
const FIRE_START_HZ: Array[float] = [820.0, 830.0] # yours, then the saucer's: each sweeps down from here...
const FIRE_END_HZ: Array[float] = [110.0, 630.0] # ...to here over FIRE_SWEEP seconds, then stays
const FIRE_SWEEP: float = 0.28 # seconds the sweep takes
const FIRE_FADE: Array[float] = [0.081, 0.3] # seconds for the volume to fall most of the way: yours fast, the saucer's slowly
const FIRE_VOLUME: float = 0.2 # set by ear
const SIREN_LOW_HZ: Array[float] = [500.0, 750.0] # large saucer, then small: the siren's lowest pitch
const SIREN_SWING_HZ: float = 920.0 # how far the pitch rises above that and falls back
const SIREN_WARBLE_HZ: Array[float] = [5.75, 8.25] # how many times a second it rises and falls
const SIREN_VOLUME: float = 0.15 # set by ear
const THUMP_HZ: float = 88.0 # the arcade's two thump notes, worked out from MAME's model of its timer chip
const THUMP_LOW_HZ: float = 82.0
const THUMP_RC: float = 0.00033 # seconds: the filter after the timer chip, 3.3 kilohms and 0.1 microfarads
const THUMP_VOLUME: float = 0.3 # set by ear

var life: bool = false # the extra ship circuit, on or off
var playback: AudioStreamGeneratorPlayback # where the samples go
var mix_rate: float # samples a second, from the AudioStreamGenerator in Stream
var life_phase: float = 0.0 # how far through one wave of the tone, from 0 to 1
var fire: Array[bool] = [false, false] # the two fire circuits, on or off: yours (0) and the saucer's (1)
var fire_phase: Array[float] = [0.0, 0.0] # how far through one wave each fire tone is
var fire_time: Array[float] = [0.0, 0.0] # seconds each fire circuit has been on; back to 0 when it goes off
var saucer: bool = false # the siren circuit, on or off
var saucer_small: bool = false # the arcade's saucer select: picks the small saucer's tone
var siren_phase: float = 0.0
var warble_phase: float = 0.0 # how far through one rise and fall of the siren's pitch
var thump: bool = false # the thump circuit, on or off
var thump_low: bool = false # which of its two notes
var thump_phase: float = 0.0
var thump_level: float = 0.0 # the thump after the filter, which follows the square wave a little behind
var thump_smooth: float # how far the filter moves towards the wave each sample, worked out in _ready

func _ready() -> void:
	mix_rate = (stream as AudioStreamGenerator).mix_rate
	thump_smooth = 1.0 - exp(-1.0 / (THUMP_RC * mix_rate))
	play()
	playback = get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	for i in playback.get_frames_available():
		var sample: float = 0.0
		if life:
			life_phase = fmod(life_phase + LIFE_HZ / mix_rate, 1.0)
			sample += LIFE_VOLUME if life_phase < 0.5 else -LIFE_VOLUME
		for f in 2:
			if fire[f]:
				var t: float = fire_time[f]
				var hz: float = lerpf(FIRE_START_HZ[f], FIRE_END_HZ[f], minf(t / FIRE_SWEEP, 1.0))
				var level: float = FIRE_VOLUME * (0.13 + 0.87 * exp(-t / FIRE_FADE[f]))
				fire_phase[f] = fmod(fire_phase[f] + hz / mix_rate, 1.0)
				sample += level if fire_phase[f] < 0.5 else -level
				fire_time[f] += 1.0 / mix_rate
			else:
				fire_time[f] = 0.0
		if saucer:
			var size: int = 1 if saucer_small else 0
			warble_phase = fmod(warble_phase + SIREN_WARBLE_HZ[size] / mix_rate, 1.0)
			var hz: float = SIREN_LOW_HZ[size] + SIREN_SWING_HZ * (triangle(warble_phase) + 1.0) / 2.0
			siren_phase = fmod(siren_phase + hz / mix_rate, 1.0)
			sample += SIREN_VOLUME * triangle(siren_phase)
		var thump_wave: float = 0.0
		if thump:
			thump_phase = fmod(thump_phase + (THUMP_LOW_HZ if thump_low else THUMP_HZ) / mix_rate, 1.0)
			thump_wave = 1.0 if thump_phase < 0.5 else -1.0
		else:
			thump_phase = 0.0 # the timer chip is held reset while the circuit is off, so each beat starts the same way
		thump_level += (thump_wave - thump_level) * thump_smooth
		sample += THUMP_VOLUME * thump_level
		playback.push_frame(Vector2(sample, sample))

# A triangle wave from a phase of 0 to 1: rises from -1 to 1 over the first half, falls back over the second.
func triangle(phase: float) -> float:
	return 1.0 - 4.0 * absf(phase - 0.5)

# Every circuit off, like the arcade's routine at $6EFA when a game ends.
func all_off() -> void:
	life = false
	fire.fill(false)
	saucer = false
	thump = false
