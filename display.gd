# The arcade's display: the score, drawn in its own digits, on top of the playfield.
extends Node2D

# Where the arcade puts the score: x 100, and 876 up its screen, which shows 10 units above the playfield.
const SCORE_AT: Vector2 = Vector2(100, 30)
const SCORE_SIZE: float = 2.0 # the arcade draws the score at twice the ROM's size: 16 x 24 per digit

var score: int = 0:
	set(value):
		score = value
		queue_redraw() # the score has changed, so draw it again

func _draw() -> void:
	# Like the arcade: the score is kept in tens, with a "0" drawn after it, so 0 shows as "00".
	# lpad puts spaces in front to make 5 places, so the score's right-hand end never moves.
	@warning_ignore("integer_division")
	var text: String = (str(score / 10) + "0").lpad(5)
	VectorFont.draw_text(self, text, SCORE_AT, SCORE_SIZE)
