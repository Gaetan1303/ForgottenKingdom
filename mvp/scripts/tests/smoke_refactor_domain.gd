extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	var legacy := {
		"id": "pnj_test",
		"nom": "Test",
		"type": "recrute",
		"role": "garde",
		"niveau": 3,
		"stats": {
			"force": 14,
			"magie": 9,
			"espionnage": 9,
			"artisanat": 8,
			"diplomatie": 8,
			"commandement": 12,
		},
		"traits": ["disciplined"],
		"etat": "disponible",
		"equipment": ["Bouclier"],
		"behavior": {"behavior": "patrouille"},
		"description": "Champ legacy a conserver",
	}

	var profile := CreatureProfile.from_dict(legacy)
	if profile.id != "pnj_test":
		failures.append("CreatureProfile: id legacy non migre")
	if profile.corruption == null:
		failures.append("CreatureProfile: profil de corruption absent")
	else:
		if profile.corruption.stage != CorruptionStage.Type.PURE:
			failures.append("CreatureProfile: stade initial non PURE")

	var roundtrip := profile.to_dict()
	if str((roundtrip.get("equipment", []) as Array)[0]) != "Bouclier":
		failures.append("CreatureProfile: equipment perdu au round-trip")
	if str((roundtrip.get("behavior", {}) as Dictionary).get("behavior", "")) != "patrouille":
		failures.append("CreatureProfile: behavior perdu au round-trip")
	if str(roundtrip.get("description", "")) != "Champ legacy a conserver":
		failures.append("CreatureProfile: champ custom perdu au round-trip")

	var corruption_service := CorruptionService.new()
	var effect := CorruptionEffect.new("test", 100.0)
	var result := corruption_service.apply(profile.corruption, effect)
	if result.new_level <= 0.0 or result.new_level >= 100.0:
		failures.append("CorruptionService: resistance non appliquee")
	if profile.corruption.stage == CorruptionStage.Type.PURE:
		failures.append("CorruptionService: stade non recalcule")

	var roster_service := CreatureRosterService.new()
	var state := roster_service.make_default_state()
	var add_result := roster_service.add_or_update(state, CreatureProfile.from_dict(legacy))
	if not bool(add_result.get("ok", false)):
		failures.append("CreatureRosterService: ajout refuse")
	else:
		state = add_result.get("state", state) as Dictionary

	var corrupt_result := roster_service.apply_corruption(state, "pnj_test", "smoke", 25.0)
	if not bool(corrupt_result.get("ok", false)):
		failures.append("CreatureRosterService: corruption PNJ refusee")
	else:
		var updated_state := corrupt_result.get("state", {}) as Dictionary
		var updated_profile := roster_service.get_profile(updated_state, "pnj_test")
		if updated_profile == null or updated_profile.corruption.level <= 0.0:
			failures.append("CreatureRosterService: corruption non persistee")

	var planner := PnjDailyPlannerService.new()
	var soldier_service := SoldierAssignmentService.new(planner)
	var soldier_state := roster_service.make_default_state()
	var pool := ["S1", "S2", "S3", "S4"]
	var planned := soldier_service.plan_mission(soldier_state, "collecter_bois", 2, pool)
	if not bool(planned.get("ok", false)):
		failures.append("SoldierAssignmentService: mission valide refusee")
	elif (planned.get("available_ids", []) as Array).size() != 2:
		failures.append("SoldierAssignmentService: reservation du pool incorrecte")

	var economy := ClanEconomyService.new()
	var economy_result := economy.gain(
		{"or": 10, "soldats": 2},
		{"or": 5, "soldats": 2},
		["S1", "S2"],
		3,
		600
	)
	if int((economy_result.get("resources", {}) as Dictionary).get("or", 0)) != 15:
		failures.append("ClanEconomyService: gain or incorrect")
	if (economy_result.get("available_soldier_ids", []) as Array).size() != 4:
		failures.append("ClanEconomyService: pool soldats desynchronise")

	if failures.is_empty():
		print("SMOKE_OK: creature/corruption refactor")
		quit(0)
		return

	for failure in failures:
		push_error("SMOKE_FAIL: %s" % failure)
	quit(1)
