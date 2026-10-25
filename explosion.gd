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

var count: int = 0xA0 # the arcade's explosion counter: starts at $A0 (160), done when it passes 255

func _ready() -> void:
	add_to_group("explosions") # so wave countdown can check for completed explosions

func _physics_process(_delta: float) -> void:
	# Like the arcade: big steps at first, then smaller and smaller ones, 38 in all.
	count += ((256 - count) >> 4) + 1
	if count > 255:
		queue_free()
		return # so a finished explosion isn't drawn again
	queue_redraw() # the dots have spread a little further

func _draw() -> void:
	# Like the arcade: six sizes, each double the last, with four steps in between each.
	var band: int = count >> 4 # 10 to 15: the first hex digit of count
	var step: int = (count >> 2) & 3 # 0 to 3, counting up within the band
	var spread: float = pow(2.0, band - 15) * (10 + 2 * step) / 16.0
	for dot: Vector2 in DOTS:
		draw_circle(dot * spread, 1.0, Color.WHITE) # a dot, like a shot
