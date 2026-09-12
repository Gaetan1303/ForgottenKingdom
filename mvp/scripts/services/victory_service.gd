class_name VictoryService
extends RefCounted
const ContextType = preload("res://scripts/services/clan_service_context.gd")
var context: ContextType
func _init(p_context: ContextType) -> void:
	context = p_context


func evaluate() -> Dictionary:
	if context.state.barre_ame <= 0:
		return {
			"terminee": true,
			"etat": "defaite",
			"message": "Barre d’âme épuisée. L’héritier est consumé par l’Éther de Cendre.",
		}

	if preload("res://scripts/services/narrative_objective_service.gd").ending_ready(context.state.campaign.get("power_routes", {})):
		return {"terminee": true, "etat": "victoire", "message": str(context.state.campaign.power_routes.get("epilogue", "Les objectifs de votre Maison sont accomplis."))}
	if preload("res://scripts/services/conquest_service.gd").new(context).submitted_count() >= 9:
		return {
			"terminee": true,
			"etat": "victoire",
			"message": "Les Neuf Maisons sont soumises. Victoire totale.",
		}

	var soldats := int(context.state.ressources.get("soldats", 0))
	var or_total := int(context.state.ressources.get("or", 0))
	# Une Maison spécialisée peut vivre sans armée : la production du refuge
	# permet de reconstruire ses réserves. Conserver l'ancienne règle hors v3.
	if int(context.state.campaign.get("version", 0)) < 3 and soldats <= 0 and or_total < 50 and not preload("res://scripts/services/diplomacy_service.gd").new(context).has_active_alliance():
		return {
			"terminee": true,
			"etat": "defaite",
			"message": "Votre clan s'effondre: plus de soldats, presque plus d'or et aucune alliance active.",
		}

	return {
		"terminee": false,
		"etat": "en_cours",
		"message": "",
	}
