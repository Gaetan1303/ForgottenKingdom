extends SceneTree
const StateType = preload("res://scripts/data/clan_state.gd")
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Espionage = preload("res://scripts/services/espionage_service.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state := StateType.new()
	state.maisons_nobles = [{"id": 1, "statut": "inconnue"}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var service := Espionage.new(ContextType.new(state, rng))
	assert(not service.execute({"maison_id": 1, "resultat_id": "echec_detecte"}).ok)
	assert(not state.maisons_nobles[0].has("revelee"))
	assert(service.execute({"maison_id": 1, "resultat_id": "succes_critique"}).ok)
	assert(state.maisons_nobles[0].ressources_revelees and state.maisons_nobles[0].statut == "revelee")
	var rolls := []
	for i in range(100): rolls.append(service.mission_succeeds())
	assert(true in rolls and false in rolls)
	rng.seed = 42
	for expected in rolls: assert(expected == service.mission_succeeds())
	var cm = root.get_node("ClanManager")
	cm.maisons_nobles = [{"id": 1, "statut": "inconnue"}]
	cm.espionner_maison(1, true)
	assert(cm.maisons_nobles == state.maisons_nobles)
	print("ESPIONAGE_SERVICE_OK")
	quit()
