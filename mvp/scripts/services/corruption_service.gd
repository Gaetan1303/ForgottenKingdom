## Service de corruption indépendant de l'UI et de ClanManager.
## L'état est sérialisable via export_state/import_state.
class_name CorruptionService
extends RefCounted

signal character_corrupted(character_id: String, level: int)
signal submission_applied(source: String, target: String, power: float)
signal resistance_broken(character_id: String)

enum CorruptionStage {
	PURE,
	TAINTED,
	BREAKING,
	SUBMISSIVE,
	CORRUPTED,
	LOST,
}

const MIN_LEVEL := 0.0
const MAX_LEVEL := 100.0
const MIN_RESISTANCE := 0.0
const MAX_RESISTANCE := 100.0

var _corruption_data: Dictionary = {}


func register_character(char_id: String, base_resistance: float = 50.0, traits: Array = []) -> Dictionary:
	var key := char_id.strip_edges()
	if key.is_empty():
		return {}
	var resistance := clampf(base_resistance, MIN_RESISTANCE, MAX_RESISTANCE)
	var profile := {
		"character_id": key,
		"level": 0.0,
		"resistance": resistance,
		"base_resistance": resistance,
		"traits": traits.duplicate(true),
		"stage": CorruptionStage.PURE,
		"last_source": "",
	}
	_corruption_data[key] = profile
	return profile.duplicate(true)


func unregister_character(char_id: String) -> bool:
	return _corruption_data.erase(char_id.strip_edges())


func has_character(char_id: String) -> bool:
	return _corruption_data.has(char_id.strip_edges())


func get_profile(char_id: String) -> Dictionary:
	var profile := _corruption_data.get(char_id.strip_edges(), {}) as Dictionary
	return profile.duplicate(true)


func get_level(char_id: String) -> float:
	return float((_corruption_data.get(char_id.strip_edges(), {}) as Dictionary).get("level", 0.0))


func get_resistance(char_id: String) -> float:
	return float((_corruption_data.get(char_id.strip_edges(), {}) as Dictionary).get("resistance", 0.0))


func get_stage(char_id: String) -> int:
	return stage_for_level(get_level(char_id))


func set_level(char_id: String, level: float, source: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _corruption_data.has(key):
		return {"ok": false, "error": "character_not_registered"}
	var profile := (_corruption_data[key] as Dictionary).duplicate(true)
	var previous := float(profile.get("level", 0.0))
	var next_level := clampf(level, MIN_LEVEL, MAX_LEVEL)
	profile["level"] = next_level
	profile["stage"] = stage_for_level(next_level)
	profile["last_source"] = source
	_corruption_data[key] = profile
	if next_level > previous:
		emit_signal("character_corrupted", key, int(round(next_level)))
	return {"ok": true, "profile": profile.duplicate(true), "delta": next_level - previous}


func apply_corruption(char_id: String, amount: float, source: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _corruption_data.has(key):
		return {"ok": false, "error": "character_not_registered"}
	if amount <= 0.0:
		return {"ok": true, "profile": get_profile(key), "delta": 0.0}
	var profile := _corruption_data[key] as Dictionary
	var resistance := clampf(float(profile.get("resistance", 0.0)), MIN_RESISTANCE, MAX_RESISTANCE)
	var effective_amount := amount * (1.0 - resistance / 100.0)
	return set_level(key, float(profile.get("level", 0.0)) + effective_amount, source)


func cleanse(char_id: String, amount: float) -> Dictionary:
	if amount <= 0.0:
		return {"ok": true, "profile": get_profile(char_id), "delta": 0.0}
	return set_level(char_id, get_level(char_id) - amount, "cleanse")


func apply_submission(source: String, target: String, power: float) -> Dictionary:
	var key := target.strip_edges()
	if not _corruption_data.has(key):
		return {"ok": false, "error": "character_not_registered"}
	var normalized_power := maxf(0.0, power)
	var profile := (_corruption_data[key] as Dictionary).duplicate(true)
	var previous_resistance := float(profile.get("resistance", 0.0))
	var next_resistance := clampf(previous_resistance - normalized_power, MIN_RESISTANCE, MAX_RESISTANCE)
	profile["resistance"] = next_resistance
	profile["last_source"] = source
	_corruption_data[key] = profile
	emit_signal("submission_applied", source, key, normalized_power)
	if previous_resistance > 0.0 and is_zero_approx(next_resistance):
		emit_signal("resistance_broken", key)
	return {
		"ok": true,
		"profile": profile.duplicate(true),
		"resistance_delta": next_resistance - previous_resistance,
	}


func restore_resistance(char_id: String, amount: float) -> Dictionary:
	var key := char_id.strip_edges()
	if not _corruption_data.has(key):
		return {"ok": false, "error": "character_not_registered"}
	var profile := (_corruption_data[key] as Dictionary).duplicate(true)
	profile["resistance"] = clampf(
		float(profile.get("resistance", 0.0)) + maxf(0.0, amount),
		MIN_RESISTANCE,
		float(profile.get("base_resistance", MAX_RESISTANCE))
	)
	_corruption_data[key] = profile
	return {"ok": true, "profile": profile.duplicate(true)}


func export_state() -> Dictionary:
	return _corruption_data.duplicate(true)


func import_state(state: Dictionary) -> void:
	_corruption_data.clear()
	for key_variant in state.keys():
		var key := str(key_variant).strip_edges()
		if key.is_empty() or not (state[key_variant] is Dictionary):
			continue
		var raw := state[key_variant] as Dictionary
		var base_resistance := clampf(float(raw.get("base_resistance", 50.0)), MIN_RESISTANCE, MAX_RESISTANCE)
		var level := clampf(float(raw.get("level", 0.0)), MIN_LEVEL, MAX_LEVEL)
		_corruption_data[key] = {
			"character_id": key,
			"level": level,
			"resistance": clampf(float(raw.get("resistance", base_resistance)), MIN_RESISTANCE, MAX_RESISTANCE),
			"base_resistance": base_resistance,
			"traits": (raw.get("traits", []) as Array).duplicate(true),
			"stage": stage_for_level(level),
			"last_source": str(raw.get("last_source", "")),
		}


static func stage_for_level(level: float) -> int:
	var value := clampf(level, MIN_LEVEL, MAX_LEVEL)
	if value < 20.0:
		return CorruptionStage.PURE
	if value < 40.0:
		return CorruptionStage.TAINTED
	if value < 60.0:
		return CorruptionStage.BREAKING
	if value < 80.0:
		return CorruptionStage.SUBMISSIVE
	if value < 95.0:
		return CorruptionStage.CORRUPTED
	return CorruptionStage.LOST


## Applique une corruption à plusieurs identifiants enregistrés.
func apply_corruption_batch(character_ids: Array, amount: float, source: String = "") -> Dictionary:
	var results: Array = []
	var succeeded := 0
	for raw_id in character_ids:
		var result: Dictionary = apply_corruption(str(raw_id), amount, source)
		results.append(result)
		if bool(result.get("ok", false)):
			succeeded += 1
	return {"ok": succeeded == character_ids.size(), "succeeded": succeeded, "results": results}


## Purifie plusieurs identifiants enregistrés.
func apply_purification_batch(character_ids: Array, amount: float) -> Dictionary:
	var results: Array = []
	var succeeded := 0
	for raw_id in character_ids:
		var result: Dictionary = cleanse(str(raw_id), amount)
		results.append(result)
		if bool(result.get("ok", false)):
			succeeded += 1
	return {"ok": succeeded == character_ids.size(), "succeeded": succeeded, "results": results}


## Alias explicites pour les intégrations déjà écrites pendant le découpage de ClanManager.
func corrupt_batch(character_ids: Array, amount: float, source: String = "") -> Dictionary:
	return apply_corruption_batch(character_ids, amount, source)


func purify_batch(character_ids: Array, amount: float) -> Dictionary:
	return apply_purification_batch(character_ids, amount)
