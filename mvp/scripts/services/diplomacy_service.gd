class_name DiplomacyService
extends "res://scripts/services/clan_action_service.gd"


func modify_relation(maison_id: int, nouvelle_relation: String) -> void:
	for i in range(context.state.maisons_nobles.size()):
		if int(context.state.maisons_nobles[i].get("id", -1)) == maison_id:
			var relation := nouvelle_relation
			var statut_courant := str(context.state.maisons_nobles[i].get("statut", "inconnue"))

			if relation == "neutre_positive":
				relation = "neutre"

			context.state.maisons_nobles[i]["relation"] = relation

			# Le hub utilise la clé "statut" pour filtrer les actions et colorer l'UI.
			# On la synchronise avec la relation, sauf si la maison est déjà soumise.
			if statut_courant != "soumise":
				if relation in ["alliee", "hostile", "neutre", "revelee", "inconnue"]:
					context.state.maisons_nobles[i]["statut"] = relation
				else:
					context.state.maisons_nobles[i]["statut"] = "neutre"
			return

func has_active_alliance() -> bool:
	for maison in context.state.maisons_nobles:
		var relation := str(maison.get("relation", ""))
		var statut := str(maison.get("statut", ""))
		if relation == "alliee" or statut == "alliee":
			return true
	return false

func can_execute(action: Dictionary) -> bool:
	for house in context.state.maisons_nobles:
		if int(house.get("id", -1)) == int(action.get("maison_id", -1)):
			return true
	return false

## Applique une négociation déjà évaluée par les tables de résultats historiques.
## Les coûts et jets génériques appartiennent au résolveur d'actions.
func execute(action: Dictionary) -> Dictionary:
	if not can_execute(action): return {"ok": false, "error": "maison_introuvable"}
	var outcome := str(action.get("resultat_id", ""))
	if outcome in ["victoire_eclatante", "victoire", "succes_critique", "succes"]:
		modify_relation(int(action.maison_id), str(action.get("effets", {}).get("relation", "alliee")))
		return {"ok": true}
	if outcome == "echec_detecte": modify_relation(int(action.maison_id), "hostile")
	return {"ok": false, "error": "negociation_refusee"}
