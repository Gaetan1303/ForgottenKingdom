
extends SceneTree

# Use global class_names from data scripts (StatDefs, CharacterBuildService, Character)
const CharacterFactoryClass = preload("res://scripts/factory/character_factory.gd")
const CharacterClass = preload("res://scripts/data/character.gd")


func _initialize() -> void:
	var failures: Array[String] = []

	_run_statdefs_sanitize_tests(failures)
	_run_build_service_tests(failures)
	_run_character_factory_tests(failures)
	_run_character_from_dict_tests(failures)

	if failures.is_empty():
		print("SMOKE_OK: stats")
		quit(0)
		return

	for f in failures:
		push_error("SMOKE_FAIL: %s" % f)
	quit(1)


func _run_statdefs_sanitize_tests(failures: Array[String]) -> void:
	var partial := {
		"force": 99,
		"magie": -5,
		"artisanat": 11,
	}
	var sanitized := StatDefs.sanitize_stats(
		partial,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)
	if int(sanitized.get("force", -1)) != StatDefs.CHARACTER_MAX_STAT:
		failures.append("StatDefs.sanitize_stats: clamp max force KO")
	if int(sanitized.get("magie", -1)) != StatDefs.CHARACTER_MIN_STAT:
		failures.append("StatDefs.sanitize_stats: clamp min magie KO")
	if int(sanitized.get("artisanat", -1)) != 11:
		failures.append("StatDefs.sanitize_stats: artisanat conserve KO")
	for key in StatDefs.STAT_KEYS:
		if not sanitized.has(key):
			failures.append("StatDefs.sanitize_stats: cle manquante %s" % key)


func _run_build_service_tests(failures: Array[String]) -> void:
	var class_bonus := {
		"force": 2,
		"magie": 0,
		"espionnage": 0,
		"artisanat": 0,
		"diplomatie": 1,
		"commandement": 0,
	}
	var raw := {
		"force": 16,
		"magie": 9,
		"espionnage": 12,
		"artisanat": 8,
		"diplomatie": 13,
		"commandement": 10,
	}
	var bonus_comp := {"magie": 2}
	var bonus_archetype := {"diplomatie": 1}

	var out := CharacterBuildService.compute_final_stats(class_bonus, raw, bonus_comp, bonus_archetype)
	if int(out.get("force", -999)) != 5:
		failures.append("CharacterBuildService: force attendue 5")
	if int(out.get("magie", -999)) != 2:
		failures.append("CharacterBuildService: magie attendue 2")
	if int(out.get("espionnage", -999)) != 2:
		failures.append("CharacterBuildService: espionnage attendue 2")
	if int(out.get("artisanat", -999)) != 1:
		failures.append("CharacterBuildService: artisanat attendue 1")
	if int(out.get("diplomatie", -999)) != 3:
		failures.append("CharacterBuildService: diplomatie attendue 3")
	if int(out.get("commandement", -999)) != 1:
		failures.append("CharacterBuildService: commandement attendue 1")


func _run_character_factory_tests(failures: Array[String]) -> void:
	var factory = CharacterFactoryClass.new()
	var profile := {
		"name": "TestNPC",
		"clan": "Clan QA",
		"classe": "hellcaster",
		"niveau": 1,
		"points_a_distribuer_base": 18,
		"stats": {
			"force": 17,
			"magie": 12,
			"espionnage": 15,
			"artisanat": 9,
			"diplomatie": 8,
			"commandement": 18,
		},
	}
	var ch = factory.create_from_profile(profile)
	if ch == null:
		failures.append("CharacterFactory: personnage null")
		return
	if int(ch.stats.get("force", -1)) != 17:
		failures.append("CharacterFactory: force non chargee depuis stats")
	if int(ch.stats.get("commandement", -1)) != 18:
		failures.append("CharacterFactory: commandement non charge depuis stats")


func _run_character_from_dict_tests(failures: Array[String]) -> void:
	var ch = CharacterClass.new()
	ch.from_dict({
		"name": "Corrupted",
		"stats": {
			"force": 999,
			"magie": -10,
			"espionnage": 14,
			"artisanat": 13,
			"diplomatie": 12,
			"commandement": 11,
		}
	})
	if int(ch.stats.get("force", -1)) != StatDefs.CHARACTER_MAX_STAT:
		failures.append("Character.from_dict: force non clamp")
	if int(ch.stats.get("magie", -1)) != StatDefs.CHARACTER_MIN_STAT:
		failures.append("Character.from_dict: magie non clamp")
