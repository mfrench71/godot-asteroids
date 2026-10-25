# Main: the playfield. Starts each wave of rocks, and keeps the score and lives.
extends Node2D

const ROCK_SCENE: PackedScene = preload("res://rock.tscn") # loaded with the script, so making a rock never waits for a file
const MAX_ROCKS: int = 11 # the arcade never starts a wave with more than 11 rocks
const POINTS: Array = [100, 50, 20] # the arcade's points for a small, medium and large rock
const START_LIVES: int = 3 # the arcade starts with 3 or 4 ships, set by a DIP switch
const WAVE_TICKS: int = 124 # the arcade waits 127 updates after the last rock: 127 / 61.5 x 60

var score: int = 0 # points this game, added from POINTS for every rock hit
var lives: int = START_LIVES # ships left, counting the one in play
var rocks_per_wave: int = 2 # like the arcade: starts at 2, and 2 are added before every wave
var wave_ticks: int = 0 # counts down to the next wave; 0 when no wave is waiting

func _ready() -> void:
	start_wave()
	update_display()

# Waits WAVE_TICKS after the last rock has gone, then starts the next wave.
func _physics_process(_delta: float) -> void:
	if wave_ticks > 0:
		wave_ticks -= 1
		if wave_ticks == 0:
			start_wave()
	elif get_tree().get_nodes_in_group("rocks").is_empty():
		wave_ticks = WAVE_TICKS # the last rock has gone: start the countdown

# A new wave of large rocks: 2 more than last time, like the arcade, up to MAX_ROCKS.
func start_wave() -> void:
	rocks_per_wave += 2
	rocks_per_wave = mini(rocks_per_wave, MAX_ROCKS)
	for i in rocks_per_wave: # runs rocks_per_wave times; i isn't used
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
	rock.speed = Vector2i(random_speed(0), random_speed(0))
	rock.velocity = to_pixels(rock.speed)
	add_child(rock) # a child of Main, like the shots
	rock.destroyed.connect(_on_rock_destroyed) # runs each time this rock is hit

# A hit rock scores its points, then splits into two of the next size down, like the arcade. Small ones just go.
func _on_rock_destroyed(rock: Rock) -> void:
	var before: int = score
	score += POINTS[rock.size]
	# Like the arcade, an extra ship each time the score passes another 10,000.
	# Dividing ints drops the fraction, which is the point here: it counts whole 10,000s.
	@warning_ignore("integer_division")
	if score / 10000 > before / 10000:
		lives += 1
	update_display()
	if rock.size == 0:
		return # a small rock leaves nothing behind
	for i in 2: # i isn't used
		var child: Rock = ROCK_SCENE.instantiate() as Rock
		child.size = rock.size - 1 # large to medium, medium to small
		child.shape = randi_range(0, 3)
		child.position = rock.position # starts where the old rock was
		child.speed = Vector2i(random_speed(rock.speed.x), random_speed(rock.speed.y))
		child.velocity = to_pixels(child.speed)
		add_child(child)
		child.destroyed.connect(_on_rock_destroyed) # so the child can split too

# One axis of a rock's speed, in playfield units per update: base plus -16 to 15, kept 6 to 31 either way, like the arcade.
func random_speed(base: int) -> int:
	var units: int = base + randi_range(-16, 15)
	if units >= 0:
		units = clampi(units, 6, 31)
	else:
		units = clampi(units, -31, -6)
	return units

# Playfield units per update to pixels per tick.
func to_pixels(speed: Vector2i) -> Vector2:
	return Vector2(speed) / 8.0 * 61.5 / 60.0

# Runs when the Ship's destroyed signal fires (connected in the editor, saved in main.tscn).
func _on_ship_destroyed() -> void:
	lives -= 1
	update_display()
	if lives == 0:
		$GameOverLabel.visible = true # hidden in main.tscn until the last ship goes
		$Ship.set_physics_process(false) # stops the ship's script, so it never comes back

# Shows the score and lives on screen.
func update_display() -> void:
	$ScoreLabel.text = str(score)
	$LivesLabel.text = "Lives: " + str(lives)
