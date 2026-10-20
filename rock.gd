class_name Rock
extends Node2D

# The arcade's four rock shapes, from the vector ROM, with y flipped for Godot.
# A large rock is drawn at the ROM's own size: 64 pixels across.
const SHAPES: Array = [
	[Vector2(0, -16), Vector2(16, -32), Vector2(32, -16), Vector2(24, 0), Vector2(32, 16), Vector2(8, 32), Vector2(-16, 32), Vector2(-32, 16), Vector2(-32, -16), Vector2(-16, -32), Vector2(0, -16)],
	[Vector2(16, -8), Vector2(32, -16), Vector2(16, -32), Vector2(0, -24), Vector2(-16, -32), Vector2(-32, -16), Vector2(-24, 0), Vector2(-32, 16), Vector2(-16, 32), Vector2(-8, 24), Vector2(16, 32), Vector2(32, 8), Vector2(16, -8)],
	[Vector2(-16, 0), Vector2(-32, 8), Vector2(-16, 32), Vector2(0, 8), Vector2(0, 32), Vector2(16, 32), Vector2(32, 8), Vector2(32, -8), Vector2(16, -32), Vector2(-8, -32), Vector2(-32, -8), Vector2(-16, 0)],
	[Vector2(8, 0), Vector2(32, -8), Vector2(32, -16), Vector2(8, -32), Vector2(-16, -32), Vector2(-8, -16), Vector2(-32, -16), Vector2(-32, 8), Vector2(-16, 32), Vector2(8, 24), Vector2(16, 32), Vector2(32, 16), Vector2(8, 0)],
]

@export_range(0, 3) var shape: int = 0  # which of the four shapes to draw

func _draw() -> void:
	draw_polyline(PackedVector2Array(SHAPES[shape]), Color.WHITE)
