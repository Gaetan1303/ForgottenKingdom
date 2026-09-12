extends SceneTree
const StateType = preload("res://scripts/data/clan_state.gd")
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Victory = preload("res://scripts/services/victory_service.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state := StateType.new()
	state.ressources = {"soldats": 0, "or": 0}
	var service := Victory.new(ContextType.new(state))
	assert(service.evaluate().etat == "defaite")
	state.campaign = {"version": 3}
	assert(not service.evaluate().terminee)
	state.maisons_nobles = [{"statut": "alliee"}]
	state.campaign = {}
	assert(not service.evaluate().terminee)
	state.barre_ame = 0
	assert(service.evaluate().etat == "defaite")
	state.barre_ame = 100
	state.maisons_nobles = []
	for i in range(9): state.maisons_nobles.append({"id": i, "statut": "soumise"})
	assert(service.evaluate().etat == "victoire")
	var cm = root.get_node("ClanManager")
	cm.maisons_nobles = state.maisons_nobles
	assert(cm.evaluer_etat_partie() == service.evaluate())
	print("VICTORY_SERVICE_OK")
	quit()
