## Dépendances injectées, sans référence à la façade ou à une scène.
class_name ClanServiceContext
extends RefCounted

const ClanStateType = preload("res://scripts/data/clan_state.gd")
var state: ClanStateType
var rng: RandomNumberGenerator
var data_loader: Object
var corruption: RefCounted = preload("res://scripts/services/corruption_service.gd").new()
var creatures: RefCounted = preload("res://scripts/services/creature_roster_service.gd").new()
var pacts: RefCounted = preload("res://scripts/services/pact_service.gd").new()
var tactical = preload("res://scripts/services/tactical_combat_service.gd").new()
var economy = preload("res://scripts/services/clan_economy_service.gd").new()
var soldiers = preload("res://scripts/services/soldier_assignment_service.gd").new()
signal save_requested
signal level_changed(level: int)
signal soul_depleted
signal resources_changed
signal recruitment_requested(role: String)


func _init(p_state: ClanStateType, p_rng: RandomNumberGenerator = null) -> void:
	state = p_state
	rng = p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
