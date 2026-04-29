extends Node

# Room 4 (Final): MCQ Puzzle
# "Complexity of Binary Search?" A: O(n)  B: O(log n) ✓  C: O(n log n)

signal puzzle_solved()
signal puzzle_failed()

var overlay: CanvasLayer
var selected_answer: String = ""
var answer_buttons: Dictionary = {}

func show_puzzle() -> void:
	GameManager.open_puzzle()
	_build_ui()

func _build_ui() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 10
	get_tree().current_scene.add_child(overlay)

	var panel = _make_panel()
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(560, 400)
	vbox.position = Vector2(-280, -200)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	_add_title(vbox, "[ PROFESSOR'S OFFICE — FINAL EXAM ]", Color(1.0, 0.4, 0.4))
	_add_spacer(vbox, 8)

	var question_bg = PanelContainer.new()
	vbox.add_child(question_bg)
	var q_label = Label.new()
	q_label.text = "What is the time complexity of Binary Search?"
	q_label.add_theme_font_size_override("font_size", 18)
	q_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_bg.add_child(q_label)

	_add_spacer(vbox, 12)
	_add_label(vbox, "Select one answer:")

	var options = [
		["A", "O(n)          — Linear time"],
		["B", "O(log n)      — Logarithmic time"],
		["C", "O(n log n)    — Linearithmic time"],
	]

	for opt in options:
		var btn = Button.new()
		btn.text = "  %s)  %s" % [opt[0], opt[1]]
		btn.custom_minimum_size = Vector2(400, 48)
		btn.add_theme_font_size_override("font_size", 16)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var key = opt[0]
		btn.pressed.connect(func(): _select_answer(key))
		vbox.add_child(btn)
		answer_buttons[key] = btn

	_add_spacer(vbox, 8)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var submit_btn = Button.new()
	submit_btn.text = "Submit Answer"
	submit_btn.custom_minimum_size = Vector2(160, 40)
	submit_btn.add_theme_font_size_override("font_size", 15)
	submit_btn.pressed.connect(_on_submit)
	btn_row.add_child(submit_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(_on_cancel)
	btn_row.add_child(cancel_btn)

func _select_answer(key: String) -> void:
	selected_answer = key
	for k in answer_buttons:
		if k == key:
			answer_buttons[k].add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			answer_buttons[k].remove_theme_color_override("font_color")

func _on_submit() -> void:
	if selected_answer == "":
		return
	if selected_answer == "B":
		_close()
		emit_signal("puzzle_solved")
	else:
		_show_feedback("WRONG! Alarm triggered!", Color(1, 0.2, 0.2))
		await get_tree().create_timer(1.2).timeout
		_close()
		emit_signal("puzzle_failed")

func _on_cancel() -> void:
	_close()
	GameManager.close_puzzle()

func _close() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null
	GameManager.close_puzzle()

func _show_feedback(msg: String, color: Color) -> void:
	if overlay == null:
		return
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.position = Vector2(-150, 80)
	overlay.add_child(lbl)

func _make_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	return panel

func _add_title(parent: Node, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _add_label(parent: Node, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)

func _add_spacer(parent: Node, height: int) -> void:
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, height)
	parent.add_child(sp)
