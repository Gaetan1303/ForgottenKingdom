## scripts/ui/character_sheet.gd
extends Control

signal saved(stats, points_remaining, char_class, feats)

var CharacterClass = preload("res://scripts/data/character.gd")
var StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const CharacterBuildService = preload("res://scripts/data/character_build_service.gd")
var _character = null

var _points_label: Label
var _stat_labels: Dictionary = {}
var _stat_keys: Array = StatDefsClass.STAT_KEYS
var _class_option: OptionButton
var _selected_class_id: String = ""
var _feats_scroll
var _feats_vbox: VBoxContainer
var _suppress_feat_signals: bool = false

# Mappings and definitions loaded from data files
var _feat_keys: Array = []
var _feat_defs: Dictionary = {}
var _class_keys: Array = []
var _class_defs: Dictionary = {}

var _feat_desc: RichTextLabel
var _class_desc: Label
var _embedded_mode: bool = false
var _class_locked: bool = false
const POINTS_RESTANTS_CIBLE = 10
const COLOR_GOLD = Color(0.91, 0.79, 0.42, 1.0)
const COLOR_GOLD_DIM = Color(0.79, 0.66, 0.30, 1.0)
const COLOR_TEXT_MAIN = Color(0.94, 0.90, 0.80, 1.0)
const COLOR_TEXT_MUTED = Color(0.66, 0.54, 0.40, 1.0)

var _stat_cost_labels: Dictionary = {}

# Vitals labels
var _pv_label: Label
var _mana_label: Label
var _ame_label: Label
var _feats_bonus_label: Label


func set_embedded_mode(value: bool) -> void:
	_embedded_mode = value

	# When embedded inside a host panel, allow the control to resize freely
	# and remove the hard minimum so the host can control sizing.
	if _embedded_mode:
		custom_minimum_size = Vector2.ZERO
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		# Default minimum for standalone presentation
		custom_minimum_size = Vector2(600, 480)


func set_class_locked(value: bool) -> void:
	_class_locked = value
	if _class_option != null:
		_class_option.disabled = value


func set_selected_class(class_value: String) -> void:
	var wanted = class_value.strip_edges().to_lower()
	if wanted.is_empty():
		return
	_selected_class_id = class_value.strip_edges()
	for i in range(_class_keys.size()):
		var key = str(_class_keys[i]).to_lower()
		var label = str((_class_defs.get(str(_class_keys[i]), {}) as Dictionary).get("name", _class_keys[i])).to_lower()
		if key == wanted or label == wanted:
			_selected_class_id = str(_class_keys[i])
			_on_class_selected(i)
			return

func _ready() -> void:
	# Build UI dynamically so the scene file stays minimal.
	print("CharacterSheet._ready: start")
	# Ensure CharacterClass is loaded and instantiate
	print_debug("CharacterSheet: CharacterClass var preloaded?", CharacterClass != null)
	if CharacterClass == null:
		CharacterClass = preload("res://scripts/data/character.gd")
	_character = null
	if CharacterClass != null:
		_character = CharacterClass.new()
	print_debug("CharacterSheet: _character created?", _character != null)
	if _character == null:
		push_warning("CharacterSheet: impossible d'initialiser le modele personnage")
		return
	custom_minimum_size = Vector2(640, 520)
	var root = MarginContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("margin_left", 8)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_right", 8)
	root.add_theme_constant_override("margin_bottom", 8)

	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)

	if not _embedded_mode:
		panel.anchor_right = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 50
		panel.offset_top = 50

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(root)
	root.add_child(panel)
	add_child(center)

	var title = Label.new()
	title.text = "Fiche Personnage"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	_points_label = Label.new()
	_points_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_points_label)

	# Class selection is owned by creation screen cards; no class dropdown here.
	_class_option = null
	_class_desc = Label.new()
	_class_desc.name = "ClassDesc"
	_class_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	_class_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_class_desc.visible = true
	panel.add_child(_class_desc)

	# Vitals area (PV / Mana / Âme)
	var vitals_hbox = HBoxContainer.new()
	vitals_hbox.name = "VitalsPanel"
	vitals_hbox.add_theme_constant_override("separation", 12)
	vitals_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vitals_hbox)

	var pv_box = VBoxContainer.new()
	pv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pv_title = Label.new()
	pv_title.text = "PV"
	pv_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	pv_box.add_child(pv_title)
	_pv_label = Label.new()
	_pv_label.name = "PVLabel"
	_pv_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	pv_box.add_child(_pv_label)
	vitals_hbox.add_child(pv_box)

	var mana_box = VBoxContainer.new()
	mana_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mana_title = Label.new()
	mana_title.text = "Mana"
	mana_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	mana_box.add_child(mana_title)
	_mana_label = Label.new()
	_mana_label.name = "ManaLabel"
	_mana_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	mana_box.add_child(_mana_label)
	vitals_hbox.add_child(mana_box)

	var ame_box = VBoxContainer.new()
	ame_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ame_title = Label.new()
	ame_title.text = "Âme"
	ame_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	ame_box.add_child(ame_title)
	_ame_label = Label.new()
	_ame_label.name = "AmeLabel"
	_ame_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	ame_box.add_child(_ame_label)
	vitals_hbox.add_child(ame_box)

	# Feats bonuses summary (flat bonuses from selected feats)
	var feats_bonus_box = VBoxContainer.new()
	feats_bonus_box.name = "FeatsBonusBox"
	feats_bonus_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var feats_bonus_title = Label.new()
	feats_bonus_title.text = "Bonus appliqués (Dons)"
	feats_bonus_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	feats_bonus_box.add_child(feats_bonus_title)
	_feats_bonus_label = Label.new()
	_feats_bonus_label.name = "FeatsBonusLabel"
	_feats_bonus_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	feats_bonus_box.add_child(_feats_bonus_label)
	vitals_hbox.add_child(feats_bonus_box)
	_load_classes()
	if _selected_class_id.is_empty() and _class_keys.size() > 0:
		_selected_class_id = str(_class_keys[0])
		_on_class_selected(0)
	elif not _selected_class_id.is_empty():
		set_selected_class(_selected_class_id)

	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.07, 0.02, 0.14, 0.85)
	stats_style.border_color = Color(0.79, 0.66, 0.30, 0.45)
	stats_style.set_border_width_all(1)
	stats_style.set_corner_radius_all(4)
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	panel.add_child(stats_panel)

	var stats_box = VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 6)
	stats_panel.add_child(stats_box)

	var stats_title = Label.new()
	stats_title.text = "Attributs"
	stats_title.add_theme_font_size_override("font_size", 14)
	stats_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	stats_box.add_child(stats_title)

	var grid = GridContainer.new()
	grid.columns = 1
	stats_box.add_child(grid)

	for stat in _stat_keys:
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lbl = Label.new()
		lbl.text = stat.capitalize()
		lbl.custom_minimum_size = Vector2(110, 0)
		lbl.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
		h.add_child(lbl)
		var btn_minus = Button.new()
		btn_minus.text = "-"
		btn_minus.custom_minimum_size = Vector2(26, 26)
		btn_minus.pressed.connect(_on_change_stat.bind(stat, -1))
		h.add_child(btn_minus)
		var val = Label.new()
		val.name = "val_%s" % stat
		val.text = "0"
		val.custom_minimum_size = Vector2(50, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
		_stat_labels[stat] = val
		h.add_child(val)
		var btn_plus = Button.new()
		btn_plus.text = "+"
		btn_plus.custom_minimum_size = Vector2(26, 26)
		btn_plus.pressed.connect(_on_change_stat.bind(stat, 1))
		h.add_child(btn_plus)
		var cost_lbl = Label.new()
		cost_lbl.text = "coût +1"
		cost_lbl.custom_minimum_size = Vector2(72, 0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		_stat_cost_labels[stat] = cost_lbl
		h.add_child(cost_lbl)
		grid.add_child(h)

	var feat_panel = PanelContainer.new()
	feat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Ensure children can't visually overflow the panel
	feat_panel.clip_contents = true
	# Provide a larger minimum so the list has enough room
	feat_panel.custom_minimum_size = Vector2(0, 420)
	var feat_style = StyleBoxFlat.new()
	feat_style.bg_color = Color(0.05, 0.01, 0.10, 0.82)
	feat_style.border_color = Color(0.79, 0.66, 0.30, 0.35)
	feat_style.set_border_width_all(1)
	feat_style.set_corner_radius_all(4)
	feat_panel.add_theme_stylebox_override("panel", feat_style)
	panel.add_child(feat_panel)

	var feat_box = VBoxContainer.new()
	feat_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feat_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feat_box.add_theme_constant_override("separation", 6)
	feat_panel.add_child(feat_box)

	var feat_label = Label.new()
	feat_label.text = "Dons / Capacités"
	feat_label.add_theme_font_size_override("font_size", 14)
	feat_label.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	feat_box.add_child(feat_label)

	_feats_scroll = ScrollContainer.new()
	_feats_scroll.name = "FeatsScroll"
	_feats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feats_scroll.custom_minimum_size = Vector2(0, 300)
	# Scroll behavior: default vertical scrolling is handled by ScrollContainer.
	# Avoid setting engine-specific properties that may not exist across versions.
	_feats_vbox = VBoxContainer.new()
	_feats_vbox.name = "FeatsVbox"
	_feats_vbox.add_theme_constant_override("separation", 4)
	_feats_scroll.add_child(_feats_vbox)
	feat_box.add_child(_feats_scroll)
	_feat_desc = RichTextLabel.new()
	_feat_desc.bbcode_enabled = false
	_feat_desc.custom_minimum_size = Vector2(0, 100)
	_feat_desc.add_theme_color_override("default_color", COLOR_TEXT_MUTED)
	feat_box.add_child(_feat_desc)
	# Load feats into the scroll container
	# (we use checkboxes inside a vbox for predictable clipping and layout)
	_load_feats()
	# Ensure feats defs are available for bonus computation

	var btn_row = HBoxContainer.new()
	var btn_apply = Button.new()
	btn_apply.text = "Appliquer"
	btn_apply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_apply.pressed.connect(_on_apply)
	btn_row.add_child(btn_apply)
	var btn_cancel = Button.new()
	btn_cancel.text = "Annuler"
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.pressed.connect(_on_cancel)
	btn_row.add_child(btn_cancel)
	var btn_export = Button.new()
	btn_export.text = "Exporter JSON"
	btn_export.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_export.pressed.connect(_on_export)
	btn_row.add_child(btn_export)
	# Embedded mode: keep the footer compact to avoid overflowing host layouts.
	if _embedded_mode:
		btn_cancel.visible = false
		btn_export.visible = false
		btn_apply.text = "Appliquer"
	panel.add_child(btn_row)

	_update_ui()
	print("CharacterSheet._ready: ui built, children=", get_child_count())

func setup(stats: Dictionary, points_left: int, char_class: String = "") -> void:
	print("CharacterSheet.setup: start; char_class=", char_class, " points_left=", points_left)
	if CharacterClass == null:
		CharacterClass = preload("res://scripts/data/character.gd")
	_character = CharacterClass.new() if CharacterClass != null else null
	if _character == null:
		push_warning("CharacterSheet.setup: unable to create Character instance")
		return
	# Prepare raw_stats from input (sanitized), but don't apply yet —
	# selecting a class may set class defaults which we want to override
	# with the incoming raw stats afterwards.
	var raw_stats: Dictionary = {}
	if stats:
		var is_modifier_form := false
		for k in stats.keys():
			if int(stats.get(k, 0)) < StatDefsClass.CHARACTER_MIN_STAT:
				is_modifier_form = true
				break
		if is_modifier_form:
			var reconstructed := {}
			for k in StatDefsClass.STAT_KEYS:
				var m := int(stats.get(k, 0))
				var score := 10 + m * 2
				reconstructed[k] = clampi(score, StatDefsClass.CHARACTER_MIN_STAT, StatDefsClass.CHARACTER_MAX_STAT)
			raw_stats = StatDefsClass.sanitize_stats(
				reconstructed,
				StatDefsClass.CHARACTER_MIN_STAT,
				StatDefsClass.CHARACTER_MAX_STAT,
				StatDefsClass.CHARACTER_MIN_STAT
			)
		else:
			raw_stats = StatDefsClass.sanitize_stats(
				stats,
				StatDefsClass.CHARACTER_MIN_STAT,
				StatDefsClass.CHARACTER_MAX_STAT,
				StatDefsClass.CHARACTER_MIN_STAT
			)

	var saved_points = int(points_left)
	if char_class != "":
		set_selected_class(char_class)
	# Re-apply raw_stats after class selection to preserve creation values
	if raw_stats.size() > 0:
		_character.stats = raw_stats
	_character.points_pool = saved_points + _character.points_spent()
	_update_ui()
	# Ensure feats list is populated when setup is invoked programmatically
	# (instantiation timing can vary; calling _load_feats() here guarantees the UI)
	_load_feats()
	_sync_feats_selection_from_model()
	print("CharacterSheet.setup: end; feats_count=", _feat_keys.size())

func _load_classes() -> void:
	var classes: Dictionary = _read_json_dict("res://data/classes.json")
	if classes.is_empty():
		classes = _read_json_dict("res://data/classes.json")
	if classes.is_empty():
		return
	_class_keys.clear()
	_class_defs.clear()
	var keys: Array = classes.keys()
	keys.sort()
	for key in keys:
		var key_s: String = str(key)
		if key_s.begins_with("_"):
			continue
		if not classes[key_s] is Dictionary:
			continue
		var entry: Dictionary = classes[key_s] as Dictionary
		_class_keys.append(key_s)
		_class_defs[key_s] = entry

func _load_feats() -> void:
	# If character model or UI container is not ready, skip loading feats now
	if _character == null:
		push_warning("CharacterSheet: _character null, skipping _load_feats for now")
		return
	if _feats_vbox == null:
		push_warning("CharacterSheet: _feats_vbox not initialized, skipping _load_feats for now")
		return
	var feats: Dictionary = _read_json_dict("res://data/feats.json")
	print("CharacterSheet: _load_feats called; feats count:", feats.size())
	if feats.is_empty():
		feats = _read_json_dict("res://data/feats.json")
	if feats.is_empty():
		return
	# clear existing widgets
	if _feats_vbox != null:
		for child in _feats_vbox.get_children():
			child.queue_free()
	_feat_keys.clear()
	_feat_defs = feats.duplicate(true)
	var keys: Array = feats.keys()
	keys.sort()
	for key in keys:
		var key_s: String = str(key)
		var entry: Dictionary = feats[key_s] as Dictionary

		var row = HBoxContainer.new()
		row.name = "row_%s" % key_s
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var cb = CheckBox.new()
		cb.name = "cb_%s" % key_s
		cb.focus_mode = Control.FOCUS_NONE
		# connect toggled to handler; signal sends (pressed) then bound args are appended
		cb.toggled.connect(_on_feat_toggled.bind(key_s))
		row.add_child(cb)
		print("CharacterSheet: added feat row", key_s)

		var lbl = Label.new()
		lbl.text = str(entry.get("name", key_s))
		lbl.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		_feats_vbox.add_child(row)
		_feat_keys.append(key_s)

	_sync_feats_selection_from_model()
	_update_feats_disabled()

func _on_change_stat(stat: String, delta: int) -> void:
	if _character == null:
		return
	if delta > 0:
		_character.increase_stat(stat)
	else:
		_character.decrease_stat(stat)
	_update_ui()
	_update_feats_disabled()

func _update_ui() -> void:
	if _character == null:
		return

	# Safeguard: character.stats should be a Dictionary. If not, fall back to defaults.
	var stats_dict: Dictionary = {}
	if _character.stats != null and _character.stats is Dictionary:
		stats_dict = _character.stats as Dictionary
	else:
		stats_dict = StatDefsClass.make_default_stats(StatDefsClass.CHARACTER_MIN_STAT)

	_points_label.text = "Points restants: %d   |   Points investis: %d" % [_character.points_remaining(), _character.points_spent()]
	for stat in _stat_keys:
		var key: String = str(stat)
		var val: int = int(stats_dict.get(key, StatDefsClass.CHARACTER_MIN_STAT))
		if _stat_labels.has(key) and _stat_labels[key] is Label:
			(_stat_labels[key] as Label).text = str(val)
		if _stat_cost_labels.has(key) and _stat_cost_labels[key] is Label:
			(_stat_cost_labels[key] as Label).text = "coût +%d" % _stat_upgrade_cost(val)

	# Update vitals (derived statistics)
	var mods = CharacterBuildService.build_modifiers(stats_dict)
	# Compute feats bonuses (flat stat changes and other effects)
	var feats_bonus = _compute_feats_bonus()
	var pv_max = 10 + int(mods.get("commandement", 0)) + int(feats_bonus.get("pv_bonus", 0))
	var mana_max = 20 + int(mods.get("magie", 0)) * 3 + int(feats_bonus.get("mana_bonus", 0))
	var clan_mgr = get_node_or_null("/root/ClanManager")
	var ame_pct = 100
	if clan_mgr != null:
		ame_pct = int(clan_mgr.barre_ame)
	if _pv_label:
		_pv_label.text = "%d / %d" % [pv_max, pv_max]
	if _mana_label:
		_mana_label.text = "%d / %d" % [mana_max, mana_max]
	if _ame_label:
		_ame_label.text = "%d%%" % ame_pct

	# Update feats bonus summary label
	if _feats_bonus_label:
		var parts: Array = []
		# show stat bonuses first
		var fb_stats = feats_bonus.get("stats", {}) as Dictionary
		for sk in fb_stats.keys():
			parts.append("%s: %s" % [sk.capitalize(), _format_signed(int(fb_stats[sk]))])
		# show other flat bonuses
		if int(feats_bonus.get("pv_bonus", 0)) != 0:
			parts.append("PV: %s" % _format_signed(int(feats_bonus.get("pv_bonus", 0))))
		if int(feats_bonus.get("mana_bonus", 0)) != 0:
			parts.append("Mana: %s" % _format_signed(int(feats_bonus.get("mana_bonus", 0))))
		_feats_bonus_label.text = ", ".join(parts) if parts.size() > 0 else "—"


func _stat_modifier(score: int) -> int:
	return int(floor((float(score) - 10.0) / 2.0))


func _format_signed(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return str(value)


func _stat_upgrade_cost(current_value: int) -> int:
	# Progressive cost after base threshold to mimic CRPG point-buy feel.
	if current_value <= 10:
		return 1
	if current_value <= 13:
		return 2
	if current_value <= 16:
		return 3
	return 4


func _update_feats_disabled() -> void:
	if _character == null or _feats_vbox == null:
		return
	# Disable feats that the character does not meet prerequisites for
	var feats_arr: Array = _character.feats if _character.feats != null else []
	for i in range(_feat_keys.size()):
		var key: String = str(_feat_keys[i])
		var allowed: bool = false
		if _character != null:
			if _character.has_method("meets_feat_prerequisites"):
				allowed = _character.meets_feat_prerequisites(key, _feat_defs)
			if not allowed and feats_arr.size() > 0:
				allowed = key in feats_arr
		var cb = _feats_vbox.get_node_or_null("cb_%s" % key) as CheckBox
		if cb != null:
			cb.disabled = not allowed


func _on_feat_selected(index: int) -> void:
	if index < 0 or index >= _feat_keys.size():
		_feat_desc.text = ""
		return
	var key: String = str(_feat_keys[index])
	var entry: Dictionary = _feat_defs.get(key, {}) as Dictionary
	var desc: String = str(entry.get("description", ""))
	var pre: Variant = entry.get("prerequisite", null)
	if pre != null:
		var pre_lines: Array[String] = []
		var pre_d: Dictionary = pre as Dictionary
		var sreq: Dictionary = pre_d.get("stats", {}) as Dictionary
		for sk in sreq.keys():
			pre_lines.append("%s >= %s" % [sk.capitalize(), str(sreq[sk])])
		var freq: Array = pre_d.get("feats", []) as Array
		for f in freq:
			pre_lines.append("Requires feat: %s" % str(f))
		if pre_lines.size() > 0:
			desc += "\nPrerequisites: %s" % ", ".join(pre_lines)
	_feat_desc.text = desc


func _on_feat_multi_selected(index: int, selected: bool) -> void:
	if _character == null:
		return
	if index < 0 or index >= _feat_keys.size():
		return
	var key: String = str(_feat_keys[index])
	if selected:
		if _character.has_method("add_feat_checked"):
			if not _character.add_feat_checked(key, _feat_defs):
				# couldn't add (prereqs), leave unchecked
				return
		else:
			_character.add_feat(key)
	else:
		if _character != null:
			_character.remove_feat(key)
	_update_feats_disabled()


func _on_feat_toggled(pressed: bool, key: String) -> void:
	if _suppress_feat_signals:
		return
	if _character == null:
		return
	if pressed:
		# Try to add feat, respecting prerequisites if helper exists
		var ok = true
		if _character.has_method("add_feat_checked"):
			ok = _character.add_feat_checked(key, _feat_defs)
		else:
			_character.add_feat(key)
		if not ok:
			# revert checkbox
			var cb = _feats_vbox.get_node_or_null("cb_%s" % key) as CheckBox
			if cb != null:
				_suppress_feat_signals = true
				cb.pressed = false
				_suppress_feat_signals = false
			return
	else:
		if _character.has_method("remove_feat"):
			_character.remove_feat(key)
	_update_ui()
	# Update description for the toggled feat
	var entry = _feat_defs.get(key, {}) as Dictionary
	var desc = str(entry.get("description", ""))
	var pre = entry.get("prerequisite", null)
	if pre != null:
		var pre_lines: Array[String] = []
		var pre_d: Dictionary = pre as Dictionary
		var sreq: Dictionary = pre_d.get("stats", {}) as Dictionary
		for sk in sreq.keys():
			pre_lines.append("%s >= %s" % [sk.capitalize(), str(sreq[sk])])
		var freq: Array = pre_d.get("feats", []) as Array
		for f in freq:
			pre_lines.append("Requires feat: %s" % str(f))
		if pre_lines.size() > 0:
			desc += "\nPrerequisites: %s" % ", ".join(pre_lines)
	_feat_desc.text = desc


func _on_class_selected(index: int) -> void:
	if index < 0 or index >= _class_keys.size():
		_class_desc.text = ""
		return
	var key: String = str(_class_keys[index])
	_selected_class_id = key
	var entry: Dictionary = _class_defs.get(key, {}) as Dictionary
	var text: String = str(entry.get("name", key))
	if entry.has("description"):
		text += "\n" + str(entry.get("description", ""))
	_class_desc.text = text

	if _character != null:
		var base_stats = _resolve_base_stats_for_class(entry)
		_character.stats = StatDefsClass.sanitize_stats(
			base_stats,
			StatDefsClass.CHARACTER_MIN_STAT,
			StatDefsClass.CHARACTER_MAX_STAT,
			StatDefsClass.CHARACTER_MIN_STAT
		)
		_character.points_pool = _character.points_spent() + POINTS_RESTANTS_CIBLE
		_update_ui()
		_update_feats_disabled()


func _resolve_base_stats_for_class(class_def: Dictionary) -> Dictionary:
	var explicit_base = class_def.get("base_stats", {}) as Dictionary
	if not explicit_base.is_empty():
		return explicit_base
	return _build_base_stats_from_class_def(class_def)


func _build_base_stats_from_class_def(class_def: Dictionary) -> Dictionary:
	var out = StatDefsClass.make_default_stats(StatDefsClass.CHARACTER_MIN_STAT)
	var primary = class_def.get("primary", []) as Array
	var secondary = class_def.get("secondary", []) as Array
	var hit_die = int(class_def.get("hit_die", 8))

	for stat in primary:
		var key = str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 3
	for stat in secondary:
		var key = str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 2

	if hit_die >= 10:
		out["force"] = int(out.get("force", 8)) + 1
		out["commandement"] = int(out.get("commandement", 8)) + 1
	elif hit_die <= 6:
		out["magie"] = int(out.get("magie", 8)) + 1

	return StatDefsClass.sanitize_stats(
		out,
		StatDefsClass.CHARACTER_MIN_STAT,
		StatDefsClass.CHARACTER_MAX_STAT,
		StatDefsClass.CHARACTER_MIN_STAT
	)

func _on_apply() -> void:
	var stats_out = {}
	var pts = 0
	var feats_out = []
	if _character != null:
		stats_out = _character.stats.duplicate(true)
		pts = _character.points_remaining()
		feats_out = _character.feats.duplicate(true) if _character.feats != null else []
	var class_id = _selected_class_id
	emit_signal("saved", stats_out, pts, class_id, feats_out)
	if not _embedded_mode:
		queue_free()

func _on_cancel() -> void:
	if _embedded_mode:
		return
	queue_free()


func _on_export() -> void:
	var base_dir: String = "res://data/exports/"
	var abs: String = ProjectSettings.globalize_path(base_dir)
	DirAccess.make_dir_recursive_absolute(abs)
	var char_name: String = "npc"
	if _character != null:
		char_name = _character.name.strip_edges()
	if char_name == "":
		char_name = "npc"
	var safe: String = char_name.replace(" ", "_")
	var fname: String = "%s_%d.json" % [safe, int(Time.get_unix_time_from_system())]
	var path: String = base_dir + fname
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_character.to_dict(), "\t"))
		file.close()
		print("Exported character JSON to:", path)
	else:
		push_warning("Unable to write export file: %s" % path)


func _read_json_dict(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed as Dictionary


func _compute_feats_bonus() -> Dictionary:
	var out = {"stats": {}}
	if _character == null:
		return out
	# Ensure feat definitions are loaded
	if _feat_defs == null or _feat_defs.size() == 0:
		_feat_defs = _read_json_dict("res://data/feats.json")
	var feats_arr: Array = _character.feats if _character.feats != null else []
	for f in feats_arr:
		var fkey = str(f)
		var fdef = _feat_defs.get(fkey, {}) as Dictionary
		var eff = fdef.get("effects", {}) as Dictionary
		# stats
		var stats_eff = eff.get("stats", {}) as Dictionary
		for sk in stats_eff.keys():
			out.get("stats")[sk] = int(out.get("stats", {}).get(sk, 0)) + int(stats_eff[sk])
		# other flat bonuses (pv_bonus, mana_bonus)
		if eff.has("pv_bonus"):
			out["pv_bonus"] = int(out.get("pv_bonus", 0)) + int(eff.get("pv_bonus"))
		if eff.has("mana_bonus"):
			out["mana_bonus"] = int(out.get("mana_bonus", 0)) + int(eff.get("mana_bonus"))
	return out


func _sync_feats_selection_from_model() -> void:
	if _character == null or _feats_vbox == null:
		return
	var feats_arr: Array = _character.feats if _character.feats != null else []
	for key in _feat_keys:
		var cb = _feats_vbox.get_node_or_null("cb_%s" % key) as CheckBox
		if cb != null:
			cb.pressed = (feats_arr.size() > 0 and key in feats_arr)
