extends CharacterBody3D

enum State { PATROL, ALERT, CHASE }

const PATROL_SPEED: float = 80.0
const ALERT_SPEED: float = 150.0
const CHASE_SPEED: float = 220.0

const VISION_RANGE: float = 250.0
const VISION_ANGLE: float = 70.0
const HEARING_RANGE: float = 300.0
const CATCH_DISTANCE: float = 30.0

var state: State = State.PATROL
var waypoints: Array = []
var current_waypoint: int = 0
var alert_target: Vector3 = Vector3.ZERO
var alert_timer: float = 0.0
const ALERT_DURATION: float = 8.0

var facing_direction: Vector3 = Vector3(1, 0, 0)
var player_ref: Node = null
var _mat: StandardMaterial3D = null
var _coat_mat: StandardMaterial3D = null

func _ready() -> void:
	# Body (dark suit)
	var body_inst = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(30, 38, 24)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.9, 0.1, 0.1)
	_mat.emission_enabled = true
	_mat.emission = Color(0.8, 0.05, 0.05)
	_mat.emission_energy_multiplier = 0.5
	_mat.metallic = 0.1
	_mat.roughness = 0.6
	body_inst.mesh = body_box
	body_inst.set_surface_override_material(0, _mat)
	body_inst.position = Vector3(0, 19, 0)
	add_child(body_inst)

	# Head
	var head_inst = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(20, 16, 20)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.85, 0.7, 0.55)
	head_mat.roughness = 0.8
	head_inst.mesh = head_box
	head_inst.set_surface_override_material(0, head_mat)
	head_inst.position = Vector3(0, 46, 0)
	add_child(head_inst)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(30, 55, 24)
	col.shape = shape
	col.position = Vector3(0, 27, 0)
	add_child(col)

func setup_waypoints(pts: Array) -> void:
	waypoints = pts
	if waypoints.size() > 0:
		current_waypoint = 0

func set_player(p: Node) -> void:
	player_ref = p

func _physics_process(delta: float) -> void:
	if not GameManager.game_active or GameManager.puzzle_open:
		velocity = Vector3.ZERO
		return

	match state:
		State.PATROL: _patrol(delta)
		State.ALERT:  _alert(delta)
		State.CHASE:  _chase(delta)

	_check_player_detection()
	_check_catch()
	move_and_slide()

func _patrol(_delta: float) -> void:
	if waypoints.size() == 0:
		velocity = Vector3.ZERO
		return

	var target = waypoints[current_waypoint]
	var dir = (target - global_position)
	dir.y = 0
	if dir.length() < 10.0:
		current_waypoint = (current_waypoint + 1) % waypoints.size()
	else:
		facing_direction = dir.normalized()
		velocity = facing_direction * PATROL_SPEED

	if _mat:
		_mat.albedo_color = Color(0.9, 0.1, 0.1)
		_mat.emission = Color(0.7, 0.05, 0.05)
		_mat.emission_energy_multiplier = 0.5

func _alert(delta: float) -> void:
	alert_timer -= delta
	if alert_timer <= 0.0:
		state = State.PATROL
		return

	var dir = (alert_target - global_position)
	dir.y = 0
	if dir.length() < 15.0:
		velocity = Vector3.ZERO
	else:
		facing_direction = dir.normalized()
		velocity = facing_direction * ALERT_SPEED

	if _mat:
		_mat.albedo_color = Color(1.0, 0.5, 0.0)
		_mat.emission = Color(0.9, 0.3, 0.0)
		_mat.emission_energy_multiplier = 0.8

func _chase(_delta: float) -> void:
	if player_ref == null:
		state = State.PATROL
		return

	var dir = (player_ref.global_position - global_position)
	dir.y = 0
	if dir.length() > 0.1:
		facing_direction = dir.normalized()
		velocity = facing_direction * CHASE_SPEED

	if _mat:
		_mat.albedo_color = Color(1.0, 0.0, 0.5)
		_mat.emission = Color(1.0, 0.0, 0.3)
		_mat.emission_energy_multiplier = 1.5

func _check_player_detection() -> void:
	if player_ref == null:
		return

	var to_player = player_ref.global_position - global_position
	to_player.y = 0
	var dist = to_player.length()

	if dist < VISION_RANGE:
		var angle = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
		if abs(angle) < VISION_ANGLE:
			if player_ref.is_hiding:
				if dist < 40.0:
					state = State.CHASE
			else:
				state = State.CHASE
			return

	var noise_radius = player_ref.get_noise_radius()
	if dist < noise_radius and GameManager.current_noise > 10.0:
		if state != State.CHASE:
			go_alert_position(player_ref.global_position)

	if state == State.CHASE and dist > VISION_RANGE * 1.5:
		go_alert_position(player_ref.global_position)

func _check_catch() -> void:
	if player_ref == null:
		return
	if state == State.CHASE:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0
		if to_player.length() < CATCH_DISTANCE:
			GameManager.player_caught()
			player_ref.global_position = Vector3(200, 0, 350)
			state = State.PATROL
			if waypoints.size() > 0:
				current_waypoint = 0

func go_alert(room_index: int) -> void:
	var room_centers = [
		Vector3(200,  0, 350),
		Vector3(750,  0, 350),
		Vector3(1300, 0, 350),
		Vector3(1850, 0, 350),
		Vector3(2400, 0, 350),
	]
	if room_index >= 0 and room_index < room_centers.size():
		alert_target = room_centers[room_index]
	state = State.ALERT
	alert_timer = ALERT_DURATION

func go_alert_position(pos: Vector3) -> void:
	alert_target = Vector3(pos.x, 0, pos.z)
	state = State.ALERT
	alert_timer = ALERT_DURATION
