extends RefCounted
class_name FKUIStyles

# ForgottenKingdom visual language — centralised, non-gameplay UI helpers.
const BG := Color("090611")
const SURFACE := Color("15101f")
const SURFACE_HIGH := Color("21172f")
const SURFACE_SOFT := Color(0.105, 0.065, 0.145, 0.94)
const PRIMARY := Color("a81e3a")
const PRIMARY_GLOW := Color("ff365d")
const PURPLE := Color("762d8d")
const ESSENCE := Color("a45cff")
const GOLD := Color("d4af55")
const GOLD_LIGHT := Color("f1d28a")
const TEXT := Color("f3edf5")
const MUTED := Color("aa9faf")
const BORDER := Color(0.55, 0.27, 0.60, 0.70)

static func panel_style(radius: int = 16, border: Color = BORDER, alpha: float = 0.94) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(SURFACE.r, SURFACE.g, SURFACE.b, alpha)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 8
	return style

static func menu_card_style(state: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.set_border_width_all(1)
	match state:
		"hover":
			style.bg_color = Color(0.18, 0.075, 0.20, 0.96)
			style.border_color = Color(PRIMARY_GLOW.r, PRIMARY_GLOW.g, PRIMARY_GLOW.b, 0.82)
			style.shadow_color = Color(PRIMARY.r, PRIMARY.g, PRIMARY.b, 0.26)
			style.shadow_size = 12
		"pressed":
			style.bg_color = Color(0.22, 0.07, 0.17, 1.0)
			style.border_color = GOLD
		"disabled":
			style.bg_color = Color(0.08, 0.055, 0.10, 0.58)
			style.border_color = Color(0.25, 0.20, 0.28, 0.45)
		_:
			style.bg_color = Color(0.075, 0.045, 0.095, 0.86)
			style.border_color = Color(0.50, 0.22, 0.52, 0.55)
	return style

static func secondary_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", menu_card_style("normal"))
	button.add_theme_stylebox_override("hover", menu_card_style("hover"))
	button.add_theme_stylebox_override("pressed", menu_card_style("pressed"))
	button.add_theme_stylebox_override("disabled", menu_card_style("disabled"))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.40, 0.48, 1.0))
	button.add_theme_font_size_override("font_size", 14)
	button.focus_mode = Control.FOCUS_ALL

static func label_title(label: Label, size: int = 28) -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_font_size_override("font_size", size)

static func label_section(label: Label, size: int = 16) -> void:
	label.add_theme_color_override("font_color", GOLD_LIGHT)
	label.add_theme_font_size_override("font_size", size)

static func label_muted(label: Label, size: int = 12) -> void:
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", size)
