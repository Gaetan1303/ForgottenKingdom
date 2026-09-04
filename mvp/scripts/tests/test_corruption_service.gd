extends SceneTree

const Enums = preload("res://scripts/core/enums.gd")
const CorruptionServiceScript = preload("res://scripts/services/corruption_service.gd")
const CreatureRosterServiceScript = preload("res://scripts/services/creature_roster_service.gd")
const PactServiceScript = preload("res://scripts/services/pact_service.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var emitted := {"progress": 0, "completed": 0, "corrupted": 0}
	var corruption := CorruptionServiceScript.new()
	corruption.training_progress.connect(func(_id, _progress): emitted["progress"] += 1)
	corruption.training_completed.connect(func(_id, _type, _results): emitted["completed"] += 1)
	corruption.character_corrupted.connect(func(_id, _level, _stage): emitted["corrupted"] += 1)

	var registered: Dictionary = corruption.register_character("pnj_adulte", 40.0, ["resilient"], 0, {}, "res://portrait.png")
	_check(not registered.is_empty(), "enregistrement PNJ refusé", failures)
	_check(corruption.has_virginity("pnj_adulte", "vaginal"), "virginity par défaut absente", failures)

	var creature_paths := [
		"res://resources/creatures/succubus_base.tres",
		"res://resources/creatures/incubus_base.tres",
		"res://resources/creatures/tentacle_beast.tres",
		"res://resources/creatures/mind_flayer.tres",
	]
	var creatures: Array = []
	for path in creature_paths:
		var creature := ResourceLoader.load(path)
		_check(creature != null and bool(creature.call("is_valid")), "créature non chargeable: %s" % path, failures)
		if creature != null:
			creatures.append(creature)
			corruption.register_creature(creature)

	if not creatures.is_empty():
		var trainer = creatures[0]
		var assigned: Dictionary = corruption.assign_creature_to_target(str(trainer.get("id")), "pnj_adulte", Enums.AssignmentType.TRAINING)
		_check(bool(assigned.get("ok", false)), "assignation créature refusée", failures)
		var started: Dictionary = corruption.start_training("pnj_adulte", Enums.TrainingType.SEDUCTION)
		_check(bool(started.get("ok", false)), "training refusé", failures)
		var advanced: Dictionary = corruption.advance_training("pnj_adulte", 200.0)
		_check(bool(advanced.get("completed", false)), "training non terminé", failures)
		_check(float(corruption.get_corruption_level("pnj_adulte")) > 0.0, "training sans corruption", failures)

	_check(int(emitted["progress"]) > 0 and int(emitted["completed"]) == 1 and int(emitted["corrupted"]) > 0, "signaux training/corruption absents", failures)
	var json := JSON.stringify(corruption.export_state())
	_check(not json.is_empty(), "état corruption non sérialisable", failures)
	var restored := CorruptionServiceScript.new()
	restored.import_state(corruption.export_state())
	_check(is_equal_approx(restored.get_corruption_level("pnj_adulte"), corruption.get_corruption_level("pnj_adulte")), "round-trip corruption invalide", failures)

	if not creatures.is_empty():
		var roster := CreatureRosterServiceScript.new()
		_check(roster.capture_creature(creatures[0]), "capture créature refusée", failures)
		roster.modify_loyalty(str(creatures[0].get("id")), 10.0)
		var roster_copy := CreatureRosterServiceScript.new()
		roster_copy.import_state(roster.export_state())
		_check(roster_copy.get_captured_list().size() == 1, "round-trip roster invalide", failures)

	var pacts := PactServiceScript.new()
	var offered: Dictionary = pacts.offer_pact("succubus_lilith", "pnj_adulte", Enums.PactType.BOND, {"ritual_power": 100.0, "requirements": ["oath"], "rewards": {"loyalty": 5}})
	_check(bool(offered.get("ok", false)), "offre de pacte refusée", failures)
	var ritual: Dictionary = pacts.attempt_pact_ritual("succubus_lilith", "pnj_adulte")
	_check(bool(ritual.get("ok", false)), "rituel de pacte refusé", failures)
	if bool(offered.get("ok", false)):
		var pact_id := str((offered.get("pact", {}) as Dictionary).get("pact_id", ""))
		pacts.fulfill_pact_requirement(pact_id, "oath")
		_check((pacts.get_pacts_for_character("pnj_adulte")[0] as Dictionary).get("status") == "fulfilled", "pacte non accompli", failures)

	_finish(failures)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("CORRUPTION_SERVICE_OK")
		quit(0)
		return
	for failure in failures:
		push_error("CORRUPTION_SERVICE_FAIL: %s" % failure)
	quit(1)
