extends CharacterBody2D

enum State { PATROL, ALERT, CHASE }

const PATROL_SPEED: float = 80.0
const ALERT_SPEED: float = 150.0
const CHASE_SPEED: float = 220.0

const VISION_RANGE: float = 250.0
const VISION_ANGLE: float = 70.0  # degrees each side
const HEARING_RANGE: float = 300.0
const CATCH_DISTANCE: float = 30.0

var state: State = State.PATROL
var waypoints: Array = []
var current_waypoint: int = 0
var alert_target: Vector2 = Vector2.ZERO
var alert_timer: float = 0.0
const ALERT_DURATION: float = 8.0

var facing_direction: Vector2 = Vector2(1, 0)
var player_ref: Node = null
var color_rect_node: ColorRect = null

# Vision cone lines (drawn via _draw)
var _draw_vision: bool = true

func _ready() -> void:
	color_rect_node = ColorRect.new()
	color_rect_node.name = "ColorRect"
	color_rect_node.size = Vector2(30, 30)
	color_rect_node.position = Vector2(-15, -15)
	color_rect_node.color = Color(0.9, 0.1, 0.1)
	add_child(color_rect_node)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	col.shape = shape
	add_child(col)

func setup_waypoints(pts: Array) -> void:
	waypoints = pts
	if waypoints.size() > 0:
		current_waypoint = 0

func set_player(p: Node) -> void:
	player_ref = p

func _physics_process(delta: float) -> void:
	if not GameManager.game_active or GameManager.puzzle_open:
		velocity = Vector2.ZERO
		return

	match state:
		State.PATROL:
			_patrol(delta)
		State.ALERT:
			_alert(delta)
		State.CHASE:
			_chase(delta)

	_check_player_detection()
	_check_catch()
	move_and_slide()
	queue_redraw()

func _patrol(delta: float) -> void:
	if waypoints.size() == 0:
		velocity = Vector2.ZERO
		return

	var target = waypoints[current_waypoint]
	var dir = (target - global_position)
	if dir.length() < 10.0:
		current_waypoint = (current_waypoint + 1) % waypoints.size()
	else:
		facing_direction = dir.normalized()
		velocity = facing_direction * PATROL_SPEED

	color_rect_node.color = Color(0.9, 0.1, 0.1)

func _alert(delta: float) -> void:
	alert_timer -= delta
	if alert_timer <= 0.0:
		state = State.PATROL
		return

	var dir = (alert_target - global_position)
	if dir.length() < 15.0:
		velocity = Vector2.ZERO
	else:
		facing_direction = dir.normalized()
		velocity = facing_direction * ALERT_SPEED

	color_rect_node.color = Color(1.0, 0.5, 0.0)

func _chase(delta: float) -> void:
	if player_ref == null:
		state = State.PATROL
		return

	var dir = (player_ref.global_position - global_position)
	if dir.length() > 0.1:
		facing_direction = dir.normalized()
		velocity = facing_direction * CHASE_SPEED

	color_rect_node.color = Color(1.0, 0.0, 0.5)

func _check_player_detection() -> void:
	if player_ref == null:
		return

	var to_player = player_ref.global_position - global_position
	var dist = to_player.length()

	# Vision cone check
	if dist < VISION_RANGE:
		var angle = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
		if abs(angle) < VISION_ANGLE:
			# Check if player is hiding
			if player_ref.is_hiding:
				# Can't see hidden player unless very close
				if dist < 40.0:
					state = State.CHASE
			else:
				state = State.CHASE
			return

	# Hearing check
	var noise_radius = player_ref.get_noise_radius()
	if dist < noise_radius and GameManager.current_noise > 10.0:
		if state != State.CHASE:
			go_alert_position(player_ref.global_position)

	# If was chasing but lost sight
	if state == State.CHASE and dist > VISION_RANGE * 1.5:
		go_alert_position(player_ref.global_position)

func _check_catch() -> void:
	if player_ref == null:
		return
	if state == State.CHASE:
		var dist = (player_ref.global_position - global_position).length()
		if dist < CATCH_DISTANCE:
			GameManager.player_caught()
			# Respawn player at room 1 center
			player_ref.global_position = Vector2(200, 350)
			state = State.PATROL
			if waypoints.size() > 0:
				current_waypoint = 0

func go_alert(room_index: int) -> void:
	# Room centers for alert targeting
	var room_centers = [
		Vector2(200, 350),
		Vector2(750, 350),
		Vector2(1300, 350),
		Vector2(1850, 350),
		Vector2(2400, 350)
	]
	if room_index >= 0 and room_index < room_centers.size():
		alert_target = room_centers[room_index]
	state = State.ALERT
	alert_timer = ALERT_DURATION

func go_alert_position(pos: Vector2) -> void:
	alert_target = pos
	state = State.ALERT
	alert_timer = ALERT_DURATION

func _draw() -> void:
	if not _draw_vision:
		return
	# Draw vision cone
	var cone_color = Color(1.0, 1.0, 0.0, 0.15)
	var points = [Vector2.ZERO]
	var steps = 12
	for i in range(steps + 1):
		var angle = deg_to_rad(-VISION_ANGLE) + deg_to_rad(VISION_ANGLE * 2.0 / steps) * i
		var base_angle = facing_direction.angle()
		var pt = Vector2(cos(base_angle + angle), sin(base_angle + angle)) * VISION_RANGE
		points.append(pt)
	points.append(Vector2.ZERO)
	draw_polygon(PackedVector2Array(points), PackedColorArray([cone_color]))
	# Hearing circle
	draw_arc(Vector2.ZERO, HEARING_RANGE, 0, TAU, 32, Color(1.0, 0.3, 0.3, 0.08), 1.5)
