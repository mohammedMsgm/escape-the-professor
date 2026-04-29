extends Node3D

# ─────────────────────────────────────────────
#  Level layout constants  (same X/Z footprint as 2-D version)
# ─────────────────────────────────────────────
const ROOM_W      = 400
const ROOM_H      = 300
const CORR_W      = 150
const CORR_H      = 80
const WALL_T      = 20
const ROOM_TOP_Y  = 200
const ROOM_BOT_Y  = 500
const CORR_TOP_Y  = 310
const CORR_BOT_Y  = 390
const ROOM_CENTER_Y = 350

const WALL_HEIGHT : float = 80.0    # 3-D wall height (Y axis)
const FLOOR_THICK : float = 6.0     # floor slab thickness

const ROOM_COLORS = [
	Color(0.08, 0.14, 0.28),   # Computer Lab  – blue
	Color(0.06, 0.20, 0.10),   # Algorithm     – green
	Color(0.06, 0.10, 0.26),   # Cybersecurity – deep blue
	Color(0.26, 0.12, 0.04),   # AI Lab        – amber
	Color(0.24, 0.04, 0.04),   # Office        – crimson
]

# ─────────────────────────────────────────────
#  Node references
# ─────────────────────────────────────────────
var player_node: CharacterBody3D
var professor_node: CharacterBody3D
var camera: Camera3D
var hud_node: Node

var terminals: Array = []
var doors:     Array = []
var exit_door: Area3D

var puzzle_scripts: Array = []

func room_left(i: int) -> int:
	return i * (ROOM_W + CORR_W)

# ─────────────────────────────────────────────
#  _ready
# ─────────────────────────────────────────────
func _ready() -> void:
	GameManager.reset()
	GameManager.start_game()

	_setup_environment()
	_build_level()
	_spawn_player()
	_spawn_professor()
	_build_hud()
	_setup_puzzles()

	GameManager.connect("game_won",       _on_game_won)
	GameManager.connect("game_lost",      _on_game_lost)
	GameManager.connect("room_completed", _on_room_completed)

# ─────────────────────────────────────────────
#  Environment & Lighting
# ─────────────────────────────────────────────
func _setup_environment() -> void:
	# World environment
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode       = Environment.BG_COLOR
	env.background_color      = Color(0.02, 0.02, 0.05)
	env.ambient_light_source  = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color   = Color(0.25, 0.27, 0.35)
	env.ambient_light_energy  = 1.0
	env.glow_enabled          = true
	env.glow_intensity        = 0.6
	env.glow_bloom            = 0.15
	env.glow_hdr_threshold    = 0.5
	we.environment = env
	add_child(we)

	# Weak directional light (top-down)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees    = Vector3(-70, -20, 0)
	sun.light_energy        = 0.6
	sun.light_color         = Color(0.9, 0.9, 1.0)
	sun.shadow_enabled      = false
	add_child(sun)

# ─────────────────────────────────────────────
#  Level builder
# ─────────────────────────────────────────────
func _build_level() -> void:
	# Outer ground plane (dark void)
	var ground_mesh = MeshInstance3D.new()
	var gplane = BoxMesh.new()
	gplane.size = Vector3(3400, 4, 900)
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.03, 0.03, 0.05)
	ground_mesh.mesh = gplane
	ground_mesh.set_surface_override_material(0, gmat)
	ground_mesh.position = Vector3(1350, -FLOOR_THICK - 2.0, 350)
	add_child(ground_mesh)

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
	var wall_col = Color(0.22, 0.22, 0.26)

	# Floor slab
	add_child(_floor_slab(Rect2(lx, ROOM_TOP_Y, ROOM_W, ROOM_H), ROOM_COLORS[i]))

	# Ceiling (semi-transparent feel – just a thin slab)
	var ceil_slab = _floor_slab(Rect2(lx, ROOM_TOP_Y, ROOM_W, ROOM_H), ROOM_COLORS[i].darkened(0.5))
	ceil_slab.position.y = WALL_HEIGHT + FLOOR_THICK / 2.0
	add_child(ceil_slab)

	# Top wall
	add_child(_wall(Rect2(lx, ROOM_TOP_Y - WALL_T, ROOM_W, WALL_T), wall_col))
	# Bottom wall
	add_child(_wall(Rect2(lx, ROOM_BOT_Y, ROOM_W, WALL_T), wall_col))

	# Left wall
	if i == 0:
		add_child(_wall(Rect2(lx - WALL_T, ROOM_TOP_Y - WALL_T, WALL_T, ROOM_H + WALL_T * 2), wall_col))
	else:
		add_child(_wall(Rect2(lx, ROOM_TOP_Y - WALL_T, WALL_T, CORR_TOP_Y - ROOM_TOP_Y + WALL_T), wall_col))
		add_child(_wall(Rect2(lx, CORR_BOT_Y,          WALL_T, ROOM_BOT_Y - CORR_BOT_Y + WALL_T), wall_col))

	# Right wall
	if i == 4:
		add_child(_wall(Rect2(lx + ROOM_W, ROOM_TOP_Y - WALL_T, WALL_T, ROOM_H + WALL_T * 2), wall_col))
	else:
		add_child(_wall(Rect2(lx + ROOM_W - WALL_T, ROOM_TOP_Y - WALL_T, WALL_T, CORR_TOP_Y - ROOM_TOP_Y + WALL_T), wall_col))
		add_child(_wall(Rect2(lx + ROOM_W - WALL_T, CORR_BOT_Y,          WALL_T, ROOM_BOT_Y - CORR_BOT_Y + WALL_T), wall_col))

	# Room accent light
	var light = OmniLight3D.new()
	light.position = Vector3(lx + ROOM_W / 2.0, WALL_HEIGHT * 0.7, ROOM_TOP_Y + ROOM_H / 2.0)
	light.light_color  = ROOM_COLORS[i].lightened(0.6)
	light.light_energy = 2.5
	light.omni_range   = maxf(float(ROOM_W), float(ROOM_H)) * 0.9
	add_child(light)

	# Room name label on the floor
	var room_names = ["COMPUTER LAB", "ALGORITHM", "CYBERSECURITY", "AI LAB", "PROFESSOR'S OFFICE"]
	var lbl = Label3D.new()
	lbl.text       = room_names[i]
	lbl.font_size  = 28
	lbl.modulate   = ROOM_COLORS[i].lightened(0.8)
	lbl.billboard  = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.position   = Vector3(lx + ROOM_W / 2.0, 1.0, ROOM_TOP_Y + 30)
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	add_child(lbl)

# ─── Corridor ───────────────────────────────
func _make_corridor(i: int) -> void:
	var cx = room_left(i) + ROOM_W
	var wall_col = Color(0.20, 0.20, 0.24)

	add_child(_floor_slab(Rect2(cx, CORR_TOP_Y, CORR_W, CORR_H), Color(0.08, 0.08, 0.11)))

	# Top & bottom corridor walls
	add_child(_wall(Rect2(cx, CORR_TOP_Y - WALL_T, CORR_W, WALL_T), wall_col))
	add_child(_wall(Rect2(cx, CORR_BOT_Y,           CORR_W, WALL_T), wall_col))

	# Dim corridor light
	var clight = OmniLight3D.new()
	clight.position    = Vector3(cx + CORR_W / 2.0, WALL_HEIGHT * 0.6, ROOM_CENTER_Y)
	clight.light_color = Color(0.5, 0.5, 0.7)
	clight.light_energy = 1.2
	clight.omni_range  = CORR_W * 0.9
	add_child(clight)

# ─── Door ───────────────────────────────────
func _make_door(i: int) -> void:
	var cx   = room_left(i) + ROOM_W + CORR_W / 2 - 10
	var cz   = float(ROOM_CENTER_Y)

	var door_area = Area3D.new()
	door_area.name     = "Door_%d" % i
	door_area.position = Vector3(cx, WALL_HEIGHT / 2.0, cz)
	add_child(door_area)

	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color       = Color(0.7, 0.35, 0.0)
	door_mat.emission_enabled   = true
	door_mat.emission           = Color(0.5, 0.2, 0.0)
	door_mat.emission_energy_multiplier = 0.4
	door_mat.metallic           = 0.6
	door_mat.roughness          = 0.3

	var door_mesh = MeshInstance3D.new()
	var dbox = BoxMesh.new()
	dbox.size = Vector3(20, WALL_HEIGHT, CORR_H)
	door_mesh.mesh = dbox
	door_mesh.set_surface_override_material(0, door_mat)
	door_area.add_child(door_mesh)

	var door_col = CollisionShape3D.new()
	var ds = BoxShape3D.new()
	ds.size = Vector3(20, WALL_HEIGHT, CORR_H)
	door_col.shape = ds
	door_area.add_child(door_col)

	door_area.set_meta("door_index",  i)
	door_area.set_meta("door_mat",    door_mat)
	door_area.set_meta("door_col",    door_col)
	door_area.set_meta("locked",      true)

	# Blocking static body
	var wall_body = StaticBody3D.new()
	wall_body.name     = "DoorWall_%d" % i
	wall_body.position = Vector3(cx, WALL_HEIGHT / 2.0, cz)
	add_child(wall_body)
	var wb_col = CollisionShape3D.new()
	var wb_shape = BoxShape3D.new()
	wb_shape.size = Vector3(20, WALL_HEIGHT, CORR_H)
	wb_col.shape = wb_shape
	wall_body.add_child(wb_col)
	door_area.set_meta("wall_body", wall_body)

	doors.append(door_area)

# ─── Terminal ───────────────────────────────
func _make_terminal(i: int) -> void:
	var lx = room_left(i)
	var tx = float(lx + ROOM_W / 2)
	var tz = float(ROOM_TOP_Y + ROOM_H / 2)

	var terminal = Area3D.new()
	terminal.name     = "Terminal_%d" % i
	terminal.position = Vector3(tx, 20, tz)
	add_child(terminal)

	# Monitor back
	var back_mat = StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.15, 0.15, 0.18)
	back_mat.metallic     = 0.8
	back_mat.roughness    = 0.2
	var back_inst = MeshInstance3D.new()
	var back_box  = BoxMesh.new()
	back_box.size = Vector3(40, 30, 8)
	back_inst.mesh = back_box
	back_inst.set_surface_override_material(0, back_mat)
	terminal.add_child(back_inst)

	# Screen
	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color             = Color(0.9, 0.8, 0.1)
	screen_mat.emission_enabled         = true
	screen_mat.emission                 = Color(0.9, 0.8, 0.1)
	screen_mat.emission_energy_multiplier = 1.5
	var screen_inst = MeshInstance3D.new()
	var screen_box  = BoxMesh.new()
	screen_box.size = Vector3(32, 22, 2)
	screen_inst.mesh = screen_box
	screen_inst.set_surface_override_material(0, screen_mat)
	screen_inst.position = Vector3(0, 0, 5)
	terminal.add_child(screen_inst)

	# Glow light
	var tlight = OmniLight3D.new()
	tlight.light_color  = Color(1.0, 0.9, 0.2)
	tlight.light_energy = 1.8
	tlight.omni_range   = 80
	terminal.add_child(tlight)

	# Billboard label
	var lbl = Label3D.new()
	lbl.text      = "[E] HACK"
	lbl.font_size = 18
	lbl.modulate  = Color(0.9, 0.8, 0.1)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position  = Vector3(0, 28, 0)
	terminal.add_child(lbl)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(60, 60, 60)
	col.shape = shape
	terminal.add_child(col)

	terminal.set_meta("room_index",  i)
	terminal.set_meta("solved",      false)
	terminal.set_meta("screen_mat",  screen_mat)
	terminal.set_meta("tlight",      tlight)
	terminal.set_meta("label",       lbl)
	terminal.body_entered.connect(func(body): _on_terminal_body_entered(body, terminal))
	terminal.body_exited.connect( func(body): _on_terminal_body_exited(body))

	terminals.append(terminal)

# ─── Exit door ──────────────────────────────
func _make_exit_door() -> void:
	var lx = room_left(4) + ROOM_W - 10
	exit_door = Area3D.new()
	exit_door.name     = "ExitDoor"
	exit_door.position = Vector3(lx, WALL_HEIGHT / 2.0, ROOM_CENTER_Y)
	add_child(exit_door)

	var exit_mat = StandardMaterial3D.new()
	exit_mat.albedo_color             = Color(0.3, 0.3, 0.3)
	exit_mat.emission_enabled         = true
	exit_mat.emission                 = Color(0.1, 0.1, 0.1)
	exit_mat.emission_energy_multiplier = 0.2

	var exit_mesh = MeshInstance3D.new()
	var ebox = BoxMesh.new()
	ebox.size = Vector3(20, WALL_HEIGHT, 80)
	exit_mesh.mesh = ebox
	exit_mesh.set_surface_override_material(0, exit_mat)
	exit_door.add_child(exit_mesh)

	var elbl = Label3D.new()
	elbl.text      = "EXIT"
	elbl.font_size = 24
	elbl.modulate  = Color(0.4, 0.4, 0.4)
	elbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	elbl.position  = Vector3(0, WALL_HEIGHT / 2.0 + 20, 0)
	exit_door.add_child(elbl)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(30, WALL_HEIGHT, 90)
	col.shape  = shape
	exit_door.add_child(col)

	exit_door.set_meta("exit_mat", exit_mat)
	exit_door.set_meta("exit_lbl", elbl)
	exit_door.body_entered.connect(_on_exit_entered)

# ─────────────────────────────────────────────
#  Spawn player
# ─────────────────────────────────────────────
func _spawn_player() -> void:
	var player_script = load("res://scripts/Player.gd")
	player_node = CharacterBody3D.new()
	player_node.name = "Player"
	player_node.set_script(player_script)
	player_node.position = Vector3(room_left(0) + ROOM_W / 2.0, 0, ROOM_CENTER_Y)
	add_child(player_node)

	# Isometric-ish camera attached to player
	camera = Camera3D.new()
	camera.position        = Vector3(0, 480, 380)
	camera.rotation_degrees = Vector3(-54, 0, 0)
	camera.fov             = 62
	player_node.add_child(camera)

	GameManager.player = player_node

# ─────────────────────────────────────────────
#  Spawn professor
# ─────────────────────────────────────────────
func _spawn_professor() -> void:
	var prof_script = load("res://scripts/Professor.gd")
	professor_node = CharacterBody3D.new()
	professor_node.name = "Professor"
	professor_node.set_script(prof_script)
	professor_node.position = Vector3(room_left(1) + ROOM_W / 2.0, 0, ROOM_CENTER_Y)
	add_child(professor_node)

	var waypts = [
		Vector3(room_left(0) + CORR_W + 30, 0, ROOM_CENTER_Y),
		Vector3(room_left(1) + CORR_W + 30, 0, ROOM_CENTER_Y),
		Vector3(room_left(2) + CORR_W + 30, 0, ROOM_CENTER_Y),
		Vector3(room_left(1) + CORR_W + 30, 0, ROOM_CENTER_Y),
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
	hud_node.name  = "HUD"
	hud_node.layer = 5
	add_child(hud_node)
	GameManager.hud = hud_node

# ─────────────────────────────────────────────
#  Puzzles
# ─────────────────────────────────────────────
func _setup_puzzles() -> void:
	var puzzle_paths = [
		"res://scripts/puzzles/CodePuzzle.gd",
		"res://scripts/puzzles/SortPuzzle.gd",
		"res://scripts/puzzles/CipherPuzzle.gd",
		"res://scripts/puzzles/MCQPuzzle.gd",
	]
	for i in range(4):
		var ps     = load(puzzle_paths[i])
		var puzzle = Node.new()
		puzzle.set_script(ps)
		puzzle.name = "Puzzle_%d" % i
		add_child(puzzle)
		var idx = i
		puzzle.connect("puzzle_solved", func(): _on_puzzle_solved(idx))
		puzzle.connect("puzzle_failed", func(): _on_puzzle_failed(idx))
		puzzle_scripts.append(puzzle)

# ─────────────────────────────────────────────
#  Terminal interaction
# ─────────────────────────────────────────────
func _on_terminal_body_entered(body: Node, terminal: Area3D) -> void:
	if body != player_node:
		return
	var ri = terminal.get_meta("room_index")
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

	var smat = terminals[room_index].get_meta("screen_mat") as StandardMaterial3D
	if smat:
		smat.albedo_color = Color(0.1, 0.9, 0.3)
		smat.emission     = Color(0.05, 0.8, 0.15)
		smat.emission_energy_multiplier = 2.0

	var tlight = terminals[room_index].get_meta("tlight") as OmniLight3D
	if tlight:
		tlight.light_color = Color(0.2, 1.0, 0.3)

	var lbl = terminals[room_index].get_meta("label") as Label3D
	if lbl:
		lbl.text    = "SOLVED ✓"
		lbl.modulate = Color(0.1, 1.0, 0.3)

	GameManager.solve_room(room_index)

	if room_index < doors.size():
		_unlock_door(room_index)

func _on_puzzle_failed(room_index: int) -> void:
	GameManager.trigger_alarm(room_index)
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

	var wb = door.get_meta("wall_body")
	if wb:
		wb.queue_free()

	var dmat = door.get_meta("door_mat") as StandardMaterial3D
	if dmat:
		dmat.albedo_color             = Color(0.1, 0.8, 0.3)
		dmat.emission                 = Color(0.05, 0.6, 0.15)
		dmat.emission_energy_multiplier = 1.0

	var dc = door.get_meta("door_col") as CollisionShape3D
	if dc:
		dc.disabled = true

	if GameManager.room_puzzles_solved[3]:
		_unlock_exit()

func _unlock_exit() -> void:
	if exit_door:
		var emat = exit_door.get_meta("exit_mat") as StandardMaterial3D
		if emat:
			emat.albedo_color             = Color(0.2, 1.0, 0.2)
			emat.emission                 = Color(0.1, 0.9, 0.1)
			emat.emission_energy_multiplier = 1.5

		var elbl = exit_door.get_meta("exit_lbl") as Label3D
		if elbl:
			elbl.text    = "🚪 EXIT – ESCAPE!"
			elbl.modulate = Color(0.2, 1.0, 0.3)

func _on_exit_entered(body: Node) -> void:
	if body != player_node:
		return
	if GameManager.room_puzzles_solved[3]:
		GameManager.game_active = false
		GameManager.emit_signal("game_won")

# ─────────────────────────────────────────────
#  Game signals
# ─────────────────────────────────────────────
func _on_game_won() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_game_lost(_reason: String) -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_room_completed(room_index: int) -> void:
	if hud_node and hud_node.has_method("update_room_name"):
		var next = mini(room_index + 1, 4)
		hud_node.update_room_name(next)

# ─────────────────────────────────────────────
#  3-D helpers
# ─────────────────────────────────────────────

## Solid wall (tall box with collision)
func _wall(rect: Rect2, color: Color) -> StaticBody3D:
	var cx = rect.position.x + rect.size.x / 2.0
	var cz = rect.position.y + rect.size.y / 2.0

	var body     = StaticBody3D.new()
	body.position = Vector3(cx, WALL_HEIGHT / 2.0, cz)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic     = 0.1
	mat.roughness    = 0.8

	var mi  = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(rect.size.x, WALL_HEIGHT, rect.size.y)
	mi.mesh  = box
	mi.set_surface_override_material(0, mat)
	body.add_child(mi)

	var col   = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(rect.size.x, WALL_HEIGHT, rect.size.y)
	col.shape  = shape
	body.add_child(col)

	return body

## Flat floor slab (no collision needed – gravity is 0)
func _floor_slab(rect: Rect2, color: Color) -> MeshInstance3D:
	var cx = rect.position.x + rect.size.x / 2.0
	var cz = rect.position.y + rect.size.y / 2.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 0.9
	mat.metallic     = 0.0

	var mi  = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(rect.size.x, FLOOR_THICK, rect.size.y)
	mi.mesh  = box
	mi.set_surface_override_material(0, mat)
	mi.position = Vector3(cx, -FLOOR_THICK / 2.0, cz)
	return mi
