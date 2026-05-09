## Slide 3: feats and abilities cards.
class_name Slide03FeatsAbilities
extends CreationSlideBase

var _selected_feats: Array = []
var _selected_ability: String = ""

func enter_slide(data: Resource) -> void:
	_selected_feats = []
	_selected_ability = ""
	if data != null and data.has_method("get"):
		var tmp_feats = data.get("selected_feats")
		if tmp_feats != null:
			_selected_feats = tmp_feats as Array
		var tmp_abilities = data.get("selected_abilities")
		if tmp_abilities != null:
			var ability_array = tmp_abilities as Array
			if ability_array.size() > 0:
				_selected_ability = str(ability_array[0])

	_build_feat_cards()
	_build_ability_cards()
	_update_card_selection()

func collect_payload() -> Dictionary:
	var abilities = []
	if _selected_ability != "":
		abilities.append(_selected_ability)
	return {
		"selected_feats": _selected_feats.duplicate(),
		"selected_abilities": abilities,
	}

func _build_feat_cards() -> void:
	var container = find_child("FeatCardGrid", true, false) as GridContainer
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

	var feats = _get_feats_source()
	var fkeys: Array = feats.keys()
	fkeys.sort()
	for fid in fkeys:
		var f = feats[fid] as Dictionary
		if _entry_has_level_prereq(f):
			continue
		var card = _create_card("don", fid, f)
		container.add_child(card)

func _build_ability_cards() -> void:
	var container = find_child("AbilityCardGrid", true, false) as GridContainer
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

	var abilities = _get_abilities_source()
	var akeys: Array = abilities.keys()
	akeys.sort()
	for aid in akeys:
		var a = abilities[aid] as Dictionary
		if _entry_has_level_prereq(a):
			continue
		var card = _create_card("ability", aid, a)
		container.add_child(card)

func _create_card(kind: String, id: String, data: Dictionary) -> Button:
	var button = Button.new()
	button.toggle_mode = true
	button.text = ""
	button.name = "%sCard_%s" % [kind, id]
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(420, 300)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.connect("toggled", Callable(self, "_on_card_toggled").bind(kind, id))
	button.add_theme_stylebox_override("normal", _make_card_style(false))
	button.add_theme_stylebox_override("hover", _make_card_style(false))
	button.add_theme_stylebox_override("pressed", _make_card_style(true))
	button.add_theme_stylebox_override("focus", _make_card_style(true))
	button.add_theme_stylebox_override("checked", _make_card_style(true))

	var layout = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)
	button.add_child(layout)

	var title = Label.new()
	title.text = _get_entry_name(data, id)
	title.add_theme_font_size_override("font_size", 16)
	var title_color = Color("e2a964") if kind == "don" else Color("7cc59f")
	title.add_theme_color_override("font_color", title_color)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size = Vector2(0, 28)
	title.clip_text = true
	layout.add_child(title)

	var info_box = HBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	info_box.custom_minimum_size = Vector2(0, 28)
	info_box.add_theme_constant_override("separation", 8)
	layout.add_child(info_box)

	var type_badge = Label.new()
	type_badge.text = "Don" if kind == "don" else "Capacité"
	type_badge.add_theme_color_override("font_color", Color(1, 1, 1))
	type_badge.add_theme_font_size_override("font_size", 13)
	type_badge.add_theme_stylebox_override("panel", _make_type_badge_style(kind))
	type_badge.clip_text = true
	type_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	type_badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	type_badge.custom_minimum_size = Vector2(100, 24)
	info_box.add_child(type_badge)

	var prereq_label = Label.new()
	prereq_label.text = "Pré-requis : %s" % _get_prerequis_text(data)
	prereq_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	prereq_label.add_theme_font_size_override("font_size", 13)
	prereq_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prereq_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	prereq_label.custom_minimum_size = Vector2(0, 24)
	prereq_label.clip_text = true
	info_box.add_child(prereq_label)

	var effect = Label.new()
	effect.text = "Effet: %s" % _get_effects_text(data)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	effect.add_theme_font_size_override("font_size", 13)
	effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	effect.custom_minimum_size = Vector2(0, 28)
	layout.add_child(effect)

	var description_box = Control.new()
	description_box.custom_minimum_size = Vector2(0, 180)
	description_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description_box.clip_contents = true
	layout.add_child(description_box)

	var description = Label.new()
	description.text = "Description: %s" % str(data.get("description", "Aucune description disponible."))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	description.add_theme_font_size_override("font_size", 12)
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.clip_text = true
	description.set_anchors_preset(Control.PRESET_FULL_RECT)
	description.offset_left = 0
	description.offset_top = 0
	description.offset_right = 0
	description.offset_bottom = 0
	description_box.add_child(description)

	button.set_pressed(_is_entry_selected(kind, id))
	return button

func _on_card_toggled(pressed: bool, kind: String, id: String) -> void:
	if kind == "don":
		if pressed:
			if not _selected_feats.has(id):
				if _selected_feats.size() >= 2:
					var btn = _find_card_button(kind, id)
					if btn:
						btn.set_pressed(false)
					return
				_selected_feats.append(id)
		else:
			_selected_feats.erase(id)
	else:
		if pressed:
			_selected_ability = id
			_deselect_other_ability_cards(id)
		else:
			if _selected_ability == id:
				_selected_ability = ""

func _find_card_button(kind: String, id: String) -> Button:
	var root_name = "%sCard_%s" % [kind, id]
	var root = find_child(root_name, true, false)
	if root is Button:
		return root
	return null

func _deselect_other_ability_cards(except_id: String) -> void:
	var abilities = GameDataLoader.get_abilities()
	for aid in abilities.keys():
		if str(aid) != except_id:
			var btn = _find_card_button("ability", str(aid))
			if btn:
				btn.set_pressed(false)

func _update_card_selection() -> void:
	for fid in _selected_feats:
		var btn = _find_card_button("don", fid)
		if btn:
			btn.set_pressed(true)
	if _selected_ability != "":
		var btn = _find_card_button("ability", _selected_ability)
		if btn:
			btn.set_pressed(true)

func _is_entry_selected(kind: String, id: String) -> bool:
	if kind == "don":
		return _selected_feats.has(id)
	return _selected_ability == id

func _make_card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("342a23") if selected else Color("1d1612")
	style.border_color = Color("d49e5d") if selected else Color("5b4d40")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	return style

func _make_type_badge_style(kind: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("c17b39") if kind == "don" else Color("3a6f55")
	style.border_color = Color("e2a964") if kind == "don" else Color("7cc59f")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 8
	style.content_margin_top = 4
	style.content_margin_right = 8
	style.content_margin_bottom = 4
	return style

func _get_entry_name(data: Dictionary, id: String) -> String:
	return str(data.get("name", data.get("nom", id)))

func _get_entry_type(data: Dictionary, kind: String) -> String:
	var value = str(data.get("type", "")).strip_edges().to_lower()
	if value != "":
		return value
	if kind == "don":
		return "passif"
	return "active"

func _get_effects_text(data: Dictionary) -> String:
	var effects = data.get("effects", data.get("effets", {}))
	if effects is Dictionary and effects.size() > 0:
		return _format_effects(effects)
	if effects is String and str(effects).strip_edges() != "":
		return str(effects)
	return "Aucun effet défini"

func _format_effects(effects: Dictionary) -> String:
	var parts: Array = []
	for key in effects.keys():
		parts.append("%s: %s" % [str(key).capitalize(), str(effects[key])])
	return _join_parts(parts, ", ")

func _get_prerequis_text(data: Dictionary) -> String:
	if data.has("prerequis"):
		var prereq = data.get("prerequis")
		match typeof(prereq):
			TYPE_STRING:
				return str(prereq)
			TYPE_DICTIONARY:
				return _format_prereq_dict(prereq)
			TYPE_ARRAY:
				return _format_string_list(prereq)
			_:
				return str(prereq)
	if data.has("disponible_des"):
		return str(data.get("disponible_des"))
	return "Aucun"

func _format_prereq_dict(prereq: Dictionary) -> String:
	var parts: Array = []
	for key in prereq.keys():
		parts.append("%s: %s" % [str(key).capitalize(), str(prereq[key])])
	return _join_parts(parts, ", ")

func _format_string_list(values: Array) -> String:
	var parts: Array = []
	for v in values:
		parts.append(str(v))
	return _join_parts(parts, ", ")

func _join_parts(parts: Array, separator: String) -> String:
	var text: String = ""
	for i in range(parts.size()):
		if i > 0:
			text += separator
		text += str(parts[i])
	return text

func _entry_has_level_prereq(data: Dictionary) -> bool:
	if data.has("disponible_des"):
		var ds = str(data.get("disponible_des", "")).to_lower()
		if ds.find("niveau") != -1:
			return true
	if data.has("prerequis"):
		var prereq = data.get("prerequis")
		if typeof(prereq) == TYPE_STRING:
			return str(prereq).to_lower().find("niveau") != -1
		if typeof(prereq) == TYPE_DICTIONARY:
			for key in prereq.keys():
				if str(key).to_lower().find("niveau") != -1:
					return true
				var value = prereq[key]
				if typeof(value) == TYPE_STRING and str(value).to_lower().find("niveau") != -1:
					return true
	return false

func _get_feats_source() -> Dictionary:
	var feats_data = GameDataLoader.get_feats()
	if feats_data.has("dons") and feats_data["dons"] is Dictionary:
		return feats_data["dons"] as Dictionary
	return feats_data

func _get_abilities_source() -> Dictionary:
	var feats_data = GameDataLoader.get_feats()
	if feats_data.has("capacites") and feats_data["capacites"] is Dictionary:
		var out: Dictionary = {}
		var abilities_root := feats_data["capacites"] as Dictionary
		for branch_key in abilities_root.keys():
			if branch_key == "description_globale":
				continue
			var branch = abilities_root[branch_key] as Dictionary
			var caps = branch.get("capacites", []) as Array
			for i in range(caps.size()):
				var cap = caps[i] as Dictionary
				var cap_id := "%s_%02d_%s" % [str(branch_key), i, _slugify(str(cap.get("nom", "capacite")))]
				out[cap_id] = {
					"name": str(cap.get("nom", cap_id)),
					"type": str(cap.get("type", "")),
					"description": str(cap.get("description", "")),
					"prerequis": cap.get("prerequis", null),
					"effects": cap.get("effets", ""),
				}
		if out.size() > 0:
			return out
	return GameDataLoader.get_abilities()

func _slugify(text: String) -> String:
	var s := text.to_lower().strip_edges()
	s = s.replace(" ", "_")
	s = s.replace("'", "")
	s = s.replace("\"", "")
	s = s.replace("-", "_")
	var out := ""
	for i in range(s.length()):
		var ch := s[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
			out += ch
	if out == "":
		return "id"
	return out
