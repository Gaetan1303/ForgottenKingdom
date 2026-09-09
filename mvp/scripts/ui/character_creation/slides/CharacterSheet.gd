## Final character sheet for slide 5.
extends CreationSlideBase

const CharacterCreationFlowType = preload("res://scripts/ui/character_creation/creation_flow_controller.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")
const MALE_PORTRAIT = preload("res://assets/images/hero/homme/male.png")
const FEMALE_PORTRAIT = preload("res://assets/images/hero/femme/female.png")

const STAT_UI_ORDER = [
	"force",
	"espionnage",
	"magie",
	"commandement",
	"diplomatie",
	"artisanat",
]

const STAT_LABELS = {
	"force": "Force",
	"espionnage": "Espionnage",
	"magie": "Magie",
	"commandement": "Commandement",
	"diplomatie": "Diplomatie",
	"artisanat": "Artisanat",
}

@onready var _sheet_panel = get_node_or_null("CharacterSheetPanel") as PanelContainer
@onready var _portrait_texture = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/Left/PortraitContainer/PortraitVBox/Portrait") as TextureRect
@onready var _class_tag_label = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/Left/PortraitContainer/PortraitVBox/ClassTag") as Label
@onready var _level_label = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/Left/PortraitContainer/PortraitVBox/LevelTag") as Label

@onready var _identity_grid = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/RightScroll/Right/IdentitySection/IdentityVBox/IdentityGrid") as GridContainer
@onready var _stats_grid = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/RightScroll/Right/StatsSection/StatsVBox/StatsGrid") as VBoxContainer
@onready var _skills_list = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/RightScroll/Right/MidSections/SkillsSection/SkillsVBox/SkillsList") as VBoxContainer
@onready var _equipment_grid = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/RightScroll/Right/MidSections/EquipmentSection/EquipVBox/EquipmentGrid") as GridContainer
@onready var _lore_text = get_node_or_null("CharacterSheetPanel/Margin/Main/Body/RightScroll/Right/LoreSection/LoreVBox/LoreScroll/LoreText") as RichTextLabel

@onready var _confirm_box = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/ConfirmCheckBox") as CheckBox
@onready var _btn_back = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/ButtonsRow/BtnBack") as Button
@onready var _btn_edit = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/ButtonsRow/BtnEdit") as Button
@onready var _btn_validate = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/ButtonsRow/BtnValidate") as Button
@onready var _btn_export = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/ButtonsRow/BtnExport") as Button
@onready var _status_label = get_node_or_null("CharacterSheetPanel/Margin/Main/ActionButtons/StatusLabel") as Label

var _snapshot = {}


func _ready() -> void:
	_wire_buttons()
	_wire_hover_fx()
	if _sheet_panel != null:
		_sheet_panel.modulate = Color(1, 1, 1, 1)


func enter_slide(data: Resource) -> void:
	_snapshot = {}
	if data != null and data.has_method("to_dict"):
		_snapshot = data.to_dict()
	_apply_sheet_data()
	_play_intro_animation()


func collect_payload() -> Dictionary:
	var accepted = false
	if _confirm_box != null:
		accepted = _confirm_box.button_pressed
	return {
		"confirmation_accepted": accepted,
	}


func _wire_buttons() -> void:
	if _btn_back != null and not _btn_back.is_connected("pressed", Callable(self, "_on_back_pressed")):
		_btn_back.connect("pressed", Callable(self, "_on_back_pressed"))
	if _btn_edit != null and not _btn_edit.is_connected("pressed", Callable(self, "_on_edit_pressed")):
		_btn_edit.connect("pressed", Callable(self, "_on_edit_pressed"))
	if _btn_validate != null and not _btn_validate.is_connected("pressed", Callable(self, "_on_validate_pressed")):
		_btn_validate.connect("pressed", Callable(self, "_on_validate_pressed"))
	if _btn_export != null and not _btn_export.is_connected("pressed", Callable(self, "_on_export_pressed")):
		_btn_export.connect("pressed", Callable(self, "_on_export_pressed"))


func _wire_hover_fx() -> void:
	var buttons = [_btn_back, _btn_edit, _btn_validate, _btn_export]
	for btn in buttons:
		if btn == null:
			continue
		if not btn.is_connected("mouse_entered", Callable(self, "_on_btn_hover_enter").bind(btn)):
			btn.connect("mouse_entered", Callable(self, "_on_btn_hover_enter").bind(btn))
		if not btn.is_connected("mouse_exited", Callable(self, "_on_btn_hover_exit").bind(btn)):
			btn.connect("mouse_exited", Callable(self, "_on_btn_hover_exit").bind(btn))


func _apply_sheet_data() -> void:
	_refresh_portrait()
	_fill_identity()
	_fill_stats()
	_fill_skills()
	_fill_equipment()
	_fill_lore()
	if _confirm_box != null:
		_confirm_box.button_pressed = bool(_snapshot.get("confirmation_accepted", false))


func _refresh_portrait() -> void:
	if _portrait_texture == null:
		return
	var appearance = str(_snapshot.get("appearance_id", "")).to_lower()
	if appearance.find("femme") != -1:
		_portrait_texture.texture = FEMALE_PORTRAIT
	else:
		_portrait_texture.texture = MALE_PORTRAIT

	if _class_tag_label != null:
		var cid = str(_snapshot.get("class_id", ""))
		var cdef = GameDataLoader.get_class_by_id(cid)
		var role_label = str(cdef.get("name", cid))
		_class_tag_label.text = "Classe : %s" % role_label
	if _level_label != null:
		_level_label.text = "Niveau 1"


func _fill_identity() -> void:
	if _identity_grid == null:
		return
	for child in _identity_grid.get_children():
		child.queue_free()

	var cid = str(_snapshot.get("class_id", ""))
	var cdef = GameDataLoader.get_class_by_id(cid)
	var role_label = str(cdef.get("name", cid))
	var race_name = str(_snapshot.get("racial_power_id", "Origine inconnue"))
	var portrait_info = _snapshot.get("portrait_payload", {}) as Dictionary
	var age = str(portrait_info.get("age", "Inconnu"))
	var origin = str(_snapshot.get("clan_name", "Sans clan"))

	_add_identity_pair("Nom", str(_snapshot.get("character_name", "Sans nom")))
	_add_identity_pair("Race/Origine", race_name)
	_add_identity_pair("Classe", role_label)
	_add_identity_pair("Âge", age)
	_add_identity_pair("Origine", origin)


func _add_identity_pair(label_text: String, value_text: String) -> void:
	if _identity_grid == null:
		return
	var key = Label.new()
	key.text = "%s :" % label_text
	key.modulate = Color(0.68, 0.77, 1.0)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value = Label.new()
	value.text = value_text
	value.modulate = Color(0.95, 0.98, 1.0)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_grid.add_child(key)
	_identity_grid.add_child(value)


func _fill_stats() -> void:
	if _stats_grid == null:
		return
	for child in _stats_grid.get_children():
		child.queue_free()

	var purchased_stats = _snapshot.get("stats", {}) as Dictionary
	var stats := CharacterCreationRules.compute_creation_display_stats(str(_snapshot.get("class_id", "")), purchased_stats)
	for key in STAT_UI_ORDER:
		var value = int(stats.get(key, StatDefs.CHARACTER_MIN_STAT))
		_stats_grid.add_child(_build_stat_row(key, value))
	var secondary_heading := Label.new()
	secondary_heading.text = "Caractéristiques secondaires"
	secondary_heading.modulate = Color(0.68, 0.77, 1.0)
	_stats_grid.add_child(secondary_heading)
	var secondary_stats := _snapshot.get("secondary_stats", {}) as Dictionary
	for key in StatDefs.SECONDARY_STAT_KEYS:
		_stats_grid.add_child(_build_secondary_stat_row(
			str(StatDefs.SECONDARY_STAT_LABELS.get(key, "")),
			int(secondary_stats.get(key, StatDefs.SECONDARY_STAT_DEFAULT))
		))


func _build_stat_row(stat_key: String, stat_value: int) -> Control:
	var row = VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)

	var top = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label = Label.new()
	label.text = str(STAT_LABELS.get(stat_key, stat_key.capitalize()))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = Color(0.81, 0.9, 1.0)
	var value = Label.new()
	var modifier := StatDefs.score_to_modifier(stat_value)
	value.text = "%d (%s%d)" % [stat_value, "+" if modifier >= 0 else "", modifier]
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.modulate = _score_color(stat_value)
	top.add_child(label)
	top.add_child(value)

	var bar = ProgressBar.new()
	bar.min_value = StatDefs.CHARACTER_MIN_STAT
	bar.max_value = 20
	bar.value = clampi(stat_value, StatDefs.CHARACTER_MIN_STAT, 20)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)

	row.add_child(top)
	row.add_child(bar)
	return row


func _build_secondary_stat_row(display_name: String, stat_value: int) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = display_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.modulate = Color(0.81, 0.9, 1.0)
	var value := Label.new()
	value.text = str(stat_value)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.modulate = Color(0.9, 0.95, 1.0)
	row.add_child(label)
	row.add_child(value)
	return row


func _score_color(score: int) -> Color:
	if score >= 16:
		return Color(0.55, 1.0, 0.7)
	if score >= 12:
		return Color(0.9, 0.95, 1.0)
	return Color(1.0, 0.72, 0.64)


func _fill_skills() -> void:
	if _skills_list == null:
		return
	for child in _skills_list.get_children():
		child.queue_free()

	var feat_ids = _snapshot.get("selected_feats", []) as Array
	for feat_id in feat_ids:
		var fdef = GameDataLoader.get_feat(str(feat_id))
		var title = str(fdef.get("name", str(feat_id)))
		_skills_list.add_child(_build_skill_row(title, _stars_for_text(title)))

	var ability_ids = _snapshot.get("selected_abilities", []) as Array
	for ability_id in ability_ids:
		var adef = GameDataLoader.get_ability_by_id(str(ability_id))
		var title = str(adef.get("name", str(ability_id)))
		_skills_list.add_child(_build_skill_row(title, _stars_for_text(title)))

	if _skills_list.get_child_count() == 0:
		_skills_list.add_child(_build_skill_row("Aucune compétence", "[.....]"))


func _build_skill_row(skill_name: String, stars: String) -> Control:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var icon = ColorRect.new()
	icon.color = Color(0.18, 0.46, 0.75, 0.95)
	icon.custom_minimum_size = Vector2(12, 12)

	var title = Label.new()
	title.text = skill_name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.modulate = Color(0.95, 0.98, 1.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var level = Label.new()
	level.text = stars
	level.modulate = Color(1.0, 0.84, 0.45)

	row.add_child(icon)
	row.add_child(title)
	row.add_child(level)
	return row


func _stars_for_text(value: String) -> String:
	var filled = clampi((value.length() % 5) + 1, 1, 5)
	return "[%s%s]" % ["*".repeat(filled), ".".repeat(5 - filled)]


func _fill_equipment() -> void:
	if _equipment_grid == null:
		return
	for child in _equipment_grid.get_children():
		child.queue_free()

	var equipped = _snapshot.get("equipped_items_by_slot", {}) as Dictionary
	var inventory = _snapshot.get("inventory_items", []) as Array

	var weapon = _first_non_empty([
		str(equipped.get("main_hand", "")),
		str(equipped.get("weapon", "")),
	])
	var armor = _first_non_empty([
		str(equipped.get("torso", "")),
		str(equipped.get("armor", "")),
	])
	var accessory = _first_non_empty([
		str(equipped.get("amulet", "")),
		str(equipped.get("ring_right", "")),
		str(equipped.get("ring_left", "")),
	])
	var special = _first_non_empty([
		str(equipped.get("off_hand", "")),
		str(inventory[0]) if inventory.size() > 0 else "",
	])

	_equipment_grid.add_child(_build_equipment_slot("Arme principale", weapon))
	_equipment_grid.add_child(_build_equipment_slot("Armure", armor))
	_equipment_grid.add_child(_build_equipment_slot("Accessoire", accessory))
	_equipment_grid.add_child(_build_equipment_slot("Objet spécial", special))


func _build_equipment_slot(slot_name: String, item_name: String) -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var title = Label.new()
	title.text = slot_name
	title.modulate = Color(0.72, 0.82, 1.0)

	var value = Label.new()
	var clean_name = item_name if item_name != "" else "(vide)"
	value.text = clean_name
	value.modulate = Color(0.95, 0.98, 1.0)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var rarity = Label.new()
	rarity.text = "Rareté : %s" % _rarity_from_name(clean_name)
	rarity.modulate = Color(0.99, 0.78, 0.42)
	rarity.add_theme_font_size_override("font_size", 11)

	vb.add_child(title)
	vb.add_child(value)
	vb.add_child(rarity)
	return panel


func _rarity_from_name(item_name: String) -> String:
	var lowered = item_name.to_lower()
	if lowered.find("obsidienne") != -1:
		return "Épique"
	if lowered.find("runique") != -1:
		return "Rare"
	if lowered == "(vide)":
		return "Aucune"
	return "Commun"


func _first_non_empty(values: Array) -> String:
	for value in values:
		var text = str(value)
		if text.strip_edges() != "" and text != "Aucun":
			return text
	return ""


func _fill_lore() -> void:
	if _lore_text == null:
		return
	var cid = str(_snapshot.get("class_id", ""))
	var cdef = GameDataLoader.get_class_by_id(cid)
	var role_label = str(cdef.get("name", cid))
	var hero = str(_snapshot.get("character_name", "Sans nom"))
	var clan = str(_snapshot.get("clan_name", "Errant"))
	var origin = str(_snapshot.get("racial_power_id", "héritage inconnu"))
	var alignment = _compute_alignment()

	var text = ""
	text += "[b]Contexte[/b]\n"
	text += "%s, héritier du clan %s, a embrassé la voie de %s.\n\n" % [hero, clan, role_label]
	text += "Origine mystique : %s.\n" % origin
	text += "Alignement moral : [color=#8BD6FF]%s[/color].\n\n" % alignment
	text += "[b]Résumé[/b]\n"
	text += "Ce personnage conjugue discipline tactique, adaptation au combat et maîtrise de son équipement."
	_lore_text.text = text


func _compute_alignment() -> String:
	var stats = _snapshot.get("stats", {}) as Dictionary
	var social = int(stats.get("diplomatie", 8)) + int(stats.get("commandement", 8))
	var stealth = int(stats.get("espionnage", 8))
	if social - stealth >= 8:
		return "Loyal"
	if stealth - social >= 6:
		return "Neutre pragmatique"
	return "Équilibré"


func _play_intro_animation() -> void:
	if _sheet_panel == null:
		return
	_sheet_panel.modulate = Color(1, 1, 1, 0.92)
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_sheet_panel, "modulate", Color(1, 1, 1, 1), 0.35)


func _on_btn_hover_enter(button: Button) -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(button, "scale", Vector2(1.03, 1.03), 0.12)


func _on_btn_hover_exit(button: Button) -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(button, "scale", Vector2.ONE, 0.12)


func _on_back_pressed() -> void:
	request_previous()


func _on_edit_pressed() -> void:
	submit_current_data()
	if manager != null and manager.has_method("go_to"):
		manager.go_to(CharacterCreationFlowType.Step.BASIC_INFO)


func _on_validate_pressed() -> void:
	if _confirm_box != null:
		_confirm_box.button_pressed = true
	request_next()


func _on_export_pressed() -> void:
	var dir_path = "user://exports"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var stamp = str(Time.get_unix_time_from_system())
	var json_path = "%s/fiche_%s.json" % [dir_path, stamp]
	var png_path = "%s/fiche_%s.png" % [dir_path, stamp]

	var file = FileAccess.open(json_path, FileAccess.WRITE)
	if file == null:
		_set_status("Échec de l’export JSON.", Color(1.0, 0.6, 0.6))
		return
	file.store_string(JSON.stringify(_build_export_payload(), "\t"))
	file.close()

	var image = get_viewport().get_texture().get_image()
	var png_error = image.save_png(png_path)
	if png_error != OK:
		_set_status("JSON exporté, échec de l’export PNG.", Color(1.0, 0.75, 0.5))
		return
	_set_status("Export OK: PNG + JSON dans user://exports", Color(0.62, 1.0, 0.73))


func _build_export_payload() -> Dictionary:
	var out = _snapshot.duplicate(true)
	out["exported_at_unix"] = Time.get_unix_time_from_system()
	out["alignment"] = _compute_alignment()
	return out


func _set_status(message: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.modulate = color
