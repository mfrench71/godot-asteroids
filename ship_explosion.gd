# The ship's explosion: six short lines where the ship was hit, like the arcade's.
class_name ShipExplosion
extends Node2D

# The arcade's six pieces: each is a line, given as where its far end is from its start,
# in pixels, with y flipped for Godot.
const PIECES: Array = [
	Vector2(-8, 12),
	Vector2(4, 8),
	Vector2(6, -2),
	Vector2(-8, -8),
	Vector2(-6, -2),
	Vector2(4, 4),
]

# How fast each piece drifts, in 1/256 pixels per tick, with y flipped for Godot.
const SPEEDS: Array = [
	Vector2(-40, -30),
	Vector2(50, 20),
	Vector2(0, 60),
	Vector2(60, -20),
	Vector2(10, -70),
	Vector2(-40, 40),
]

var count: int = 0xA0 # the arcade's explosion counter, as for rocks
var ticks: int = 0 # counts every tick, like the arcade's frame counter
var offsets: Array = [] # where each piece starts, from the centre

func _ready() -> void:
	for speed: Vector2 in SPEEDS:
		offsets.append(speed / 16.0) # like the arcade, each piece starts a little way out

func _physics_process(_delta: float) -> void:
	# The same counter as a rock's, but it only moves on every other tick, so it lasts 56.
	count += ((256 - count) >> 4) + (ticks & 1)
	ticks += 1
	if count > 255:
		queue_free()

func _draw() -> void:
	for i in PIECES.size():
		draw_line(offsets[i], offsets[i] + PIECES[i], Color.WHITE)
