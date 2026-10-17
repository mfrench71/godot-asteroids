extends Node2D

func _draw() -> void:
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-8, -8), Vector2(12, 0), Vector2(-8, 8)])
	draw_polyline(outline, Color.WHITE)
	draw_line(Vector2(-3, -6), Vector2(-3, 6), Color.WHITE)
