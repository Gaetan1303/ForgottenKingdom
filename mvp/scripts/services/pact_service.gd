## Cycle de vie des pactes. Les effets sont décrits dans les données du pacte et
## restent sans effet sur le monde tant qu'un orchestrateur ne les applique pas.
class_name PactService
extends RefCounted

const Enums = preload("res://scripts/core/enums.gd")

signal pact_offered(creature_id: String, target_id: String, pact_type: int)
signal pact_accepted(pact_id: String, terms: Dictionary)
signal pact_rejected(creature_id: String, target_id: String, reason: String)
signal pact_broken(pact_id: String, reason: String)
signal pact_fulfilled(pact_id: String, rewards: Dictionary)

var _active_pacts: Dictionary = {}
var _pact_counter: int = 0


func offer_pact(creature_id: String, target_id: String, pact_type: int, terms: Dictionary) -> Dictionary:
	var creature_key := creature_id.strip_edges()
	var target_key := target_id.strip_edges()
	if creature_key.is_empty() or target_key.is_empty():
		return {"ok": false, "error": "invalid_participant"}
	if not Enums.is_valid_pact_type(pact_type) or pact_type == Enums.PactType.NONE:
		return {"ok": false, "error": "invalid_pact_type"}
	_pact_counter += 1
	var pact_id := "pact_%06d" % _pact_counter
	var pact := {
		"pact_id": pact_id, "creature_id": creature_key, "target_id": target_key,
		"pact_type": pact_type, "terms": terms.duplicate(true), "status": "offered",
		"fulfilled_requirements": [],
	}
	_active_pacts[pact_id] = pact
	pact_offered.emit(creature_key, target_key, pact_type)
	return {"ok": true, "pact": pact.duplicate(true)}


func attempt_pact_ritual(creature_id: String, target_id: String) -> Dictionary:
	var candidate: Dictionary = {}
	for pact in _active_pacts.values():
		var data := pact as Dictionary
		if str(data.get("creature_id", "")) == creature_id and str(data.get("target_id", "")) == target_id and str(data.get("status", "")) == "offered":
			candidate = data.duplicate(true)
			break
	if candidate.is_empty():
		pact_rejected.emit(creature_id, target_id, "pact_not_offered")
		return {"ok": false, "error": "pact_not_offered"}
	var pact_id := str(candidate.get("pact_id", ""))
	var required_power := calculate_required_power(creature_id, target_id, int(candidate.get("pact_type", 0)))
	var terms := candidate.get("terms", {}) as Dictionary
	var ritual_power := clampf(float(terms.get("ritual_power", 50.0)), 0.0, 100.0)
	if ritual_power < required_power:
		pact_rejected.emit(creature_id, target_id, "ritual_failed")
		return {"ok": false, "error": "ritual_failed", "required_power": required_power, "chance": required_power}
	candidate["status"] = "active"
	_active_pacts[pact_id] = candidate
	pact_accepted.emit(pact_id, terms.duplicate(true))
	return {"ok": true, "pact": candidate.duplicate(true), "required_power": required_power, "chance": required_power}


func calculate_required_power(_creature_id: String, _target_id: String, pact_type: int) -> float:
	var difficulty := float(maxi(0, pact_type - Enums.PactType.SERVICE)) * 7.5
	return clampf(35.0 + difficulty, 5.0, 95.0)


func fulfill_pact_requirement(pact_id: String, requirement: String) -> void:
	if not _active_pacts.has(pact_id):
		return
	var pact := (_active_pacts[pact_id] as Dictionary).duplicate(true)
	var completed := (pact.get("fulfilled_requirements", []) as Array).duplicate(true)
	if requirement not in completed:
		completed.append(requirement)
	pact["fulfilled_requirements"] = completed
	var terms := pact.get("terms", {}) as Dictionary
	var required := terms.get("requirements", []) as Array
	if required.all(func(item): return item in completed):
		pact["status"] = "fulfilled"
		pact_fulfilled.emit(pact_id, (terms.get("rewards", {}) as Dictionary).duplicate(true))
	_active_pacts[pact_id] = pact


func break_pact(pact_id: String, reason: String) -> bool:
	if not _active_pacts.has(pact_id):
		return false
	var pact := (_active_pacts[pact_id] as Dictionary).duplicate(true)
	pact["status"] = "broken"
	pact["break_reason"] = reason
	_active_pacts[pact_id] = pact
	pact_broken.emit(pact_id, reason)
	return true


func get_active_pacts() -> Array:
	var result: Array = []
	for pact in _active_pacts.values():
		if str((pact as Dictionary).get("status", "")) in ["offered", "active"]:
			result.append((pact as Dictionary).duplicate(true))
	return result


func get_pacts_for_creature(creature_id: String) -> Array:
	return _filter_pacts("creature_id", creature_id)


func get_pacts_for_character(char_id: String) -> Array:
	return _filter_pacts("target_id", char_id)


func export_state() -> Dictionary:
	return {"active_pacts": _active_pacts.duplicate(true), "pact_counter": _pact_counter}


func import_state(state: Dictionary) -> void:
	_active_pacts = (state.get("active_pacts", {}) as Dictionary).duplicate(true)
	_pact_counter = maxi(0, int(state.get("pact_counter", 0)))


func _filter_pacts(field: String, value: String) -> Array:
	var result: Array = []
	for pact in _active_pacts.values():
		if str((pact as Dictionary).get(field, "")) == value.strip_edges():
			result.append((pact as Dictionary).duplicate(true))
	return result

## Alias historique : cette valeur a toujours été un seuil, pas une probabilité.
func calculate_pact_success_chance(creature_id: String, target_id: String, pact_type: int) -> float:
	return calculate_required_power(creature_id, target_id, pact_type)
