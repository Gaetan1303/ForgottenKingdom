## Source unique des stats partagées (joueur, PNJ, monstres, clan).
class_name StatDefs
extends RefCounted

const STAT_KEYS := ["force", "magie", "espionnage", "artisanat", "diplomatie", "commandement"]

const SECONDARY_STAT_KEYS := ["ESP", "TRA", "ESE"]
const SECONDARY_STAT_LABELS := {
	"ESP": "Esprit",
	"TRA": "Transfuge",
	"ESE": "Essence",
}
const SECONDARY_STAT_DEFAULT: int = 0
const SECONDARY_STAT_MIN: int = 0
const SECONDARY_STAT_MAX: int = 20

const CHARACTER_MIN_STAT: int = 8
const CHARACTER_MAX_STAT: int = 18
const CLAN_MIN_STAT: int = 1
const CLAN_MAX_STAT: int = 20


static func make_default_stats(default_value: int) -> Dictionary:
	var out := {}
	for key in STAT_KEYS:
		out[key] = int(default_value)
	return out


static func make_default_secondary_stats(default_value: int = SECONDARY_STAT_DEFAULT) -> Dictionary:
	var out := {}
	for key in SECONDARY_STAT_KEYS:
		out[key] = int(default_value)
	return out


static func sanitize_secondary_stats(input: Dictionary) -> Dictionary:
	var out := make_default_secondary_stats()
	for key in SECONDARY_STAT_KEYS:
		out[key] = clampi(
			int(input.get(key, SECONDARY_STAT_DEFAULT)),
			SECONDARY_STAT_MIN,
			SECONDARY_STAT_MAX
		)
	return out


static func sanitize_stats(input: Dictionary, min_value: int, max_value: int, default_value: int) -> Dictionary:
	var out := make_default_stats(default_value)
	for key in STAT_KEYS:
		out[key] = clampi(int(input.get(key, default_value)), min_value, max_value)
	return out


static func merge_stats(base_stats: Dictionary, delta_stats: Dictionary) -> Dictionary:
	var out := base_stats.duplicate(true)
	for key in STAT_KEYS:
		if delta_stats.has(key):
			out[key] = int(out.get(key, 0)) + int(delta_stats[key])
	return out


static func score_to_modifier(score: int) -> int:
	return int(floor((score - 10) / 2.0))


static func build_modifiers(raw_stats: Dictionary) -> Dictionary:
	var mods := {}
	for key in STAT_KEYS:
		mods[key] = score_to_modifier(int(raw_stats.get(key, CHARACTER_MIN_STAT)))
	return mods
