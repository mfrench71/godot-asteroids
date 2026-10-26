# The flying saucer: large or small. For now it only draws itself.
class_name Saucer
extends Node2D

# The arcade's saucer outline, from the vector ROM, with y flipped for Godot.
# 80 across at the ROM's own size; the arcade draws it at half (large) or a quarter (small).
const OUTLINE: Array = [
	Vector2(-40, 8),
	Vector2(-16, 24),
	Vector2(16, 24),
	Vector2(40, 8),
	Vector2(16, -8),
	Vector2(8, -24),
	Vector2(-8, -24),
	Vector2(-16, -8),
	Vector2(-40, 8)
]

@export var small: bool = false # the arcade's two saucers: large (200 points) or small (1000)

func _ready() -> void:
	scale = Vector2.ONE * (0.25 if small else 0.5) # 20 or 40 pixels across; lines stay 1 pixel wide

func _draw() -> void:
	draw_polyline(PackedVector2Array(OUTLINE), Color.WHITE) # the outline, joined end to end
	draw_line(Vector2(-40, 8), Vector2(40, 8), Color.WHITE) # the line across the middle
	draw_line(Vector2(-16, -8), Vector2(16, -8), Color.WHITE) # the line under the dome
