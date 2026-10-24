# The player's ship: turning, thrust, drag, screen wrap, the flame and firing.
extends Node2D

# THRUST, DRAG and MAX_SPEED are the arcade's values, converted to pixels and 60 ticks a second
const TURN_SPEED: float = 4.33 # the arcade's turn speed: 3/256 of a turn per update, at 61.5 updates a second
const THRUST: float = 0.065 # reaches top speed in 2.08 s, like the arcade (pixels per tick, added each tick Up is held)
const DRAG: float = 0.996 # the arcade's x 127/128 every 2nd update (speed kept each tick when not thrusting)
const MAX_SPEED: float = 8.07 # the arcade's max speed: capped at $3F playfield units per update
const BULLET_SCENE: PackedScene = preload("res://bullet.tscn") # loaded with the script, so firing never waits for a file
const SHOT_SPEED: float = 8.07 # the arcade's 63 playfield units per update
const SHOT_MAX_SPEED: float = 14.22 # the arcade's cap of 111 playfield units per update
const MAX_SHOTS: int = 4 # the arcade has 4 slots for the player's shots
const SHOT_START: float = 11.9 # 95 playfield units ahead of the ship's centre
const SHIP_SIZE: float = 7.0 # the arcade adds 28 to a rock's size for the ship: 28 / 4 pixels

# Speed and direction, in pixels per tick. Outside any function,
# so the ship keeps drifting from one tick to the next.
var velocity: Vector2 = Vector2.ZERO
var thrusting: bool = false # true while Up is held
var ticks: int = 0 # counts every tick, like the arcade's frame counter
var flame_on: bool = false # whether _draw draws the flame

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("rotate_left"):
		rotation_degrees -= TURN_SPEED # anticlockwise
	if Input.is_action_pressed("rotate_right"):
		rotation_degrees += TURN_SPEED # clockwise
	ticks += 1
	thrusting = Input.is_action_pressed("thrust")
	# Flicker like the arcade: bit 2 of the count is on for 4 ticks, then off for 4.
	# _draw only runs when asked, so redraw whenever the flame changes.
	var flame_was_on: bool = flame_on
	flame_on = thrusting and (ticks & 4) != 0
	if flame_on != flame_was_on:
		queue_redraw()
	if thrusting:
		# Speed up in the direction the nose points. from_angle wants radians.
		velocity += Vector2.from_angle(rotation) * THRUST
		# Cap x and y separately, like the arcade, so diagonals are faster.
		velocity.x = clampf(velocity.x, -MAX_SPEED, MAX_SPEED)
		velocity.y = clampf(velocity.y, -MAX_SPEED, MAX_SPEED)
	else:
		# Drag only when not thrusting, like the arcade.
		velocity *= DRAG
	position += velocity
	# Off one edge, back on the opposite one.
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	# Like the arcade, a rock that touches the ship destroys it, and the rock is hit too.
	for rock: Rock in get_tree().get_nodes_in_group("rocks"):
		if rock.is_hit_by(position, SHIP_SIZE):
			rock.hit()
			queue_free()
			return
	# Fire once per press, if one of the 4 shot slots is free.
	if Input.is_action_just_pressed("fire") and get_tree().get_nodes_in_group("player_shots").size() < MAX_SHOTS:
		var bullet: Bullet = BULLET_SCENE.instantiate() as Bullet # a new copy of the shot scene
		bullet.position = position + Vector2.from_angle(rotation) * SHOT_START # ahead of the ship, like the arcade
		bullet.velocity = Vector2.from_angle(rotation) * SHOT_SPEED + velocity # plus the ship's speed, so shots fired forward go faster
		# Capped on x and y separately, like the ship's speed.
		bullet.velocity.x = clampf(bullet.velocity.x, -SHOT_MAX_SPEED, SHOT_MAX_SPEED)
		bullet.velocity.y = clampf(bullet.velocity.y, -SHOT_MAX_SPEED, SHOT_MAX_SPEED)
		get_parent().add_child(bullet) # into Main, so it flies on its own

func _draw() -> void:
	# The nose points right because a rotation of 0 faces right.
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-6, 4),    # crossbar, bottom end
		Vector2(-6, -4),   # crossbar, top end
		Vector2(-10, -8),  # top fin
		Vector2(14, 0),    # nose
		Vector2(-10, 8),   # bottom fin
		Vector2(-6, 4),    # back to the start, to close the outline
	])
	draw_polyline(outline, Color.WHITE)
	if flame_on:
		# From the crossbar out to a point behind the ship, and back.
		var flame: PackedVector2Array = PackedVector2Array([Vector2(-6, 4), Vector2(-14, 0), Vector2(-6, -4)])
		draw_polyline(flame, Color.WHITE)
