## Roster stateful des créatures capturées, avec API stateless legacy conservée.
class_name CreatureRosterService
extends RefCounted

const CreatureProfileClass = preload("res://scripts/data/creature_profile.gd")

signal creature_captured(creature_id: String, profile: Resource)
signal creature_released(creature_id: String)
signal creature_loyalty_changed(creature_id: String, new_loyalty: float)
signal creature_corrupted(creature_id: String, corruption_level: float)

var _captured: Dictionary = {}
var _available: Array = []


func capture_creature(creature_profile: Resource) -> bool:
	if creature_profile == null or not creature_profile.is_valid() or _captured.has(creature_profile.id):
		return false
	_captured[creature_profile.id] = _entry(creature_profile)
	_available = _available.filter(func(entry): return str(entry.get("id", "")) != creature_profile.id)
	creature_captured.emit(creature_profile.id, creature_profile)
	return true


func release_creature(creature_id: String) -> bool:
	var key := creature_id.strip_edges()
	if not _captured.erase(key):
		return false
	creature_released.emit(key)
	return true


func add_available_creature(creature_profile: Resource) -> bool:
	if creature_profile == null or not creature_profile.is_valid() or _captured.has(creature_profile.id):
		return false
	var data: Dictionary = creature_profile.to_dict()
	for index in range(_available.size()):
		if str((_available[index] as Dictionary).get("id", "")) == creature_profile.id:
			_available[index] = data
			return true
	_available.append(data)
	return true


func get_captured_list() -> Array:
	var result: Array = []
	for creature_id in _captured:
		result.append((_captured[creature_id] as Dictionary).duplicate(true))
	return result


func get_available_for_assignment() -> Array:
	var result: Array = []
	for creature_id in _captured:
		var entry := _captured[creature_id] as Dictionary
		if (entry.get("assignment", {}) as Dictionary).is_empty():
			result.append(entry.duplicate(true))
	return result


func get_profile_by_id(creature_id: String) -> Resource:
	var entry := _captured.get(creature_id.strip_edges(), {}) as Dictionary
	if entry.is_empty():
		for raw in _available:
			if str((raw as Dictionary).get("id", "")) == creature_id.strip_edges():
				return CreatureProfileClass.from_dict(raw as Dictionary)
		return null
	return CreatureProfileClass.from_dict(entry.get("profile", {}) as Dictionary)


func modify_loyalty(creature_id: String, delta: float) -> void:
	var key := creature_id.strip_edges()
	if not _captured.has(key):
		return
	var entry := (_captured[key] as Dictionary).duplicate(true)
	entry["loyalty"] = clampf(float(entry.get("loyalty", 50.0)) + delta, -100.0, 100.0)
	var profile := (entry.get("profile", {}) as Dictionary).duplicate(true)
	profile["loyaute"] = entry["loyalty"]
	entry["profile"] = profile
	_captured[key] = entry
	creature_loyalty_changed.emit(key, float(entry["loyalty"]))


func modify_corruption(creature_id: String, delta: float) -> void:
	var key := creature_id.strip_edges()
	if not _captured.has(key):
		return
	var entry := (_captured[key] as Dictionary).duplicate(true)
	entry["corruption"] = clampf(float(entry.get("corruption", 0.0)) + delta, 0.0, 100.0)
	var profile := (entry.get("profile", {}) as Dictionary).duplicate(true)
	profile["corruption"] = entry["corruption"]
	entry["profile"] = profile
	_captured[key] = entry
	creature_corrupted.emit(key, float(entry["corruption"]))


func set_assignment(creature_id: String, assignment: Dictionary) -> bool:
	var key := creature_id.strip_edges()
	if not _captured.has(key):
		return false
	var entry := (_captured[key] as Dictionary).duplicate(true)
	entry["assignment"] = assignment.duplicate(true)
	_captured[key] = entry
	return true


func get_creature_status(creature_id: String) -> Dictionary:
	return (_captured.get(creature_id.strip_edges(), {}) as Dictionary).duplicate(true)


func export_state() -> Dictionary:
	return {"captured": _captured.duplicate(true), "available": _available.duplicate(true)}


func import_state(state: Dictionary) -> void:
	_captured.clear()
	_available.clear()
	var captured := state.get("captured", {}) as Dictionary
	for raw_id in captured:
		var key := str(raw_id).strip_edges()
		var raw := captured.get(raw_id, {}) as Dictionary
		var profile_data := raw.get("profile", raw) as Dictionary
		var profile: Resource = CreatureProfileClass.from_dict(profile_data)
		if key.is_empty() or not profile.is_valid():
			continue
		var entry := _entry(profile)
		entry["loyalty"] = clampf(float(raw.get("loyalty", profile.loyalty)), -100.0, 100.0)
		entry["corruption"] = clampf(float(raw.get("corruption", profile.corruption)), 0.0, 100.0)
		entry["assignment"] = (raw.get("assignment", {}) as Dictionary).duplicate(true)
		_captured[key] = entry
	for raw in state.get("available", []) as Array:
		if raw is Dictionary:
			var profile: Resource = CreatureProfileClass.from_dict(raw as Dictionary)
			if profile.is_valid() and not _captured.has(profile.id):
				add_available_creature(profile)


## API historique opérant sur un Array, maintenue pour les écrans existants.
func add(roster: Array, profile: Resource) -> Dictionary:
	if profile == null or not bool(profile.call("is_valid")):
		return _error(roster, "profil_creature_invalide")
	if find_index(roster, str(profile.get("id"))) >= 0:
		return _error(roster, "creature_deja_presente")
	var next_roster := roster.duplicate(true)
	next_roster.append(profile.call("to_dict"))
	return {"ok": true, "roster": next_roster, "creature": profile.call("to_dict")}


func upsert(roster: Array, profile: Resource) -> Dictionary:
	if profile == null or not bool(profile.call("is_valid")):
		return _error(roster, "profil_creature_invalide")
	var next_roster := roster.duplicate(true)
	var index := find_index(next_roster, str(profile.get("id")))
	if index >= 0: next_roster[index] = profile.call("to_dict")
	else: next_roster.append(profile.call("to_dict"))
	return {"ok": true, "roster": next_roster, "creature": profile.call("to_dict")}


func remove(roster: Array, creature_id: String) -> Dictionary:
	var index := find_index(roster, creature_id)
	if index < 0: return _error(roster, "creature_introuvable")
	var next_roster := roster.duplicate(true)
	var removed := (next_roster[index] as Dictionary).duplicate(true)
	next_roster.remove_at(index)
	return {"ok": true, "roster": next_roster, "creature": removed}


func set_state(roster: Array, creature_id: String, next_state: String) -> Dictionary:
	var index := find_index(roster, creature_id)
	if index < 0: return _error(roster, "creature_introuvable")
	var profile: Resource = CreatureProfileClass.from_dict(roster[index] as Dictionary)
	if not profile.set_state(next_state): return _error(roster, "etat_creature_invalide")
	var next_roster := roster.duplicate(true)
	next_roster[index] = profile.to_dict()
	return {"ok": true, "roster": next_roster, "creature": profile.to_dict()}


func get_profile(roster: Array, creature_id: String) -> Resource:
	var index := find_index(roster, creature_id)
	return null if index < 0 else CreatureProfileClass.from_dict(roster[index] as Dictionary)


func get_available(roster: Array) -> Array:
	var result: Array = []
	for entry in roster:
		var profile: Resource = CreatureProfileClass.from_dict(entry as Dictionary)
		if profile.is_available(): result.append(profile.to_dict())
	return result


func sanitize(roster: Array) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for entry in roster:
		if not (entry is Dictionary): continue
		var profile: Resource = CreatureProfileClass.from_dict(entry as Dictionary)
		if not profile.is_valid() or seen.has(profile.id): continue
		seen[profile.id] = true
		result.append(profile.to_dict())
	return result


func find_index(roster: Array, creature_id: String) -> int:
	for index in range(roster.size()):
		if roster[index] is Dictionary and str((roster[index] as Dictionary).get("id", "")) == creature_id.strip_edges(): return index
	return -1


func add_creature(roster: Array, profile: Resource) -> Dictionary: return add(roster, profile)
func upsert_creature(roster: Array, profile: Resource) -> Dictionary: return upsert(roster, profile)
func remove_creature(roster: Array, creature_id: String) -> Dictionary: return remove(roster, creature_id)
func update_state(roster: Array, creature_id: String, next_state: String) -> Dictionary: return set_state(roster, creature_id, next_state)


static func _entry(profile: Resource) -> Dictionary:
	return {"profile": profile.to_dict(), "loyalty": profile.loyalty, "corruption": profile.corruption, "assignment": {}}


static func _error(roster: Array, code: String) -> Dictionary:
	return {"ok": false, "error": code, "roster": roster.duplicate(true)}

## Frontière de recrutement commune aux rencontres, alliances et pactes.
func acquire_creature(profile: Resource, route: String) -> Dictionary:
	if route not in ["combat", "diplomatie", "occultisme", "liberation", "pacte", "alliance"]:
		return {"ok": false, "error": "voie_inconnue"}
	if profile == null or not profile.is_valid(): return {"ok": false, "error": "profil_creature_invalide"}
	var recruited: Resource = CreatureProfileClass.from_dict(profile.to_dict())
	recruited.metadata["acquisition_route"] = route
	if not capture_creature(recruited): return {"ok": false, "error": "creature_deja_presente"}
	return {"ok": true, "creature_id": recruited.id, "route": route}
