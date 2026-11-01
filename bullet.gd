# One player shot: flies straight, wraps, hits a rock or saucer, and lasts about 1.17 seconds.
class_name Bullet
extends Node2D

const LIFETIME: int = 70 # the arcade's 18 steps, one every 4th update: 72 updates, 1.17 seconds
const SPEED: float = 8.07 # the arcade's 63 playfield units per update
const MAX_SPEED: float = 14.22 # the arcade's cap of 111 playfield units per update
const AHEAD: float = 11.9 # starts 95 playfield units ahead of whoever fired it

var velocity: Vector2 = Vector2.ZERO # pixels per tick, set by launch()
var ticks_left: int = LIFETIME # counts down to 0, then the shot is removed

func _ready() -> void:
	add_to_group("player_shots") # so the ship can count its shots

# Sets up a new shot the way the arcade sets up every shot, the player's or the saucer's:
# a little ahead of whoever fired it, at the shot speed plus their own speed, capped on x and y.
func launch(from: Vector2, angle: float, base_velocity: Vector2) -> void:
	var direction: Vector2 = Vector2.from_angle(angle)
	position = from + direction * AHEAD
	velocity = direction * SPEED + base_velocity
	velocity.x = clampf(velocity.x, -MAX_SPEED, MAX_SPEED)
	velocity.y = clampf(velocity.y, -MAX_SPEED, MAX_SPEED)

func _physics_process(_delta: float) -> void:
	ticks_left -= 1
	if ticks_left <= 0:
		queue_free() # gone at the end of this tick
		return # so a removed shot doesn't move again
	position += velocity
	# Off one edge, back on the opposite one, like everything in Asteroids.
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	# Like the arcade, a shot checks the saucer before the rocks.
	for saucer: Saucer in get_tree().get_nodes_in_group("saucers"):
		if saucer.is_hit_by(position):
			saucer.hit()
			queue_free()
			return
	# Like the arcade, a shot can hit one rock, and both go.
	for rock: Rock in get_tree().get_nodes_in_group("rocks"):
		if rock.is_hit_by(position):
			rock.hit()
			queue_free()
			return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE) # a dot, like the arcade's zero-length line
