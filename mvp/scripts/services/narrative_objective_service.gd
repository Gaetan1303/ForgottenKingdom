extends RefCounted

const Objective = preload("res://scripts/domain/narrative_objective.gd")
const Resolution = preload("res://scripts/domain/objective_resolution.gd")
const METHODS := ["combat", "occult", "espionage", "diplomacy", "command", "craft"]
const GALLERIES := "secure_galleries"

static func ensure(state: Dictionary) -> void:
	register(state, {"id": GALLERIES, "description": "Sécuriser les galeries et retrouver les outils de la Maison.", "resolution_methods": METHODS.duplicate(), "next_objective": "rebuild_refuge"})

static func register(state: Dictionary, definition: Dictionary) -> bool:
	if not state.has("objectives"): state["objectives"] = {}
	var id := str(definition.get("id", ""))
	if id.is_empty() or state.objectives.has(id) or definition.get("resolution_methods", []).is_empty(): return false
	state.objectives[id] = Objective.new(definition).to_dict()
	return true

static func completed(state: Dictionary, id: String = GALLERIES) -> bool:
	return str(state.get("objectives", {}).get(id, {}).get("status", "")) == "completed"

static func resolve(state: Dictionary, result: Resolution, id: String = GALLERIES) -> bool:
	if id == GALLERIES: ensure(state)
	if not state.get("objectives", {}).has(id): return false
	var objective := Objective.new(state.objectives[id])
	if not objective.complete(result): return false
	state.objectives[id] = objective.to_dict()
	state["next_objective"] = objective.next_objective
	state["epilogue"] = result.consequences
	return true

static func ending_ready(state: Dictionary) -> bool:
	# Les campagnes définissent leurs objectifs finaux ; aucune méthode n'est imposée.
	var required: Array = state.get("ending_objectives", [])
	if required.is_empty(): return false
	for id in required:
		if not completed(state, str(id)): return false
	return true
