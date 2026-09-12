## Dépendances injectées, sans référence à la façade ou à une scène.
class_name ClanServiceContext
extends RefCounted

const ClanStateType = preload("res://scripts/data/clan_state.gd")
var state: ClanStateType
var rng: RandomNumberGenerator
var data_loader: Object

func _init(p_state: ClanStateType, p_rng: RandomNumberGenerator = null) -> void:
	state = p_state
	rng = p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
