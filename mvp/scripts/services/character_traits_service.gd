## Service metier: aggregation des traits gameplay pour la creation.
class_name CharacterTraitsService
extends RefCounted


static func default_traits() -> Dictionary:
	return {
		"mana_cost_reduction_pct": 0,
		"soldats_cost_reduction_attaquer_pct": 0,
		"bonus_score_actions": {},
		"night_soul_regen": 0,
		"night_reputation_gain": 0,
	}


static func build_traits(traits_data: Dictionary, don_id: String, pouvoir_id: String, competence_id: String) -> Dictionary:
	var traits := default_traits()

	var dons := traits_data.get("dons", {}) as Dictionary
	var pouvoirs := traits_data.get("pouvoirs", {}) as Dictionary
	var competences := traits_data.get("competences", {}) as Dictionary

	merge_effects(traits, (dons.get(don_id, {}) as Dictionary).get("effects", {}) as Dictionary)
	merge_effects(traits, (pouvoirs.get(pouvoir_id, {}) as Dictionary).get("effects", {}) as Dictionary)
	merge_effects(traits, (competences.get(competence_id, {}) as Dictionary).get("effects", {}) as Dictionary)

	var caps := traits_data.get("caps", {}) as Dictionary
	return apply_caps(traits, caps)


static func merge_effects(destination: Dictionary, effets: Dictionary) -> void:
	if effets.is_empty():
		return

	for key in effets.keys():
		if key == "bonus_score_actions":
			var dest_map := (destination.get("bonus_score_actions", {}) as Dictionary).duplicate(true)
			var src_map := effets.get("bonus_score_actions", {}) as Dictionary
			for action_id in src_map.keys():
				dest_map[action_id] = int(dest_map.get(action_id, 0)) + int(src_map[action_id])
			destination["bonus_score_actions"] = dest_map
		else:
			destination[key] = int(destination.get(key, 0)) + int(effets[key])


static func apply_caps(traits: Dictionary, caps: Dictionary) -> Dictionary:
	var out := traits.duplicate(true)
	out["mana_cost_reduction_pct"] = clampi(
		int(out.get("mana_cost_reduction_pct", 0)),
		0,
		maxi(0, int(caps.get("mana_cost_reduction_pct", 35)))
	)
	out["soldats_cost_reduction_attaquer_pct"] = clampi(
		int(out.get("soldats_cost_reduction_attaquer_pct", 0)),
		0,
		maxi(0, int(caps.get("soldats_cost_reduction_attaquer_pct", 20)))
	)
	out["night_soul_regen"] = clampi(
		int(out.get("night_soul_regen", 0)),
		0,
		maxi(0, int(caps.get("night_soul_regen", 4)))
	)
	out["night_reputation_gain"] = clampi(
		int(out.get("night_reputation_gain", 0)),
		0,
		maxi(0, int(caps.get("night_reputation_gain", 2)))
	)

	var per_action_cap := maxi(0, int(caps.get("bonus_per_action_max", 3)))
	var map_bonus := (out.get("bonus_score_actions", {}) as Dictionary).duplicate(true)
	for action_id in map_bonus.keys():
		map_bonus[action_id] = clampi(int(map_bonus[action_id]), -per_action_cap, per_action_cap)
	out["bonus_score_actions"] = map_bonus

	return out
