class_name Bullet
extends Node2D

const LIFETIME: int = 70  # the arcade's 18 steps, one every 4th update: 72 updates, 1.17 seconds

var velocity: Vector2 = Vector2.ZERO  # pixels per tick, set by the ship when it fires
var ticks_left: int = LIFETIME

func _ready() -> void:
	add_to_group("player_shots")  # so the ship can count its shots

func _physics_process(_delta: float) -> void:
	ticks_left -= 1
	if ticks_left <= 0:
		queue_free()
		return
	position += velocity
	# Off one edge, back on the opposite one, like everything in Asteroids.
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	# Like the arcade, a shot can hit one rock, and both go.
	for rock: Rock in get_tree().get_nodes_in_group("rocks"):
		if rock.is_hit_by(position):
			rock.queue_free()
			queue_free()
			return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)  # a dot, like the arcade's zero-length line
