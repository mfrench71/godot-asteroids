# Main: the playfield. Starts and ends each game, starts each wave of rocks, shows the saucers, and keeps the score, lives and high scores, and saves the table.
extends Node2D

const ROCK_SCENE: PackedScene = preload("res://rock.tscn") # loaded with the script, so making a rock never waits for a file
const EXPLOSION_SCENE: PackedScene = preload("res://explosion.tscn") # like ROCK_SCENE, loaded with the script
const SAUCER_SCENE: PackedScene = preload("res://saucer.tscn") # like ROCK_SCENE, loaded with the script
const MAX_ROCKS: int = 11 # the arcade never starts a wave with more than 11 rocks
const POINTS: Array = [100, 50, 20] # the arcade's points for a small, medium and large rock
const START_LIVES: int = 3 # the arcade starts with 3 or 4 ships, set by a DIP switch
const WAVE_TICKS: int = 124 # the arcade waits 127 updates after the last rock: 127 / 61.5 x 60
const ROCK_HIT_WAIT: int = 80 # the arcade's $50: a saucer comes once no rock has been hit for this long
const SAUCER_RETRY: int = 18 # the arcade's $12: when it isn't time for a saucer, look again after this many
const START_TICKS: int = 125 # the arcade shows PLAYER 1 for 128 updates before the ship comes: 128 / 61.5 x 60
const GAME_OVER_TICKS: int = 189 # the arcade ends the game once the last explosion is over: 194 updates after the hit, 194 / 61.5 x 60
const HIGH_SCORES: int = 10 # the arcade keeps the ten best scores
const TABLE_SECONDS: float = 16.65 # the arcade swaps the table and the rocks every 1024 updates: 1024 / 61.5
# Everything that flies about the playfield, by group: start_game empties them, and the table and the initials freeze them.
const PLAYFIELD_GROUPS: Array = ["rocks", "explosions", "saucers", "saucer_explosions", "player_shots", "saucer_shots"]
const LETTERS: String = " ABCDEFGHIJKLMNOPQRSTUVWXYZ" # the arcade's choices for an initial, in order: a space, then A to Z
const LETTER_TICKS: int = 8 # rotate held down steps the letter every 8 updates, like the arcade
const HYPERSPACE_HOLD: int = 3 # hyperspace accepts a letter once held for 3 updates, like the arcade
const FIRST_LETTER_SECONDS: float = 66.6 # the arcade's time for the first initial: 4096 updates / 61.5
const NEXT_LETTER_SECONDS: float = 50.0 # and for each one after: 3072 updates / 61.5
const SAVE_PATH: String = "user://high_scores.cfg" # user:// is a folder Godot gives the game for its own files
const THUMP_START_GAP: int = 48 # the arcade's $30: updates between beats at the start of each wave
const THUMP_MIN_GAP: int = 8 # the shortest gap the arcade allows
const THUMP_TICKS: int = 4 # each beat is on for 4 updates
const LIFE_TICKS: int = 88 # the arcade's $B0 (176), counted down twice an update: about 1.4 seconds of beeping
const SHIP_FIRE: int = 0 # which fire circuit, as the arcade's X register picks them
const SAUCER_FIRE: int = 1
const FIRE_TICKS: int = 16 # the arcade's $10: updates a fire sound stays on
# The arcade's explosion pitches, indexed by Rock.size: small, medium, large. A bigger rock picks up its noise less often, so it sounds lower.
const EXPLOSION_DIVIDERS: Array[int] = [3, 5, 12]
const EXPLOSION_TICKS: int = 63 # the arcade's $3F: updates an explosion takes to fade away

var score: int = 0 # points this game: rocks score from POINTS, saucers 200 or 1000
var lives: int = 0 # ships left, counting the one in play; none until a game starts
var rocks_per_wave: int = 2 # like the arcade: starts at 2, and 2 are added before every wave
var wave_ticks: int = 0 # counts down to the next wave; 0 when no wave is waiting
# The saucer's timers, like the arcade's: they count once every 4 ticks (see _physics_process).
var saucer_time_reload: int = 146 # the wait after each saucer: 6 less each time, but never below 32
var saucer_timer: int = 0 # counts down to the next chance of a saucer; set by start_wave
var max_rocks_for_ufo: int = 5 # fewer rocks than this also brings a saucer: 1 more each wave, up to 10
var rock_hit_timer: int = 0 # set to ROCK_HIT_WAIT by every rock hit, counts down to 0
var playing: bool = false # true while a game is on; false in attract mode, when there's no ship
var start_ticks: int = 0 # counts down while PLAYER 1 shows; 0 the rest of the time
var game_over_ticks: int = 0 # counts down while GAME OVER shows; 0 the rest of the time
var high_scores: Array[int] = [] # the ten best scores, best first; 0 is an empty place
var high_initials: Array[String] = [] # the initials for each place in high_scores
var showing_table: bool = false # true while attract mode shows the high score table instead of the rocks
var playfield_frozen: bool = false # true while the table or the initials hide the rocks and saucers
var entering: int = -1 # the place in the table whose initials are being entered; -1 when none
var letter: int = 0 # which of the three initials is being chosen: 0, 1 or 2
var hyperspace_ticks: int = 0 # how long hyperspace has been held during entry
var thump_gap: int = THUMP_START_GAP # shrinks by 1 every 64 ticks, back to THUMP_START_GAP each wave
var thump_ticks: int = 0 # counts down to the next beat
var thump_low: bool = false # which of the two notes comes next
var life_ticks: int = 0 # counts down while the extra ship beeps
var fire_timers: Array[int] = [0, 0] # the arcade's fire timers: updates left, or -1 when a new shot wants its sound
var thump_on_ticks: int = 0 # counts down the 4 ticks a beat is on
var explosion_ticks: int = 0 # counts down while an explosion fades

func _ready() -> void:
	AudioServer.set_bus_mute(0, true) # silent until a game starts, like the arcade
	high_scores.resize(HIGH_SCORES) # ten places; a typed int array fills new places with 0
	high_initials.resize(HIGH_SCORES)
	high_initials.fill("   ") # three spaces: no initials yet, like the arcade
	load_high_scores()
	$Display.high_scores = high_scores # the same arrays, not copies, so the Display sees every new score
	$Display.high_initials = high_initials
	start_wave()
	update_display()
	$Ship.visible = false # no ship until a game starts
	$Ship.set_physics_process(false)
	# Like the arcade, whose slow timer starts at 0 when it's switched on: the table's turn first, if there's a table.
	show_table(high_scores[0] > 0)
	$TableTimer.start(TABLE_SECONDS)
	$Ship.fired.connect(start_fire_sound.bind(SHIP_FIRE)) # bind adds the circuit number when the signal calls it

# Starts a game when start is pressed and counts PLAYER 1 down, then waits WAVE_TICKS after the last rock and explosion have gone before the next wave.
# Handles the GAME OVER countdown.
func _physics_process(_delta: float) -> void:
	if playing:
		heartbeat()
		update_fire_sound(SHIP_FIRE)
		update_fire_sound(SAUCER_FIRE)
		update_saucer_sound()
		update_explosion_sound()
		update_thrust_sound()
	update_life_sound()
	if not playing and Input.is_action_just_pressed("start"):
		start_game()
	if start_ticks > 0:
		start_ticks -= 1
		if start_ticks == 0:
			$Display.message = "" # PLAYER 1 goes as the ship comes in
	if entering >= 0:
		enter_initials()
	if game_over_ticks > 0:
		game_over_ticks -= 1
		if game_over_ticks == 0:
			end_game()
	if wave_ticks > 0:
		wave_ticks -= 1
		if wave_ticks == 0:
			start_wave()
	elif get_tree().get_nodes_in_group("rocks").is_empty() and get_tree().get_nodes_in_group("explosions").is_empty():
		wave_ticks = WAVE_TICKS # the last rock and explosion have gone: start the countdown
	# Like the arcade, the saucer's timers count every 4th tick while there's no saucer, the ship is in play or no game is on, and the playfield isn't frozen.
	if Engine.get_physics_frames() % 4 == 0 and (not playing or $Ship.visible) and no_saucer() and not playfield_frozen:
		count_to_saucer()

# Starts a game from attract mode, like the arcade: the screen emptied, the score and ships reset,
# then PLAYER 1 while the first wave and the ship wait.
func start_game() -> void:
	thump_low = false # every game's first beat is the low note, like the arcade's
	explosion_ticks = 0 # an explosion set going in attract mode, where the sound routine never runs, mustn't play at START
	fire_timers.fill(0) # a saucer shot asked for its sound in attract mode, where the routine never runs, so clear it
	AudioServer.set_bus_mute(0, false)
	playing = true
	if entering >= 0: # START during entry ends it, with the initials as they stand, like the arcade
		entering = -1
		$EntryTimer.stop()
		$Display.initials = ""
		save_high_scores() # with the initials chosen so far
	$TableTimer.stop()
	show_table(false) # the table goes, if it was up
	# Everything left from attract mode goes. The arcade empties all its slots.
	for group: String in PLAYFIELD_GROUPS:
		for node: Node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	score = 0
	lives = START_LIVES
	update_display()
	rocks_per_wave = 2 # start_wave adds 2, so the first wave is 4, like the arcade
	wave_ticks = WAVE_TICKS # the first wave comes as PLAYER 1 goes
	saucer_time_reload = 146 # the arcade's $92, as at the start
	max_rocks_for_ufo = 5
	$Display.message = "PLAYER 1"
	start_ticks = START_TICKS
	$Ship.respawn_ticks = START_TICKS # the ship comes in when PLAYER 1 goes, if the middle is clear
	$Ship.set_physics_process(true)

# Back to attract mode, like the arcade once the last explosion has gone: GAME OVER goes, the score is checked for the table,
# and the last score stays on screen. A score that makes the table brings up the initials; otherwise PUSH START flashes again.
func end_game() -> void:
	$SoundBoard.all_off() # the arcade turns every circuit off when a game ends
	AudioServer.set_bus_mute(0, true) # the arcade turns every sound off when a game ends
	life_ticks = 0 # the arcade clears the extra ship timer with every other sound
	explosion_ticks = 0
	playing = false
	var place: int = check_high_score()
	update_display()
	# A saucer still flying fires without waiting for the ship from now on, as it would in attract mode.
	for saucer: Saucer in get_tree().get_nodes_in_group("saucers"):
		saucer.playing = false
	if place >= 0:
		save_high_scores() # the score is kept, even if the game is closed during entry
		start_entry(place)
	else:
		$Display.message = "PUSH START"
		# The arcade shows the rocks until its slow timer next ticks over, 1 to 256 updates away, then the table.
		$TableTimer.start(randi_range(1, 256) / 61.5)

# Like the arcade at the end of a game: the score goes in above the first entry it beats, and the rest move down one.
# It has to beat it, so a tie goes below and a score of 0 never goes in. Returns the place, or -1 if it didn't go in.
func check_high_score() -> int:
	for i in HIGH_SCORES:
		if score > high_scores[i]:
			high_scores.insert(i, score)
			high_initials.insert(i, "A  ") # the arcade starts the initials at "A", then 2 blanks
			# insert made 11: the last one drops off the end.
			high_scores.resize(HIGH_SCORES)
			high_initials.resize(HIGH_SCORES)
			return i # one place only
	return -1

# Writes the table to SAVE_PATH, so it's still there next time. The arcade keeps it in RAM, and loses it at power off.
func save_high_scores() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("high_scores", "scores", high_scores)
	config.set_value("high_scores", "initials", high_initials)
	var error: Error = config.save(SAVE_PATH)
	if error != OK:
		push_warning("Couldn't save the high scores: " + error_string(error))

# Reads the table back from SAVE_PATH, if there is one. The first time the game runs there isn't, so the table stays empty.
func load_high_scores() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return # no file yet: the table starts empty, like the arcade's at power on
	# assign copies the values into the arrays the Display already shares, rather than making new ones.
	high_scores.assign(config.get_value("high_scores", "scores", high_scores))
	high_initials.assign(config.get_value("high_scores", "initials", high_initials))
	# In case the file was changed by hand: the table is always ten long.
	high_scores.resize(HIGH_SCORES)
	high_initials.resize(HIGH_SCORES)

# The arcade's entry screen: the playfield frozen, no PUSH START, and the first initial set to "A".
func start_entry(place: int) -> void:
	entering = place
	letter = 0
	hyperspace_ticks = 0
	$Display.message = ""
	$Display.initials = high_initials[entering]
	freeze_playfield(true)
	$EntryTimer.start(FIRST_LETTER_SECONDS)

# Runs every tick during entry: rotate steps the letter, hyperspace accepts it.
func enter_initials() -> void:
	var initials: String = high_initials[entering] # a copy: written back below
	if Engine.get_physics_frames() % LETTER_TICKS == 0:
		var index: int = LETTERS.find(initials[letter])
		if Input.is_action_pressed("rotate_left"):
			index += 1
		elif Input.is_action_pressed("rotate_right"):
			index -= 1
		initials[letter] = LETTERS[posmod(index, LETTERS.length())] # past Z comes the space, and before it, Z
	# Like the arcade, a letter is only accepted once hyperspace has been held a moment, so a quick tap doesn't count.
	if Input.is_action_pressed("hyperspace"):
		hyperspace_ticks += 1
	else:
		hyperspace_ticks = 0
	if hyperspace_ticks == HYPERSPACE_HOLD:
		letter += 1
		if letter == 3:
			high_initials[entering] = initials
			end_entry()
			return
		initials[letter] = "A" # each new initial starts at "A", like the arcade
		$EntryTimer.start(NEXT_LETTER_SECONDS)
	high_initials[entering] = initials
	$Display.initials = initials

# Entry is over: the arcade shows the table at once, with the new initials in it.
func end_entry() -> void:
	entering = -1
	save_high_scores() # with the new initials
	$EntryTimer.stop()
	$Display.initials = ""
	$Display.message = "PUSH START"
	show_table(true)
	$TableTimer.start(TABLE_SECONDS)

# Runs when the EntryTimer runs out: entry ends with the initials as they are, like the arcade.
func _on_entry_timer_timeout() -> void:
	end_entry()

# Swaps between the table and the rocks, like the arcade's attract mode. The table only shows if a score has gone in.
func _on_table_timer_timeout() -> void:
	show_table(not showing_table and high_scores[0] > 0)
	$TableTimer.start(TABLE_SECONDS)

# Shows or hides the table. While it shows, the playfield is frozen, like the arcade.
func show_table(shown: bool) -> void:
	showing_table = shown
	$Display.table_shown = shown
	freeze_playfield(shown)

# Hides and stops everything on the playfield, or lets it all carry on, like the arcade,
# which skips drawing and moving the rocks and saucers while the table or the initials show.
func freeze_playfield(frozen: bool) -> void:
	playfield_frozen = frozen
	for group: String in PLAYFIELD_GROUPS:
		for node: Node2D in get_tree().get_nodes_in_group(group):
			freeze(node, frozen)

# Hides a node and stops its scripts, or shows it and lets it carry on from where it stopped.
func freeze(node: Node2D, frozen: bool) -> void:
	node.visible = not frozen
	node.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT

# A new wave of large rocks: 2 more than last time, like the arcade, up to MAX_ROCKS.
func start_wave() -> void:
	thump_gap = THUMP_START_GAP # like the arcade: every wave starts slow
	rocks_per_wave += 2
	rocks_per_wave = mini(rocks_per_wave, MAX_ROCKS)
	for i in rocks_per_wave: # runs rocks_per_wave times; i isn't used
		spawn_rock()
	max_rocks_for_ufo += 1
	max_rocks_for_ufo = mini(max_rocks_for_ufo, 10)
	saucer_timer = 127 # the arcade's $7F: each wave waits a while before the first chance of a saucer

# Like the arcade's heartbeat: two notes taking turns, the gap between them shrinking as the wave goes on.
func heartbeat() -> void:
	if Engine.get_physics_frames() % 64 == 0 and thump_gap > THUMP_MIN_GAP:
		thump_gap -= 1
	# Silent with no rocks, or with the ship neither in play nor in hyperspace, like the arcade.
	var ship_here: bool = $Ship.visible or $Ship.hyperspace_ticks > 0
	if get_tree().get_nodes_in_group("rocks").is_empty() or not ship_here:
		thump_ticks = thump_gap # when it starts again, the first beat is a whole gap away
		thump_on_ticks = 0
		$SoundBoard.thump = false
		return
	thump_ticks -= 1
	if thump_ticks <= 0:
		thump_low = not thump_low
		$SoundBoard.thump_low = thump_low
		thump_ticks = THUMP_TICKS + thump_gap
		thump_on_ticks = THUMP_TICKS
	$SoundBoard.thump = thump_on_ticks > 0
	if thump_on_ticks > 0:
		thump_on_ticks -= 1

# A shot asks for its sound, like the arcade storing $80 in the circuit's timer.
func start_fire_sound(which: int) -> void:
	fire_timers[which] = -1

# The arcade's routine at $75CD, every update for each fire circuit. A new shot while the sound is on
# switches it off for one update, so the circuit starts its sweep again on the next.
func update_fire_sound(which: int) -> void:
	var on: bool = $SoundBoard.fire[which]
	if not on and fire_timers[which] < 0:
		fire_timers[which] = FIRE_TICKS
		on = true
	elif on and fire_timers[which] > 0:
		fire_timers[which] -= 1
		on = fire_timers[which] > 0
	else:
		on = false
	$SoundBoard.fire[which] = on

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
	freeze(rock, playfield_frozen) # a wave that comes while the playfield is frozen waits behind it, like the arcade

# A hit rock explodes, scores unless a saucer hit it, then splits into two of the next size down, like the arcade. Small ones just go.
func _on_rock_destroyed(rock: Rock, scored: bool) -> void:
	play_explosion(rock.size)
	rock_hit_timer = ROCK_HIT_WAIT # a rock was hit, even by the saucer: put off the saucer
	spawn_explosion(rock.position) # where the rock was
	if scored:
		add_score(POINTS[rock.size])
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

# One explosion, the same for a rock or a saucer. Returns it, for anything that needs to change it.
func spawn_explosion(at: Vector2) -> Explosion:
	var explosion: Explosion = EXPLOSION_SCENE.instantiate() as Explosion
	explosion.position = at
	add_child(explosion) # a child of Main, like the rocks
	return explosion

# Plays the explosion for a size. The arcade has one explosion circuit, so a new one cuts off the last.
func play_explosion(size: int) -> void:
	$SoundBoard.explosion_divider = EXPLOSION_DIVIDERS[size]
	explosion_ticks = EXPLOSION_TICKS

# Adds points, with an extra ship each time the score passes another 10,000, like the arcade.
func add_score(points: int) -> void:
	var before: int = score
	score += points
	# Dividing ints drops the fraction, which is the point here: it counts whole 10,000s.
	@warning_ignore("integer_division")
	if score / 10000 > before / 10000:
		lives += 1
		life_ticks = LIFE_TICKS
	update_display()

# Like the arcade: the extra ship tone is on while bit 2 of the tick count is set, so it beeps 4 ticks on and 4 off until life_ticks runs out.
func update_life_sound() -> void:
	$SoundBoard.life = life_ticks > 0 and (Engine.get_physics_frames() & 4) != 0
	if life_ticks > 0:
		life_ticks -= 1

# Counts down to the next chance of a saucer, and sends one if the arcade's rules say so.
func count_to_saucer() -> void:
	if rock_hit_timer > 0:
		rock_hit_timer -= 1
	saucer_timer -= 1
	if saucer_timer > 0:
		return
	saucer_timer = SAUCER_RETRY # if no saucer comes now, look again later
	var rocks: int = get_tree().get_nodes_in_group("rocks").size()
	# A saucer comes when no rock has been hit for a while, or when only a few rocks are left.
	if rock_hit_timer == 0 or (rocks > 0 and rocks < max_rocks_for_ufo):
		spawn_saucer()

# Like the arcade's one place for a saucer: empty when no saucer is flying and none is exploding.
func no_saucer() -> bool:
	return get_tree().get_nodes_in_group("saucers").is_empty() and get_tree().get_nodes_in_group("saucer_explosions").is_empty()

func spawn_saucer() -> void:
	# Each saucer brings the next one sooner, like the arcade, but never sooner than 32.
	if saucer_time_reload - 6 >= 32:
		saucer_time_reload -= 6
	var saucer: Saucer = SAUCER_SCENE.instantiate() as Saucer
	saucer.small = pick_small() # before add_child, so the saucer's _ready sees it
	saucer.ship = $Ship # so the saucer can check whether it hits the ship
	saucer.accurate = score >= 35000 # from 35,000 points, the small saucer's aim gets better
	saucer.playing = playing # in attract mode, it fires without waiting for the ship
	add_child(saucer) # the saucer picks its own side and height in _ready
	saucer.gone.connect(_on_saucer_gone)
	saucer.destroyed.connect(_on_saucer_destroyed)
	saucer.fired.connect(start_fire_sound.bind(SAUCER_FIRE))

# Like the arcade: the siren is on while a saucer is flying, in that saucer's tone.
func update_saucer_sound() -> void:
	var saucer: Saucer = get_tree().get_first_node_in_group("saucers") as Saucer
	$SoundBoard.saucer = saucer != null
	if saucer != null:
		$SoundBoard.saucer_small = saucer.small

# Like the arcade: the explosion's volume falls one step every 4 updates, from 15 to 0.
func update_explosion_sound() -> void:
	if explosion_ticks > 0:
		explosion_ticks -= 1
	$SoundBoard.explosion_volume = explosion_ticks >> 2

# Like the arcade: the thrust sound while Up is held and the ship is in play, and never otherwise.
func update_thrust_sound() -> void:
	$SoundBoard.thrust = $Ship.visible and Input.is_action_pressed("thrust")

# Like the arcade: the first saucers are large, then a random roll that favours small ones more and more,
# and from 30,000 points every saucer is small.
func pick_small() -> bool:
	if saucer_time_reload >= 128:
		return false # the first three saucers: 140, 134 and 128
	if score >= 30000:
		return true
	return (saucer_time_reload >> 1) < randi_range(0, 255) # small unless half the reload is at least the roll

# Runs when a saucer goes off the side, or when a saucer's explosion has gone: the wait for the next one starts again.
func _on_saucer_gone() -> void:
	saucer_timer = saucer_time_reload

# Runs when a shot or rock hits a saucer: it explodes and scores unless it ran into a rock.
func _on_saucer_destroyed(saucer: Saucer, scored: bool) -> void:
	play_explosion(1 if saucer.small else 2) # the arcade gives the small saucer the medium rock's pitch, the large saucer the large rock's
	var explosion: Explosion = spawn_explosion(saucer.position)
	# Like the arcade, the explosion takes the saucer's place: no new saucer while it lasts,
	# and the next wave doesn't wait for it, because that only waits for rocks.
	explosion.remove_from_group("explosions")
	explosion.add_to_group("saucer_explosions")
	explosion.tree_exited.connect(_on_saucer_gone) # when it has gone, the wait for the next saucer starts
	if scored:
		add_score(1000 if saucer.small else 200) # the arcade's points: 1000 for a small saucer, 200 for a large

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
	play_explosion(1)
	lives -= 1
	update_display()
	if lives == 0:
		$Display.message = "GAME OVER" # GAME OVER, in the arcade's letters
		$Ship.set_physics_process(false) # stops the ship's script until the next game
		game_over_ticks = GAME_OVER_TICKS # back to attract mode when the explosion has gone

# Shows the score, lives and best score on screen.
func update_display() -> void:
	$Display.score = score # the setter redraws it
	$Display.lives = lives
	$Display.top_score = high_scores[0] # the best, drawn at the top

# Runs every 0.52 s (the BlinkTimer's timeout, connected in the editor): in attract mode, and not during entry, PUSH START flashes.
func _on_blink_timer_timeout() -> void:
	if playing or entering >= 0:
		return
	$Display.message = "" if $Display.message == "PUSH START" else "PUSH START"
