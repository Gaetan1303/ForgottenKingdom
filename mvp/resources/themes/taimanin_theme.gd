extends RefCounted
class_name taimaninThemeBuilder

const PALETTE := {
	"night_blue": Color("#1A1A3E"),
	"night_blue_dark": Color("#121230"),
	"violet_hover": Color("#3D2B6B"),
	"violet_pressed": Color("#2A1F4B"),
	"gold": Color("#C8A84B"),
	"gold_bright": Color("#FFD700"),
	"text_white": Color("#F8F8FF"),
	"text_disabled": Color("#A9A9B8"),
	"shadow_black": Color(0, 0, 0, 0.95),
	"panel_bg": Color("#111433"),
	"progress_bg": Color("#0C0E22"),
	"hp_red": Color("#C63B3B"),
	"mp_blue": Color("#3A7BD5"),
	"atk_green": Color("#3CAD5B")
}

static func create_theme(pixel_font: Font = null) -> Theme:
	var theme := Theme.new()

	# Label
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", PALETTE["text_white"])
	theme.set_color("font_shadow_color", "Label", PALETTE["shadow_black"])
	theme.set_constant("shadow_offset_x", "Label", 2)
	theme.set_constant("shadow_offset_y", "Label", 2)
	if pixel_font != null:
		theme.set_font("font", "Label", pixel_font)

	# Button
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = PALETTE["night_blue"]
	btn_normal.border_color = PALETTE["gold"]
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = PALETTE["violet_hover"]

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = PALETTE["violet_pressed"]
	btn_pressed.shadow_color = Color(0, 0, 0, 0.7)
	btn_pressed.shadow_size = 3

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = PALETTE["night_blue_dark"]
	btn_disabled.border_color = PALETTE["text_disabled"]

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", PALETTE["text_white"])
	theme.set_color("font_hover_color", "Button", PALETTE["text_white"])
	theme.set_color("font_pressed_color", "Button", PALETTE["text_white"])
	theme.set_color("font_disabled_color", "Button", PALETTE["text_disabled"])
	theme.set_font_size("font_size", "Button", 16)
	if pixel_font != null:
		theme.set_font("font", "Button", pixel_font)

	# PanelContainer
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PALETTE["panel_bg"]
	panel_style.border_color = PALETTE["gold"]
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# ProgressBar
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = PALETTE["progress_bg"]
	pb_bg.corner_radius_top_left = 6
	pb_bg.corner_radius_top_right = 6
	pb_bg.corner_radius_bottom_left = 6
	pb_bg.corner_radius_bottom_right = 6
	pb_bg.border_color = PALETTE["gold"]
	pb_bg.border_width_left = 1
	pb_bg.border_width_top = 1
	pb_bg.border_width_right = 1
	pb_bg.border_width_bottom = 1

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = PALETTE["mp_blue"]
	pb_fill.corner_radius_top_left = 6
	pb_fill.corner_radius_top_right = 6
	pb_fill.corner_radius_bottom_left = 6
	pb_fill.corner_radius_bottom_right = 6
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)
	theme.set_font_size("font_size", "ProgressBar", 14)
	theme.set_color("font_color", "ProgressBar", PALETTE["text_white"])
	if pixel_font != null:
		theme.set_font("font", "ProgressBar", pixel_font)

	return theme
