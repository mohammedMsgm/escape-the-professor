extends Node2D

# ─────────────────────────────────────────────
#  Level layout constants
# ─────────────────────────────────────────────
const ROOM_W      = 400
const ROOM_H      = 300
const CORR_W      = 150
const CORR_H      = 80
const WALL_T      = 20          # wall thickness
const ROOM_TOP_Y  = 200
const ROOM_BOT_Y  = 500         # = ROOM_TOP_Y + ROOM_H
const CORR_TOP_Y  = 310
const CORR_BOT_Y  = 390
const ROOM_CENTER_Y = 350       # midpoint of corridor / room height

const ROOM_COLORS = [
	Color(0.13, 0.17, 0.22),   # Room 1 – Computer Lab
	Color(0.12, 0.20, 0.14),   # Room 2 – Algorithm
	Color(0.10, 0.14, 0.22),   # Room 3 – Cybersecurity
	Color(0.22, 0.14, 0.10),   # Room 4 – AI Lab
	Color(0.20, 0.10, 0.10),   # Room 5 – Office
]

# Pre-computed room left-edge X positions
# Room 0 starts at x=0, then corridor, room 1, ...
func room_left(i: int) -> int:
	return i * (ROOM_W + CORR_W)

# ─────────────────────────────────────────────
#  Node references built at runtime
# ─────────────────────────────────────────────
var player_node: CharacterBody2D
var professor_node: CharacterBody2D
var camera: Camera2D
var hud_node: Node

var terminals: Array = []   # [Area2D, ...]  indexed 0-3
var doors: Array    = []    # [Area2D, ...]  indexed 0-3 (between rooms)
var exit_door: Area2D

var puzzle_scripts: Array = []  # one per room (0-3)

# ─────────────────────────────────────────────
#  _ready – build the whole scene
# ─────────────────────────────────────────────
func _ready() -> void:
	GameManager.reset()
	GameManager.start_game()

	_build_level()
	_spawn_player()
	_spawn_professor()
	_build_hud()
	_setup_puzzles()

	# Connect GameManager signals
	GameManager.connect("game_won",  _on_game_won)
	GameManager.connect("game_lost", _on_game_lost)
	GameManager.connect("room_completed", _on_room_completed)

# ─────────────────────────────────────────────
#  Level builder
# ─────────────────────────────────────────────
func _build_level() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.10)
	bg.size = Vector2(3200, 700)
	bg.position = Vector2(-50, 100)
	add_child(bg)

	for i in range(5):
		_make_room(i)

	for i in range(4):
		_make_corridor(i)
		_make_door(i)
		_make_terminal(i)

	_make_exit_door()

# ─── Room ───────────────────────────────────
func _make_room(i: int) -> void:
	var lx = room_left(i)
	# Floor
	var floor_rect = _static_body(
		Rect2(lx, ROOM_TOP_Y, ROOM_W, ROOM_H),
		ROOM_COLORS[i], false
	)
	add_child(floor_rect)

	# Walls (4 sides, with gaps for doors/corridors)
	var wall_col = Color(0.25, 0.25, 0.28)

	# Top wall – full width
	add_child(_static_body(Rect2(lx, ROOM_TOP_Y - WALL_T, ROOM_W, WALL_T), wall_col))
	# Bottom wall – full width
	add_child(_static_body(Rect2(lx, ROOM_BOT_Y, ROOM_W, WALL_T), wall_col))

	# Left wall – skip gap if not room 0 (corridor joins from left)
	if i == 0:
		add_child(_static_body(Rect2(lx - WALL_T, ROOM_TOP_Y - WALL_T, WALL_T, ROOM_H + WALL_T * 2), wall_col))
	else:
		# Left wall above corridor gap
		add_child(_static_body(Rect2(lx, ROOM_TOP_Y - WALL_T, WALL_T, CORR_TOP_Y - ROOM_TOP_Y + WALL_T), wall_col))
		# Left wall below corridor gap
		add_child(_static_body(Rect2(lx, CORR_BOT_Y, WALL_T, ROOM_BOT_Y - CORR_BOT_Y + WALL_T), wall_col))

	# Right wall – skip gap if not room 4
	if i == 4:
		# Right wall full (exit door will be placed here separately)
		add_child(_static_body(Rect2(lx + ROOM_W, ROOM_TOP_Y - WALL_T, WALL_T, ROOM_H + WALL_T * 2), wall_col))
	else:
		# Right wall above corridor gap
		add_child(_static_body(Rect2(lx + ROOM_W - WALL_T, ROOM_TOP_Y - WALL_T, WALL_T, CORR_TOP_Y - ROOM_TOP_Y + WALL_T), wall_col))
		# Right wall below corridor gap
		add_child(_static_body(Rect2(lx + ROOM_W - WALL_T, CORR_BOT_Y, WALL_T, ROOM_BOT_Y - CORR_BOT_Y + WALL_T), wall_col))

# ─── Corridor ───────────────────────────────
func _make_corridor(i: int) -> void:
	var cx = room_left(i) + ROOM_W
	var wall_col = Color(0.25, 0.25, 0.28)

	# Floor
	var floor_r = ColorRect.new()
	floor_r.color = Color(0.10, 0.10, 0.13)
	floor_r.size = Vector2(CORR_W, CORR_H)
	floor_r.position = Vector2(cx, CORR_TOP_Y)
	add_child(floor_r)

	# Top wall of corridor
	add_child(_static_body(Rect2(cx, CORR_TOP_Y - WALL_T, CORR_W, WALL_T), wall_col))
	# Bottom wall of corridor
	add_child(_static_body(Rect2(cx, CORR_BOT_Y, CORR_W, WALL_T), wall_col))

# ─── Door (between rooms) ───────────────────
func _make_door(i: int) -> void:
	# Door sits in the corridor, visually blocking passage until unlocked
	var cx = room_left(i) + ROOM_W + CORR_W / 2 - 10
	var door_area = Area2D.new()
	door_area.name = "Door_%d" % i
	door_area.position = Vector2(cx, ROOM_CENTER_Y)
	add_child(door_area)

	var door_rect = ColorRect.new()
	door_rect.size = Vector2(20, CORR_H)
	door_rect.position = Vector2(-10, -CORR_H / 2)
	door_rect.color = Color(0.8, 0.4, 0.0)
	door_area.add_child(door_rect)

	var door_col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, CORR_H)
	door_col.shape = shape
	door_col.name = "DoorCollision"
	door_area.add_child(door_col)

	# Interaction zone
	var interact_zone = CollisionShape2D.new()
	var iz_shape = RectangleShape2D.new()
	iz_shape.size = Vector2(50, CORR_H + 20)
	interact_zone.shape = iz_shape
	interact_zone.name = "InteractZone"
	door_area.add_child(interact_zone)

	# Tag for game logic
	door_area.set_meta("door_index", i)
	door_area.set_meta("door_rect", door_rect)
	door_area.set_meta("door_col", door_col)
	door_area.set_meta("locked", true)

	# Also add a static body so player can't walk through locked door
	var wall_body = StaticBody2D.new()
	wall_body.name = "DoorWall_%d" % i
	wall_body.position = Vector2(cx, ROOM_CENTER_Y)
	add_child(wall_body)
	var wb_col = CollisionShape2D.new()
	var wb_shape = RectangleShape2D.new()
	wb_shape.size = Vector2(20, CORR_H)
	wb_col.shape = wb_shape
	wall_body.add_child(wb_col)
	door_area.set_meta("wall_body", wall_body)

	doors.append(door_area)

# ─── Terminal ───────────────────────────────
func _make_terminal(i: int) -> void:
	var lx = room_left(i)
	# Place terminal near center of room
	var tx = lx + ROOM_W / 2
	var ty = ROOM_TOP_Y + ROOM_H / 2

	var terminal = Area2D.new()
	terminal.name = "Terminal_%d" % i
	terminal.position = Vector2(tx, ty)
	add_child(terminal)

	var trect = ColorRect.new()
	trect.size = Vector2(36, 36)
	trect.position = Vector2(-18, -18)
	trect.color = Color(0.9, 0.8, 0.1)
	terminal.add_child(trect)

	# Glow label
	var label = Label.new()
	label.text = "[E]"
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.position = Vector2(-11, -8)
	terminal.add_child(label)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	col.shape = shape
	terminal.add_child(col)

	terminal.set_meta("room_index", i)
	terminal.set_meta("solved", false)
	terminal.body_entered.connect(func(body): _on_terminal_body_entered(body, terminal))
	terminal.body_exited.connect(func(body): _on_terminal_body_exited(body))

	terminals.append(terminal)

# ─── Exit door ──────────────────────────────
func _make_exit_door() -> void:
	var lx = room_left(4) + ROOM_W - 10
	exit_door = Area2D.new()
	exit_door.name = "ExitDoor"
	exit_door.position = Vector2(lx, ROOM_CENTER_Y)
	add_child(exit_door)

	var drect = ColorRect.new()
	drect.size = Vector2(20, 80)
	drect.position = Vector2(-10, -40)
	drect.color = Color(0.2, 0.8, 0.2)
	exit_door.add_child(drect)

	var lbl = Label.new()
	lbl.text = "EXIT"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.position = Vector2(-14, -8)
	exit_door.add_child(lbl)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 90)
	col.shape = shape
	exit_door.add_child(col)

	exit_door.body_entered.connect(_on_exit_entered)
	# Start dimmed (locked)
	drect.color = Color(0.4, 0.4, 0.4)

# ─────────────────────────────────────────────
#  Spawn player
# ─────────────────────────────────────────────
func _spawn_player() -> void:
	var player_script = load("res://scripts/Player.gd")
	player_node = CharacterBody2D.new()
	player_node.name = "Player"
	player_node.set_script(player_script)
	player_node.position = Vector2(room_left(0) + ROOM_W / 2, ROOM_CENTER_Y)
	add_child(player_node)

	# Camera
	camera = Camera2D.new()
	camera.zoom = Vector2(1.2, 1.2)
	camera.enabled = true
	player_node.add_child(camera)

	GameManager.player = player_node

# ─────────────────────────────────────────────
#  Spawn professor
# ─────────────────────────────────────────────
func _spawn_professor() -> void:
	var prof_script = load("res://scripts/Professor.gd")
	professor_node = CharacterBody2D.new()
	professor_node.name = "Professor"
	professor_node.set_script(prof_script)
	professor_node.position = Vector2(room_left(1) + ROOM_W / 2, ROOM_CENTER_Y)
	add_child(professor_node)

	# Patrol waypoints along corridors
	var waypts = [
		Vector2(room_left(0) + CORR_W + 30, ROOM_CENTER_Y),
		Vector2(room_left(1) + CORR_W + 30, ROOM_CENTER_Y),
		Vector2(room_left(2) + CORR_W + 30, ROOM_CENTER_Y),
		Vector2(room_left(1) + CORR_W + 30, ROOM_CENTER_Y),
	]
	professor_node.call("setup_waypoints", waypts)
	professor_node.call("set_player", player_node)

	GameManager.professor = professor_node

# ─────────────────────────────────────────────
#  HUD
# ─────────────────────────────────────────────
func _build_hud() -> void:
	var hud_script = load("res://scripts/HUD.gd")
	hud_node = CanvasLayer.new()
	hud_node.set_script(hud_script)
	hud_node.name = "HUD"
	hud_node.layer = 5
	add_child(hud_node)
	GameManager.hud = hud_node

# ─────────────────────────────────────────────
#  Puzzle setup
# ─────────────────────────────────────────────
func _setup_puzzles() -> void:
	var puzzle_paths = [
		"res://scripts/puzzles/CodePuzzle.gd",
		"res://scripts/puzzles/SortPuzzle.gd",
		"res://scripts/puzzles/CipherPuzzle.gd",
		"res://scripts/puzzles/MCQPuzzle.gd",
	]
	for i in range(4):
		var ps = load(puzzle_paths[i])
		var puzzle = Node.new()
		puzzle.set_script(ps)
		puzzle.name = "Puzzle_%d" % i
		add_child(puzzle)
		var idx = i  # capture by value
		puzzle.connect("puzzle_solved", func(): _on_puzzle_solved(idx))
		puzzle.connect("puzzle_failed", func(): _on_puzzle_failed(idx))
		puzzle_scripts.append(puzzle)

# ─────────────────────────────────────────────
#  Terminal interaction
# ─────────────────────────────────────────────
func _on_terminal_body_entered(body: Node, terminal: Area2D) -> void:
	if body != player_node:
		return
	var ri = terminal.get_meta("room_index")
	# Can interact if not already solved
	if not terminal.get_meta("solved"):
		player_node.set_near_terminal(func(): _open_puzzle(ri))

func _on_terminal_body_exited(body: Node) -> void:
	if body != player_node:
		return
	player_node.set_near_terminal(null)

func _open_puzzle(room_index: int) -> void:
	if GameManager.puzzle_open:
		return
	if terminals[room_index].get_meta("solved"):
		return
	puzzle_scripts[room_index].call("show_puzzle")

# ─────────────────────────────────────────────
#  Puzzle outcomes
# ─────────────────────────────────────────────
func _on_puzzle_solved(room_index: int) -> void:
	terminals[room_index].set_meta("solved", true)
	# Change terminal color to green
	var trect = terminals[room_index].get_child(0)
	if trect is ColorRect:
		trect.color = Color(0.1, 0.9, 0.3)

	GameManager.solve_room(room_index)

	# Unlock the door after this room
	if room_index < doors.size():
		_unlock_door(room_index)

func _on_puzzle_failed(room_index: int) -> void:
	GameManager.trigger_alarm(room_index)
	# Flash HUD
	if hud_node and hud_node.has_method("trigger_alarm_flash"):
		hud_node.trigger_alarm_flash()

# ─────────────────────────────────────────────
#  Door logic
# ─────────────────────────────────────────────
func _unlock_door(i: int) -> void:
	if i >= doors.size():
		return
	var door = doors[i]
	door.set_meta("locked", false)

	# Remove the blocking wall body
	var wb = door.get_meta("wall_body")
	if wb:
		wb.queue_free()

	# Change door color to green/open
	var dr = door.get_meta("door_rect")
	if dr:
		dr.color = Color(0.1, 0.8, 0.3)

	# Disable blocking collision on door itself
	var dc = door.get_meta("door_col")
	if dc:
		dc.disabled = true

	# If all 4 doors unlocked, light up exit
	if GameManager.room_puzzles_solved[3]:
		_unlock_exit()

func _unlock_exit() -> void:
	if exit_door:
		var drect = exit_door.get_child(0)
		if drect is ColorRect:
			drect.color = Color(0.2, 1.0, 0.2)

func _on_exit_entered(body: Node) -> void:
	if body != player_node:
		return
	# Only win if room 4 (MCQ) is solved
	if GameManager.room_puzzles_solved[3]:
		GameManager.game_active = false
		GameManager.emit_signal("game_won")

# ─────────────────────────────────────────────
#  Game signals
# ─────────────────────────────────────────────
func _on_game_won() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_game_lost(reason: String) -> void:
	GameManager.set_meta("lose_reason", reason)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_room_completed(room_index: int) -> void:
	if hud_node and hud_node.has_method("update_room_name"):
		var next = min(room_index + 1, 4)
		hud_node.update_room_name(next)

# ─────────────────────────────────────────────
#  Helper – make a StaticBody2D rectangle
# ─────────────────────────────────────────────
func _static_body(rect: Rect2, color: Color, solid: bool = true) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = Vector2(rect.position.x, rect.position.y)

	var cr = ColorRect.new()
	cr.size = Vector2(rect.size.x, rect.size.y)
	cr.color = color
	body.add_child(cr)

	if solid:
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(rect.size.x, rect.size.y)
		col.shape = shape
		col.position = Vector2(rect.size.x / 2, rect.size.y / 2)
		body.add_child(col)

	return body
