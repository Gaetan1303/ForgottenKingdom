extends SceneTree
const Persistence = preload("res://scripts/services/json_persistence_service.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var cm = root.get_node("ClanManager")
	# Ancien JSON sans ClanState, support, campagne, ni pool explicite.
	var legacy := {"nom_clan": "Maison ancienne", "nom_personnage": "Aren", "classe": "hellcaster",
		"stats": {"force": 10}, "ressources": {"or": 60, "soldats": 3}, "tour_actuel": 4,
		"moment_journee": "nuit", "maisons_nobles": [{"id": 1, "relation": "alliee", "statut": "alliee"}],
		"pnj_gestion": {"roster": [], "planning": {"missions_pnj": [], "missions_soldats": [{"action_id": "collecter_bois", "effectif": 2}]}}}
	assert(Persistence.write_json_atomic(cm._get_clan_save_path(), legacy))
	assert(cm.charger_sauvegarde())
	assert(cm.nom_clan == "Maison ancienne" and cm.daily_phase == "soir" and cm.tour_actuel == 4)
	assert(cm.clan_id != "" and cm._a_alliance_active())
	assert(cm._soldats_disponibles.size() == 3)
	assert(cm.pnj_gestion.planning.missions_soldats[0].assigned.size() == 2)
	cm.sauvegarder()
	var saved := Persistence.read_json_with_backup(cm._get_clan_save_path())
	assert(saved.has("ressources") and not saved.has("state"))
	assert(saved.has("soldats_disponibles") and saved.has("pact_state") and saved.has("corruption_state"))
	assert(cm.charger_sauvegarde())
	cm.sauvegarder()
	assert(Persistence.read_json_with_backup(cm._get_clan_save_path()) == saved)
	assert(cm.annuler_mission_soldats(0).ok and cm.get_ressource("soldats") == 5)
	# Les anciens IDs explicites restent stables après chargement.
	cm.sauvegarder()
	var ids: Array = cm._soldats_disponibles.duplicate()
	assert(cm.charger_sauvegarde() and cm._soldats_disponibles == ids)
	print("CLAN_LEGACY_SAVE_OK")
	quit()
