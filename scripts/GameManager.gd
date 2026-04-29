extends Node

# Game state
var time_remaining: float = 1800.0  # 30 minutes
var lives: int = 3
var rooms_completed: int = 0
var total_rooms: int = 4  # 4 puzzles (rooms 1-4, room 5 is final MCQ)
var game_active: bool = false
var puzzle_open: bool = false

# Noise system
var current_noise: float = 0.0  # 0-100
var noise_decay_rate: float = 15.0  # per second

# Room tracking
var room_puzzles_solved: Array = [false, false, false, false, false]  # 5 rooms
var doors_unlocked: Array = [false, false, false, false]  # 4 doors between rooms

# References (set by Game.gd)
var professor: Node = null
var player: Node = null
var hud: Node = null

signal noise_changed(value: float)
signal life_lost(lives_remaining: int)
signal room_completed(room_index: int)
signal game_won()
signal game_lost(reason: String)
signal puzzle_opened()
signal puzzle_closed()

func _ready() -> void:
	pass

func start_game() -> void:
	time_remaining = 1800.0
	lives = 3
	rooms_completed = 0
	game_active = true
	puzzle_open = false
	current_noise = 0.0
	room_puzzles_solved = [false, false, false, false, false]
	doors_unlocked = [false, false, false, false]

func _process(delta: float) -> void:
	if not game_active:
		return
	if puzzle_open:
		return

	# Count down timer
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		trigger_game_over("Time's up! You failed the exam.")

	# Decay noise
	current_noise = max(0.0, current_noise - noise_decay_rate * delta)
	emit_signal("noise_changed", current_noise)

func add_noise(amount: float) -> void:
	current_noise = min(100.0, current_noise + amount)
	emit_signal("noise_changed", current_noise)

func trigger_alarm(room_index: int) -> void:
	add_noise(80.0)
	if professor:
		professor.go_alert(room_index)

func solve_room(room_index: int) -> void:
	if room_index < 0 or room_index >= 5:
		return
	room_puzzles_solved[room_index] = true
	rooms_completed += 1
	emit_signal("room_completed", room_index)
	# Unlock next door
	if room_index < 4:
		doors_unlocked[room_index] = true
	if room_index == 4:
		# Final room solved — game won
		game_active = false
		emit_signal("game_won")

func is_door_unlocked(door_index: int) -> bool:
	if door_index < 0 or door_index >= 4:
		return false
	return doors_unlocked[door_index]

func player_caught() -> void:
	lives -= 1
	emit_signal("life_lost", lives)
	if lives <= 0:
		trigger_game_over("Caught too many times! Permanently confined.")

func trigger_game_over(reason: String) -> void:
	game_active = false
	emit_signal("game_lost", reason)

func open_puzzle() -> void:
	puzzle_open = true
	emit_signal("puzzle_opened")

func close_puzzle() -> void:
	puzzle_open = false
	emit_signal("puzzle_closed")

func get_time_string() -> String:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]

func reset() -> void:
	time_remaining = 1800.0
	lives = 3
	rooms_completed = 0
	game_active = false
	puzzle_open = false
	current_noise = 0.0
	room_puzzles_solved = [false, false, false, false, false]
	doors_unlocked = [false, false, false, false]
	professor = null
	player = null
	hud = null
