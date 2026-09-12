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
	print("PNJ_FIVE_SUPPORT_MECHANICS_OK")
	quit()
