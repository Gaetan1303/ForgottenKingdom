## Service métier de construction des stats finales d'un personnage.
class_name CharacterBuildService
extends RefCounted

const StatDefsClass = preload("res://scripts/data/stat_defs.gd")


static func compute_final_stats(
	class_stats_bonus: Dictionary,
	raw_stats: Dictionary,
	competence_bonus: Dictionary,
	archetype_bonus: Dictionary,
	feats_bonus: Dictionary = {}
) -> Dictionary:
	var base: Dictionary = StatDefsClass.sanitize_stats(
		class_stats_bonus,
		StatDefsClass.CLAN_MIN_STAT,
		StatDefsClass.CLAN_MAX_STAT,
		0
	)

	# Merge flat stat bonuses coming from feats or other effects
	base = StatDefsClass.merge_stats(base, feats_bonus)

	for key in StatDefsClass.STAT_KEYS:
		base[key] = int(base.get(key, 0)) + StatDefsClass.score_to_modifier(int(raw_stats.get(key, StatDefsClass.CHARACTER_MIN_STAT)))

	base = StatDefsClass.merge_stats(base, competence_bonus)
	base = StatDefsClass.merge_stats(base, archetype_bonus)

	var final_stats: Dictionary = StatDefsClass.sanitize_stats(base, StatDefsClass.CLAN_MIN_STAT, StatDefsClass.CLAN_MAX_STAT, 0)
	var derived_stats: Dictionary = build_derived_stats(final_stats)
	for key in derived_stats.keys():
		final_stats[key] = derived_stats[key]

	return final_stats


static func build_modifiers(raw_stats: Dictionary) -> Dictionary:
	return StatDefsClass.build_modifiers(raw_stats)


static func build_derived_stats(final_stats: Dictionary) -> Dictionary:
	var result := {
		"attaque": 10 + int(final_stats.get("force", 0)) + int(final_stats.get("commandement", 0)),
		"defense": 10 + int(final_stats.get("espionnage", 0)),
		"resistance": 10 + int(final_stats.get("magie", 0)),
		"initiative": int(final_stats.get("espionnage", 0)),
		"jet_vigueur": int(final_stats.get("force", 0)),
		"jet_volonte": int(final_stats.get("magie", 0)),
		"jet_reflexes": int(final_stats.get("espionnage", 0)),
	}
	return result
