extends CharacterBody2D

const WALK_SPEED: float = 150.0
const RUN_SPEED: float = 280.0
const CROUCH_SPEED: float = 60.0

const WALK_NOISE: float = 20.0
const RUN_NOISE: float = 70.0
const CROUCH_NOISE: float = 2.0

var is_crouching: bool = false
var is_running: bool = false
var near_terminal = null  # Callable or null
var near_door = null      # Callable or null
var is_hiding: bool = false

# Noise emission timer
var noise_timer: float = 0.0
const NOISE_INTERVAL: float = 0.3

var _color_rect: ColorRect = null

func _ready() -> void:
	# Create visual body
	var rect = ColorRect.new()
	rect.name = "ColorRect"
	rect.size = Vector2(28, 28)
	rect.position = Vector2(-14, -14)
	rect.color = Color(0.2, 0.5, 1.0)
	add_child(rect)
	_color_rect = rect

	# Collision shape
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	if not GameManager.game_active or GameManager.puzzle_open:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	is_running = Input.is_action_pressed("run") and not Input.is_action_pressed("crouch")
	is_crouching = Input.is_action_pressed("crouch")
	is_hiding = is_crouching

	var speed: float
	var noise_amount: float

	if is_running:
		speed = RUN_SPEED
		noise_amount = RUN_NOISE
		if _color_rect: _color_rect.color = Color(0.1, 0.3, 1.0)
	elif is_crouching:
		speed = CROUCH_SPEED
		noise_amount = CROUCH_NOISE
		if _color_rect: _color_rect.color = Color(0.4, 0.7, 1.0)
	else:
		speed = WALK_SPEED
		noise_amount = WALK_NOISE
		if _color_rect: _color_rect.color = Color(0.2, 0.5, 1.0)

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		noise_timer += delta
		if noise_timer >= NOISE_INTERVAL:
			noise_timer = 0.0
			GameManager.add_noise(noise_amount * NOISE_INTERVAL)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Handle interaction
	if Input.is_action_just_pressed("interact"):
		if near_terminal != null and near_terminal is Callable:
			near_terminal.call()
		elif near_door != null and near_door is Callable:
			near_door.call()

func get_noise_radius() -> float:
	if is_running:
		return 200.0
	elif is_crouching:
		return 40.0
	else:
		return 100.0

func set_near_terminal(callable) -> void:
	near_terminal = callable

func set_near_door(callable) -> void:
	near_door = callable
