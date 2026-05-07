## Slide 2: class selection and stat allocation.
class_name Slide02ClassStats
extends CreationSlideBase

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")

const CARD_COLUMNS := 3

var _selected_class_id: String = ""


func enter_slide(data: Resource) -> void:
	_populate_class_cards()
	var class_id := ""
	var incoming_stats: Dictionary = {}

	if data != null and data.has_method("get"):
		var tmp_id: Variant = data.get("class_id")
		if tmp_id != null:
			class_id = str(tmp_id)
		var tmp_stats: Variant = data.get("stats")
		if tmp_stats != null:
			incoming_stats = tmp_stats as Dictionary

	if class_id != "":
		_select_class_card(class_id)
	else:
		# default to first class if none selected yet
		var classes: Dictionary = GameDataLoader.get_classes()
		var keys: Array = classes.keys()
		keys.sort()
		if keys.size() > 0:
			_select_class_card(str(keys[0]))

	if incoming_stats.is_empty():
		return
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(incoming_stats[key]) if incoming_stats.has(key) else default_stat
			node.value = float(stat_value)


func collect_payload() -> Dictionary:
	return {
		"class_id": _selected_class_id,
		"stats": _collect_stats(),
	}


func _collect_stats() -> Dictionary:
	var out := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			out[key] = int(node.value)
	return out


func _populate_class_cards() -> void:
	var grid := find_child("ClassesGrid", true, false) as GridContainer
	if grid == null:
		return
	grid.columns = CARD_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if grid.get_child_count() > 0:
		return

	var classes: Dictionary = GameDataLoader.get_classes()
	var keys: Array = classes.keys()
	keys.sort()
	for key in keys:
		var cdef := classes[key] as Dictionary
		grid.add_child(_build_class_card(str(key), cdef))

	call_deferred("_refresh_class_selection")


func _build_class_card(class_id: String, class_data: Dictionary) -> Button:
	var card := Button.new()
	card.name = "ClassCard_%s" % class_id
	card.text = ""
	card.custom_minimum_size = Vector2(150, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.set_meta("class_id", class_id)
	card.add_theme_stylebox_override("normal", _make_card_style(false))
	card.add_theme_stylebox_override("hover", _make_card_style(false))
	card.add_theme_stylebox_override("pressed", _make_card_style(false))
	card.add_theme_stylebox_override("focus", _make_card_style(false))
	card.connect("pressed", Callable(self, "_on_class_card_pressed").bind(class_id))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 0.0
	margin.offset_top = 0.0
	margin.offset_right = 0.0
	margin.offset_bottom = 0.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0, 0)
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var icon_path := str(class_data.get("icon", ""))
	if icon_path != "":
		if icon_path.begins_with("mvp/"):
			icon_path = icon_path.replace("mvp/", "")
		if not icon_path.begins_with("res://"):
			icon_path = "res://%s" % icon_path
		if not ResourceLoader.exists(icon_path):
			var fallback_name := "%s.webp" % class_id
			var fallback_path := "res://assets/class_icons/%s" % fallback_name
			if ResourceLoader.exists(fallback_path):
				icon_path = fallback_path
		var texture: Texture2D = null
		if ResourceLoader.exists(icon_path):
			texture = load(icon_path) as Texture2D
		if texture != null:
			var icon := TextureRect.new()
			icon.texture = texture
			icon.expand = true
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(0, 64)
			icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(icon)

	var title := Label.new()
	title.text = str(class_data.get("name", class_id))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = 1
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var badge := Label.new()
	badge.text = _class_attribute_label(class_data)
	badge.add_theme_color_override("font_color", _class_attribute_color(class_data))
	badge.add_theme_font_size_override("font_size", 12)
	badge.horizontal_alignment = 1
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(badge)

	return card


func _class_attribute_label(class_data: Dictionary) -> String:
	var primary := class_data.get("primary", []) as Array
	if "magie" in primary:
		return "Magie"
	if "force" in primary:
		return "Force"
	return "Autre"


func _class_attribute_color(class_data: Dictionary) -> Color:
	var primary := class_data.get("primary", []) as Array
	if "magie" in primary:
		return Color8(107, 181, 255)
	if "force" in primary:
		return Color8(255, 142, 124)
	return Color8(190, 190, 190)


func _on_class_card_pressed(class_id: String) -> void:
	_select_class_card(class_id)


func _select_class_card(class_id: String) -> void:
	_selected_class_id = class_id
	_apply_class_stats(class_id)
	_refresh_class_selection()


func _apply_class_stats(class_id: String) -> void:
	var stats := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	if class_id != "":
		var point_buy := CharacterCreationRules.apply_point_buy_for_class(class_id, 10)
		if point_buy.has("stats"):
			stats = point_buy["stats"] as Dictionary

	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(stats[key]) if stats.has(key) else default_stat
			node.value = float(stat_value)


func _refresh_class_selection() -> void:
	var grid := find_child("ClassesGrid", true, false) as GridContainer
	if grid == null:
		return
	for child in grid.get_children():
		if child is Button:
			var card := child as Button
			var card_class_id := str(card.get_meta("class_id", ""))
			var selected := card_class_id == _selected_class_id
			var style := _make_card_style(selected)
			card.add_theme_stylebox_override("normal", style)
			card.add_theme_stylebox_override("hover", style)
			card.add_theme_stylebox_override("pressed", style)
			card.add_theme_stylebox_override("focus", style)


func _make_card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2d1d1a") if selected else Color("181312")
	style.border_color = Color("e0ac6f") if selected else Color("5d4943")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 4
	return style
