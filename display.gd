# The arcade's display: the score, drawn in its own digits, and lives displayed as ships, on top of the playfield.
extends Node2D

# Where the arcade puts the score: x 100, and 876 up its screen, which shows 10 units above the playfield.
const SCORE_AT: Vector2 = Vector2(100, 30)
const SCORE_SIZE: float = 2.0 # the arcade draws the score at twice the ROM's size: 16 x 24 per digit
# Where the arcade starts the row of ships: x 160, and 852 up its screen.
const LIVES_AT: Vector2 = Vector2(160, 54)
const LIVES_GAP: float = 16.0 # each ship 16 to the right of the last, so their fins touch
# The arcade's spare ship, from the vector ROM: the ship's own outline, turned to point up.
const SHIP_ICON: Array = [Vector2(-4, 6), Vector2(4, 6), Vector2(8, 10), Vector2(0, -14), Vector2(-8, 10), Vector2(-4, 6)]

var score: int = 0:
	set(value):
		score = value
		queue_redraw() # the score has changed, so draw it again

var lives: int = 0:
	set(value):
		lives = value
		queue_redraw() # one ship more or fewer

func _draw() -> void:
	# Like the arcade: the score is kept in tens, with a "0" drawn after it, so 0 shows as "00".
	# lpad puts spaces in front to make 5 places, so the score's right-hand end never moves.
	@warning_ignore("integer_division")
	var text: String = (str(score / 10) + "0").lpad(5)
	VectorFont.draw_text(self, text, SCORE_AT, SCORE_SIZE)
	# One little ship for each life, counting the one in play, like the arcade.
	for i in lives:
		draw_set_transform(LIVES_AT + Vector2(i * LIVES_GAP, 0)) # draw this one from here
		draw_polyline(PackedVector2Array(SHIP_ICON), Color.WHITE)
	draw_set_transform(Vector2.ZERO) # back to normal, for anything drawn after
