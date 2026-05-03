## Service métier de construction des stats finales d'un personnage.
class_name CharacterBuildService
extends RefCounted

# Use StatDefs global class_name from data/stat_defs.gd


static func compute_final_stats(
	class_stats_bonus: Dictionary,
	raw_stats: Dictionary,
	competence_bonus: Dictionary,
	archetype_bonus: Dictionary,
	feats_bonus: Dictionary = {}
) -> Dictionary:
	var base := StatDefs.sanitize_stats(
		class_stats_bonus,
		StatDefs.CLAN_MIN_STAT,
		StatDefs.CLAN_MAX_STAT,
		0
	)

	# Merge flat stat bonuses coming from feats or other effects
	base = StatDefs.merge_stats(base, feats_bonus)

	for key in StatDefs.STAT_KEYS:
		base[key] = int(base.get(key, 0)) + StatDefs.score_to_modifier(int(raw_stats.get(key, StatDefs.CHARACTER_MIN_STAT)))

	base = StatDefs.merge_stats(base, competence_bonus)
	base = StatDefs.merge_stats(base, archetype_bonus)

	return StatDefs.sanitize_stats(base, StatDefs.CLAN_MIN_STAT, StatDefs.CLAN_MAX_STAT, 0)


static func build_modifiers(raw_stats: Dictionary) -> Dictionary:
	return StatDefs.build_modifiers(raw_stats)
