extends CharacterBody3D

const WALK_SPEED: float = 150.0
const RUN_SPEED: float = 280.0
const CROUCH_SPEED: float = 60.0

const WALK_NOISE: float = 20.0
const RUN_NOISE: float = 70.0
const CROUCH_NOISE: float = 2.0

var is_crouching: bool = false
var is_running: bool = false
var near_terminal = null
var near_door = null
var is_hiding: bool = false

var noise_timer: float = 0.0
const NOISE_INTERVAL: float = 0.3

var _mat: StandardMaterial3D = null

func _ready() -> void:
	# Body mesh
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(28, 40, 28)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.2, 0.5, 1.0)
	_mat.emission_enabled = true
	_mat.emission = Color(0.1, 0.3, 0.9)
	_mat.emission_energy_multiplier = 0.6
	_mat.metallic = 0.3
	_mat.roughness = 0.4
	mesh_inst.mesh = box
	mesh_inst.set_surface_override_material(0, _mat)
	mesh_inst.position = Vector3(0, 20, 0)
	add_child(mesh_inst)

	# Head accent
	var head_inst = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(18, 12, 18)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.75, 0.6)
	head_mat.roughness = 0.8
	head_inst.mesh = head_box
	head_inst.set_surface_override_material(0, head_mat)
	head_inst.position = Vector3(0, 46, 0)
	add_child(head_inst)

	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(28, 52, 28)
	col.shape = shape
	col.position = Vector3(0, 26, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not GameManager.game_active or GameManager.puzzle_open:
		velocity = Vector3.ZERO
		return

	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		direction.z -= 1
	if Input.is_action_pressed("move_down"):
		direction.z += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	is_running  = Input.is_action_pressed("run")   and not Input.is_action_pressed("crouch")
	is_crouching = Input.is_action_pressed("crouch")
	is_hiding    = is_crouching

	var speed: float
	var noise_amount: float

	if is_running:
		speed = RUN_SPEED
		noise_amount = RUN_NOISE
		if _mat:
			_mat.albedo_color = Color(0.1, 0.3, 1.0)
			_mat.emission = Color(0.05, 0.15, 0.9)
			_mat.emission_energy_multiplier = 1.2
	elif is_crouching:
		speed = CROUCH_SPEED
		noise_amount = CROUCH_NOISE
		if _mat:
			_mat.albedo_color = Color(0.4, 0.7, 1.0)
			_mat.emission = Color(0.2, 0.4, 0.8)
			_mat.emission_energy_multiplier = 0.2
	else:
		speed = WALK_SPEED
		noise_amount = WALK_NOISE
		if _mat:
			_mat.albedo_color = Color(0.2, 0.5, 1.0)
			_mat.emission = Color(0.1, 0.3, 0.9)
			_mat.emission_energy_multiplier = 0.6

	if direction != Vector3.ZERO:
		velocity = direction.normalized() * speed
		noise_timer += delta
		if noise_timer >= NOISE_INTERVAL:
			noise_timer = 0.0
			GameManager.add_noise(noise_amount * NOISE_INTERVAL)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

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
	return 100.0

func set_near_terminal(callable) -> void:
	near_terminal = callable

func set_near_door(callable) -> void:
	near_door = callable
