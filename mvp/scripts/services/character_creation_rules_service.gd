## Service metier: regles de creation de personnage (hors UI).
class_name CharacterCreationRulesService
extends RefCounted


static func get_class_data(classe_id: String) -> Dictionary:
	var classes: Dictionary = GameDataLoader.get_classes()
	if classes.has(classe_id):
		var entry := classes[classe_id] as Dictionary
		var stats_bonus := derive_stats_bonus_from_base(resolve_base_stats_for_class(entry))
		return {
			"nom": str(entry.get("name", classe_id)),
			"stats_bonus": stats_bonus,
			"equipement": entry.get("starting_abilities", []),
			"competences": entry.get("starting_feats", []),
		}

	return {
		"nom": classe_id,
		"stats_bonus": StatDefs.make_default_stats(0),
		"equipement": [],
		"competences": [],
	}


static func derive_stats_bonus_from_base(base_stats: Dictionary) -> Dictionary:
	var out := StatDefs.make_default_stats(0)
	if base_stats.is_empty():
		return out
	for key in StatDefs.STAT_KEYS:
		var score := int(base_stats.get(key, 10))
		out[key] = score - 10
	return out


static func resolve_base_stats_for_class(class_def: Dictionary) -> Dictionary:
	var explicit_base := class_def.get("base_stats", {}) as Dictionary
	if not explicit_base.is_empty():
		return explicit_base
	return build_base_stats_from_class_def(class_def)


static func build_base_stats_from_class_def(class_def: Dictionary) -> Dictionary:
	var out := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	var primary := class_def.get("primary", []) as Array
	var secondary := class_def.get("secondary", []) as Array
	var hit_die := int(class_def.get("hit_die", 8))

	for stat in primary:
		var key := str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 3
	for stat in secondary:
		var key := str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 2

	if hit_die >= 10:
		out["force"] = int(out.get("force", 8)) + 1
		out["commandement"] = int(out.get("commandement", 8)) + 1
	elif hit_die <= 6:
		out["magie"] = int(out.get("magie", 8)) + 1

	return StatDefs.sanitize_stats(
		out,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)


static func apply_point_buy_for_class(classe_id: String, target_points: int) -> Dictionary:
	var stats := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	var points_restants := target_points
	var classes: Dictionary = GameDataLoader.get_classes()
	if classes.has(classe_id) and classes[classe_id] is Dictionary:
		var class_def := classes[classe_id] as Dictionary
		var base_stats := resolve_base_stats_for_class(class_def)
		stats = StatDefs.sanitize_stats(
			base_stats,
			StatDefs.CHARACTER_MIN_STAT,
			StatDefs.CHARACTER_MAX_STAT,
			StatDefs.CHARACTER_MIN_STAT
		)
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
	var mods := CharacterBuildService.build_modifiers(fiche_stats)

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
		"initiative": int(mods["espionnage"]),
		"defense": 10 + int(mods["espionnage"]),
		"jet_vigueur": int(mods["force"]),
		"jet_volonte": int(mods["magie"]),
		"jet_reflexes": int(mods["espionnage"]),
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
	var pre: Variant = feat_def.get("prerequisite", null)
	if pre == null:
		return desc

	var pre_lines: Array[String] = []
	var pre_d: Dictionary = pre as Dictionary
	var stat_requirements: Dictionary = pre_d.get("stats", {}) as Dictionary
	for stat_key in stat_requirements.keys():
		pre_lines.append("%s >= %s" % [str(stat_key).capitalize(), str(stat_requirements[stat_key])])
	var feat_requirements: Array = pre_d.get("feats", []) as Array
	for feat_id in feat_requirements:
		pre_lines.append("Requires feat: %s" % str(feat_id))

	if pre_lines.size() > 0:
		desc += "\nPrerequisites: %s" % _join_string_array(pre_lines, ", ")
	return desc


static func stat_upgrade_cost_preview(current_value: int) -> int:
	# UI preview cost curve used by character sheet.
	if current_value <= 10:
		return 1
	if current_value <= 13:
		return 2
	if current_value <= 16:
		return 3
	return 4


static func build_points_summary(points_remaining: int, points_spent: int) -> String:
	return "Points restants: %d   |   Points investis: %d" % [points_remaining, points_spent]


static func compute_sheet_vitals(stats_dict: Dictionary, feats_effects: Dictionary, ame_pct: int) -> Dictionary:
	var mods := CharacterBuildService.build_modifiers(stats_dict)
	var pv_max := 10 + int(mods.get("commandement", 0)) + int(feats_effects.get("pv_bonus", 0))
	var mana_max := 20 + int(mods.get("magie", 0)) * 3 + int(feats_effects.get("mana_bonus", 0))
	return {
		"pv_max": pv_max,
		"mana_max": mana_max,
		"ame_pct": ame_pct,
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
	var feats_bonus := compute_feats_bonus(
		feats_defs,
		classe_data.get("competences", []) as Array,
		selected_feats
	)
	return CharacterBuildService.compute_final_stats(
		classe_data.get("stats_bonus", {}) as Dictionary,
		raw_stats,
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
