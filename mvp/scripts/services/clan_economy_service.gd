## Règles économiques pures du clan. Aucune dépendance au singleton ClanManager.
class_name ClanEconomyService
extends RefCounted

const RESOURCE_KEYS := [
	"or", "soldats", "mana", "reputation", "renseignements",
	"bois", "fer", "pierre", "nourriture", "essence"
]
const SOLDIERS_MAX := 600


func sanitize(resources: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in RESOURCE_KEYS:
		var value := maxi(0, int(resources.get(key, 0)))
		if key == "soldats":
			value = mini(value, SOLDIERS_MAX)
		result[key] = value
	return result


func can_afford(resources: Dictionary, cost: Dictionary) -> bool:
	for key in cost.keys():
		var amount := maxi(0, int(cost.get(key, 0)))
		if int(resources.get(key, 0)) < amount:
			return false
	return true


func spend(resources: Dictionary, cost: Dictionary) -> Dictionary:
	if not can_afford(resources, cost):
		return {"ok": false, "error": "ressources_insuffisantes", "resources": sanitize(resources)}
	var delta: Dictionary = {}
	for key in cost.keys():
		delta[key] = -maxi(0, int(cost.get(key, 0)))
	return apply_delta(resources, delta, true)


func gain(resources: Dictionary, gains: Dictionary) -> Dictionary:
	var delta: Dictionary = {}
	for key in gains.keys():
		delta[key] = maxi(0, int(gains.get(key, 0)))
	return apply_delta(resources, delta, false)


func apply_turn_income(resources: Dictionary, production: Dictionary) -> Dictionary:
	return gain(resources, production)


func apply_delta(resources: Dictionary, delta: Dictionary, reject_negative: bool = true) -> Dictionary:
	var next_resources := sanitize(resources)
	var applied: Dictionary = {}
	for key_variant in delta.keys():
		var key := str(key_variant)
		if not RESOURCE_KEYS.has(key):
			continue
		var before := int(next_resources.get(key, 0))
		var requested := int(delta.get(key_variant, 0))
		var after := before + requested
		if reject_negative and after < 0:
			return {
				"ok": false,
				"error": "ressource_negative",
				"resource": key,
				"resources": sanitize(resources),
			}
		after = maxi(0, after)
		if key == "soldats":
			after = mini(after, SOLDIERS_MAX)
		next_resources[key] = after
		applied[key] = after - before
	return {"ok": true, "resources": next_resources, "changes": applied}


func get_resource(resources: Dictionary, key: String, default_value: int = 0) -> int:
	return int(resources.get(key, default_value))
