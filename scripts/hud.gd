extends CanvasLayer

func _ready() -> void:
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)

	var title_panel := _make_panel()
	title_panel.position = Vector2(32, 28)
	title_panel.custom_minimum_size = Vector2(248, 82)
	ui.add_child(title_panel)

	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", 2)
	title_panel.add_child(title_stack)

	var title := Label.new()
	title.text = "ТИХИЕ ВОДЫ"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("f0e8d4"))
	title_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Северная поляна   ·   День 01"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("b9c6a5"))
	title_stack.add_child(subtitle)

	var hint := _make_panel()
	hint.anchor_left = 0.0
	hint.anchor_top = 1.0
	hint.anchor_right = 0.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 32.0
	hint.offset_top = -86.0
	hint.offset_right = 435.0
	hint.offset_bottom = -28.0
	ui.add_child(hint)

	var hint_text := Label.new()
	hint_text.text = "WASD / стрелки — движение     Shift — быстрый шаг"
	hint_text.add_theme_font_size_override("font_size", 13)
	hint_text.add_theme_color_override("font_color", Color("d9dfce"))
	hint_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_child(hint_text)

	var quiet_note := Label.new()
	quiet_note.text = "Неспешно исследуйте берег"
	quiet_note.anchor_left = 1.0
	quiet_note.anchor_top = 0.0
	quiet_note.anchor_right = 1.0
	quiet_note.anchor_bottom = 0.0
	quiet_note.offset_left = -270.0
	quiet_note.offset_top = 38.0
	quiet_note.offset_right = -34.0
	quiet_note.offset_bottom = 62.0
	quiet_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quiet_note.add_theme_font_size_override("font_size", 12)
	quiet_note.add_theme_color_override("font_color", Color(0.9, 0.91, 0.81, 0.76))
	ui.add_child(quiet_note)

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.10, 0.78)
	style.border_color = Color(0.79, 0.78, 0.62, 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	return panel
