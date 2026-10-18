extends Node2D

# Temporary values until I scale the arcade's numbers to the window.
const TURN_SPEED: float = 4.0	# degrees of rotation per tick
const THRUST: float = 0.1		# pixels per tick, added each tick 'Up' is held
const DRAG: float = 0.99		# speed kept each tick when not thrusting
const MAX_SPEED: float = 8.0	# top speed on x and on y, in pixels per tick

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
	print("drawing", ticks)  # temporary: shows how often _draw runs
	# The nose points right because a rotation of 0 faces right.
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-8, -8), Vector2(12, 0), Vector2(-8, 8)])
	draw_polyline(outline, Color.WHITE)
	draw_line(Vector2(-3, -6), Vector2(-3, 6), Color.WHITE) # crossbar at the back
	if flame_on:
		var flame: PackedVector2Array = PackedVector2Array([Vector2(-3, -3), Vector2(-10, 0), Vector2(-3, 3)])
		draw_polyline(flame, Color.WHITE)
