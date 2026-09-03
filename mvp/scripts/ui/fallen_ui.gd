## Cohesive visual language for Royaume déchu / Chroniques des Neuf Nobles.
## Pure presentation helper: no gameplay state, navigation or signals live here.
extends RefCounted

const BG := Color("09050d")
const BG_WINE := Color("170712")
const PANEL := Color("160d1d")
const PANEL_RAISED := Color("211128")
const PANEL_SOFT := Color("28172f")
const BORDER := Color("5f3b69")
const BORDER_SOFT := Color("3a2742")
const VIOLET := Color("9a52b3")
const VIOLET_BRIGHT := Color("c078d5")
const CRIMSON := Color("b63b4b")
const CRIMSON_BRIGHT := Color("dc5a67")
const GOLD := Color("d7b56d")
const GOLD_SOFT := Color("a98952")
const TEXT := Color("f3ecf3")
const MUTED := Color("b6a8b8")
const DIM := Color("7e7182")
const SUCCESS := Color("77b58a")
const DANGER := Color("db6670")

const EMBLEM_PATH := "res://assets/icon/jeu.png"


static func apply(root: Control, screen_kind: String = "default") -> void:
	if root == null:
		return
	var shared_theme := build_theme()
	root.theme = shared_theme
	_propagate_theme(root, shared_theme)
	_apply_root_background(root, screen_kind)
	_style_existing_tree(root, screen_kind)
	if screen_kind != "narrative" and screen_kind != "intro":
		_install_watermark(root, screen_kind)


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 15

	# Labels / readable text.
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_selected_color", "RichTextLabel", Color("ffffff"))
	theme.set_color("selection_color", "RichTextLabel", Color(0.55, 0.24, 0.63, 0.45))

	# Containers / panels.
	theme.set_stylebox("panel", "PanelContainer", _panel_style(PANEL, BORDER_SOFT, 1, 12, 12))
	theme.set_stylebox("panel", "Panel", _panel_style(PANEL, BORDER_SOFT, 1, 12, 12))

	# Buttons.
	var btn_normal := _panel_style(Color("211329"), Color("5b3d66"), 1, 9, 14)
	var btn_hover := _panel_style(Color("32203b"), VIOLET, 1, 9, 14)
	var btn_pressed := _panel_style(Color("421c2c"), GOLD_SOFT, 2, 9, 14)
	var btn_disabled := _panel_style(Color("151018"), Color("2c2330"), 1, 9, 14)
	var btn_focus := _panel_style(Color(0, 0, 0, 0), GOLD, 2, 9, 12)
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color("fff7e6"))
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", DIM)
	theme.set_font_size("font_size", "Button", 15)

	# Text / numeric fields.
	var field := _panel_style(Color("100914"), Color("4a3351"), 1, 7, 10)
	var field_focus := _panel_style(Color("180d1d"), VIOLET, 2, 7, 9)
	for type_name in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", type_name, field)
		theme.set_stylebox("focus", type_name, field_focus)
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_placeholder_color", type_name, DIM)
		theme.set_color("caret_color", type_name, GOLD)

	# ItemList selection states (saves, targets, etc.).
	theme.set_stylebox("panel", "ItemList", _panel_style(Color("100914"), BORDER_SOFT, 1, 8, 6))
	theme.set_stylebox("hovered", "ItemList", _panel_style(Color("25152d"), VIOLET, 1, 6, 4))
	theme.set_stylebox("selected", "ItemList", _panel_style(Color("38203a"), GOLD_SOFT, 1, 6, 4))
	theme.set_stylebox("selected_focus", "ItemList", _panel_style(Color("422441"), GOLD, 2, 6, 3))
	theme.set_color("font_color", "ItemList", TEXT)
	theme.set_color("font_selected_color", "ItemList", Color("fff5dc"))

	# Progress bars.
	theme.set_stylebox("background", "ProgressBar", _panel_style(Color("0c0810"), BORDER_SOFT, 1, 6, 2))
	theme.set_stylebox("fill", "ProgressBar", _panel_style(Color("6f2e79"), VIOLET_BRIGHT, 1, 6, 2))
	theme.set_color("font_color", "ProgressBar", TEXT)

	# Checkboxes and options inherit button colors, but keep labels soft.
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_hover_color", "CheckBox", GOLD)
	theme.set_color("font_pressed_color", "CheckBox", GOLD)

	# Separators.
	var sep := StyleBoxLine.new()
	sep.color = Color(0.48, 0.31, 0.53, 0.65)
	sep.thickness = 1
	theme.set_stylebox("separator", "HSeparator", sep)
	var vsep := StyleBoxLine.new()
	vsep.color = Color(0.48, 0.31, 0.53, 0.65)
	vsep.thickness = 1
	vsep.vertical = true
	theme.set_stylebox("separator", "VSeparator", vsep)

	# Shared spacing makes screens feel like one product.
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("h_separation", "GridContainer", 10)
	theme.set_constant("v_separation", "GridContainer", 10)

	return theme


static func primary_button(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _panel_style(Color("3a1825"), GOLD_SOFT, 1, 9, 14))
	button.add_theme_stylebox_override("hover", _panel_style(Color("552334"), GOLD, 2, 9, 13))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("6b283a"), Color("f0ce84"), 2, 9, 13))
	button.add_theme_color_override("font_color", Color("fff3dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))


static func danger_button(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _panel_style(Color("2d1119"), Color("77313c"), 1, 9, 14))
	button.add_theme_stylebox_override("hover", _panel_style(Color("461722"), CRIMSON_BRIGHT, 2, 9, 13))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("5c1b28"), CRIMSON_BRIGHT, 2, 9, 13))
	button.add_theme_color_override("font_color", Color("ffd9dd"))


static func menu_button(button: Button, prominent: bool = false) -> void:
	if button == null:
		return
	button.flat = false
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 74
	var normal_color := Color("1d1024") if not prominent else Color("341522")
	var normal_border := Color("52365d") if not prominent else GOLD_SOFT
	button.add_theme_stylebox_override("normal", _panel_style(normal_color, normal_border, 1, 11, 16))
	button.add_theme_stylebox_override("hover", _panel_style(Color("34203c"), GOLD if prominent else VIOLET, 2, 11, 15))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("481d32"), GOLD, 2, 11, 15))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0, 0, 0, 0), GOLD, 2, 11, 15))


static func card_style(selected: bool = false) -> StyleBoxFlat:
	if selected:
		var selected_style := _panel_style(Color("27131e"), GOLD, 2, 10, 10)
		selected_style.shadow_color = Color(0.55, 0.18, 0.45, 0.35)
		selected_style.shadow_size = 8
		return selected_style
	var style := _panel_style(Color("120b17"), Color("49304f"), 1, 10, 10)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	return style


static func _panel_style(bg: Color, border: Color, border_width: int, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func _apply_root_background(root: Control, screen_kind: String) -> void:
	var bg := root.find_child("Background", true, false)
	if bg is ColorRect:
		var rect := bg as ColorRect
		match screen_kind:
			"main_menu": rect.color = Color(0, 0, 0, 0)
			"narrative", "intro": rect.color = Color("08050d")
			"clan", "dungeon", "map": rect.color = Color("09050f")
			_: rect.color = BG


static func _propagate_theme(node: Node, shared_theme: Theme) -> void:
	if node is Control:
		(node as Control).theme = shared_theme
	for child in node.get_children():
		_propagate_theme(child, shared_theme)


static func _style_existing_tree(node: Node, screen_kind: String) -> void:
	if node is Control:
		_style_node(node as Control, screen_kind)
	for child in node.get_children():
		_style_existing_tree(child, screen_kind)


static func _style_node(node: Control, screen_kind: String) -> void:
	var lower := node.name.to_lower()
	if node is Label:
		var label := node as Label
		if lower.contains("title") or lower.contains("titre") or lower.contains("header"):
			label.add_theme_color_override("font_color", GOLD)
			if label.get_theme_font_size("font_size") < 18:
				label.add_theme_font_size_override("font_size", 18)
		elif lower.contains("subtitle") or lower.contains("periode") or lower.contains("description") or lower.contains("desc"):
			label.add_theme_color_override("font_color", MUTED)
	elif node is PanelContainer:
		if lower.contains("dialog") or lower.contains("textbox"):
			node.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.025, 0.075, 0.94), Color(0.51, 0.31, 0.57, 0.8), 1, 12, 14))
		elif lower.contains("header"):
			node.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.035, 0.08, 0.96), GOLD_SOFT, 1, 8, 10))
	elif node is Button:
		var button := node as Button
		if screen_kind == "main_menu" and lower.begins_with("btn"):
			if lower.contains("nouvelle"):
				menu_button(button, true)
			elif lower.contains("quitter"):
				menu_button(button, false)
				danger_button(button)
			else:
				menu_button(button, false)
		elif lower.contains("next") or lower.contains("continuer") or lower.contains("confirm") or lower.contains("fintour") or lower.contains("load"):
			primary_button(button)
		elif lower.contains("delete") or lower.contains("quitter") or lower.contains("attaquer"):
			danger_button(button)
	if screen_kind == "narrative":
		if lower == "chaptertitle":
			(node as Label).add_theme_color_override("font_color", GOLD)
		if lower == "pageindicator":
			(node as Label).add_theme_color_override("font_color", MUTED)


static func _install_watermark(root: Control, screen_kind: String) -> void:
	# Do not inject free-positioned decoration into Container roots: containers own child layout.
	if root is Container:
		return
	if root.get_node_or_null("FallenWatermark") != null:
		return
	if not ResourceLoader.exists(EMBLEM_PATH):
		return
	var tex := load(EMBLEM_PATH) as Texture2D
	if tex == null:
		return
	var mark := TextureRect.new()
	mark.name = "FallenWatermark"
	mark.texture = tex
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.modulate = Color(1, 1, 1, 0.045 if screen_kind != "main_menu" else 0.10)
	mark.anchor_left = 1.0
	mark.anchor_top = 0.0
	mark.anchor_right = 1.0
	mark.anchor_bottom = 0.0
	mark.offset_left = -310.0
	mark.offset_top = 18.0
	mark.offset_right = -18.0
	mark.offset_bottom = 310.0
	root.add_child(mark)
	root.move_child(mark, min(1, root.get_child_count() - 1))
