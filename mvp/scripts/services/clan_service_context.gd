## Dépendances injectées, sans référence à la façade ou à une scène.
class_name ClanServiceContext
extends RefCounted

const ClanStateType = preload("res://scripts/data/clan_state.gd")
var state: ClanStateType
var rng: RandomNumberGenerator
var data_loader: Object
var economy = preload("res://scripts/services/clan_economy_service.gd").new()
var soldiers = preload("res://scripts/services/soldier_assignment_service.gd").new()
signal resources_changed
signal recruitment_requested(role: String)


func _init(p_state: ClanStateType, p_rng: RandomNumberGenerator = null) -> void:
	state = p_state
	rng = p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
