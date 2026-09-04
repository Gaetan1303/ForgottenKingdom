extends SceneTree

const AUTOLOAD_WAIT_FRAMES := 180


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var clan_manager: Node = null

	for _i in range(AUTOLOAD_WAIT_FRAMES):
		clan_manager = get_root().get_node_or_null("/root/ClanManager")
		if clan_manager != null:
			break
		await process_frame

	if clan_manager == null:
		failures.append("ClanManager indisponible")
		_finish(failures)
		return

	clan_manager.nouvelle_partie("Aren", "Clan Test", "hellcaster", {"magie": 1}, {})

	if not clan_manager.has_method("ajouter_pnj_gere"):
		failures.append("ClanManager: API ajouter_pnj_gere manquante")
		_finish(failures)
		return

	var pnj_story: Dictionary = clan_manager.ajouter_pnj_gere("pnj_story_aren", "Aren", "scenario", "stratege", 4, {
		"force": 6,
		"magie": 8,
		"espionnage": 7,
		"artisanat": 4,
		"diplomatie": 5,
		"commandement": 9,
	})
	var pnj_recrue: Dictionary = clan_manager.ajouter_pnj_gere("pnj_recrue_01", "Vael", "recrute", "eclaireur", 2, {
		"force": 5,
		"magie": 3,
		"espionnage": 8,
		"artisanat": 4,
		"diplomatie": 4,
		"commandement": 5,
	})
	if str(pnj_story.get("type", "")) != "scenario":
		failures.append("ClanManager: type PNJ scenario non conserve")
	if str(pnj_recrue.get("type", "")) != "recrute":
		failures.append("ClanManager: type PNJ recrute non conserve")

	var mission_soldats: Dictionary = clan_manager.planifier_mission_soldats("collecter_bois", 12)
	if not bool(mission_soldats.get("ok", false)):
		failures.append("ClanManager: planification soldats invalide")

	var support: Dictionary = clan_manager.assigner_pnj_support_journee("pnj_story_aren", "attaquer")
	if not bool(support.get("ok", false)):
		failures.append("ClanManager: support PNJ invalide")

	var expedition: Dictionary = clan_manager.assigner_pnj_expedition_journee("pnj_recrue_01", 4242)
	if not bool(expedition.get("ok", false)):
		failures.append("ClanManager: expedition PNJ invalide")

	var resolution: Dictionary = clan_manager.resoudre_planning_pnj_journee()
	var gains := resolution.get("resource_gains", {}) as Dictionary
	if int(gains.get("bois", 0)) <= 0:
		failures.append("ClanManager: gains soldats non appliques")
	var hero_support := resolution.get("hero_support", {}) as Dictionary
	if int(hero_support.get("attaquer", 0)) <= 0:
		failures.append("ClanManager: bonus support absent")
	var expeditions := resolution.get("expeditions", []) as Array
	if expeditions.is_empty():
		failures.append("ClanManager: rapport expedition absent")

	var state: Dictionary = clan_manager.get_pnj_gestion_state()
	var planning := state.get("planning", {}) as Dictionary
	var missions_pnj := planning.get("missions_pnj", []) as Array
	var missions_soldats := planning.get("missions_soldats", []) as Array
	if not missions_pnj.is_empty() or not missions_soldats.is_empty():
		failures.append("ClanManager: le planning devrait etre reinitialise apres resolution")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SMOKE_OK: integration ClanManager PNJ")
		quit(0)
		return

	for failure in failures:
		push_error("SMOKE_FAIL: %s" % failure)
	quit(1)