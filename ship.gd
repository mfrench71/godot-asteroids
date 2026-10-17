extends Node2D

const TURN_SPEED: float = 4.0

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("rotate_left"):
		rotation_degrees -= TURN_SPEED
	if Input.is_action_pressed("rotate_right"):
		rotation_degrees += TURN_SPEED

func _draw() -> void:
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-8, -8), Vector2(12, 0), Vector2(-8, 8)])
	draw_polyline(outline, Color.WHITE)
	draw_line(Vector2(-3, -6), Vector2(-3, 6), Color.WHITE)
