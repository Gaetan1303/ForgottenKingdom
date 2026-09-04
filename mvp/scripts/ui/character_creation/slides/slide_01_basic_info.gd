## Slide 1: base identity fields, portrait and racial power.
class_name Slide01BasicInfo
extends CreationSlideBase

const APPEARANCE_CHOICES := [
	{"id": "homme_balafre", "label": "Homme balafré"},
	{"id": "homme_exile", "label": "Homme exilé"},
	{"id": "femme_des_marches", "label": "Femme des Marches"},
	{"id": "femme_alteree", "label": "Femme altérée"},
]

const CARD_COLUMNS := 2

var _selected_racial_power_id: String = ""


func enter_slide(data: Resource) -> void:
	var appearance := find_child("AppearanceOption", true, false) as OptionButton
	if appearance and appearance.item_count == 0:
		for choice in APPEARANCE_CHOICES:
			var idx := appearance.item_count
			var label: String = str(choice["label"]) if choice.has("label") else ""
			var value: String = str(choice["id"]) if choice.has("id") else ""
			appearance.add_item(label)
			appearance.set_item_metadata(idx, value)

	_populate_racial_power_grid()
	_select_racial_power("")

	if data == null:
		return
	var name_line := find_child("CharacterName", true, false)
	if name_line:
		var name_value: String = ""
		if data.has_method("get"):
			name_value = str(data.call("get", "character_name"))
		_set_text_value(name_line, name_value)
	var clan_line := find_child("ClanName", true, false)
	if clan_line:
		var clan_value: String = ""
		if data.has_method("get"):
			clan_value = str(data.call("get", "clan_name"))
		_set_text_value(clan_line, clan_value)
	if appearance:
		var appearance_value: String = ""
		if data.has_method("get"):
			appearance_value = str(data.call("get", "appearance_id"))
		_select_by_metadata(appearance, appearance_value)
	var racial_value: String = ""
	if data.has_method("get"):
		racial_value = str(data.call("get", "racial_power_id"))
	_select_racial_power(racial_value)
	var portrait_node := find_child("PortraitUploadArea", true, false)
	if portrait_node and portrait_node.has_method("load_from_dict"):
		var portrait_payload: Dictionary = {}
		if data.has_method("get"):
			var temp_payload: Variant = data.call("get", "portrait_payload")
			if temp_payload != null:
				portrait_payload = temp_payload as Dictionary
		portrait_node.load_from_dict(portrait_payload)


func collect_payload() -> Dictionary:
	return {
		"character_name": _text_from_node("CharacterName"),
		"clan_name": _text_from_node("ClanName"),
		"appearance_id": _option_id_from_node("AppearanceOption"),
		"racial_power_id": _selected_racial_power_id,
		"portrait_payload": _portrait_payload(),
	}


func _text_from_node(node_name: String) -> String:
	var node := find_child(node_name, true, false)
	if node is LineEdit:
		return (node as LineEdit).text.strip_edges()
	if node is TextEdit:
		return (node as TextEdit).text.strip_edges()
	return ""


func _set_text_value(node: Node, value: String) -> void:
	if node is LineEdit:
		(node as LineEdit).text = value
	elif node is TextEdit:
		(node as TextEdit).text = value


func _option_id_from_node(node_name: String) -> String:
	var option := find_child(node_name, true, false) as OptionButton
	if option == null or option.item_count <= 0:
		return ""
	var idx := maxi(0, option.selected)
	if idx >= option.item_count:
		idx = option.item_count - 1
	var meta: Variant = option.get_item_metadata(idx)
	return "" if meta == null else str(meta)


func _portrait_payload() -> Dictionary:
	var portrait_node := find_child("PortraitUploadArea", true, false)
	if portrait_node and portrait_node.has_method("to_dict"):
		return portrait_node.to_dict()
	return {}


func _populate_racial_power_grid() -> void:
	var grid := find_child("RacialPowerGrid", true, false) as GridContainer
	if grid == null:
		return
	grid.columns = CARD_COLUMNS
	# allow the grid to expand to available width
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if grid.get_child_count() > 0:
		return
	var traits_data := GameDataLoader.get_character_traits()
	var category := "pouvoirs"
	var group := traits_data.get(category, {}) as Dictionary
	var keys := group.keys()
	keys.sort()
	for trait_id in keys:
		var trait_data = group[trait_id]
		grid.add_child(_build_trait_card(str(trait_id), trait_data as Dictionary, category))

	# Ajuste les largeurs des cards une fois le layout calculé
	call_deferred("_adjust_card_min_width")


func _build_trait_card(trait_id, data, category):
	var card := Button.new()
	card.name = "%s_%s" % [category.capitalize(), trait_id]
	card.text = ""
	card.custom_minimum_size = Vector2(260, 132)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.set_meta("trait_id", trait_id)
	card.set_meta("trait_category", category)
	card.add_theme_stylebox_override("normal", _make_card_style(false))
	card.add_theme_stylebox_override("hover", _make_card_style(false))
	card.add_theme_stylebox_override("pressed", _make_card_style(false))
	card.add_theme_stylebox_override("focus", _make_card_style(false))
	card.connect("pressed", Callable(self, "_select_racial_power").bind(trait_id))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	# Button is not a Container; force child to occupy full card rect.
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
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var title := Label.new()
	title.text = str(data.get("label", trait_id))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = 0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var description := Label.new()
	description.text = str(data.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 11)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.horizontal_alignment = 0
	description.custom_minimum_size = Vector2(0, 48)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(description)

	return card

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


func _select_racial_power(power_id: String) -> void:
	_selected_racial_power_id = power_id
	var grid := find_child("RacialPowerGrid", true, false) as GridContainer
	if grid == null:
		return
	for child in grid.get_children():
		if child is Button:
			var card := child as Button
			var card_category := str(card.get_meta("trait_category", ""))
			var card_trait_id := str(card.get_meta("trait_id", ""))
			var selected := (card_category == "pouvoirs" and card_trait_id == power_id)
			var style := _make_card_style(selected)
			card.add_theme_stylebox_override("normal", style)
			card.add_theme_stylebox_override("hover", style)
			card.add_theme_stylebox_override("pressed", style)
			card.add_theme_stylebox_override("focus", style)

	# push selection to manager immediately and save draft
	if manager != null and manager.has_method("update_from_slide"):
		manager.update_from_slide(manager.get_current_step(), {"racial_power_id": _selected_racial_power_id})
		if manager.has_method("save_draft"):
			manager.save_draft()


func _select_by_metadata(option: OptionButton, wanted_id: String) -> void:
	if option == null or wanted_id.is_empty():
		return
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == wanted_id:
			option.select(i)
			return


func _adjust_card_min_width() -> void:
	var grid := find_child("RacialPowerGrid", true, false) as GridContainer
	if grid == null:
		return
	# Si la grille n'a pas encore de taille utile, réessayer plus tard
	if grid.size.x <= 0:
		call_deferred("_adjust_card_min_width")
		return

	var columns: int = max(1, int(grid.columns))
	var parent := grid.get_parent()
	var parent_width: float = 0.0
	if parent and parent is Control:
		parent_width = float((parent as Control).size.x)
	var total_width: float = parent_width if parent_width > 0.0 else float(grid.size.x)
	var spacing: float = 12.0
	var per: int = int((total_width - spacing * (columns - 1)) / columns) - 16
	if per < 160:
		per = 160

	# ensure the grid requests enough width to host columns
	if parent_width > 0.0:
		grid.custom_minimum_size = Vector2(parent_width, grid.custom_minimum_size.y)

	for child in grid.get_children():
		if child is Button:
			var btn := child as Button
			btn.custom_minimum_size = Vector2(per, btn.custom_minimum_size.y)
