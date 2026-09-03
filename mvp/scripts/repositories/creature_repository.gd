class_name CreatureRepository
extends RefCounted

## Repository en mémoire, indépendant de l'UI et du système de sauvegarde.
## ClanManager reste temporairement la façade de compatibilité et sérialise
## le repository dans pnj_gestion["roster"].
var _items: Dictionary = {}
var _order: Array[String] = []


func load_from_array(roster: Array) -> void:
	_items.clear()
	_order.clear()
	for raw in roster:
		if not (raw is Dictionary):
			continue
		var profile := CreatureProfile.from_dict(raw as Dictionary)
		if profile.id.is_empty():
			continue
		upsert(profile)


func to_array() -> Array:
	var result: Array = []
	for creature_id in _order:
		var profile := get_by_id(creature_id)
		if profile != null:
			result.append(profile.to_dict())
	return result


func upsert(profile: CreatureProfile) -> CreatureProfile:
	if profile == null:
		return null
	profile.sanitize()
	if profile.id.is_empty():
		return null
	if not _items.has(profile.id):
		_order.append(profile.id)
	_items[profile.id] = profile
	return profile


func get_by_id(creature_id: String) -> CreatureProfile:
	return _items.get(creature_id) as CreatureProfile


func has(creature_id: String) -> bool:
	return _items.has(creature_id)


func remove(creature_id: String) -> bool:
	if not _items.has(creature_id):
		return false
	_items.erase(creature_id)
	_order.erase(creature_id)
	return true


func all() -> Array[CreatureProfile]:
	var result: Array[CreatureProfile] = []
	for creature_id in _order:
		var profile := get_by_id(creature_id)
		if profile != null:
			result.append(profile)
	return result


func size() -> int:
	return _items.size()
