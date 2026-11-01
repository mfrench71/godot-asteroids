# The arcade's lettering, from the vector ROM: every character is 8 wide, 12 tall, and 12 apart.
# Each character is a list of strokes, each stroke a line through its points, with y flipped for Godot.
# The baseline is y = 0, so the characters go up from it.
class_name VectorFont

const ADVANCE: float = 12.0 # the arcade moves 12 units right after every character

const GLYPHS: Dictionary = {
	"0": [[Vector2(0, 0), Vector2(0, -12), Vector2(8, -12), Vector2(8, 0), Vector2(0, 0)]],
	"1": [[Vector2(4, 0), Vector2(4, -12)]],
	"2": [[Vector2(0, -12), Vector2(8, -12), Vector2(8, -6), Vector2(0, -6), Vector2(0, 0), Vector2(8, 0)]],
	"3": [[Vector2(0, 0), Vector2(8, 0), Vector2(8, -12), Vector2(0, -12)], [Vector2(0, -6), Vector2(8, -6)]],
	"4": [[Vector2(0, -12), Vector2(0, -6), Vector2(8, -6)], [Vector2(8, -12), Vector2(8, 0)]],
	"5": [[Vector2(0, 0), Vector2(8, 0), Vector2(8, -6), Vector2(0, -6), Vector2(0, -12), Vector2(8, -12)]],
	"6": [[Vector2(0, -6), Vector2(8, -6), Vector2(8, 0), Vector2(0, 0), Vector2(0, -12)]],
	"7": [[Vector2(0, -12), Vector2(8, -12), Vector2(8, 0)]],
	"8": [[Vector2(0, 0), Vector2(8, 0), Vector2(8, -12), Vector2(0, -12), Vector2(0, 0)], [Vector2(0, -6), Vector2(8, -6)]],
	"9": [[Vector2(8, 0), Vector2(8, -12), Vector2(0, -12), Vector2(0, -6), Vector2(8, -6)]],
	# Letters, so far only the ones the game uses. The rest come when messages need them.
	"A": [[Vector2(0, 0), Vector2(0, -8), Vector2(4, -12), Vector2(8, -8), Vector2(8, 0)], [Vector2(0, -4), Vector2(8, -4)]],
	"E": [[Vector2(8, -12), Vector2(0, -12), Vector2(0, 0), Vector2(8, 0)], [Vector2(0, -6), Vector2(6, -6)]],
	"G": [[Vector2(8, -8), Vector2(8, -12), Vector2(0, -12), Vector2(0, 0), Vector2(8, 0), Vector2(8, -4), Vector2(4, -4)]],
	"M": [[Vector2(0, 0), Vector2(0, -12), Vector2(4, -8), Vector2(8, -12), Vector2(8, 0)]],
	"O": [[Vector2(0, 0), Vector2(0, -12), Vector2(8, -12), Vector2(8, 0), Vector2(0, 0)]], # the same lines as "0", like the arcade
	"R": [[Vector2(0, 0), Vector2(0, -12), Vector2(8, -12), Vector2(8, -6), Vector2(0, -6)], [Vector2(2, -6), Vector2(8, 0)]],
	"V": [[Vector2(0, -12), Vector2(4, 0), Vector2(8, -12)]],
}

# Draws text with its first character's bottom-left corner at, size times the ROM's own size.
# Only works from inside canvas's _draw, like any draw_ call. Characters with no strokes, such as a space, are gaps.
static func draw_text(canvas: CanvasItem, text: String, at: Vector2, size: float) -> void:
	for i in text.length():
		var corner: Vector2 = at + Vector2(i * ADVANCE * size, 0)
		for stroke: Array in GLYPHS.get(text[i], []):
			var points: PackedVector2Array = PackedVector2Array()
			for point: Vector2 in stroke:
				points.append(corner + point * size)
			canvas.draw_polyline(points, Color.WHITE)
