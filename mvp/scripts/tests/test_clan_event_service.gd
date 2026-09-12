extends SceneTree
const StateType = preload("res://scripts/data/clan_state.gd")
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Events = preload("res://scripts/services/clan_event_service.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var state := StateType.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var ctx := ContextType.new(state, rng)
	var events := Events.new(ctx)
	state.tour_actuel = 4
	state.moment_journee = "nuit"
	assert(events.evaluate_conditions('tour >= 4 AND moment_journee = "nuit" AND or > 30'))
	assert(not events.evaluate_conditions("inconnue > 0"))
	assert(not events.evaluate_conditions("tour < 4"))
	assert(events.evaluate_conditions("null"))
	var choices := [{"id": "a", "condition": "tour >= 4", "probabilite": 0.5, "effets": {"or_recupere": 2}}, {"id": "b", "probabilite": 1.0}]
	var draws := []
	for i in range(20): draws.append(events.draw_event(choices).id)
	rng.seed = 42
	for expected in draws: assert(events.draw_event(choices).id == expected)
	var before: int = state.ressources.or
	events.apply_event(choices[0])
	assert(state.ressources.or == before + 2 and state.evenements_declenches == ["a"])
	events.apply_event(choices[0])
	assert(state.evenements_declenches == ["a"])
	var cm = root.get_node("ClanManager")
	cm.ressources = state.ressources.duplicate()
	cm._appliquer_effets({"or_recupere": 5, "mana_gain": 2, "production_or_bonus": 3})
	events.apply_effects({"or_recupere": 5, "mana_gain": 2, "production_or_bonus": 3})
	assert(cm.ressources == state.ressources)
	cm.sauvegarder()
	assert(cm.charger_sauvegarde())
	print("CLAN_EVENT_SERVICE_OK")
	quit()
