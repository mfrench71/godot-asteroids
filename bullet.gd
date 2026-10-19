class_name Bullet
extends Node2D

var velocity: Vector2 = Vector2.ZERO  # pixels per tick, set by the ship when it fires

func _physics_process(_delta: float) -> void:
	position += velocity
	# Off one edge, back on the opposite one, like everything in Asteroids.
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)

func _draw() -> void:
		draw_circle(Vector2.ZERO, 1.0, Color.WHITE)  # a dot, like the arcade's zero-length line
