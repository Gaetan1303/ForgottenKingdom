## Snapshot Phase 2 minimal. Il transporte les nouveaux sous-états sans devenir
## une seconde source de vérité pendant le shadow mode.
class_name WorldState
extends Resource

@export var legacy_state: Dictionary = {}
@export var corruption_data: Dictionary = {}
@export var creature_roster: Dictionary = {}
@export var pact_data: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"legacy_state": legacy_state.duplicate(true),
		"corruption_data": corruption_data.duplicate(true),
		"creature_roster": creature_roster.duplicate(true),
		"pact_data": pact_data.duplicate(true),
	}
