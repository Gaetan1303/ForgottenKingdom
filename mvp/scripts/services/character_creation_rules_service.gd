## Service metier: regles de creation de personnage (hors UI).
class_name CharacterCreationRulesService
extends RefCounted

const CharacterBuildServiceClass = preload("res://scripts/data/character_build_service.gd")


static func get_class_data(classe_id: String) -> Dictionary:
	var classes := _get_classes()
	if classes.has(classe_id):
		var entry := classes[classe_id] as Dictionary
		return {
			"nom": str(entry.get("name", classe_id)),
			"stats_bonus": get_explicit_class_bonuses(entry),
			"equipement": entry.get("starting_abilities", []),
			"competences": entry.get("starting_feats", []),
		}

	return {
		"nom": classe_id,
		"stats_bonus": StatDefs.make_default_stats(0),
		"equipement": [],
		"competences": [],
	}


static func get_explicit_class_bonuses(class_def: Dictionary) -> Dictionary:
	var explicit := class_def.get("starting_stat_bonuses", {}) as Dictionary
	var out := StatDefs.make_default_stats(0)
	for key in StatDefs.STAT_KEYS:
		out[key] = int(explicit.get(key, 0))
	return out


static func apply_point_buy_for_class(classe_id: String, target_points: int) -> Dictionary:
	var stats := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	var points_restants := target_points
	var classes := _get_classes()
	if classes.has(classe_id) and classes[classe_id] is Dictionary:
		var class_def := classes[classe_id] as Dictionary
		var bonuses := get_explicit_class_bonuses(class_def)
		for key in StatDefs.STAT_KEYS:
			stats[key] = int(stats[key]) + int(bonuses.get(key, 0))
		return {
			"stats": stats,
			"points_restants": points_restants,
		}

	var priorities := ["force", "magie", "espionnage", "artisanat", "diplomatie", "commandement"]
	var spent := 0
	var idx := 0
	while spent < target_points and points_restants > 0 and idx < 48:
		var stat := str(priorities[idx % priorities.size()])
		if int(stats.get(stat, 8)) < 16:
			stats[stat] = int(stats[stat]) + 1
			points_restants -= 1
			spent += 1
		idx += 1

	return {
		"stats": stats,
		"points_restants": points_restants,
	}


static func build_complete_sheet(classe_choisie: String, fiche_stats: Dictionary, fiche_points_restants: int) -> Dictionary:
	var mods: Dictionary = CharacterBuildServiceClass.build_modifiers(fiche_stats)
	var derived: Dictionary = CharacterBuildServiceClass.build_derived_stats(mods)

	var pv_base := 10
	if classe_choisie == "chevalier_sombre":
		pv_base = 14
	elif classe_choisie == "mage_du_pacte":
		pv_base = 8
	elif classe_choisie == "stratege_des_ombres":
		pv_base = 10

	var points_spent := 0
	for k in StatDefs.STAT_KEYS:
		points_spent += max(0, int(fiche_stats.get(k, StatDefs.CHARACTER_MIN_STAT)) - StatDefs.CHARACTER_MIN_STAT)
	var points_pool_total := points_spent + fiche_points_restants

	return {
		"classe": classe_choisie,
		"niveau": 1,
		"points_a_distribuer_base": points_pool_total,
		"points_restants": fiche_points_restants,
		"stats_brutes": fiche_stats.duplicate(true),
		"modificateurs": mods,
		"pv_max": pv_base + int(mods["commandement"]),
		"initiative": int(derived["initiative"]),
		"defense": int(derived["defense"]),
		"attaque": int(derived["attaque"]),
		"resistance": int(derived["resistance"]),
		"jet_vigueur": int(derived["jet_vigueur"]),
		"jet_volonte": int(derived["jet_volonte"]),
		"jet_reflexes": int(derived["jet_reflexes"]),
	}


static func competence_bonus(competence_id: String) -> Dictionary:
	match competence_id:
		"maitrise_martiale":
			return {"force": 1, "commandement": 1}
		"rituel_occulte":
			return {"magie": 2}
		"diplomatie_de_guerre":
			return {"diplomatie": 1, "commandement": 1}
		"infiltration":
			return {"espionnage": 2}
	return {}


static func archetype_bonus(archetype: String) -> Dictionary:
	match archetype:
		"Lame jurée (inspiration Guerrier)":
			return {"force": 2}
		"Ensorceleur abyssal (inspiration Magicien)":
			return {"magie": 2}
		"Traqueur des ruines (inspiration Rôdeur)":
			return {"espionnage": 1, "force": 1}
		"Prédicateur noir (inspiration Clerc)":
			return {"diplomatie": 1, "magie": 1}
		"Ombrelame (inspiration Roublard)":
			return {"espionnage": 2}
		"Alchimiste de siège (inspiration Alchimiste)":
			return {"artisanat": 2}
	return {}


static func compute_feats_bonus(feats_defs: Dictionary, class_feats: Array, selected_feats: Array) -> Dictionary:
	var feats_bonus: Dictionary = {}
	for cf in class_feats:
		_accumulate_feat_stats_bonus(feats_bonus, feats_defs, str(cf))
	for feat_id in selected_feats:
		_accumulate_feat_stats_bonus(feats_bonus, feats_defs, str(feat_id))
	return feats_bonus


static func compute_feats_effects(feats_defs: Dictionary, feat_ids: Array) -> Dictionary:
	var out := {"stats": {}}
	for feat_id in feat_ids:
		_accumulate_feat_effects(out, feats_defs, str(feat_id))
	return out


static func build_feat_description(feat_def: Dictionary) -> String:
	var desc := str(feat_def.get("description", ""))
	var pre: Variant = feat_def.get("prerequis", feat_def.get("prerequisite", null))
	if pre == null or not pre is Dictionary:
		return desc

	var pre_lines: Array[String] = []
	var pre_d: Dictionary = pre as Dictionary
	var stat_requirements: Dictionary = pre_d.get("stats", {}) as Dictionary
	for stat_key in stat_requirements.keys():
		pre_lines.append("%s : %d minimum" % [str(stat_key).replace("_", " ").capitalize(), int(stat_requirements[stat_key])])
	var feat_requirements: Array = pre_d.get("dons", pre_d.get("feats", [])) as Array
	for feat_id in feat_requirements:
		pre_lines.append("Don requis : %s" % _get_feat_name(str(feat_id)))

	if pre_lines.size() > 0:
		desc += "\nPrérequis : %s" % _join_string_array(pre_lines, ", ")
	return desc


static func stat_upgrade_cost_preview(_current_value: int) -> int:
	# Règle commune à la création et à la fiche : +1 coûte toujours 1 point.
	return 1


static func get_creation_class_score_bonus(classe_id: String) -> Dictionary:
	# Les valeurs de départ des classes sont des bonus de score externes au point-buy.
	# Elles ne doivent donc jamais être comptées parmi les points investis par le joueur.
	var out := StatDefs.make_default_stats(0)
	var classes := _get_classes()
	if not classes.has(classe_id) or not classes[classe_id] is Dictionary:
		return out
	return get_explicit_class_bonuses(classes[classe_id] as Dictionary)


static func compute_creation_display_stats(classe_id: String, purchased_stats: Dictionary) -> Dictionary:
	var out := StatDefs.sanitize_stats(
		purchased_stats,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)
	var class_bonus := get_creation_class_score_bonus(classe_id)
	for key in StatDefs.STAT_KEYS:
		out[key] = int(out.get(key, StatDefs.CHARACTER_MIN_STAT)) + int(class_bonus.get(key, 0))
	return out


static func _get_classes() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var loader := tree.root.get_node_or_null("GameDataLoader")
	if loader == null or not loader.has_method("get_classes"):
		return {}
	return loader.get_classes() as Dictionary


static func _get_feat_name(feat_id: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var loader := tree.root.get_node_or_null("GameDataLoader")
		if loader != null and loader.has_method("get_feat"):
			var feat := loader.get_feat(feat_id) as Dictionary
			if not feat.is_empty():
				return str(feat.get("nom", feat.get("name", feat_id)))
	return feat_id.replace("_", " ").capitalize()


static func build_points_summary(points_remaining: int, points_spent: int) -> String:
	return "Points restants: %d   |   Points investis: %d" % [points_remaining, points_spent]


static func compute_sheet_vitals(stats_dict: Dictionary, feats_effects: Dictionary, ame_pct: int) -> Dictionary:
	var mods: Dictionary = CharacterBuildServiceClass.build_modifiers(stats_dict)
	var derived: Dictionary = CharacterBuildServiceClass.build_derived_stats(mods)
	var pv_max := 10 + int(mods.get("commandement", 0)) + int(feats_effects.get("pv_bonus", 0))
	var mana_max := 20 + int(mods.get("magie", 0)) * 3 + int(feats_effects.get("mana_bonus", 0))
	return {
		"pv_max": pv_max,
		"mana_max": mana_max,
		"ame_pct": ame_pct,
		"attaque": int(derived["attaque"]),
		"defense": int(derived["defense"]),
		"resistance": int(derived["resistance"]),
		"initiative": int(derived["initiative"]),
	}


static func build_feats_bonus_summary(feats_effects: Dictionary) -> String:
	var parts: Array[String] = []
	var stats_bonus := feats_effects.get("stats", {}) as Dictionary
	for stat_key in stats_bonus.keys():
		parts.append("%s: %s" % [str(stat_key).capitalize(), _format_signed_int(int(stats_bonus[stat_key]))])
	if int(feats_effects.get("pv_bonus", 0)) != 0:
		parts.append("PV: %s" % _format_signed_int(int(feats_effects.get("pv_bonus", 0))))
	if int(feats_effects.get("mana_bonus", 0)) != 0:
		parts.append("Mana: %s" % _format_signed_int(int(feats_effects.get("mana_bonus", 0))))
	return _join_string_array(parts, ", ") if parts.size() > 0 else "—"


static func compute_final_stats_for_creation(
	classe_data: Dictionary,
	raw_stats: Dictionary,
	competence_id: String,
	archetype_label: String,
	feats_defs: Dictionary,
	selected_feats: Array
) -> Dictionary:
	return build_character_result_for_creation(classe_data, raw_stats, competence_id, archetype_label, feats_defs, selected_feats).character_scores


static func build_character_result_for_creation(
	classe_data: Dictionary,
	character_scores: Dictionary,
	competence_id: String,
	archetype_label: String,
	feats_defs: Dictionary,
	selected_feats: Array
) -> Dictionary:
	var feats_bonus := compute_feats_bonus(
		feats_defs,
		classe_data.get("competences", []) as Array,
		selected_feats
	)
	return CharacterBuildService.build_character_result(
		classe_data.get("stats_bonus", {}) as Dictionary,
		character_scores,
		competence_bonus(competence_id),
		archetype_bonus(archetype_label),
		feats_bonus
	)


static func _accumulate_feat_stats_bonus(destination: Dictionary, feats_defs: Dictionary, feat_id: String) -> void:
	if feat_id.is_empty():
		return
	var feat_def := feats_defs.get(feat_id, {}) as Dictionary
	var effects := feat_def.get("effects", {}) as Dictionary
	var stats_effects := effects.get("stats", {}) as Dictionary
	for stat_key in stats_effects.keys():
		destination[stat_key] = int(destination.get(stat_key, 0)) + int(stats_effects[stat_key])


static func _accumulate_feat_effects(destination: Dictionary, feats_defs: Dictionary, feat_id: String) -> void:
	if feat_id.is_empty():
		return
	var feat_def := feats_defs.get(feat_id, {}) as Dictionary
	var effects := feat_def.get("effects", {}) as Dictionary
	var destination_stats := destination.get("stats", {}) as Dictionary
	var stats_effects := effects.get("stats", {}) as Dictionary
	for stat_key in stats_effects.keys():
		destination_stats[stat_key] = int(destination_stats.get(stat_key, 0)) + int(stats_effects[stat_key])
	destination["stats"] = destination_stats
	if effects.has("pv_bonus"):
		destination["pv_bonus"] = int(destination.get("pv_bonus", 0)) + int(effects.get("pv_bonus", 0))
	if effects.has("mana_bonus"):
		destination["mana_bonus"] = int(destination.get("mana_bonus", 0)) + int(effects.get("mana_bonus", 0))


static func _join_string_array(values: Array[String], separator: String) -> String:
	if values.is_empty():
		return ""
	var out := ""
	for i in range(values.size()):
		out += values[i]
		if i < values.size() - 1:
			out += separator
	return out


static func _format_signed_int(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return str(value)
