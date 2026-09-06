## Complète les infobulles souris de Godot par une lecture au focus clavier.
extends RefCounted

static func bind(control: Control) -> void:
	if control == null or control.has_meta("keyboard_tooltip"):
		return
	control.set_meta("keyboard_tooltip", true)
	control.focus_mode = Control.FOCUS_ALL
	var layer := CanvasLayer.new()
	layer.layer = 90
	control.add_child(layer)
	var panel := PanelContainer.new()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.06, 0.98)
	style.border_color = Color(0.8, 0.68, 1)
	style.set_border_width_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var text := RichTextLabel.new()
	text.fit_content = false
	text.scroll_active = true
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("normal_font_size", 16)
	text.add_theme_color_override("default_color", Color.WHITE)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(text)
	control.focus_entered.connect(func():
		text.text = control.tooltip_text
		var viewport := control.get_viewport_rect().size
		var width := minf(480, viewport.x - 56)
		var estimated_lines := text.text.split("\n").size() + int(ceil(float(text.text.length()) / 60.0))
		text.custom_minimum_size = Vector2(width, minf(viewport.y - 72, maxf(100, estimated_lines * 24)))
		panel.size = text.custom_minimum_size + Vector2(24, 24)
		panel.position = Vector2(maxf(16, viewport.x - panel.size.x - 16), 24)
		panel.visible = not text.text.is_empty()
	)
	control.focus_exited.connect(func(): panel.hide())
	control.visibility_changed.connect(func():
		if not control.is_visible_in_tree(): panel.hide()
	)

	control.gui_input.connect(func(event: InputEvent):
		if panel.visible and event is InputEventKey and event.pressed:
			if event.keycode == KEY_PAGEDOWN or event.keycode == KEY_PAGEUP:
				text.get_v_scroll_bar().value += 120 if event.keycode == KEY_PAGEDOWN else -120
				control.accept_event()
	)
