extends Node2D

const TURN_SPEED: float = 4.0
const THRUST: float = 0.1
const DRAG: float = 0.99
const MAX_SPEED: float = 8.0

var velocity: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("rotate_left"):
		rotation_degrees -= TURN_SPEED
	if Input.is_action_pressed("rotate_right"):
		rotation_degrees += TURN_SPEED
	if Input.is_action_pressed("thrust"):
		velocity += Vector2.from_angle(rotation) * THRUST
		velocity.x = clampf(velocity.x, -MAX_SPEED, MAX_SPEED)
		velocity.y = clampf(velocity.y, -MAX_SPEED, MAX_SPEED)
	else:
		velocity *= DRAG
	position += velocity
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)

func _draw() -> void:
	var outline: PackedVector2Array = PackedVector2Array([Vector2(-8, -8), Vector2(12, 0), Vector2(-8, 8)])
	draw_polyline(outline, Color.WHITE)
	draw_line(Vector2(-3, -6), Vector2(-3, 6), Color.WHITE)
