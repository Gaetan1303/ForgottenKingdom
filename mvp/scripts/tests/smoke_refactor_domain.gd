extends SceneTree

const CreatureProfileScript = preload("res://scripts/data/creature_profile.gd")
const CreatureFactoryScript = preload("res://scripts/factory/creature_factory.gd")
const CreatureRosterServiceScript = preload("res://scripts/services/creature_roster_service.gd")
const CorruptionServiceScript = preload("res://scripts/services/corruption_service.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var legacy := {
		"id": "creature_test", "nom": "Test", "species_id": "imp", "niveau": 3,
		"stats": {"force": 14}, "traits": ["disciplined"], "etat": "disponible",
		"equipment": ["Bouclier"], "behavior": {"behavior": "patrouille"},
		"description": "Champ legacy a conserver",
	}
	var profile := CreatureProfileScript.from_dict(legacy)
	if profile.id != "creature_test" or not profile.is_valid():
		failures.append("CreatureProfile: migration legacy invalide")
	var roundtrip: Dictionary = profile.to_dict()
	if str((roundtrip.get("equipment", []) as Array)[0]) != "Bouclier" or str(roundtrip.get("description", "")) != "Champ legacy a conserver":
		failures.append("CreatureProfile: données legacy perdues")

	var factory := CreatureFactoryScript.new()
	var generated = factory.generate_profile(legacy)
	if generated == null or not generated.is_valid():
		failures.append("CreatureFactory: génération invalide")

	var roster := CreatureRosterServiceScript.new()
	var added: Dictionary = roster.add([], profile)
	if not bool(added.get("ok", false)) or roster.get_available(added.get("roster", []) as Array).size() != 1:
		failures.append("CreatureRosterService: API legacy invalide")

	var corruption := CorruptionServiceScript.new()
	corruption.register_character("pnj_test", 50.0, [])
	var result: Dictionary = corruption.apply_corruption("pnj_test", 20.0, "smoke")
	if not bool(result.get("ok", false)) or corruption.get_corruption_level("pnj_test") <= 0.0:
		failures.append("CorruptionService: corruption invalide")

	if failures.is_empty():
		print("SMOKE_OK: creature/corruption refactor")
		quit(0)
		return
	for failure in failures:
		push_error("SMOKE_FAIL: %s" % failure)
	quit(1)
