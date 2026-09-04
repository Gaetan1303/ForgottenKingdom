extends SceneTree

const Enums = preload("res://scripts/core/enums.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var clan_manager := get_root().get_node_or_null("ClanManager")
	if clan_manager == null:
		push_error("CORRUPTION_CLAN_MANAGER_FAIL: autoload absent")
		quit(1)
		return
	clan_manager.ajouter_pnj_gere("pnj_shadow_test", "Shadow", "test", "auxiliaire", 1, {}, [])
	if clan_manager.get_corruption_profile("pnj_shadow_test").is_empty():
		failures.append("nouveau PNJ non enregistré dans le service")
	var roster = clan_manager.get_creature_roster_service()
	var creature: Resource = ResourceLoader.load("res://resources/creatures/succubus_base.tres")
	if creature == null or not roster.capture_creature(creature):
		failures.append("capture via roster refusée")
	else:
		var assigned: Dictionary = clan_manager.assign_creature_to_pnj("succubus_lilith", "pnj_shadow_test", Enums.AssignmentType.TRAINING)
		if not bool(assigned.get("ok", false)):
			failures.append("assignation via façade refusée")
		var started: Dictionary = clan_manager.start_pnj_training("pnj_shadow_test", Enums.TrainingType.SEDUCTION)
		if not bool(started.get("ok", false)):
			failures.append("training via façade refusé")
		clan_manager.process_corruption_tick(200.0)
		var saved_level := float(clan_manager.get_corruption_profile("pnj_shadow_test").get("level", 0.0))
		if saved_level <= 0.0:
			failures.append("tick façade sans effet shadow")
		var pact_service = clan_manager.get_pact_service()
		pact_service.offer_pact("succubus_lilith", "pnj_shadow_test", Enums.PactType.BOND, {"ritual_power": 100.0})
		clan_manager.sauvegarder()
		clan_manager.get_corruption_service().cleanse("pnj_shadow_test", 100.0)
		if not clan_manager.charger_sauvegarde():
			failures.append("rechargement sauvegarde refusé")
		elif not is_equal_approx(float(clan_manager.get_corruption_profile("pnj_shadow_test").get("level", 0.0)), saved_level):
			failures.append("corruption perdue au rechargement")
		elif clan_manager.get_creature_roster_service().get_captured_list().size() != 1:
			failures.append("roster perdu au rechargement")
		elif clan_manager.get_pact_service().get_pacts_for_character("pnj_shadow_test").size() != 1:
			failures.append("pacte perdu au rechargement")

	if failures.is_empty():
		print("CORRUPTION_CLAN_MANAGER_OK")
		quit(0)
		return
	for failure in failures:
		push_error("CORRUPTION_CLAN_MANAGER_FAIL: %s" % failure)
	quit(1)
