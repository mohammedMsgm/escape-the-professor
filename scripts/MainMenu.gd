extends Control

func _ready() -> void:
	GameManager.reset()
	_build_ui()

func _build_ui() -> void:
	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.10)
	add_child(bg)

	# Animated scanlines (simple)
	var scanlines = ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.color = Color(0, 0, 0, 0.05)
	add_child(scanlines)

	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(500, 450)
	center.position = Vector2(-250, -225)
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	# Title
	var title = Label.new()
	title.text = "ESCAPE THE PROFESSOR"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Campus Survival"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(subtitle)

	var sep = HSeparator.new()
	center.add_child(sep)

	# Story text
	var story = Label.new()
	story.text = "You wake up in a locked university.\nA professor has turned it into an experimental exam.\nSolve 5 puzzles in 30 minutes and escape.\nFailure means permanent confinement."
	story.add_theme_font_size_override("font_size", 14)
	story.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(story)

	var sep2 = HSeparator.new()
	center.add_child(sep2)

	# Controls info
	var controls = Label.new()
	controls.text = "CONTROLS\nWASD — Move   |   Shift — Run (loud!)   |   Ctrl — Crouch (silent)\nE — Interact with terminals and doors"
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(controls)

	var sep3 = HSeparator.new()
	center.add_child(sep3)

	# Start button
	var start_btn = Button.new()
	start_btn.text = "▶  START GAME"
	start_btn.custom_minimum_size = Vector2(240, 54)
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.pressed.connect(_on_start)
	center.add_child(start_btn)

	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(120, 36)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_btn.pressed.connect(_on_quit)
	center.add_child(quit_btn)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit() -> void:
	get_tree().quit()
