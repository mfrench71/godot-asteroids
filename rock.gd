class_name Rock
extends Node2D

# The arcade's four rock shapes, from the vector ROM, with y flipped for Godot.
# A large rock is drawn at the ROM's own size: 64 pixels across.
const SHAPES: Array = [
	[Vector2(0, -16), Vector2(16, -32), Vector2(32, -16), Vector2(24, 0), Vector2(32, 16), Vector2(8, 32), Vector2(-16, 32), Vector2(-32, 16), Vector2(-32, -16), Vector2(-16, -32), Vector2(0, -16)],
	[Vector2(16, -8), Vector2(32, -16), Vector2(16, -32), Vector2(0, -24), Vector2(-16, -32), Vector2(-32, -16), Vector2(-24, 0), Vector2(-32, 16), Vector2(-16, 32), Vector2(-8, 24), Vector2(16, 32), Vector2(32, 8), Vector2(16, -8)],
	[Vector2(-16, 0), Vector2(-32, 8), Vector2(-16, 32), Vector2(0, 8), Vector2(0, 32), Vector2(16, 32), Vector2(32, 8), Vector2(32, -8), Vector2(16, -32), Vector2(-8, -32), Vector2(-32, -8), Vector2(-16, 0)],
	[Vector2(8, 0), Vector2(32, -8), Vector2(32, -16), Vector2(8, -32), Vector2(-16, -32), Vector2(-8, -16), Vector2(-32, -16), Vector2(-32, 8), Vector2(-16, 32), Vector2(8, 24), Vector2(16, 32), Vector2(32, 16), Vector2(8, 0)],
]

var size: int = 2  # 2 large, 1 medium, 0 small

# Half the width of the area a shot has to land in, for each size: small, medium, large.
# The arcade's 42, 72 and 132 are halves of a distance in playfield units, so x 2 / 8 for pixels.
const HIT_SIZE: Array = [10.5, 18.0, 33.0]

@export_range(0, 3) var shape: int = 0  # which of the four shapes to draw

var velocity: Vector2 = Vector2.ZERO # pixels per tick, set by Main when the rock is made

func _ready() -> void:
	add_to_group("rocks")  # so shots can find every rock

# The arcade's hit test: a box with its corners cut off, an octagon, centred on the rock.
func is_hit_by(point: Vector2) -> bool:
	var dx: float = absf(point.x - position.x)
	var dy: float = absf(point.y - position.y)
	var h: float = HIT_SIZE[size]
	return dx <= h and dy <= h and dx + dy < h * 1.5

func _physics_process(_delta: float) -> void:
	position += velocity
	# Off one edge, back on the opposite one, like everything in Asteroids.
	var screen_size: Vector2 = get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)

func _draw() -> void:
	draw_polyline(PackedVector2Array(SHAPES[shape]), Color.WHITE)
