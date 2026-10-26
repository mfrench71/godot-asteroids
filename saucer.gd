# The flying saucer: large or small. Comes in from one side, wanders up and down, and leaves at the other.
class_name Saucer
extends Node2D

# The arcade's saucer outline, from the vector ROM, with y flipped for Godot.
# 80 across at the ROM's own size; the arcade draws it at half (large) or a quarter (small).
const OUTLINE: Array = [
	Vector2(-40, 8),
	Vector2(-16, 24),
	Vector2(16, 24),
	Vector2(40, 8),
	Vector2(16, -8),
	Vector2(8, -24),
	Vector2(-8, -24),
	Vector2(-16, -8),
	Vector2(-40, 8)
]

const SPEED: int = 16 # playfield units per update, like a rock's speed; 2 pixels
const TURNS: Array = [-SPEED, 0, 0, SPEED] # the arcade's table: up, level, level or down, picked at random
const TURN_TICKS: int = 125 # the arcade turns every 128 updates: 128 / 61.5 x 60

@export var small: bool = false # the arcade's two saucers: large (200 points) or small (1000)

var speed: Vector2i = Vector2i.ZERO # playfield units per update, like a rock's

func _ready() -> void:
	scale = Vector2.ONE * (0.25 if small else 0.5) # 20 or 40 pixels across; lines stay 1 pixel wide
	var screen_size: Vector2 = get_viewport_rect().size
	# Like the arcade: in at the left edge heading right, or at the right edge heading left.
	if randi_range(0, 1) == 0:
		position.x = 0.0
		speed.x = SPEED
	else:
		position.x = screen_size.x
		speed.x = -SPEED
	# A random row of 32 pixels. The arcade picks 0 to 31 but has only 24 rows, so AND 23 folds
	# 24-31 onto 16-23, making those rows twice as likely. y is flipped: row 0 is the bottom.
	var row: int = randi_range(0, 31)
	if row >= 24:
		row &= 23
	position.y = screen_size.y - row * 32.0

func _physics_process(_delta: float) -> void:
	# Like the arcade, a new up-or-down on the game's clock, not counted from when this saucer came.
	if Engine.get_physics_frames() % TURN_TICKS == 0:
		speed.y = TURNS[randi_range(0, 3)]
	position += Vector2(speed) / 8.0 * 61.5 / 60.0 # units per update to pixels per tick, like Main's to_pixels
	var screen_size: Vector2 = get_viewport_rect().size
	position.y = wrapf(position.y, 0.0, screen_size.y) # off the top, back on the bottom, and the other way
	if position.x < 0.0 or position.x > screen_size.x:
		queue_free() # off the left or right edge: this saucer has gone

func _draw() -> void:
	draw_polyline(PackedVector2Array(OUTLINE), Color.WHITE) # the outline, joined end to end
	draw_line(Vector2(-40, 8), Vector2(40, 8), Color.WHITE) # the line across the middle
	draw_line(Vector2(-16, -8), Vector2(16, -8), Color.WHITE) # the line under the dome
