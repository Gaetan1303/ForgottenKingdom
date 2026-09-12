extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var cm = root.get_node("ClanManager")
	cm.nouvelle_partie("Aren", "Test", "hellcaster", {})
	cm.payer({"soldats": 999})
	cm.gagner({"soldats": 200})
	var pool: Array = cm._soldats_disponibles.duplicate()
	assert(cm.planifier_mission_soldats("collecter_bois", 100).ok)
	assert(cm.planifier_mission_soldats("collecter_fer", 100).ok) # pas de double décompte
	assert(cm.get_ressource("soldats") == 0)
	assert(not cm.planifier_mission_soldats("collecter_bois", 1).ok)
	assert(cm.adjust_mission_soldier_count(0, 5).warning == "insufficient")
	assert(cm.unassign_soldier_from_mission(0, str(pool[0])).ok)
	assert(cm.get_ressource("soldats") == 1)
	assert(cm.adjust_mission_soldier_count(0, 1).assigned == 1)
	cm.sauvegarder()
	assert(cm.charger_sauvegarde())
	var result: Dictionary = cm.resoudre_planning_pnj_journee()
	assert(result.soldier_losses == 2)
	assert(cm.get_ressource("soldats") == 198) # seuls deux assignés perdus
	assert(cm.pnj_gestion.planning.missions_soldats.is_empty())
	cm.resoudre_planning_pnj_journee()
	assert(cm.get_ressource("soldats") == 198)
	assert(cm.planifier_mission_soldats("collecter_bois", 4).ok)
	assert(cm.adjust_mission_soldier_count(0, -999).removed == 4)
	assert(cm.get_ressource("soldats") == 198)
	assert(cm.planifier_mission_soldats("collecter_bois", 4).ok)
	assert(cm.annuler_mission_soldats(0).ok and cm.get_ressource("soldats") == 198)
	# Ancien format effectif seul : matérialisation unique, IDs jamais réutilisés.
	cm.pnj_gestion.planning.missions_soldats = [{"action_id": "collecter_bois", "effectif": 3}]
	assert(cm.annuler_mission_soldats(0).ok)
	assert(cm.get_ressource("soldats") == 201)
	var seen := {}
	for id in cm._soldats_disponibles:
		assert(not seen.has(id))
		seen[id] = true
	print("SOLDIER_FACADE_OK")
	quit()
