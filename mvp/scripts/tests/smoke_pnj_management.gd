extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var service_script := load("res://scripts/services/pnj_daily_planner_service.gd")
	if service_script == null:
		failures.append("service PNJ introuvable")
		_finish(failures)
		return

	var planner: Variant = service_script.new()
	var roster := [
		planner.make_pnj_profile("pnj_story_ingrid", "Ingrid", "scenario", "stratege", 4, {
			"force": 6,
			"magie": 8,
			"espionnage": 7,
			"artisanat": 4,
			"diplomatie": 5,
			"commandement": 9,
		}),
		planner.make_pnj_profile("pnj_recrue_01", "Vael", "recrute", "eclaireur", 2, {
			"force": 5,
			"magie": 3,
			"espionnage": 8,
			"artisanat": 4,
			"diplomatie": 4,
			"commandement": 5,
		}),
	]
	var planning: Dictionary = planner.make_daily_plan()

	var soldats_refuses: Dictionary = planner.assign_soldiers(planning, "collecter_bois", 999, 30)
	if bool(soldats_refuses.get("ok", true)):
		failures.append("assignation soldats: le depassement d'effectif devrait etre refuse")

	var soldats_ok: Dictionary = planner.assign_soldiers(planning, "collecter_bois", 12, 30)
	if not bool(soldats_ok.get("ok", false)):
		failures.append("assignation soldats: mission valide refusee")
	else:
		planning = soldats_ok.get("planning", planning) as Dictionary

	var support_ok: Dictionary = planner.assign_pnj_support(roster, planning, "pnj_story_ingrid", "attaquer")
	if not bool(support_ok.get("ok", false)):
		failures.append("support PNJ: affectation valide refusee")
	else:
		planning = support_ok.get("planning", planning) as Dictionary
		roster = support_ok.get("roster", roster) as Array

	var support_double: Dictionary = planner.assign_pnj_support(roster, planning, "pnj_story_ingrid", "espionner")
	if bool(support_double.get("ok", true)):
		failures.append("support PNJ: double affectation non bloquee")

	roster[1]["etat"] = "blesse"
	var support_blesse: Dictionary = planner.assign_pnj_support(roster, planning, "pnj_recrue_01", "espionner")
	if bool(support_blesse.get("ok", true)):
		failures.append("support PNJ: un PNJ blesse ne doit pas etre assignable")
	roster[1]["etat"] = "disponible"

	var expedition_assign: Dictionary = planner.assign_pnj_expedition(roster, planning, "pnj_recrue_01", 4242)
	if not bool(expedition_assign.get("ok", false)):
		failures.append("expedition PNJ: affectation valide refusee")
	else:
		planning = expedition_assign.get("planning", planning) as Dictionary
		roster = expedition_assign.get("roster", roster) as Array

	var expedition: Dictionary = planner.build_expedition(roster[1], 4242)
	var rooms := expedition.get("rooms", []) as Array
	if rooms.size() != 4:
		failures.append("expedition PNJ: le mini-donjon doit contenir 4 salles")
	else:
		var expected_types := ["combat_faible", "evenement_aleatoire", "repos", "boss"]
		for i in range(expected_types.size()):
			var room := rooms[i] as Dictionary
			if str(room.get("type", "")) != expected_types[i]:
				failures.append("expedition PNJ: ordre des salles invalide")
				break

	var report_a: Dictionary = planner.resolve_expedition(roster[1], expedition)
	var report_b: Dictionary = planner.resolve_expedition(roster[1], planner.build_expedition(roster[1], 4242))
	if JSON.stringify(report_a) != JSON.stringify(report_b):
		failures.append("expedition PNJ: la resolution doit etre deterministe a seed fixe")

	var support_report: Dictionary = planner.resolve_daily_plan(roster, planning)
	var bonuses := support_report.get("hero_support", {}) as Dictionary
	if int(bonuses.get("attaquer", 0)) <= 0:
		failures.append("resolution journee: bonus heroique manquant")
	var expedition_reports := support_report.get("expeditions", []) as Array
	if expedition_reports.is_empty():
		failures.append("resolution journee: rapport d'expedition manquant")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SMOKE_OK: gestion PNJ")
		quit(0)
		return

	for failure in failures:
		push_error("SMOKE_FAIL: %s" % failure)
	quit(1)