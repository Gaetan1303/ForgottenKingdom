## Logique de domaine des neuf maisons nobles, indépendante du stockage et de l'UI.
class_name ClanHouseService
extends RefCounted

const VALID_RELATIONS := ["hostile", "neutre", "favorable", "alliee", "soumise"]


func get_house(houses: Array, house_id: Variant) -> Dictionary:
	var index := find_house_index(houses, house_id)
	if index < 0:
		return {}
	return (houses[index] as Dictionary).duplicate(true)


func find_house_index(houses: Array, house_id: Variant) -> int:
	var needle := str(house_id)
	for index in range(houses.size()):
		if houses[index] is Dictionary and str((houses[index] as Dictionary).get("id", "")) == needle:
			return index
	return -1


func reveal(houses: Array, house_id: Variant) -> Dictionary:
	return _update_house_flag(houses, house_id, "revelee", true)


func mark_spied(houses: Array, house_id: Variant) -> Dictionary:
	var result := _update_house_flag(houses, house_id, "espionnee", true)
	if not bool(result.get("ok", false)):
		return result
	var next_houses := result.get("houses", []) as Array
	return _update_house_flag(next_houses, house_id, "revelee", true)


func set_relation(houses: Array, house_id: Variant, relation: String) -> Dictionary:
	var normalized := relation.strip_edges().to_lower()
	if not VALID_RELATIONS.has(normalized):
		return _error(houses, "relation_invalide")
	var index := find_house_index(houses, house_id)
	if index < 0:
		return _error(houses, "maison_introuvable")
	var next_houses := houses.duplicate(true)
	var house := (next_houses[index] as Dictionary).duplicate(true)
	house["relation"] = normalized
	next_houses[index] = house
	return {"ok": true, "houses": next_houses, "house": house.duplicate(true)}


func conquer_bastion(houses: Array, house_id: Variant, bastion_id: String) -> Dictionary:
	var index := find_house_index(houses, house_id)
	if index < 0:
		return _error(houses, "maison_introuvable")
	var next_houses := houses.duplicate(true)
	var house := (next_houses[index] as Dictionary).duplicate(true)
	var bastions := (house.get("bastions", []) as Array).duplicate(true)
	var found := false
	for bastion_index in range(bastions.size()):
		if not (bastions[bastion_index] is Dictionary):
			continue
		var bastion := (bastions[bastion_index] as Dictionary).duplicate(true)
		if str(bastion.get("id", "")) != bastion_id:
			continue
		bastion["conquis"] = true
		bastions[bastion_index] = bastion
		found = true
		break
	if not found:
		return _error(houses, "bastion_introuvable")
	house["bastions"] = bastions
	if _all_bastions_conquered(bastions):
		house["statut"] = "soumise"
		house["relation"] = "soumise"
	next_houses[index] = house
	return {"ok": true, "houses": next_houses, "house": house.duplicate(true)}


func conquered_bastion_count(houses: Array, house_id: Variant) -> int:
	var house := get_house(houses, house_id)
	var count := 0
	for entry in house.get("bastions", []) as Array:
		if entry is Dictionary and bool((entry as Dictionary).get("conquis", false)):
			count += 1
	return count


func sanitize(houses: Array) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for entry in houses:
		if not (entry is Dictionary):
			continue
		var house := (entry as Dictionary).duplicate(true)
		var id_key := str(house.get("id", ""))
		if id_key.is_empty() or seen.has(id_key):
			continue
		seen[id_key] = true
		house["revelee"] = bool(house.get("revelee", false))
		house["espionnee"] = bool(house.get("espionnee", false))
		var relation := str(house.get("relation", "neutre")).to_lower()
		house["relation"] = relation if VALID_RELATIONS.has(relation) else "neutre"
		var bastions: Array = []
		for bastion_entry in house.get("bastions", []) as Array:
			if not (bastion_entry is Dictionary):
				continue
			var bastion := (bastion_entry as Dictionary).duplicate(true)
			bastion["conquis"] = bool(bastion.get("conquis", false))
			bastion["defense"] = maxi(0, int(bastion.get("defense", 0)))
			bastions.append(bastion)
		house["bastions"] = bastions
		result.append(house)
	return result


func _update_house_flag(houses: Array, house_id: Variant, key: String, value: bool) -> Dictionary:
	var index := find_house_index(houses, house_id)
	if index < 0:
		return _error(houses, "maison_introuvable")
	var next_houses := houses.duplicate(true)
	var house := (next_houses[index] as Dictionary).duplicate(true)
	house[key] = value
	next_houses[index] = house
	return {"ok": true, "houses": next_houses, "house": house.duplicate(true)}


func _all_bastions_conquered(bastions: Array) -> bool:
	if bastions.is_empty():
		return false
	for entry in bastions:
		if not (entry is Dictionary) or not bool((entry as Dictionary).get("conquis", false)):
			return false
	return true


func _error(houses: Array, code: String) -> Dictionary:
	return {"ok": false, "error": code, "houses": houses.duplicate(true)}


## Alias de compatibilité pour le vocabulaire du ClanManager.
func spy_house(houses: Array, house_id: Variant) -> Dictionary:
	return mark_spied(houses, house_id)


func conquer(houses: Array, house_id: Variant, bastion_id: String) -> Dictionary:
	return conquer_bastion(houses, house_id, bastion_id)
