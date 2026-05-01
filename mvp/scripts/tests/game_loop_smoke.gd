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
		failures.append("Autoload ClanManager indisponible après attente")
		_finish(failures)
		return

	# 1) Creation + initialisation campagne
	var stats_bonus := {
		"force": 1,
		"magie": 1,
		"espionnage": 0,
		"artisanat": 0,
		"diplomatie": 0,
		"commandement": 1,
	}
	var profil := {
		"genre": "Femme",
		"apparence": "Noble exile",
		"pouvoir_magique": "Invocation Demoniaque",
		"pouvoir_magique_id": "demon_invocation",
		"archetype_pathfinder": "Ensorceleur abyssal (inspiration Magicien)",
		"don": "Tacticien de Champ de Bataille",
		"don_id": "battlefield_tactician",
		"competence": "Rituel occulte",
		"competence_id": "rituel_occulte",
		"equipement_depart": "Catalyseur runique",
		"equipement_depart_id": "catalyseur_runique",
		"magie_pactes": true,
		"traits_gameplay": {
			"mana_cost_reduction_pct": 30,
			"soldats_cost_reduction_attaquer_pct": 10,
			"bonus_score_actions": {"attaquer": 2, "recruter_pnj": 1},
			"night_soul_regen": 3,
			"night_reputation_gain": 1,
		}
	}
	clan_manager.nouvelle_partie("Ingrid", "Clan Test", "mage_du_pacte", stats_bonus, profil)

	if str(clan_manager.nom_clan) != "Clan Test":
		failures.append("nouvelle_partie: nom_clan non initialise")
	if not bool(clan_manager.magie_pactes_active()):
		failures.append("nouvelle_partie: magie des pactes inactive")

	# 2) Coûts modifies par traits
	var cout_recruter: Dictionary = clan_manager.get_action_cout_modifie("recruter", {"mana": 35}) as Dictionary
	if int(cout_recruter.get("mana", -1)) >= 35:
		failures.append("traits: reduction mana non appliquee sur recruter")
	var cout_attaquer: Dictionary = clan_manager.get_action_cout_modifie("attaquer", {"soldats": 10}) as Dictionary
	if int(cout_attaquer.get("soldats", 999)) >= 10:
		failures.append("traits: reduction soldats non appliquee sur attaquer")

	# 3) Bonus de score action
	if int(clan_manager.get_bonus_score_action("attaquer")) <= 0:
		failures.append("traits: bonus score attaquer absent")

	# 4) Passifs de nuit
	clan_manager.barre_ame = 90
	var rep_avant := int((clan_manager.ressources as Dictionary).get("reputation", 0))
	var msg_passifs := str(clan_manager.appliquer_passifs_nuit())
	if int(clan_manager.barre_ame) <= 90:
		failures.append("passifs nuit: ame non regeneree")
	if int((clan_manager.ressources as Dictionary).get("reputation", 0)) <= rep_avant:
		failures.append("passifs nuit: reputation non augmentee")
	if msg_passifs.is_empty():
		failures.append("passifs nuit: message de feedback vide")

	# 5) Conditions de fin
	var etat_cours: Dictionary = clan_manager.evaluer_etat_partie() as Dictionary
	if bool(etat_cours.get("terminee", true)):
		failures.append("etat partie: en cours attendu")

	clan_manager.barre_ame = 0
	var etat_defaite_ame: Dictionary = clan_manager.evaluer_etat_partie() as Dictionary
	if str(etat_defaite_ame.get("etat", "")) != "defaite":
		failures.append("etat partie: defaite ame non detectee")

	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SMOKE_OK: boucle gameplay validee")
		quit(0)
		return

	for f in failures:
		push_error("SMOKE_FAIL: " + f)
	quit(1)
