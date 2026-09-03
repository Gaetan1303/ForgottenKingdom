extends SceneTree

const CorruptionServiceScript = preload("res://scripts/services/corruption_service.gd")
const CreatureRosterServiceScript = preload("res://scripts/services/creature_roster_service.gd")
const PactServiceScript = preload("res://scripts/services/pact_service.gd")
const WorldStateAdapterScript = preload("res://scripts/adapters/world_state_adapter.gd")

class FakeClan extends Node:
	var tour_actuel: int = 2
	var moment_journee: String = "nuit"
	var ressources: Dictionary = {"or": 50}
	var maisons_nobles: Array = []
	var pnj_gestion: Dictionary = {"roster": [{"id": "pnj_test", "nom": "Test"}]}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var clan := FakeClan.new()
	var corruption := CorruptionServiceScript.new()
	corruption.setup(clan)
	corruption.register_character("pnj_test", 50.0)
	corruption.set_corruption("pnj_test", 42.0, "adapter_test")
	clan.set_meta("corruption_service", corruption)
	clan.set_meta("creature_roster", CreatureRosterServiceScript.new())
	clan.set_meta("pact_service", PactServiceScript.new())

	var world_state = WorldStateAdapterScript.from_clan_manager(clan)
	var saved: Dictionary = WorldStateAdapterScript.to_save_dict(world_state)
	var restored = WorldStateAdapterScript.from_save_dict(saved)
	if float((restored.corruption_data.get("profiles", {}) as Dictionary).get("pnj_test", {}).get("level", 0.0)) != 42.0:
		failures.append("round-trip corruption_data invalide")

	var target := FakeClan.new()
	var target_corruption := CorruptionServiceScript.new()
	target_corruption.setup(target)
	target.set_meta("corruption_service", target_corruption)
	target.set_meta("creature_roster", CreatureRosterServiceScript.new())
	target.set_meta("pact_service", PactServiceScript.new())
	WorldStateAdapterScript.apply_to_clan_manager(restored, target)
	if target_corruption.get_corruption_level("pnj_test") != 42.0:
		failures.append("application au service shadow invalide")
	var migrated_pnj := (target.pnj_gestion.get("roster", []) as Array)[0] as Dictionary
	if float(migrated_pnj.get("corruption", 0.0)) != 42.0:
		failures.append("synchronisation legacy explicite invalide")

	clan.free()
	target.free()
	if failures.is_empty():
		print("WORLD_STATE_ADAPTER_OK")
		quit(0)
		return
	for failure in failures:
		push_error("WORLD_STATE_ADAPTER_FAIL: %s" % failure)
	quit(1)
