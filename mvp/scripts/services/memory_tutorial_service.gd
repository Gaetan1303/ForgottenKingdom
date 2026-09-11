## Séquences pilotées par les résultats réels des actions, avec acquittement explicite.
## Le bac d'exercice est le seul propriétaire de ses réserves fictives.
extends RefCounted

const Loops = preload("res://scripts/services/power_loop_service.gd")
const Combat = preload("res://scripts/services/tactical_combat_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Result = preload("res://scripts/domain/loop_action_result.gd")

static func sequences() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorials/memories.json")) as Array

static func fresh() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return {"version": 1, "sequence": 0, "step": 0, "completed": [], "skipped": [], "affinities": {},
		"feedback": "", "awaiting_ack": false, "finished": false, "rng_state": str(rng.state),
		"simulation": {"resources": {"or": 80, "mana": 40, "nourriture": 30, "bois": 16, "fer": 12, "pierre": 8, "essence": 2, "soldats": 6, "renseignements": 0, "reputation": 0},
		"stats": {"force": 10, "magie": 10, "espionnage": 10, "artisanat": 10, "ESP": 4, "TRA": 4, "ESE": 4},
		"corruption": 0.0, "phase": "jour", "loops": Loops.initial_state(), "battle": training_battle()}, "events": []}

static func training_battle() -> Dictionary:
	var battle := Combat.create([{"id": "child", "nom": "Vous, enfant", "stats": {"force": 10, "magie": 10, "commandement": 10, "espionnage": 12}}], ["Garde d’entraînement"])
	for unit in battle.units:
		if unit.team == "enemy":
			unit.x = 1
			unit.hp = 50
			unit.max_hp = 50
	return battle

static func current(memory: Dictionary) -> Dictionary:
	if bool(memory.get("finished", false)): return {}
	var all := sequences()
	var index := int(memory.get("sequence", 0))
	if index < 0 or index >= all.size(): return {}
	return all[index].steps[int(memory.get("step", 0))]

static func act(memory: Dictionary, action_id: String) -> Result:
	var result := Result.new()
	var step := current(memory)
	if step.is_empty() or bool(memory.get("awaiting_ack", false)):
		result.message = "Lisez la conséquence avant de poursuivre."
		return result
	var allowed: Array = step.actions.duplicate()
	# Un échec de fabrication n'enferme pas le joueur dans une recette sans composants.
	if str(step.required_event) == "artifact_created": allowed.append("materials")
	if action_id not in allowed:
		result.message = "Cette action ne correspond pas à la consigne."
		return result
	var sim: Dictionary = memory.simulation
	var sequence: Dictionary = sequences()[int(memory.sequence)]
	if action_id.begins_with("training_"):
		result = _training_action(sim, action_id)
		result.route = str(sequence.id)
	else:
		var rng := RandomNumberGenerator.new()
		rng.state = int(str(memory.rng_state))
		result = Loops.evaluate(action_id, sim.loops, sim.resources, sim.stats, rng.randi_range(0, 99))
		if result.accepted:
			memory.rng_state = str(rng.state)
			sim.loops = result.next_state
	if not result.accepted: return result
	for key in result.cost: sim.resources[key] = int(sim.resources.get(key, 0)) - int(result.cost[key])
	for key in result.gains: sim.resources[key] = int(sim.resources.get(key, 0)) + int(result.gains[key])
	sim.corruption = float(sim.corruption) + result.corruption
	memory.feedback = result.message
	memory.events.append({"sequence": sequence.id, "step": step.id, "action": action_id, "event": result.event})
	if result.succeeded and result.event == str(step.required_event):
		memory.awaiting_ack = true
		var affinity := str(sequence.id) + "_affinity"
		memory.affinities[affinity] = int(memory.affinities.get(affinity, 0)) + 1
	return result

static func _training_action(sim: Dictionary, action_id: String) -> Result:
	var result := Result.new()
	if action_id == "training_night":
		sim.phase = "soir"
		result.event = "phase_changed"
		result.message = "Le soir tombe. Les soldats se reposent ; les préparatifs du lendemain commencent."
	else:
		var battle: Dictionary = training_battle() if action_id == "training_cast" else sim.battle.duplicate(true)
		var kind := "attack" if action_id == "training_attack" else ("defend" if action_id == "training_defend" else "ability")
		var before: int = Combat.active(battle).hp
		var applied := Combat.command(battle, kind, 1, 0, int(sim.resources.mana))
		if not bool(applied.get("ok", false)):
			result.message = str(applied.get("message", "Action refusée."))
			return result
		sim.battle = battle
		result.cost = {"mana": int(applied.get("cost", 0))}
		Combat.command(sim.battle, "end", 0, 0, int(sim.resources.mana))
		result.event = {"attack": "attack_executed", "defend": "defense_executed", "ability": "spell_executed"}[kind]
		result.message = "La cible a %d PV. Vous avez %d PV (−%d). %s" % [int(Combat.unit_at(sim.battle, 1, 0).get("hp", 0)), int(Combat.active(sim.battle).hp), before - int(Combat.active(sim.battle).hp), "Votre garde a amorti la riposte." if kind == "defend" else "L’action et sa riposte apparaissent sur le terrain."]
	result.accepted = true
	result.succeeded = true
	return result

static func acknowledge(memory: Dictionary) -> bool:
	if not bool(memory.get("awaiting_ack", false)): return false
	memory.awaiting_ack = false
	memory.feedback = ""
	memory.step = int(memory.step) + 1
	var sequence: Dictionary = sequences()[int(memory.sequence)]
	if int(memory.step) >= sequence.steps.size():
		memory.completed.append(str(sequence.id))
		_next_sequence(memory)
	return true

static func skip(memory: Dictionary) -> void:
	if bool(memory.get("finished", false)): return
	var id: String = str(sequences()[int(memory.sequence)].id)
	if id not in memory.skipped: memory.skipped.append(id)
	_next_sequence(memory)

static func _next_sequence(memory: Dictionary) -> void:
	memory.sequence = int(memory.sequence) + 1
	memory.step = 0
	memory.awaiting_ack = false
	memory.feedback = ""
	memory.finished = int(memory.sequence) >= sequences().size()
	# Chaque leçon résout un exercice distinct, en conservant les renseignements appris.
	memory.simulation.loops.objectives = {}
	Objectives.ensure(memory.simulation.loops)

static func affinity_text(memory: Dictionary) -> String:
	var names: PackedStringArray = []
	var affinities: Dictionary = memory.get("affinities", {})
	for route in Loops.ROUTE_LABELS:
		if int(affinities.get(str(route) + "_affinity", 0)) > 0: names.append(str(Loops.ROUTE_LABELS[route]))
	return "Souvenirs pratiqués : " + ", ".join(names) + ". Toutes les classes et approches restent libres." if not names.is_empty() else "Vos souvenirs ne définissent pas votre avenir. Toutes les approches restent libres."
