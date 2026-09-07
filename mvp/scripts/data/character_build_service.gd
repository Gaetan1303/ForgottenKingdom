## Service métier de construction des stats finales d'un personnage.
class_name CharacterBuildService
extends RefCounted

# Use StatDefs global class_name from data/stat_defs.gd


static func compute_final_stats(
	class_stats_bonus: Dictionary,
	character_scores: Dictionary,
	competence_bonus: Dictionary,
	archetype_bonus: Dictionary,
	feats_bonus: Dictionary = {}
) -> Dictionary:
	var final_scores := StatDefs.sanitize_stats(
		character_scores,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)
	for key in StatDefs.STAT_KEYS:
		final_scores[key] = int(final_scores[key]) + int(class_stats_bonus.get(key, 0))
		final_scores[key] += int(competence_bonus.get(key, 0))
		final_scores[key] += int(archetype_bonus.get(key, 0))
		final_scores[key] += int(feats_bonus.get(key, 0))
		final_scores[key] = clampi(int(final_scores[key]), StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT)
	return final_scores


static func build_character_result(
	class_stats_bonus: Dictionary,
	character_scores: Dictionary,
	competence_bonus: Dictionary = {},
	archetype_bonus: Dictionary = {},
	feats_bonus: Dictionary = {}
) -> Dictionary:
	var final_scores := compute_final_stats(class_stats_bonus, character_scores, competence_bonus, archetype_bonus, feats_bonus)
	var modifiers := build_modifiers(final_scores)
	return {
		"character_scores": final_scores,
		"modifiers": modifiers,
		"derived_stats": build_derived_stats(modifiers),
	}


static func build_modifiers(raw_stats: Dictionary) -> Dictionary:
	return StatDefs.build_modifiers(raw_stats)


static func build_derived_stats(modifiers: Dictionary) -> Dictionary:
	var result := {
		"attaque": 10 + int(modifiers.get("force", 0)) + int(modifiers.get("commandement", 0)),
		"defense": 10 + int(modifiers.get("espionnage", 0)),
		"resistance": 10 + int(modifiers.get("magie", 0)),
		"initiative": int(modifiers.get("espionnage", 0)),
		"jet_vigueur": int(modifiers.get("force", 0)),
		"jet_volonte": int(modifiers.get("magie", 0)),
		"jet_reflexes": int(modifiers.get("espionnage", 0)),
	}
	return result
