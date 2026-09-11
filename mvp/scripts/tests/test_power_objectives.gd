extends SceneTree
const Loops = preload("res://scripts/services/power_loop_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Resolution = preload("res://scripts/domain/objective_resolution.gd")
var failures: Array[String] = []
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var paths := {"espionage": ["observe", "sabotage"], "diplomacy": ["audience", "bargain"], "occult": ["ward", "bind"], "craft": ["craft_grounded", "deploy_artifact"], "command": ["recruit_squad", "formation_guard", "command_assault"]}
	for route in paths:
		var state := Loops.initial_state()
		var resources := {"or": 40, "mana": 24, "bois": 8, "fer": 2, "pierre": 8, "nourriture": 12, "soldats": 0, "renseignements": 0, "reputation": 0}
		var snapshot := JSON.stringify(state)
		check(not Loops.evaluate("invented", state, resources, {}, 50).accepted and JSON.stringify(state) == snapshot, "action inconnue sans mutation")
		for action in paths[route]:
			var result := Loops.evaluate(action, state, resources, {}, 50)
			check(result.accepted, route + ": " + result.message)
			if not result.accepted: continue
			state = result.next_state
			for key in result.cost: resources[key] = int(resources.get(key, 0)) - int(result.cost[key])
			for key in result.gains: resources[key] = int(resources.get(key, 0)) + int(result.gains[key])
		check(Objectives.completed(state), route + " termine le même objectif")
		check(state.objectives.secure_galleries.resolution_method == route, "méthode distincte")
		check(state.next_objective == "rebuild_refuge", "suite narrative commune")
		check(not Loops.evaluate(paths[route][-1], state, resources, {}, 50).accepted, "résolution idempotente")
		check(Objectives.completed(JSON.parse_string(JSON.stringify(state))), "round-trip JSON")
	var state := Loops.initial_state()
	var resources := {"bois": 2, "fer": 2, "pierre": 1}
	var failed := Loops.evaluate("craft_grounded", state, resources, {}, 99)
	check(failed.accepted and not failed.succeeded and failed.next_state.artifacts.is_empty(), "échec artisanal réel")
	check(not Loops.evaluate("use_secret", state, {"or": 10, "renseignements": 10}, {}, 50).accepted, "secret inconnu inaccessible")
	# Le même contrat accepte une fin définie par des objectifs, sans boss imposé.
	for method in Objectives.METHODS:
		var finale := {"ending_objectives": ["discover_truth"]}
		check(not Objectives.ending_ready(finale), "objectif final inconnu ne valide pas la fin")
		Objectives.register(finale, {"id": "discover_truth", "description": "Découvrir la vérité", "resolution_methods": Objectives.METHODS.duplicate()})
		var resolution := Resolution.new()
		resolution.method = "invented"
		check(not Objectives.resolve(finale, resolution, "discover_truth"), "méthode non déclarée refusée")
		resolution.method = method
		check(Objectives.resolve(finale, resolution, "discover_truth") and Objectives.ending_ready(finale), "fin abstraite : " + str(method))
		check(not Objectives.resolve(finale, resolution, "discover_truth"), "fin idempotente")
	if failures.is_empty(): print("POWER_OBJECTIVES_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
