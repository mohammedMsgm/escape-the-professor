extends Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.02, 0.02)
	add_child(bg)

	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(500, 380)
	center.position = Vector2(-250, -190)
	center.add_theme_constant_override("separation", 22)
	add_child(center)

	var won = GameManager.rooms_completed >= 4

	# Main outcome label
	var outcome = Label.new()
	if won:
		outcome.text = "YOU ESCAPED!"
		outcome.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		outcome.text = "GAME OVER"
		outcome.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	outcome.add_theme_font_size_override("font_size", 48)
	outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(outcome)

	# Reason / flavour
	var reason_text: String
	if won:
		reason_text = "Congratulations! You solved all puzzles\nand escaped the professor's exam!"
	else:
		if GameManager.has_meta("lose_reason"):
			reason_text = GameManager.get_meta("lose_reason")
		else:
			reason_text = "You failed to escape in time."
	var reason = Label.new()
	reason.text = reason_text
	reason.add_theme_font_size_override("font_size", 16)
	reason.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(reason)

	var sep = HSeparator.new()
	center.add_child(sep)

	# Stats
	var stats = Label.new()
	stats.text = "Rooms completed: %d / 4\nTime remaining: %s\nLives left: %d" % [
		GameManager.rooms_completed,
		GameManager.get_time_string(),
		GameManager.lives
	]
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(stats)

	var sep2 = HSeparator.new()
	center.add_child(sep2)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	center.add_child(btn_row)

	var retry_btn = Button.new()
	retry_btn.text = "▶  Play Again"
	retry_btn.custom_minimum_size = Vector2(160, 46)
	retry_btn.add_theme_font_size_override("font_size", 16)
	retry_btn.pressed.connect(_on_retry)
	btn_row.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(140, 46)
	menu_btn.add_theme_font_size_override("font_size", 16)
	menu_btn.pressed.connect(_on_menu)
	btn_row.add_child(menu_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(100, 46)
	quit_btn.add_theme_font_size_override("font_size", 16)
	quit_btn.pressed.connect(_on_quit)
	btn_row.add_child(quit_btn)

func _on_retry() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_menu() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit() -> void:
	get_tree().quit()
