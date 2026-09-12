class_name ConquestService
extends "res://scripts/services/clan_action_service.gd"


func get_house(id: int) -> Dictionary:
	for maison in context.state.maisons_nobles:
		if int(maison.get("id", -1)) == id:
			return maison
	return {}

func conquer_bastion(maison_id: int, bastion_id: String) -> void:
	for i in range(context.state.maisons_nobles.size()):
		if int(context.state.maisons_nobles[i].get("id", -1)) == maison_id:
			var bastions: Array = context.state.maisons_nobles[i].get("bastions", [])
			for j in range(bastions.size()):
				if bastions[j].get("id", "") == bastion_id:
					bastions[j]["conquis"] = true
					context.state.maisons_nobles[i]["revelee"] = true
			# Vérifie si toute la maison est soumise
			check_submission(i)
			return

func check_submission(index: int) -> void:
	var bastions: Array = context.state.maisons_nobles[index].get("bastions", [])
	var tous_conquis := bastions.all(func(b): return bool(b.get("conquis", false)))
	if tous_conquis:
		context.state.maisons_nobles[index]["statut"] = "soumise"

func submitted_count() -> int:
	var count := 0
	for m in context.state.maisons_nobles:
		if m.get("statut", "") == "soumise":
			count += 1
	return count

func can_execute(action: Dictionary) -> bool:
	var house := get_house(int(action.get("maison_id", -1)))
	for bastion in house.get("bastions", []):
		if str(bastion.get("id", "")) == str(action.get("bastion_id", "")):
			return not bool(bastion.get("conquis", false))
	return false

## La zone et le combat en cours sont persistés dans la campagne canonique.
func start_battle(action: Dictionary, party: Array, enemies: Array, floor_index: int = 0) -> Dictionary:
	if not can_execute(action): return {"ok": false, "error": "bastion_indisponible"}
	if not context.state.campaign.get("territorial_battle", {}).is_empty():
		return {"ok": false, "error": "combat_deja_en_cours"}
	var supported: Array = preload("res://scripts/services/pnj_daily_planner_service.gd").new(context).supported_combat_party(party)
	var battle: Dictionary = context.tactical.create(supported, enemies, floor_index)
	context.state.campaign["territorial_battle"] = {"maison_id": int(action.maison_id), "bastion_id": str(action.bastion_id), "battle": battle}
	return {"ok": true, "battle": battle.duplicate(true)}

func execute(action: Dictionary) -> Dictionary:
	var engagement: Dictionary = context.state.campaign.get("territorial_battle", {})
	if engagement.is_empty(): return {"ok": false, "error": "combat_absent"}
	var battle: Dictionary = engagement.battle
	var result: Dictionary = context.tactical.command(battle, str(action.get("kind", "end")), int(action.get("x", 0)), int(action.get("y", 0)), int(context.state.ressources.get("mana", 0)))
	if bool(result.get("ok", false)) and int(result.get("cost", 0)) > 0:
		context.economy.pay(context, {"mana": int(result.cost)})
	var outcome := str(battle.get("outcome", ""))
	if outcome == "victory": conquer_bastion(int(engagement.maison_id), str(engagement.bastion_id))
	if not outcome.is_empty(): context.state.campaign.erase("territorial_battle")
	result["outcome"] = outcome
	return result
