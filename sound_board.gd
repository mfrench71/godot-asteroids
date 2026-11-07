extends AudioStreamPlayer

# Makes the game's sounds in code, as the arcade's sound circuits do. Main switches them on and off, as the arcade's program does.

const LIFE_HZ: float = 3000.0 # the arcade's extra ship tone: a 3 kHz square wave, taken from the board's clock
const LIFE_VOLUME: float = 0.2 # a fraction of full volume, set by ear
const FIRE_START_HZ: Array[float] = [820.0, 830.0] # yours, then the saucer's: each sweeps down from here...
const FIRE_END_HZ: Array[float] = [110.0, 630.0] # ...to here over FIRE_SWEEP seconds, then stays
const FIRE_SWEEP: float = 0.28 # seconds the sweep takes
const FIRE_FADE: Array[float] = [0.081, 0.3] # seconds for the volume to fall most of the way: yours fast, the saucer's slowly
const FIRE_VOLUME: float = 0.2 # set by ear

var life: bool = false # the extra ship circuit, on or off
var playback: AudioStreamGeneratorPlayback # where the samples go
var mix_rate: float # samples a second, from the AudioStreamGenerator in Stream
var life_phase: float = 0.0 # how far through one wave of the tone, from 0 to 1
var fire: Array[bool] = [false, false] # the two fire circuits, on or off: yours (0) and the saucer's (1)
var fire_phase: Array[float] = [0.0, 0.0] # how far through one wave each fire tone is
var fire_time: Array[float] = [0.0, 0.0] # seconds each fire circuit has been on; back to 0 when it goes off

func _ready() -> void:
	mix_rate = (stream as AudioStreamGenerator).mix_rate
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
		playback.push_frame(Vector2(sample, sample))
