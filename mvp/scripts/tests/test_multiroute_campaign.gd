extends SceneTree
const Campaign = preload("res://scripts/services/power_campaign_service.gd")
const Loops = preload("res://scripts/services/power_loop_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
const Memories = preload("res://scripts/services/memory_tutorial_service.gd")
var failures: Array[String] = []
var cm: Node
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func settle() -> void:
	for _i in range(6): await process_frame
func next_decision() -> void:
	var count := 0
	while cm.action_deja_utilisee_pour_moment() and count < 4:
		check(cm.advance_day_phase().ok, "temps canonique avancé")
		count += 1
func run() -> void:
	seed(4271)
	root.size = Vector2i(1280, 720)
	cm = root.get_node("ClanManager")
	var save := root.get_node("SaveSystem")
	var dungeon := root.get_node("DungeonGenerator")
	var paths := {"espionage": ["observe", "sabotage"], "diplomacy": ["audience", "bargain"], "occult": ["ward", "bind"], "craft": ["craft_grounded", "deploy_artifact"], "command": ["recruit_squad", "formation_guard", "command_assault"]}
	for route in paths:
		save.set_active_slot("multiroute_" + str(route))
		cm.nouvelle_partie("Héritier", "Maison libre", "hellcaster", {})
		Refuge.initialize(cm.service_context)
		cm.campaign.version = 3
		Campaign.ensure(cm.service_context)
		check(not cm.evaluer_etat_partie().terminee, "pas de défaite faute d’armée au démarrage")
		check(cm.get_pnj_gestion_state().roster.size() == 1 and cm.get_pnj_gestion_state().roster[0].id == "pnj_kael", "Kael seule au présent")
		Refuge.prioritize_galleries(cm.service_context)
		Refuge.social_choice(cm.service_context, true)
		var panel: Control = load("res://scripts/ui/power_routes_panel.gd").new()
		panel.size = Vector2(850, 680)
		root.add_child(panel)
		await settle()
		for tab in panel.find_children("route_*", "Button", true, false):
			check(tab.size.x >= 180 and tab.size.y < 100, "onglets lisibles dans le conteneur de flux")
		for action in paths[route]:
			next_decision()
			panel._select(str(route))
			var button := panel._content.get_node(str(action)) as Button
			check(not button.disabled, route + ": action accessible au joueur " + str(action))
			button.pressed.emit()
			await settle()
			check(panel._pending and panel._modal.visible, "résultat bloquant")
			var snapshot := JSON.stringify(cm.get_ressources())
			button.pressed.emit()
			check(JSON.stringify(cm.get_ressources()) == snapshot, "double clic sans double dépense")
			check(cm.charger_sauvegarde(), "chargement après action")
			check(not cm.campaign.power_routes.pending_feedback.is_empty(), "résultat non acquitté conservé")
			panel._modal.get_continue_button().pressed.emit()
			await settle()
			# L'échec artisanal reste jouable avec les mêmes sources de ressources.
			var retries := 0
			while str(action) == "craft_grounded" and cm.campaign.power_routes.artifacts.is_empty() and retries < 10:
				next_decision()
				check(Campaign.execute(cm.service_context, "materials").accepted, "récupération après échec")
				Campaign.acknowledge(cm.service_context)
				next_decision()
				Campaign.execute(cm.service_context, "craft_grounded")
				Campaign.acknowledge(cm.service_context)
				retries += 1
		check(Objectives.completed(cm.campaign.power_routes), route + " : objectif commun terminé")
		check(not cm.evaluer_etat_partie().terminee, "spécialisation viable dans les règles de fin de tour")
		var objective: Dictionary = cm.campaign.power_routes.objectives[Objectives.GALLERIES]
		check(objective.resolution_method == route, "méthode persistée : " + str(route))
		check(Refuge.has(cm.service_context, "salvage") and cm.campaign.power_routes.next_objective == "rebuild_refuge", "progression narrative débloquée")
		check(cm.campaign.get("run", {}).is_empty() and dungeon.current_run.is_empty(), "pacifiste : aucune expédition ni combat personnel")
		check(not Refuge.has(cm.service_context, "combat"), "aucun accomplissement martial factice")
		cm.sauvegarder()
		check(cm.charger_sauvegarde(), "save/load des résolutions")
		check(cm.campaign.power_routes.objectives[Objectives.GALLERIES].resolution_method == route, "méthode conservée au chargement")
		next_decision()
		var before := JSON.stringify(cm.get_ressources())
		check(not Campaign.execute(cm.service_context, str(paths[route][-1])).accepted and before == JSON.stringify(cm.get_ressources()), "objectif non répétable après chargement")
		Refuge.repair(cm.service_context, "workshop", "pnj_kael")
		check(Refuge.has(cm.service_context, "rebuild"), "atelier accessible par " + str(route))
		Refuge.study_relic(cm.service_context, false)
		check(Refuge.has(cm.service_context, "soul"), "démonstration terminée sans rituel imposé")
		panel.queue_free()
		await settle()
	# Relecture d'un enseignement sans modifier le présent ni les affinités.
	cm.campaign["memories"] = Memories.fresh()
	cm.campaign.memories.finished = true
	cm.sauvegarder()
	var snapshot := JSON.stringify(cm.campaign)
	var resources_before := JSON.stringify(cm.get_ressources())
	save.set_value("opening", {"active": false})
	var replay: Control = load("res://scenes/memory_tutorial.tscn").instantiate()
	root.add_child(replay)
	replay.init_data({"replay": 0})
	replay._actions.get_node("training_attack").pressed.emit()
	check(JSON.stringify(cm.campaign) == snapshot and JSON.stringify(cm.get_ressources()) == resources_before, "relecture sans mutation du monde")
	replay.queue_free()
	await settle()
	# Migration : anciens slots et anciens accomplissements gardent leur progression.
	cm.campaign.erase("power_routes")
	Campaign.ensure(cm.service_context)
	check(Objectives.completed(cm.campaign.power_routes) and cm.campaign.power_routes.objectives[Objectives.GALLERIES].resolution_method == "legacy", "migration sans inventer une méthode")
	if failures.is_empty(): print("MULTIROUTE_CAMPAIGN_OK · PACIFIST_RUN_OK · SAVE_LOAD_ROUTES_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
