## Valeur persistable : la méthode et son prix restent consultables après résolution.
extends RefCounted

var method: String = ""
var consequences: String = ""
var reputation: int = 0
var relations: Dictionary = {}
var cost: Dictionary = {}
var future_events: Array = []

func to_dict() -> Dictionary:
	return {"method": method, "consequences": consequences, "reputation": reputation,
		"relations": relations.duplicate(true), "cost": cost.duplicate(true),
		"future_events": future_events.duplicate(true)}
