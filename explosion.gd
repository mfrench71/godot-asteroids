# One rock explosion: the arcade's cloud of dots, where a rock was hit.
class_name Explosion
extends Node2D

# The arcade's shrapnel at its largest: 10 dots, in pixels from the centre, with y flipped for Godot.
const DOTS: Array = [
	Vector2(-16, 0),
	Vector2(-32, 16),
	Vector2(-16, 32),
	Vector2(8, 24),
	Vector2(24, 32),
	Vector2(24, 16),
	Vector2(32, -8),
	Vector2(24, -32),
	Vector2(-8, -24),
	Vector2(-32, -32),
]

var ticks_left: int = 38 # the arcade's explosion lasts 38 updates

func _physics_process(_delta: float) -> void:
	ticks_left -= 1
	if ticks_left <= 0:
		queue_free()

func _draw() -> void:
	for dot: Vector2 in DOTS:
		draw_circle(dot, 1.0, Color.WHITE) # a dot, like a shot
