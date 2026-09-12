## Règles économiques pures du clan. Aucune dépendance au singleton ClanManager.
class_name ClanEconomyService
extends RefCounted

const RESOURCE_KEYS := [
	"or", "soldats", "mana", "reputation", "renseignements",
	"bois", "fer", "pierre", "nourriture", "essence"
]
const SOLDIERS_MAX := 600
const DOMAIN_ROLES := ["forgeron", "alchimiste", "intendant", "arcaniste"]


func sanitize(resources: Dictionary, preserve_extra: bool = false, limit_soldiers: bool = true) -> Dictionary:
	var result: Dictionary = resources.duplicate(true) if preserve_extra else {}
	for key in RESOURCE_KEYS:
		var value := maxi(0, int(resources.get(key, 0)))
		if key == "soldats" and limit_soldiers:
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


## Contrat historique : coûts signés autorisés, sans normaliser l'état lu.
func can_pay(resources: Dictionary, cost: Dictionary) -> bool:
	for key in cost:
		if resources.get(key, 0) < int(cost[key]):
			return false
	return true


## Débit sans précondition. Les IDs soldats sont appliqués par l'orchestrateur.
func debit(resources: Dictionary, key: Variant, amount: int) -> void:
	resources[key] = maxi(0, int(resources.get(key, 0)) - amount)


## Delta signé historique ; une clé inconnue ne crée pas une nouvelle ressource.
func credit(resources: Dictionary, key: Variant, amount: int) -> void:
	if resources.has(key):
		resources[key] = int(resources[key]) + amount


func total_production(base: Dictionary, domain_sheets: Dictionary, affinities: Dictionary) -> Dictionary:
	var total := base.duplicate(true)
	for key in RESOURCE_KEYS:
		if not total.has(key):
			total[key] = 0
	var bonus := domain_production(domain_sheets, affinities)
	for key in bonus:
		total[key] = int(total.get(key, 0)) + int(bonus[key])
	return total


func domain_production(fiches_domaine: Dictionary, affinites_pnj: Dictionary) -> Dictionary:
	var bonus := {
		"or": 0,
		"mana": 0,
		"fer": 0,
		"essence": 0,
		"bois": 0,
		"pierre": 0,
		"nourriture": 0,
	}

	for role in DOMAIN_ROLES:
		if not fiches_domaine.has(role):
			continue
		var fiche := fiches_domaine[role] as Dictionary
		if not bool(fiche.get("actif", false)):
			continue

		var niveau := clampi(int(fiche.get("niveau", 1)), 1, 20)
		var affinite := clampi(int(fiche.get("affinite", int(affinites_pnj.get(role, 0)))), -100, 100)
		var bonus_aff := maxi(0, affinite) / 25

		match role:
			"forgeron":
				bonus["fer"] += niveau + bonus_aff
				bonus["pierre"] += maxi(1, niveau / 3)
			"alchimiste":
				bonus["essence"] += maxi(1, niveau / 2) + bonus_aff
				bonus["mana"] += maxi(1, niveau / 2)
			"intendant":
				bonus["or"] += 5 * niveau + (2 * bonus_aff)
				bonus["nourriture"] += maxi(1, niveau / 2)
			"arcaniste":
				bonus["mana"] += 2 * niveau + bonus_aff
				if niveau >= 5:
					bonus["essence"] += 1

	return bonus


func action_cost(action_id: String, cout_base: Dictionary, traits: Dictionary, caps: Dictionary) -> Dictionary:
	var cout := cout_base.duplicate(true)

	var mana_reduc_pct := clampi(int(traits.get("mana_cost_reduction_pct", 0)), 0, int(caps.get("mana_cost_reduction_pct", 35)))
	if mana_reduc_pct > 0 and cout.has("mana"):
		if action_id in ["recruter", "recruter_pnj", "recuperer"]:
			cout["mana"] = maxi(0, int(round(int(cout["mana"]) * (100 - mana_reduc_pct) / 100.0)))

	var soldats_reduc_atk := clampi(int(traits.get("soldats_cost_reduction_attaquer_pct", 0)), 0, int(caps.get("soldats_cost_reduction_attaquer_pct", 20)))
	if soldats_reduc_atk > 0 and action_id == "attaquer" and cout.has("soldats"):
		cout["soldats"] = maxi(0, int(round(int(cout["soldats"]) * (100 - soldats_reduc_atk) / 100.0)))

	return cout

func pay(context, cout: Dictionary) -> void:
	for res in cout:
		if str(res) == "soldats":
			# remove soldier IDs from pool when paying soldiers
			var to_remove := maxi(0, int(cout[res]))
			remove_available(context, to_remove)
		else:
			debit(context.state.ressources, res, int(cout[res]))
	context.resources_changed.emit()

func gain_state(context, gains: Dictionary) -> void:
	for res in gains:
		if context.state.ressources.has(res):
			var inc := int(gains[res])
			if str(res) == "soldats":
				# add soldier IDs to pool when gaining soldiers
				add_available(context, inc)
			else:
				credit(context.state.ressources, res, inc)
	context.resources_changed.emit()

func remove_available(context, count: int) -> int:
	var result: Dictionary = context.soldiers.remove_soldiers(context.state._soldats_disponibles, count)
	context.state._soldats_disponibles = result.pool
	context.state.ressources["soldats"] = context.state._soldats_disponibles.size()
	context.resources_changed.emit()
	return (result.removed_ids as Array).size()

func add_available(context, count: int) -> int:
	var result: Dictionary = context.soldiers.add_soldiers(context.state._soldats_disponibles, count, context.state._soldat_next_id)
	context.state._soldats_disponibles = result.pool
	context.state._soldat_next_id = result.next_id
	context.state.ressources["soldats"] = context.state._soldats_disponibles.size()
	context.resources_changed.emit()
	return (result.added_ids as Array).size()
