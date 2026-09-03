## Slide 2: class selection and stat allocation.
class_name Slide02ClassStats
extends "res://scripts/ui/character_creation/slides/creation_slide_base.gd"

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const ClassCardFactory = preload("res://scripts/ui/tween/classedeperso/class_card_factory.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")
const CharacterBuildService = preload("res://scripts/data/character_build_service.gd")

const CARD_COLUMNS := 3

var _selected_class_id: String = ""
const POINTS_POOL_TOTAL: int = 18
var _class_base_stats: Dictionary = {}

func _ready() -> void:
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			# ensure spinbox has sane min/step/max so allocation is constrained
			node.min_value = StatDefs.CHARACTER_MIN_STAT
			node.step = 1
			# give a generous initial max; will be tightened by _update_points_pool()
			node.max_value = StatDefs.CHARACTER_MIN_STAT + POINTS_POOL_TOTAL
			node.value_changed.connect(Callable(self, "_on_stat_value_changed").bind(key))
	_update_derived_stats()
	_update_points_pool()
	# initialize class base stats to the default min so point calculations work
	_class_base_stats = StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)

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
		_update_derived_stats()
		return
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(incoming_stats[key]) if incoming_stats.has(key) else default_stat
			node.value = float(stat_value)
	_update_derived_stats()


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
	var card: Button = ClassCardFactory.create(class_id, str(class_data.get("icon", "")))
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
	content.name = "CardContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0, 0)
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var title := Label.new()
	title.text = str(class_data.get("name", class_id))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", _class_attribute_color(class_data))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var progression_rows := GameDataLoader.get_class_progression(class_id)
	if progression_rows.size() > 0:
		var lvl_info := Label.new()
		lvl_info.text = "Niveaux: %d" % progression_rows.size()
		lvl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_info.modulate = Color(0.85, 0.82, 0.72, 0.95)
		lvl_info.add_theme_font_size_override("font_size", 12)
		lvl_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lvl_info)

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
	_reset_stat_spinboxes()
	_apply_class_stats(class_id)
	_refresh_class_selection()
	_refresh_progression_summary(class_id)


func _apply_class_stats(class_id: String) -> void:
	var stats := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	if class_id != "":
		var point_buy := CharacterCreationRules.apply_point_buy_for_class(class_id, 10)
		if point_buy.has("stats"):
			stats = point_buy["stats"] as Dictionary
			# remember class base stats so allocated points are computed relative to them
			_class_base_stats = stats.duplicate(true)

	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(stats[key]) if stats.has(key) else default_stat
			# set bounds before value so the value is clamped to the class base if needed
			node.min_value = float(stat_value)
			node.step = 1
			node.max_value = float(stat_value + POINTS_POOL_TOTAL)
			node.value = float(stat_value)
	_update_derived_stats()

func _reset_stat_spinboxes() -> void:
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			node.min_value = StatDefs.CHARACTER_MIN_STAT
			node.step = 1
			node.max_value = StatDefs.CHARACTER_MIN_STAT + POINTS_POOL_TOTAL
			node.value = float(StatDefs.CHARACTER_MIN_STAT)


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

func _on_stat_value_changed(value: float, stat_key: String) -> void:
	_update_derived_stats()

func _update_derived_stats() -> void:
	var stats := _collect_stats()
	var mods := CharacterBuildService.build_modifiers(stats)
	var derived := CharacterBuildService.build_derived_stats(mods)

	_set_derived_label("DerivedAttaqueValue", int(derived.get("attaque", 0)))
	_set_derived_label("DerivedDefenseValue", int(derived.get("defense", 0)))
	_set_derived_label("DerivedResistanceValue", int(derived.get("resistance", 0)))
	_set_derived_label("DerivedInitiativeValue", int(derived.get("initiative", 0)))
	_set_derived_label("DerivedVigueurValue", int(derived.get("jet_vigueur", 0)))
	_set_derived_label("DerivedVolonteValue", int(derived.get("jet_volonte", 0)))
	_set_derived_label("DerivedReflexesValue", int(derived.get("jet_reflexes", 0)))
	_update_points_pool()

func _set_derived_label(node_name: String, value: int) -> void:
	var node := find_child(node_name, true, false) as Label
	if node:
		node.text = str(value)

func _update_points_pool() -> void:
	var stats: Dictionary = _collect_stats()
	var spent: int = 0
	# compute spent using the same stat cost curve as the rest of the UI
	for key in StatDefs.STAT_KEYS:
		var value: int = int(stats.get(key, StatDefs.CHARACTER_MIN_STAT))
		var base_val: int = int(_class_base_stats.get(key, StatDefs.CHARACTER_MIN_STAT))
		if value > base_val:
			spent += _compute_stat_cost(base_val, value)
	var remaining: int = max(0, POINTS_POOL_TOTAL - spent)
	var label: Label = find_child("PointsPoolLabel", true, false) as Label
	if label:
		label.text = "Points restants: %d / %d" % [remaining, POINTS_POOL_TOTAL]

	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var value: int = int(node.value)
			node.max_value = float(_calculate_max_stat_value(value, remaining))

func _calculate_max_stat_value(current_value: int, remaining_points: int) -> int:
	var max_value := current_value
	while max_value < StatDefs.CHARACTER_MAX_STAT:
		var next_cost := CharacterCreationRules.stat_upgrade_cost_preview(max_value)
		if next_cost > remaining_points:
			break
		remaining_points -= next_cost
		max_value += 1
	return max_value


func _compute_stat_cost(from_value: int, to_value: int) -> int:
	var cost := 0
	for value in range(from_value, to_value):
		cost += CharacterCreationRules.stat_upgrade_cost_preview(value)
	return cost


func _refresh_progression_summary(class_id: String) -> void:
	var summary := find_child("ProgressionSummary", true, false) as ScrollContainer
	if summary == null:
		return
	var grid := summary.get_node("ProgressionGrid") as GridContainer
	if grid == null:
		return
	_clear_progression_grid(grid)

	if class_id == "":
		_add_progression_message(grid, "Selectionnez une classe pour afficher sa progression.")
		return

	var rows := GameDataLoader.get_class_progression(class_id)
	if rows.is_empty():
		_add_progression_message(grid, "Aucune progression disponible pour cette classe.")
		return

	var headers := ["Stats", "Talents"]
	for header in headers:
		_add_progression_grid_cell(grid, header, true)

	for row in rows:
		var d := row as Dictionary
		var stats_text := "Niv %d\nATK %d\nDEF %d\nRES %d" % [
			int(d.get("niveau", 0)),
			int(d.get("attaque", 0)),
			int(d.get("defense", 0)),
			int(d.get("resistance", 0)),
		]
		var talents_text := str(d.get("talents", ""))

		_add_progression_grid_cell(grid, stats_text, false)
		_add_progression_grid_cell(grid, talents_text, false)


func _clear_progression_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()


func _add_progression_message(grid: GridContainer, message: String) -> void:
	_clear_progression_grid(grid)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_progression_cell_style(false))

	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.valign = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 13)
	panel.add_child(label)
	grid.add_child(panel)


func _add_progression_grid_cell(grid: GridContainer, text: String, heading: bool) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_progression_cell_style(heading))

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.valign = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if heading else HORIZONTAL_ALIGNMENT_LEFT
	if heading:
		label.add_theme_color_override("font_color", Color8(230, 210, 170))
		label.add_theme_font_size_override("font_size", 13)
	else:
		label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)
	grid.add_child(panel)


func _make_progression_cell_style(heading: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.03, 0.18 if heading else 0.12)
	style.border_color = Color("5d4943")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style


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
