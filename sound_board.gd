extends AudioStreamPlayer

# Makes the game's sounds in code, as the arcade's sound circuits do. Main switches them on and off, as the arcade's program does.

const LIFE_HZ: float = 3000.0 # the arcade's extra ship tone: a 3 kHz square wave, taken from the board's clock
const LIFE_VOLUME: float = 0.2 # a fraction of full volume, set by ear

var life: bool = false # the extra ship circuit, on or off
var playback: AudioStreamGeneratorPlayback # where the samples go
var mix_rate: float # samples a second, from the AudioStreamGenerator in Stream
var life_phase: float = 0.0 # how far through one wave of the tone, from 0 to 1

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
		playback.push_frame(Vector2(sample, sample))
