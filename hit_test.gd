# The arcade's hit test, shared by everything that can be hit: rocks, the saucer and the ship.
class_name HitTest

# True when point is inside an octagon centred on centre: a box reaching h each way, with its corners cut off.
static func octagon(point: Vector2, centre: Vector2, h: float) -> bool:
	var dx: float = absf(point.x - centre.x)
	var dy: float = absf(point.y - centre.y)
	return dx <= h and dy <= h and dx + dy < h * 1.5
