# The arcade's display: the score and best score, drawn in its own digits, lives displayed as ships, its messages and the high score table, on top of the playfield.
extends Node2D

# Where the arcade puts the score: x 100, and 876 up its screen, which shows 10 units above the playfield.
const SCORE_AT: Vector2 = Vector2(100, 30)
const TEXT_SIZE: float = 2.0 # the arcade draws the score and its messages at twice the ROM's size: 16 x 24 per character
# Where the arcade starts the row of ships: x 160, and 852 up its screen.
const LIVES_AT: Vector2 = Vector2(160, 54)
const LIVES_GAP: float = 16.0 # each ship 16 to the right of the last, so their fins touch
# The arcade's spare ship, from the vector ROM: the ship's own outline, turned to point up.
const SHIP_ICON: Array = [Vector2(-4, 6), Vector2(4, 6), Vector2(8, 10), Vector2(0, -14), Vector2(-8, 10), Vector2(-4, 6)]
# Where the arcade writes each message, from its table at $7871: x, and 906 - its y.
const MESSAGES: Dictionary = {
	"PUSH START": Vector2(400, 114),
	"GAME OVER": Vector2(400, 278),
	"PLAYER 1": Vector2(400, 178),
	"HIGH SCORES": Vector2(400, 178),
}
# Where the arcade puts the best score: x 480, at the same height as the score, and at the ROM's own size.
const TOP_SCORE_AT: Vector2 = Vector2(480, 30)
const TOP_SCORE_SIZE: float = 1.0
# Where the arcade starts the table: x 380, 668 up its screen, and each row 32 lower.
const TABLE_AT: Vector2 = Vector2(380, 238)
const TABLE_GAP: float = 32.0

var score: int = 0:
	set(value):
		score = value
		queue_redraw() # the score has changed, so draw it again

var top_score: int = 0:
	set(value):
		top_score = value
		queue_redraw() # a new best score, so draw it again

var lives: int = 0:
	set(value):
		lives = value
		queue_redraw() # one ship more or fewer

var message: String = "":
	set(value):
		message = value
		queue_redraw() # show the new message, or none

var high_scores: Array[int] = [] # Main's arrays, set in its _ready
var high_initials: Array[String] = []

var table_shown: bool = false:
	set(value):
		table_shown = value
		queue_redraw() # the table comes or goes

func _draw() -> void:
	VectorFont.draw_text(self, score_text(score), SCORE_AT, TEXT_SIZE)
	VectorFont.draw_text(self, score_text(top_score), TOP_SCORE_AT, TOP_SCORE_SIZE) # always shown, like the arcade
	# One little ship for each life, counting the one in play, like the arcade.
	for i in lives:
		draw_set_transform(LIVES_AT + Vector2(i * LIVES_GAP, 0)) # draw this one from here
		draw_polyline(PackedVector2Array(SHIP_ICON), Color.WHITE)
	draw_set_transform(Vector2.ZERO) # back to normal, for anything drawn after
	if message != "":
		VectorFont.draw_text(self, message, MESSAGES[message], TEXT_SIZE)
	if table_shown:
		VectorFont.draw_text(self, "HIGH SCORES", MESSAGES["HIGH SCORES"], TEXT_SIZE)
		# Each row like " 1 12340 ABC": the place, the score and the initials, like the arcade.
		for i in high_scores.size():
			if high_scores[i] == 0:
				break # the arcade stops at the first empty place
			var row: String = str(i + 1).lpad(2) + " " + score_text(high_scores[i]) + " " + high_initials[i]
			VectorFont.draw_text(self, row, TABLE_AT + Vector2(0, i * TABLE_GAP), TEXT_SIZE)

# A score as the arcade writes it: kept in tens, with a "0" drawn after, so 0 shows as "00".
# lpad puts spaces in front to make 5 places, so the right-hand end never moves.
func score_text(points: int) -> String:
	@warning_ignore("integer_division")
	return (str(points / 10) + "0").lpad(5)
