extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var cm = root.get_node("ClanManager")
	for action in ["attaquer", "espionner", "diplomatie", "fortifier", "recuperer"]:
		cm.nouvelle_partie("Aren", "Soutien", "hellcaster", {})
		cm.ajouter_pnj_gere("helper", "Aide", "recrute", "stratege", 4, {"force": 14, "commandement": 14, "magie": 14, "diplomatie": 14, "espionnage": 14, "artisanat": 14})
		assert(cm.assigner_pnj_support_journee("helper", action).ok)
		var bonus: int = cm.get_pnj_support_bonus(action)
		assert(bonus > 0 and cm.get_pnj_support_bonus("inconnue") == 0)
		# La vraie vue ajoute ce bonus au score qui sélectionne les effets de l'action.
		var view = load("res://scenes/resolution_action.tscn").instantiate()
		root.add_child(view)
		view._action_id = action
		view._action_cfg = {"stat_principale": "force", "stat_secondaire": ""}
		cm.service_context.rng.seed = 42
		view._calculer_resolution()
		var supported: int = view._score_joueur
		cm.service_context.rng.seed = 42
		view._calculer_resolution()
		assert(supported - view._score_joueur == bonus)
		view.queue_free()
		assert(cm.consume_pnj_support(action) == 0)
		var resources: Dictionary = cm.get_ressources()
		cm.resoudre_planning_pnj_journee()
		assert(cm.get_ressources() == resources) # soutien sans rente en ressources
		cm.sauvegarder()
		assert(cm.charger_sauvegarde() and cm.get_pnj_support_bonus(action) == 0)
		cm.tour_actuel += 1
		assert(cm.get_pnj_support_bonus(action) == 0)
	_test_service_mechanics()
	print("PNJ_FIVE_SUPPORT_MECHANICS_OK")
	quit()

func _test_service_mechanics() -> void:
	var state = preload("res://scripts/data/clan_state.gd").new()
	var ctx = preload("res://scripts/services/clan_service_context.gd").new(state)
	var planner = preload("res://scripts/services/pnj_daily_planner_service.gd").new(ctx)
	var population = preload("res://scripts/services/clan_population_service.gd").new(ctx)
	population.ajouter_pnj_gere("helper", "Aide", "recrute", "mage", 4, {"force": 14, "commandement": 14, "magie": 14, "diplomatie": 14, "espionnage": 14, "artisanat": 14})
	planner.store_resolved_support({"attaquer": 6, "espionner": 6, "diplomatie": 6, "recuperer": 6})
	var party := [{"id": "hero", "nom": "Aren", "stats": {"force": 9}}]
	var battle: Dictionary = ctx.tactical.create(planner.supported_combat_party(party), ["garde"])
	var hero: Dictionary
	for unit in battle.units:
		if unit.id == "hero": hero = unit
	assert(hero.force == 15 and party[0].stats.force == 9)
	var campaign = preload("res://scripts/services/power_campaign_service.gd")
	var loops = preload("res://scripts/services/power_loop_service.gd")
	var espionage_stats: Dictionary = campaign.action_stats(ctx, "observe")
	assert(espionage_stats.espionnage == state.stats.espionnage + 6)
	state.stats.diplomatie = 12
	var diplomacy_stats: Dictionary = campaign.action_stats(ctx, "bargain")
	var route_state: Dictionary = loops.initial_state()
	assert(loops.cost_for(loops.definitions().bargain, route_state, diplomacy_stats).or < loops.cost_for(loops.definitions().bargain, route_state, state.stats).or)
	state.pnj_gestion.roster[0].etat = "blesse"
	var mana: int = state.ressources.mana
	preload("res://scripts/services/refuge_service.gd").recover(ctx, "helper")
	assert(state.pnj_gestion.roster[0].etat == "disponible" and state.ressources.mana == mana)
	assert(planner.support_bonus("recuperer") == 0)
