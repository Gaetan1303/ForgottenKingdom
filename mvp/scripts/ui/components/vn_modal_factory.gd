class_name VnModalFactory
extends RefCounted

## Builder des overlays modaux de la visual novel.
## Il centralise le focus, le process mode et les dimensions afin d'éviter
## qu'une popup bloque la narration sur une petite fenêtre ou quand l'arbre
## principal est momentanément en pause.

static func build_tutorial(parent: Node, on_confirm: Callable) -> Dictionary:
	var layer := CanvasLayer.new()
	layer.name = "TutoLayer"
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(layer)

	var dim := _make_dim(0.75)
	layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "TutoPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.08, 0.02, 0.18, 0.97),
		Color(0.6, 0.2, 0.9, 0.9)
	))
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "TutoTitle"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.name = "TutoBody"
	body.bbcode_enabled = true
	body.scroll_active = true
	body.scroll_following = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 13)
	body.add_theme_color_override("default_color", Color(0.88, 0.85, 1.0, 1.0))
	vbox.add_child(body)

	var button := Button.new()
	button.name = "BtnTutoOk"
	button.text = "Compris !"
	button.custom_minimum_size = Vector2(140, 36)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if on_confirm.is_valid():
		button.pressed.connect(on_confirm)
	vbox.add_child(button)

	layer.visible = false
	return {
		"layer": layer,
		"panel": panel,
		"title": title,
		"body": body,
		"button": button,
	}


static func build_recruitment(parent: Node, on_confirm: Callable) -> Dictionary:
	var layer := CanvasLayer.new()
	layer.name = "RecruitLayer"
	layer.layer = 11
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(layer)

	var dim := _make_dim(0.80)
	layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "RecruitPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.05, 0.01, 0.12, 0.97),
		Color(0.2, 0.5, 1.0, 0.8)
	))
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "⚔  Premier Allié"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.8))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var title := Label.new()
	title.name = "RecruitTitle"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var role := Label.new()
	role.name = "RecruitRole"
	role.add_theme_font_size_override("font_size", 13)
	role.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 0.9))
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(role)

	vbox.add_child(HSeparator.new())

	var description := RichTextLabel.new()
	description.name = "RecruitDesc"
	description.bbcode_enabled = true
	description.scroll_active = true
	description.scroll_following = false
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("normal_font_size", 13)
	description.add_theme_color_override("default_color", Color(0.88, 0.85, 1.0, 1.0))
	vbox.add_child(description)

	vbox.add_child(HSeparator.new())

	var stats_label := Label.new()
	stats_label.text = "Statistiques"
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
	vbox.add_child(stats_label)

	var stats := VBoxContainer.new()
	stats.name = "RecruitStats"
	vbox.add_child(stats)

	vbox.add_child(HSeparator.new())

	var button := Button.new()
	button.name = "BtnRecruit"
	button.text = "Accueillir dans le clan"
	button.custom_minimum_size = Vector2(200, 40)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	if on_confirm.is_valid():
		button.pressed.connect(on_confirm)
	vbox.add_child(button)

	layer.visible = false
	return {
		"layer": layer,
		"panel": panel,
		"title": title,
		"role": role,
		"description": description,
		"stats": stats,
		"button": button,
	}


static func fit_centered(panel: Control, viewport_size: Vector2, max_size: Vector2, min_size: Vector2) -> void:
	if panel == null:
		return
	var available := Vector2(
		maxf(240.0, viewport_size.x - 32.0),
		maxf(220.0, viewport_size.y - 32.0)
	)
	var width := minf(max_size.x, available.x)
	var height := minf(max_size.y, available.y)
	width = maxf(minf(min_size.x, available.x), width)
	height = maxf(minf(min_size.y, available.y), height)

	panel.custom_minimum_size = Vector2(width, height)
	panel.offset_left = -width * 0.5
	panel.offset_top = -height * 0.5
	panel.offset_right = width * 0.5
	panel.offset_bottom = height * 0.5


static func _make_dim(alpha: float) -> ColorRect:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	return dim


static func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = border
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style
