## Opérations de domaine immuables sur un roster de créatures sérialisées.
class_name CreatureRosterService
extends RefCounted

const CreatureProfileClass = preload("res://scripts/data/creature_profile.gd")


func add(roster: Array, profile: Resource) -> Dictionary:
	if profile == null or not profile.is_valid():
		return _error(roster, "profil_creature_invalide")
	if find_index(roster, profile.creature_id) >= 0:
		return _error(roster, "creature_deja_presente")
	var next_roster := roster.duplicate(true)
	next_roster.append(profile.to_dict())
	return {"ok": true, "roster": next_roster, "creature": profile.to_dict()}


func upsert(roster: Array, profile: Resource) -> Dictionary:
	if profile == null or not profile.is_valid():
		return _error(roster, "profil_creature_invalide")
	var next_roster := roster.duplicate(true)
	var index := find_index(next_roster, profile.creature_id)
	if index >= 0:
		next_roster[index] = profile.to_dict()
	else:
		next_roster.append(profile.to_dict())
	return {"ok": true, "roster": next_roster, "creature": profile.to_dict()}


func remove(roster: Array, creature_id: String) -> Dictionary:
	var index := find_index(roster, creature_id)
	if index < 0:
		return _error(roster, "creature_introuvable")
	var next_roster := roster.duplicate(true)
	var removed := (next_roster[index] as Dictionary).duplicate(true)
	next_roster.remove_at(index)
	return {"ok": true, "roster": next_roster, "creature": removed}


func set_state(roster: Array, creature_id: String, next_state: String) -> Dictionary:
	var index := find_index(roster, creature_id)
	if index < 0:
		return _error(roster, "creature_introuvable")
	var profile := CreatureProfileClass.from_dict(roster[index] as Dictionary)
	if not profile.set_state(next_state):
		return _error(roster, "etat_creature_invalide")
	var next_roster := roster.duplicate(true)
	next_roster[index] = profile.to_dict()
	return {"ok": true, "roster": next_roster, "creature": profile.to_dict()}


func get_profile(roster: Array, creature_id: String) -> Resource:
	var index := find_index(roster, creature_id)
	if index < 0:
		return null
	return CreatureProfileClass.from_dict(roster[index] as Dictionary)


func get_available(roster: Array) -> Array:
	var result: Array = []
	for entry in roster:
		var profile := CreatureProfileClass.from_dict(entry as Dictionary)
		if profile.is_available():
			result.append(profile.to_dict())
	return result


func sanitize(roster: Array) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for entry in roster:
		if not (entry is Dictionary):
			continue
		var profile := CreatureProfileClass.from_dict(entry as Dictionary)
		if not profile.is_valid() or seen.has(profile.creature_id):
			continue
		seen[profile.creature_id] = true
		result.append(profile.to_dict())
	return result


func find_index(roster: Array, creature_id: String) -> int:
	var needle := creature_id.strip_edges()
	for index in range(roster.size()):
		if roster[index] is Dictionary and str((roster[index] as Dictionary).get("id", "")) == needle:
			return index
	return -1


func _error(roster: Array, code: String) -> Dictionary:
	return {"ok": false, "error": code, "roster": roster.duplicate(true)}


## Alias de compatibilité pour un ClanManager déjà migré vers des verbes explicites.
func add_creature(roster: Array, profile: Resource) -> Dictionary:
	return add(roster, profile)


func upsert_creature(roster: Array, profile: Resource) -> Dictionary:
	return upsert(roster, profile)


func remove_creature(roster: Array, creature_id: String) -> Dictionary:
	return remove(roster, creature_id)


func update_state(roster: Array, creature_id: String, next_state: String) -> Dictionary:
	return set_state(roster, creature_id, next_state)
