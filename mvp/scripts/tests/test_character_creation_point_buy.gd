extends SceneTree

const CreationData = preload("res://scripts/ui/character_creation/creation_data.gd")
const Rules = preload("res://scripts/services/character_creation_rules_service.gd")

var _failures: Array[String] = []
var _submitted_payload: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_test_linear_rule()
	await _test_slide_2_state_and_persistence()
	await _test_slide_3_prerequisites()
	if _failures.is_empty():
		print("CHARACTER_CREATION_POINT_BUY_OK")
		quit(0)
		return
	for failure in _failures:
		push_error("POINT_BUY_FAIL: %s" % failure)
	quit(1)


func _test_linear_rule() -> void:
	for value in [8, 9, 12, 13, 17]:
		_expect(Rules.stat_upgrade_cost_preview(value) == 1, "+1 depuis %d doit coûter 1 point" % value)
	var data := CreationData.new()
	_expect(data.stats_points_pool == 10, "la réserve initiale doit être de 10")
	_expect(data.points_remaining() == 10, "l’état initial doit afficher 10 / 10")
	data.load_dict({"stats_points_pool": 18, "stats": {}})
	_expect(data.stats_points_pool == 10, "un ancien brouillon ne doit pas restaurer la réserve de 18")


func _test_slide_2_state_and_persistence() -> void:
	var packed := load("res://scenes/character_creation/slides/slide_02_class_stats.tscn") as PackedScene
	var slide := packed.instantiate()
	root.add_child(slide)
	await process_frame
	var data := CreationData.new()
	data.class_id = "hellcaster"
	slide.enter_slide(data)
	await process_frame
	var label := slide.find_child("PointsPoolLabel", true, false) as Label
	_expect(label.text == "Points restants : 10 / 10", "compteur initial incorrect : %s" % label.text)
	var progression_text := _collect_label_text(slide.find_child("ProgressionGrid", true, false))
	_expect(progression_text.find("Caractéristiques") != -1, "la progression doit afficher Caractéristiques")
	_expect(progression_text.find("Attaque :") != -1 and progression_text.find("ATK") == -1, "les caractéristiques secondaires doivent être écrites en français")
	_expect(progression_text.find("abyss_focus") == -1, "un identifiant de talent ne doit pas être visible")

	var force := slide.find_child("Stat_force", true, false) as SpinBox
	force.value += 1
	_expect(label.text == "Points restants : 9 / 10", "+1 Force doit laisser 9 points")
	force.value += 4
	_expect(int(slide.collect_payload()["stats"]["force"]) == 13, "+5 Force doit produire une valeur achetée de 13")
	_expect(label.text == "Points restants : 5 / 10", "+5 Force doit laisser 5 points")
	_expect(force.tooltip_text.find("Points investis : +5") != -1, "l’infobulle doit détailler les points investis")
	_expect((slide.find_child("Modifier_force", true, false) as Label).text == "(+1)", "Force 13 doit afficher le modificateur +1")

	force.value -= 5
	var allocations := {"force": 3, "magie": 2, "espionnage": 1, "commandement": 4}
	for key in allocations.keys():
		var spin := slide.find_child("Stat_%s" % key, true, false) as SpinBox
		spin.value += int(allocations[key])
	_expect(label.text == "Points restants : 0 / 10", "dix augmentations cumulées doivent épuiser la réserve")
	var magie := slide.find_child("Stat_magie", true, false) as SpinBox
	var magie_before := int(magie.value)
	magie.value += 1
	_expect(int(magie.value) == magie_before, "une onzième augmentation doit être refusée")
	var commandement := slide.find_child("Stat_commandement", true, false) as SpinBox
	commandement.value -= 1
	_expect(label.text == "Points restants : 1 / 10", "une diminution doit rendre exactement un point")

	var before_class_change := slide.collect_payload()["stats"] as Dictionary
	slide._select_class_card("demon_blade")
	_expect(slide.collect_payload()["stats"] == before_class_change, "un changement de classe ne doit pas modifier les investissements")
	_submitted_payload = {}
	slide.slide_data_submitted.connect(_capture_submitted_payload)
	slide.request_previous()
	_expect((_submitted_payload.get("stats", {}) as Dictionary) == before_class_change, "le retour à l’étape 1 doit enregistrer les investissements")

	var restored_data := CreationData.new()
	restored_data.class_id = "demon_blade"
	restored_data.stats = before_class_change.duplicate(true)
	var restored := packed.instantiate()
	root.add_child(restored)
	await process_frame
	restored.enter_slide(restored_data)
	await process_frame
	_expect(restored.collect_payload()["stats"] == before_class_change, "un retour à l’étape 2 doit restaurer les investissements")
	_expect((restored.find_child("PointsPoolLabel", true, false) as Label).text == "Points restants : 1 / 10", "le compteur doit survivre à l’aller-retour")
	slide.queue_free()
	restored.queue_free()
	await process_frame


func _test_slide_3_prerequisites() -> void:
	var packed := load("res://scenes/character_creation/slides/slide_03_feats_abilities.tscn") as PackedScene
	var slide := packed.instantiate()
	root.add_child(slide)
	await process_frame
	var data := CreationData.new()
	data.class_id = "hellcaster"
	data.stats["force"] = 12
	slide.enter_slide(data)
	await process_frame
	var attack := slide.find_child("donCard_attaque_puissante", true, false) as Button
	_expect(attack != null and attack.disabled, "Attaque puissante doit être indisponible avec Force 12")
	var prereq := attack.find_child("PrerequisiteLabel", true, false) as Label
	_expect(prereq.text.find("Force : 12 / 13 ✗") != -1, "le prérequis doit afficher la valeur réelle et la valeur requise")
	var attack_text := _collect_label_text(attack)
	_expect(attack_text.find("FOR") == -1 and attack_text.find(">=") == -1, "la carte ne doit afficher ni abréviation ni opérateur technique")
	_expect(attack_text.find("Texte :") == -1, "le type interne texte ne doit pas apparaître dans l’effet")
	slide.queue_free()
	await process_frame
	data.stats["force"] = 13
	slide = packed.instantiate()
	root.add_child(slide)
	await process_frame
	slide.enter_slide(data)
	await process_frame
	attack = slide.find_child("donCard_attaque_puissante", true, false) as Button
	_expect(attack != null and not attack.disabled, "Attaque puissante doit être disponible avec Force 13")
	prereq = attack.find_child("PrerequisiteLabel", true, false) as Label
	_expect(prereq.text.find("Force : 13 / 13 ✓") != -1, "le prérequis rempli doit être explicitement validé")
	var wall := slide.find_child("donCard_mur_de_boucliers", true, false) as Button
	_expect(wall != null and wall.disabled, "un don dépendant doit rester indisponible sans le don requis")
	var robustesse := slide.find_child("donCard_robustesse", true, false) as Button
	robustesse.set_pressed(true)
	var wall_prereq := wall.find_child("PrerequisiteLabel", true, false) as Label
	_expect(wall_prereq.text.find("Don : Robustesse ✓") != -1, "le nom français du don requis doit être affiché")
	slide.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _capture_submitted_payload(payload: Dictionary) -> void:
	_submitted_payload = payload.duplicate(true)


func _collect_label_text(node: Node) -> String:
	if node == null:
		return ""
	var out: String = str((node as Label).text) + "\n" if node is Label else ""
	for child in node.get_children():
		out += _collect_label_text(child)
	return out
