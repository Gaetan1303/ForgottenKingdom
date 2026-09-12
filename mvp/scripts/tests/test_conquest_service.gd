extends SceneTree
const StateType = preload("res://scripts/data/clan_state.gd")
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Conquest = preload("res://scripts/services/conquest_service.gd")
class CombatProbe extends RefCounted:
	var called := false
	var outcome := "victory"
	func create(_party: Array, _enemies: Array, _floor: int) -> Dictionary: return {"outcome": ""}
	func command(battle: Dictionary, _kind: String, _x: int, _y: int, _mana: int) -> Dictionary:
		called = true
		battle.outcome = outcome
		return {"ok": true, "cost": 3}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state := StateType.new()
	state.maisons_nobles = [{"id": 1, "statut": "hostile", "relation": "hostile", "bastions": [{"id": "a", "conquis": false}]}]
	var context := ContextType.new(state)
	var combat := CombatProbe.new()
	context.tactical = combat
	var service := Conquest.new(context)
	assert(service.start_battle({"maison_id": 1, "bastion_id": "a"}, [], []).ok)
	combat.outcome = "defeat"
	service.execute({})
	assert(not state.maisons_nobles[0].bastions[0].conquis)
	assert(service.start_battle({"maison_id": 1, "bastion_id": "a"}, [], []).ok)
	combat.outcome = "victory"
	assert(service.execute({}).outcome == "victory" and combat.called)
	assert(state.maisons_nobles[0].bastions[0].conquis and service.submitted_count() == 1)
	assert(state.maisons_nobles[0].relation == "hostile") # contrat historique
	var cm = root.get_node("ClanManager")
	cm.maisons_nobles = [{"id": 1, "statut": "hostile", "relation": "hostile", "bastions": [{"id": "a", "conquis": false}]}]
	cm.conquerir_bastion(1, "a")
	assert(cm.maisons_nobles == state.maisons_nobles)
	cm.sauvegarder()
	assert(cm.charger_sauvegarde() and cm.maisons_soumises() == 1)
	print("CONQUEST_SERVICE_OK")
	quit()
