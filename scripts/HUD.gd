extends CanvasLayer

var timer_label: Label
var lives_label: Label
var noise_bar: ProgressBar
var room_label: Label
var flash_rect: ColorRect
var flash_timer: float = 0.0

const ROOM_NAMES = [
	"Computer Lab",
	"Algorithm Room",
	"Cybersecurity Room",
	"AI Lab",
	"Professor's Office"
]

func _ready() -> void:
	_build_hud()
	GameManager.connect("noise_changed", _on_noise_changed)
	GameManager.connect("life_lost", _on_life_lost)
	GameManager.connect("room_completed", _on_room_completed)

func _build_hud() -> void:
	# Background panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 60)
	add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	# Timer
	var timer_vbox = VBoxContainer.new()
	hbox.add_child(timer_vbox)
	var timer_title = Label.new()
	timer_title.text = "TIME"
	timer_title.add_theme_font_size_override("font_size", 11)
	timer_vbox.add_child(timer_title)
	timer_label = Label.new()
	timer_label.text = "30:00"
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	timer_vbox.add_child(timer_label)

	# Lives
	var lives_vbox = VBoxContainer.new()
	hbox.add_child(lives_vbox)
	var lives_title = Label.new()
	lives_title.text = "LIVES"
	lives_title.add_theme_font_size_override("font_size", 11)
	lives_vbox.add_child(lives_title)
	lives_label = Label.new()
	lives_label.text = "❤ ❤ ❤"
	lives_label.add_theme_font_size_override("font_size", 18)
	lives_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lives_vbox.add_child(lives_label)

	# Noise
	var noise_vbox = VBoxContainer.new()
	noise_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(noise_vbox)
	var noise_title = Label.new()
	noise_title.text = "NOISE"
	noise_title.add_theme_font_size_override("font_size", 11)
	noise_vbox.add_child(noise_title)
	noise_bar = ProgressBar.new()
	noise_bar.min_value = 0
	noise_bar.max_value = 100
	noise_bar.value = 0
	noise_bar.custom_minimum_size = Vector2(150, 20)
	noise_vbox.add_child(noise_bar)

	# Room name
	var room_vbox = VBoxContainer.new()
	room_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(room_vbox)
	var room_title = Label.new()
	room_title.text = "ROOM"
	room_title.add_theme_font_size_override("font_size", 11)
	room_vbox.add_child(room_title)
	room_label = Label.new()
	room_label.text = "Computer Lab"
	room_label.add_theme_font_size_override("font_size", 14)
	room_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	room_vbox.add_child(room_label)

	# Red flash overlay for alarm
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 0, 0, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)

func _process(delta: float) -> void:
	if not GameManager.game_active:
		return

	# Update timer
	var t = GameManager.time_remaining
	timer_label.text = GameManager.get_time_string()
	if t < 300.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.0))
	else:
		timer_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))

	# Flash decay
	if flash_timer > 0.0:
		flash_timer -= delta
		flash_rect.color = Color(1, 0, 0, min(0.4, flash_timer * 0.8))
	else:
		flash_rect.color = Color(1, 0, 0, 0)

func _on_noise_changed(value: float) -> void:
	noise_bar.value = value

func _on_life_lost(lives_remaining: int) -> void:
	match lives_remaining:
		3: lives_label.text = "❤ ❤ ❤"
		2: lives_label.text = "❤ ❤ 🖤"
		1: lives_label.text = "❤ 🖤 🖤"
		0: lives_label.text = "🖤 🖤 🖤"

func _on_room_completed(room_index: int) -> void:
	pass

func update_room_name(room_index: int) -> void:
	if room_index >= 0 and room_index < ROOM_NAMES.size():
		room_label.text = ROOM_NAMES[room_index]

func trigger_alarm_flash() -> void:
	flash_timer = 0.6
