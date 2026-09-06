## Slide 2: class selection and stat allocation.
class_name Slide02ClassStats
extends "res://scripts/ui/character_creation/slides/creation_slide_base.gd"

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const ClassCardFactory = preload("res://scripts/ui/tween/classedeperso/class_card_factory.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")
const CharacterBuildService = preload("res://scripts/data/character_build_service.gd")
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const POINTS_POOL_TOTAL: int = 10
const STAT_LABELS := {
	"force": "Force", "magie": "Magie", "espionnage": "Espionnage",
	"artisanat": "Artisanat", "diplomatie": "Diplomatie", "commandement": "Commandement",
}
const PROGRESSION_TALENT_LABELS := {
	"blood_edge": "Lame de sang", "abyss_focus": "Focalisation abyssale",
	"blood_fury": "Fureur sanguinaire", "cendré_tactician": "Tacticien cendré",
	"crimson_focus": "Focalisation écarlate", "feral_bond": "Lien sauvage",
	"hellforge_engineer": "Ingénieur de la forge infernale", "mind_echo": "Écho mental",
	"predator_instinct": "Instinct du prédateur", "silent_killer": "Tueur silencieux",
	"soul_anchor": "Ancre spirituelle", "unyielding_oath": "Serment inébranlable",
	"void_step": "Pas du vide", "void_tongue": "Langue du vide",
}

var _selected_class_id: String = ""
var _invested_points: Dictionary = {}
var _class_bonus_stats: Dictionary = {}
var _secondary_stats: Dictionary = {}
var _updating_controls := false

func _ready() -> void:
	$Content/StepTitle.hide()
	var reset := Button.new()
	reset.name = "BtnReset"
	reset.text = "Réinitialiser les points"
	reset.tooltip_text = "Récupérer les 10 points investis. La classe choisie et ses bonus sont conservés."
	preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(reset)
	$Content/Nav.add_child(reset)
	$Content/Nav.move_child(reset, 0)
	reset.pressed.connect(func():
		_invested_points = StatDefs.make_default_stats(0)
		_refresh_stat_controls()
		submit_current_data())
	_invested_points = StatDefs.make_default_stats(0)
	_class_bonus_stats = StatDefs.make_default_stats(0)
	_secondary_stats = StatDefs.make_default_secondary_stats()
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			node.min_value = StatDefs.CHARACTER_MIN_STAT
			node.step = 1
			node.max_value = StatDefs.CHARACTER_MIN_STAT + POINTS_POOL_TOTAL
			node.value_changed.connect(Callable(self, "_on_stat_value_changed").bind(key))
		var stat_label := find_child("Label%s" % str(key).capitalize(), true, false) as Label
		_configure_tooltip_for_stat_row(key, stat_label, node)
	for key in StatDefs.SECONDARY_STAT_KEYS:
		var secondary_label := find_child("Label_%s" % key, true, false) as Label
		var secondary_value := find_child("Secondary_%s" % key, true, false) as Label
		_configure_tooltip_for_secondary_row(key, secondary_label, secondary_value)
	_refresh_stat_controls()
	_refresh_secondary_stats()

func enter_slide(data: Resource) -> void:
	_populate_class_cards()
	var class_id := ""
	var incoming_stats: Dictionary = {}
	var incoming_secondary_stats: Dictionary = {}

	if data != null and data.has_method("get"):
		var tmp_id: Variant = data.get("class_id")
		if tmp_id != null:
			class_id = str(tmp_id)
		var tmp_stats: Variant = data.get("stats")
		if tmp_stats != null:
			incoming_stats = tmp_stats as Dictionary
		var tmp_secondary_stats: Variant = data.get("secondary_stats")
		if tmp_secondary_stats != null and tmp_secondary_stats is Dictionary:
			incoming_secondary_stats = tmp_secondary_stats as Dictionary

	_invested_points = StatDefs.make_default_stats(0)
	if not incoming_stats.is_empty():
		for key in StatDefs.STAT_KEYS:
			_invested_points[key] = maxi(0, int(incoming_stats.get(key, StatDefs.CHARACTER_MIN_STAT)) - StatDefs.CHARACTER_MIN_STAT)
	_secondary_stats = StatDefs.sanitize_secondary_stats(incoming_secondary_stats)
	_refresh_secondary_stats()

	if class_id == "":
		# default to first class if none selected yet
		var classes: Dictionary = GameDataLoader.get_classes()
		var keys: Array = classes.keys()
		keys.sort()
		if keys.size() > 0:
			class_id = str(keys[0])
	_select_class_card(class_id)


func collect_payload() -> Dictionary:
	return {
		"class_id": _selected_class_id,
		"stats": _collect_stats(),
		"secondary_stats": _secondary_stats.duplicate(true),
	}


func _configure_tooltip_for_stat_row(stat_key: String, stat_label: Label, stat_control: SpinBox) -> void:
	preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(stat_label)
	var tooltip := _stat_rules_tooltip(stat_key)
	if stat_label:
		stat_label.mouse_filter = Control.MOUSE_FILTER_STOP
		stat_label.tooltip_text = tooltip
	if stat_control:
		stat_control.tooltip_text = tooltip
		# The embedded LineEdit is the actual hovered control over the number.
		stat_control.get_line_edit().tooltip_text = tooltip + "\nFlèches haut/bas : investir ou récupérer 1 point. Budget partagé : 10 points."
		preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(stat_control.get_line_edit())
	var modifier_label := find_child("Modifier_%s" % stat_key, true, false) as Label
	if modifier_label:
		modifier_label.mouse_filter = Control.MOUSE_FILTER_STOP
		modifier_label.tooltip_text = tooltip
	var info_label := find_child("Info_%s" % stat_key, true, false) as Label
	if info_label:
		info_label.mouse_filter = Control.MOUSE_FILTER_STOP
		info_label.tooltip_text = tooltip


func _configure_tooltip_for_secondary_row(stat_key: String, stat_label: Label, value_label: Label) -> void:
	preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(stat_label)
	var tooltip := _secondary_stat_tooltip(stat_key)
	for control in [stat_label, value_label]:
		if control:
			control.mouse_filter = Control.MOUSE_FILTER_STOP
			control.tooltip_text = tooltip
	var info_label := find_child("Info_%s" % stat_key, true, false) as Label
	if info_label:
		info_label.mouse_filter = Control.MOUSE_FILTER_STOP
		info_label.tooltip_text = tooltip


func _refresh_secondary_stats() -> void:
	for key in StatDefs.SECONDARY_STAT_KEYS:
		var value_label := find_child("Secondary_%s" % key, true, false) as Label
		if value_label:
			value_label.text = str(int(_secondary_stats.get(key, StatDefs.SECONDARY_STAT_DEFAULT)))


func _collect_stats() -> Dictionary:
	var out := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	for key in StatDefs.STAT_KEYS:
		out[key] = StatDefs.CHARACTER_MIN_STAT + int(_invested_points.get(key, 0))
	return out


func _collect_display_stats() -> Dictionary:
	var out := _collect_stats()
	for key in StatDefs.STAT_KEYS:
		out[key] = int(out[key]) + int(_class_bonus_stats.get(key, 0))
	return out


func _populate_class_cards() -> void:
	var grid := find_child("ClassesGrid", true, false) as GridContainer
	if grid == null:
		return
	if grid.get_child_count() > 0:
		return

	var classes: Dictionary = GameDataLoader.get_classes()
	var keys: Array = classes.keys()
	keys.sort()
	# Disposition en T : toutes les classes sur une seule bande horizontale.
	# Le ScrollContainer prend le relais sur les écrans étroits.
	grid.columns = maxi(1, keys.size())
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for key in keys:
		var cdef := classes[key] as Dictionary
		grid.add_child(_build_class_card(str(key), cdef))

	call_deferred("_refresh_class_selection")


func _build_class_card(class_id: String, class_data: Dictionary) -> Button:
	var card: Button = ClassCardFactory.create(class_id, str(class_data.get("icon", "")))
	card.name = "ClassCard_%s" % class_id
	card.set_meta("icon_height", 64)
	card.text = ""
	card.custom_minimum_size = Vector2(184, 132)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.focus_mode = Control.FOCUS_ALL
	card.tooltip_text = str(class_data.get("description", "")) + "\nCaractéristiques conseillées : " + ", ".join(PackedStringArray(class_data.get("primary", []))) + "\nSpécialisez vos 10 points ou compensez les caractéristiques non favorisées par votre classe."
	preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(card)
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
	_refresh_progression_summary(class_id)


func _apply_class_stats(class_id: String) -> void:
	_class_bonus_stats = CharacterCreationRules.get_creation_class_score_bonus(class_id)
	_refresh_stat_controls()


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
	if _updating_controls:
		return
	var class_bonus := int(_class_bonus_stats.get(stat_key, 0))
	var requested := maxi(0, int(value) - StatDefs.CHARACTER_MIN_STAT - class_bonus)
	var previous := int(_invested_points.get(stat_key, 0))
	_invested_points[stat_key] = mini(requested, previous + _points_remaining())
	_refresh_stat_controls()


func _points_spent() -> int:
	var spent := 0
	for key in StatDefs.STAT_KEYS:
		spent += maxi(0, int(_invested_points.get(key, 0)))
	return spent


func _points_remaining() -> int:
	return maxi(0, POINTS_POOL_TOTAL - _points_spent())


func _refresh_stat_controls() -> void:
	_updating_controls = true
	var remaining := _points_remaining()
	for key in StatDefs.STAT_KEYS:
		var invested := int(_invested_points.get(key, 0))
		var class_bonus := int(_class_bonus_stats.get(key, 0))
		var final_value := StatDefs.CHARACTER_MIN_STAT + invested + class_bonus
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			node.min_value = float(StatDefs.CHARACTER_MIN_STAT + class_bonus)
			node.max_value = float(final_value + remaining)
			node.value = float(final_value)
			node.tooltip_text = _stat_breakdown_tooltip(key, final_value)
		var detailed_tooltip := _stat_breakdown_tooltip(key, final_value)
		var stat_name := find_child("Label%s" % str(key).capitalize(), true, false) as Label
		if stat_name: stat_name.tooltip_text = detailed_tooltip
		var modifier_label := find_child("Modifier_%s" % key, true, false) as Label
		if modifier_label:
			modifier_label.text = "(%s)" % _format_signed(StatDefs.score_to_modifier(final_value))
			modifier_label.tooltip_text = detailed_tooltip
		var info_label := find_child("Info_%s" % key, true, false) as Label
		if info_label:
			info_label.tooltip_text = detailed_tooltip
	_updating_controls = false
	_update_derived_stats()

func _update_derived_stats() -> void:
	var stats := _collect_display_stats()
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
		var rules := {"DerivedAttaqueValue": "Attaque de la fiche : 10 + modificateurs de Force et de Commandement.", "DerivedDefenseValue": "Défense de la fiche : 10 + modificateur d’Espionnage.", "DerivedResistanceValue": "Résistance de la fiche : 10 + modificateur de Magie.", "DerivedInitiativeValue": "Initiative de la fiche : modificateur d’Espionnage. L’expédition utilise le score d’Espionnage pour l’ordre des tours.", "DerivedVigueurValue": "Jet de vigueur : modificateur de Force.", "DerivedVolonteValue": "Jet de volonté : modificateur de Magie.", "DerivedReflexesValue": "Jet de réflexes : modificateur d’Espionnage."}
		node.tooltip_text = str(rules.get(node_name, ""))
		preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(node)

func _update_points_pool() -> void:
	var remaining := _points_remaining()
	var label: Label = find_child("PointsPoolLabel", true, false) as Label
	if label:
		label.text = "Points restants : %d / %d" % [remaining, POINTS_POOL_TOTAL]


func _stat_breakdown_tooltip(stat_key: String, final_value: int) -> String:
	return StatDefs.description(stat_key) + "\n\n" + "%s : %d\n\nValeur de base : %d\nPoints investis : %s\nBonus de classe : %s\nBonus de clan : 0\nMalus actif : 0\n\nTotal : %d\nModificateur : %s" % [
		str(STAT_LABELS.get(stat_key, stat_key.capitalize())), final_value,
		StatDefs.CHARACTER_MIN_STAT, _format_signed(int(_invested_points.get(stat_key, 0))),
		_format_signed(int(_class_bonus_stats.get(stat_key, 0))), final_value,
		_format_signed(StatDefs.score_to_modifier(final_value)),
	]


func _stat_rules_tooltip(stat_key: String) -> String:
	var descriptions := {
		"force": "Mesure la puissance physique du personnage.\n\nInfluence :\n• l’Attaque\n• le jet de Vigueur",
		"magie": "Mesure sa maîtrise de l’Éther de Cendre.\n\nInfluence :\n• la Résistance\n• le jet de Volonté\n• la réserve de mana",
		"espionnage": "Mesure sa furtivité et sa vivacité.\n\nInfluence :\n• la Défense\n• l’Initiative\n• le jet de Réflexes",
		"artisanat": "Mesure sa maîtrise de la forge et des vestiges.",
		"diplomatie": "Mesure son influence et son talent de négociation.",
		"commandement": "Mesure son autorité et sa discipline.\n\nInfluence :\n• l’Attaque\n• les points de vie maximaux",
	}
	return "%s\n\n%s\n\nUtilisée comme prérequis par certains dons." % [
		str(STAT_LABELS.get(stat_key, stat_key.capitalize())), str(descriptions.get(stat_key, "")),
	]


func _secondary_stat_tooltip(stat_key: String) -> String:
	var tooltips := {
		"ESP": "Esprit\n\nMesure la force mentale et la stabilité psychique du personnage.\n\nPeut influencer :\n• la résistance mentale ;\n• certains jets de volonté ;\n• certains prérequis.",
		"TRA": "Transfuge\n\nMesure l'affinité du personnage avec la magi-tech.\n\nUtilisé pour :\n• les technologies occultes ;\n• les équipements magi-tech ;\n• certaines capacités spécialisées.",
		"ESE": "Essence\n\nMesure la qualité, la stabilité et la nature de l’essence et du sang.\n\nPeut être utilisée pour :\n• les prérequis de lignée ;\n• certaines capacités raciales ;\n• les mécaniques liées au sang.",
	}
	return str(tooltips.get(stat_key, ""))


func _format_signed(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


func _refresh_progression_summary(class_id: String) -> void:
	var summary := find_child("ProgressionSummary", true, false) as ScrollContainer
	if summary == null:
		return
	var grid := summary.get_node("ProgressionGrid") as GridContainer
	if grid == null:
		return
	_clear_progression_grid(grid)

	if class_id == "":
		_add_progression_message(grid, "Sélectionnez une classe pour afficher sa progression.")
		return

	var rows := GameDataLoader.get_class_progression(class_id)
	if rows.is_empty():
		_add_progression_message(grid, "Aucune progression disponible pour cette classe.")
		return

	var headers := ["Caractéristiques", "Talents"]
	for header in headers:
		_add_progression_grid_cell(grid, header, true)

	for row in rows:
		var d := row as Dictionary
		var stats_text := "Niveau %d\nAttaque : %d\nDéfense : %d\nRésistance : %d" % [
			int(d.get("niveau", 0)),
			int(d.get("attaque", 0)),
			int(d.get("defense", 0)),
			int(d.get("resistance", 0)),
		]
		var talents_text := _resolve_progression_talents(str(d.get("talents", "")))

		_add_progression_grid_cell(grid, stats_text, false)
		_add_progression_grid_cell(grid, talents_text, false)


func _resolve_progression_talents(raw_text: String) -> String:
	var resolved: Array[String] = []
	for raw_part in raw_text.split(",", false):
		var part := str(raw_part).strip_edges()
		resolved.append(str(PROGRESSION_TALENT_LABELS.get(part, part)))
	return ", ".join(resolved)


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
	return FallenUI.card_style(selected)
