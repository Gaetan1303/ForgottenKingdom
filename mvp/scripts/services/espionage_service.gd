class_name EspionageService
extends "res://scripts/services/clan_action_service.gd"


func reveal_information(id: int, succes_critique: bool = false) -> void:
	for i in range(context.state.maisons_nobles.size()):
		if int(context.state.maisons_nobles[i].get("id", -1)) == id:
			context.state.maisons_nobles[i]["revelee"]   = true
			context.state.maisons_nobles[i]["espionnee"] = true
			if str(context.state.maisons_nobles[i].get("statut", "inconnue")) == "inconnue":
				context.state.maisons_nobles[i]["statut"] = "revelee"
			if succes_critique:
				context.state.maisons_nobles[i]["ressources_revelees"] = true

func can_execute(action: Dictionary) -> bool:
	for house in context.state.maisons_nobles:
		if int(house.get("id", -1)) == int(action.get("maison_id", -1)): return true
	return false

func execute(action: Dictionary) -> Dictionary:
	if not can_execute(action): return {"ok": false, "error": "maison_introuvable"}
	var outcome := str(action.get("resultat_id", ""))
	if outcome in ["victoire_eclatante", "succes_critique", "victoire", "succes", "echec_partiel"]:
		reveal_information(int(action.maison_id), outcome in ["victoire_eclatante", "succes_critique"])
		return {"ok": true}
	return {"ok": false, "error": "infiltration_echouee"}

## Contrat historique des missions de renseignement des soldats (70%).
func mission_succeeds() -> bool:
	return context.rng.randf() <= 0.7

func apply_soldier_intelligence(results: Array) -> void:
	for report in results:
		if str(report.get("action_id", "")) != "espionner" or int(report.get("gains", {}).get("renseignements", 0)) <= 0: continue
		for house in context.state.maisons_nobles:
			if not bool(house.get("revelee", false)):
				# Cette voie historique ne change pas le statut de la maison.
				house["revelee"] = true
				house["espionnee"] = true
				break
