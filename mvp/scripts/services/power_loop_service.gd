## Règles partagées. Entrées lues seulement ; le résultat est appliqué par l'appelant.
## Les réserves, la corruption et les relations des Maisons gardent leurs propriétaires.
extends RefCounted

const Result = preload("res://scripts/domain/loop_action_result.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Resolution = preload("res://scripts/domain/objective_resolution.gd")
const ROUTE_LABELS := {"combat": "Combat", "occult": "Arts occultes", "espionage": "Espionnage", "diplomacy": "Diplomatie", "command": "Commandement", "craft": "Artisanat"}

static func definitions() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/power_actions.json")) as Dictionary

static func initial_state() -> Dictionary:
	var state := {"version": 1, "knowledge": [], "preparations": [], "progress": {},
		"artifacts": [], "formation": "", "morale": 0, "fatigue": 0, "exposure": 0,
		"warden_relation": 0, "future_events": [], "investment": {}, "history": []}
	Objectives.ensure(state)
	return state

static func normalize(state: Dictionary) -> void:
	var defaults := initial_state()
	for key in defaults:
		if not state.has(key): state[key] = defaults[key]

static func cost_for(action: Dictionary, state: Dictionary, stats: Dictionary = {}) -> Dictionary:
	var cost: Dictionary = action.get("cost", {}).duplicate(true)
	if bool(action.get("requires_formation", false)):
		cost["soldats"] = 1 if str(state.get("formation", "")) == "guard" else 3
		if "forces" in state.get("knowledge", []): cost.soldats = maxi(0, int(cost.soldats) - 1)
		if not state.get("artifacts", []).is_empty() or int(stats.get("commandement", 8)) >= 14: cost.soldats = maxi(0, int(cost.soldats) - 1)
	if str(action.get("method", "")) == "diplomacy" and cost.has("or"):
		cost.or = maxi(1, int(cost.or) + maxi(0, -int(state.get("warden_relation", 0))) - maxi(0, (int(stats.get("diplomatie", 8)) - 8) / 4))
	return cost

static func risk_for(action: Dictionary, state: Dictionary, stats: Dictionary) -> int:
	var risk := int(action.get("risk", 0))
	if action.has("recipe"):
		risk -= int((int(stats.get("ESP", 0)) + int(stats.get("TRA", 0)) + int(stats.get("ESE", 0)) + int(stats.get("artisanat", 8))) / 4)
		if "passage" in state.get("knowledge", []): risk -= 5
	if str(action.get("route", "")) == "espionage": risk -= maxi(0, int(stats.get("espionnage", 8)) - 8)
	return clampi(risk, 0, 60)

static func reason(action_id: String, state: Dictionary, resources: Dictionary, stats: Dictionary = {}) -> String:
	var all := definitions()
	if not all.has(action_id): return "Action inconnue."
	var action: Dictionary = all[action_id]
	if Objectives.completed(state) and action.has("method"): return "Les galeries sont déjà sécurisées."
	if action_id in ["ward", "pact", "audience"] and str(action.get("preparation", "")) in state.get("preparations", []): return "Ce préparatif est déjà acquis."
	var prerequisite := preparation_reason(action, state)
	if not prerequisite.is_empty(): return prerequisite
	if int(action.get("requires_soldiers", 0)) > int(resources.get("soldats", 0)): return "Il faut six soldats disponibles."
	var cost := cost_for(action, state, stats)
	for key in cost:
		if int(resources.get(key, 0)) < int(cost[key]): return "Réserves insuffisantes : " + resources_text(cost)
	return ""

static func preparation_reason(action: Dictionary, state: Dictionary) -> String:
	for key in action.get("requires", []):
		if key not in state.get("preparations", []): return "Préparez d’abord une audience."
	if action.has("requires_any"):
		var prepared := false
		for key in action.requires_any:
			if key in state.get("preparations", []): prepared = true
		if not prepared: return "Tracez un cercle ou acceptez un pacte bref."
	for key in action.get("requires_knowledge", []):
		if key not in state.get("knowledge", []): return "Ce renseignement reste inconnu."
	if bool(action.get("requires_artifact", false)) and state.get("artifacts", []).is_empty(): return "Fabriquez un automate à l’établi."
	if bool(action.get("requires_formation", false)) and str(state.get("formation", "")).is_empty(): return "Placez d’abord les unités."
	return ""

static func evaluate(action_id: String, state: Dictionary, resources: Dictionary, stats: Dictionary, roll: int) -> Result:
	var result := Result.new()
	result.message = reason(action_id, state, resources, stats)
	if not result.message.is_empty(): return result
	var action: Dictionary = definitions()[action_id]
	result.accepted = true
	result.succeeded = true
	result.route = str(action.route)
	result.event = str(action.event)
	result.message = str(action.feedback)
	result.cost = cost_for(action, state, stats)
	result.gains = action.get("gains", {}).duplicate(true)
	result.corruption = float(action.get("corruption", 0))
	result.next_state = state.duplicate(true)
	var next := result.next_state
	normalize(next)
	var risk := risk_for(action, state, stats)
	var hazard := clampi(roll, 0, 99) < risk
	for key in action.get("knowledge", []):
		if key not in next.knowledge:
			next.knowledge.append(key)
			result.gains["renseignements"] = int(result.gains.get("renseignements", 0)) + 1
	if action.has("preparation") and action.preparation not in next.preparations: next.preparations.append(action.preparation)
	if action.has("formation"):
		next.formation = str(action.formation)
		next.morale = 2 if next.formation == "guard" else 0
	if result.route == "espionage" and hazard:
		next.exposure = int(next.exposure) + 1
		next.warden_relation = int(next.warden_relation) - 2
		result.message += " Votre agent a été aperçu : exposition +1, relation −2. Le renseignement est conservé."
	if action.has("recipe"):
		# Un échec consomme les composants, mais la récupération reste accessible.
		if roll >= 95:
			result.succeeded = false
			result.event = "craft_failed"
			result.message = "Le mécanisme se brise. Les composants sont perdus ; récupérez des matériaux et essayez une méthode différente."
		else:
			var quality := "altered" if hazard else ("exceptional" if roll >= 80 else "normal")
			next.artifacts.append({"id": "automaton_%d" % next.artifacts.size(), "quality": quality, "recipe": action.recipe.duplicate(true)})
			if hazard:
				result.corruption += 2
				result.message += " Une ombre répond dans le métal : automate altéré, +2 corruption. Il reste utilisable."
			elif quality == "exceptional": result.message += " Réussite exceptionnelle : la protection servira aussi aux troupes."
	if result.route == "occult" and action.has("method"):
		if "ward" in next.preparations: result.corruption = maxf(1, result.corruption - 2)
		if "secret" in next.knowledge: result.corruption = maxf(1, result.corruption - 1)
		if hazard:
			result.corruption += 4
			result.message += " Le sceau résonne : +4 corruption supplémentaires."
	if action_id == "command_assault":
		next.fatigue = int(next.fatigue) + 1
		result.message += " Pertes : %d soldat(s). Moral : %d ; fatigue : %d." % [int(result.cost.get("soldats", 0)), int(next.morale), int(next.fatigue)]
	if action.has("method"):
		var resolution := Resolution.new()
		resolution.method = str(action.method)
		resolution.consequences = result.message
		resolution.reputation = int(action.get("reputation", 0))
		resolution.relations = {"gallery_wardens": int(action.get("relation", 0))}
		resolution.cost = next.investment.duplicate(true)
		for key in result.cost: resolution.cost[key] = int(resolution.cost.get(key, 0)) + int(result.cost[key])
		resolution.future_events = [str(action.get("future", ""))]
		Objectives.resolve(next, resolution)
		next.warden_relation = int(next.warden_relation) + int(action.get("relation", 0))
		next.future_events.append_array(resolution.future_events)
		result.gains["reputation"] = resolution.reputation
		result.gains.merge({"bois": 8, "fer": 6, "essence": 1}, true)
		next["tools_found"] = true
	next.progress[result.route] = int(next.progress.get(result.route, 0)) + 1
	for key in result.cost: next.investment[key] = int(next.investment.get(key, 0)) + int(result.cost[key])
	next.history.append({"action": action_id, "event": result.event, "route": result.route, "message": result.message, "cost": result.cost.duplicate(true), "corruption": result.corruption})
	return result

static func resources_text(values: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in values:
		if int(values[key]) != 0: parts.append("%d %s" % [int(values[key]), "Renseignements" if str(key) == "renseignements" else str(key)])
	return ", ".join(parts) if not parts.is_empty() else "aucune réserve"
