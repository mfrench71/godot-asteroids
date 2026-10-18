extends Node2D

# THRUST, DRAG and MAX_SPEED are the arcade's values, converted to pixels and 60 ticks a second
const TURN_SPEED: float = 4.33	# the arcade's turn speed: 3/256 of a turn per update, at 61.5 updates a second
const THRUST: float = 0.065		# reaches top speed in 2.08 s, like the arcade (pixels per tick, added each tick Up is held)
const DRAG: float = 0.996		# the arcade's x 127/128 every 2nd update (speed kept each tick when not thrusting)
const MAX_SPEED: float = 8.07	# the arcade's max speed: capped at $3F playfield units per update

# Speed and direction, in pixels per tick. Outside any function,
# so the ship keeps drifting from one tick to the next.
var velocity: Vector2 = Vector2.ZERO
var thrusting: bool = false
var ticks: int = 0 # counts every tick, like the arcade's frame counter
var flame_on: bool = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("rotate_left"):
		rotation_degrees -= TURN_SPEED
	if Input.is_action_pressed("rotate_right"):
		rotation_degrees += TURN_SPEED	
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

func _draw() -> void:
	# The nose points right because a rotation of 0 faces right.
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-6, 4), Vector2(-6, -4), Vector2(-10, -8), Vector2(14, 0), Vector2(-10, 8), Vector2(-6, 4)])
	draw_polyline(outline, Color.WHITE)
	if flame_on:
		var flame: PackedVector2Array = PackedVector2Array([Vector2(-6, 4), Vector2(-14, 0), Vector2(-6, -4)])
		draw_polyline(flame, Color.WHITE)
