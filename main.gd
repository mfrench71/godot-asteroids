# Main: the playfield. Starts the first wave of rocks.
extends Node2D

const ROCK_SCENE: PackedScene = preload("res://rock.tscn") # loaded with the script, so making a rock never waits for a file
const FIRST_WAVE: int = 4 # the arcade starts with 2 rocks per wave and adds 2 before the first

func _ready() -> void:
	for i in FIRST_WAVE: # runs FIRST_WAVE times; i isn't used
		spawn_rock()

func spawn_rock() -> void:
	var rock: Rock = ROCK_SCENE.instantiate() as Rock
	rock.shape = randi_range(0, 3) # every new rock is large, with a random shape
	# Like the arcade, start somewhere along the left edge or the top edge.
	var screen_size: Vector2 = get_viewport_rect().size
	if randi_range(0, 1) == 0:
		rock.position = Vector2(0.0, randf_range(0.0, screen_size.y))
	else:
		rock.position = Vector2(randf_range(0.0, screen_size.x), 0.0)
	rock.velocity = Vector2(random_speed(), random_speed())
	add_child(rock) # a child of Main, like the shots

# One axis of the arcade's random rock speed: 6 to 15 playfield units per update, either way.
func random_speed() -> float:
	var units: int = randi_range(-16, 15)
	if units >= 0:
		units = maxi(units, 6)
	else:
		units = mini(units, -6)
	return units / 8.0 * 61.5 / 60.0 # playfield units per update to pixels per tick
