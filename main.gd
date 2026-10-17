extends Node2D
var frames: int = 0
var seconds: float = 0.0
var physics_frames: int = 0
var physics_seconds: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Main is ready")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frames = frames + 1
	seconds = seconds + delta
	if seconds >= 1.0:
		print("Frames this second: ", frames)
		frames = 0
		seconds = 0.0

func _physics_process(delta: float) -> void:
		physics_frames = physics_frames + 1
		physics_seconds = physics_seconds + delta
		if physics_seconds >= 1.0:
			print("Physics ticks this second: ", physics_frames)
			physics_frames = 0
			physics_seconds = 0.0
