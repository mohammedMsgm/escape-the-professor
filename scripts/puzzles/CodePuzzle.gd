extends Node

# Room 1: Code Puzzle
# for i in range(?): print(i) — must print 0 to 9. Answer: 10

signal puzzle_solved()
signal puzzle_failed()

var overlay: CanvasLayer
var answer_input: LineEdit
var room_index: int = 0

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
	vbox.custom_minimum_size = Vector2(500, 350)
	vbox.position = Vector2(-250, -175)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_add_title(vbox, "[ COMPUTER LAB TERMINAL ]", Color(0.3, 1.0, 0.5))
	_add_label(vbox, "Complete the code to print numbers 0 through 9:")
	_add_spacer(vbox, 8)

	var code_bg = PanelContainer.new()
	vbox.add_child(code_bg)
	var code_label = Label.new()
	code_label.text = "for i in range( ? ):\n    print(i)"
	code_label.add_theme_font_size_override("font_size", 16)
	code_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	code_bg.add_child(code_label)

	_add_spacer(vbox, 8)
	_add_label(vbox, "What number should replace '?'")

	answer_input = LineEdit.new()
	answer_input.placeholder_text = "Enter your answer..."
	answer_input.custom_minimum_size = Vector2(200, 36)
	answer_input.add_theme_font_size_override("font_size", 16)
	vbox.add_child(answer_input)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var submit_btn = Button.new()
	submit_btn.text = "Submit"
	submit_btn.custom_minimum_size = Vector2(120, 38)
	submit_btn.add_theme_font_size_override("font_size", 15)
	submit_btn.pressed.connect(_on_submit)
	btn_row.add_child(submit_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(120, 38)
	cancel_btn.add_theme_font_size_override("font_size", 15)
	cancel_btn.pressed.connect(_on_cancel)
	btn_row.add_child(cancel_btn)

	answer_input.grab_focus()

func _on_submit() -> void:
	var answer = answer_input.text.strip_edges()
	if answer == "10":
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

# --- UI helpers ---
func _make_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	return panel

func _add_title(parent: Node, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
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
