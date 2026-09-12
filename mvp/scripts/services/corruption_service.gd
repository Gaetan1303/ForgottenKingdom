## État de corruption des personnages. Le service fonctionne en shadow mode :
## il ne modifie jamais ClanManager directement.
class_name CorruptionService
extends RefCounted

const Enums = preload("res://scripts/core/enums.gd")
const TrainingSystemClass = preload("res://scripts/services/training_system.gd")

signal character_registered(char_id: String, profile: Dictionary)
signal character_corrupted(char_id: String, level: float, stage: int)
signal resistance_broken(char_id: String, source: String)
signal submission_applied(source: String, target: String, power: float, is_sexual: bool)
signal obedience_changed(char_id: String, old_val: float, new_val: float)
signal perversion_changed(char_id: String, new_level: float)
signal arousal_changed(char_id: String, new_level: float)
signal training_started(char_id: String, training_type: int, creature_id: String)
signal training_progress(char_id: String, progress: float)
signal training_completed(char_id: String, training_type: int, results: Dictionary)
signal experience_gained(char_id: String, exp_type: int, details: Dictionary)
signal assignment_changed(char_id: String, assignment: Dictionary)
signal bond_formed(master_id: String, slave_id: String, pact_type: int)
signal bond_broken(slave_id: String, reason: String)
signal creature_assigned(creature_id: String, target_id: String, assignment_type: int)

const MIN_LEVEL := 0.0
const MAX_LEVEL := 100.0
const MIN_RESISTANCE := 0.0
const MAX_RESISTANCE := 100.0
const MIN_OBEDIENCE := 0.0
const MAX_OBEDIENCE := 100.0
const MIN_AROUSAL := 0.0
const MAX_AROUSAL := 100.0
const MIN_PERVERSION := 0.0
const MAX_PERVERSION := 100.0
const MIN_SHAME := 0.0
const MAX_SHAME := 100.0

var _profiles: Dictionary = {}
var _creatures: Dictionary = {}
var _assignments: Dictionary = {}
var _bonds: Dictionary = {}
var _history: Dictionary = {}
var _training_system: RefCounted = TrainingSystemClass.new()
## Accepte également les anciennes sources exposant pnj_gestion, sans les retenir.
func setup(source) -> void:
	if source == null: return
	var legacy_state: Variant = source.get("pnj_gestion")
	if not (legacy_state is Dictionary): return
	for raw in (legacy_state as Dictionary).get("roster", []):
		if not (raw is Dictionary):
			continue
		var pnj := raw as Dictionary
		var char_id := str(pnj.get("id", "")).strip_edges()
		if char_id.is_empty() or has_character(char_id):
			continue
		var profile := register_character(
			char_id,
			float(pnj.get("resistance_mentale", pnj.get("resistance", 50.0))),
			pnj.get("traits", []) as Array,
			int(pnj.get("orientation", 0)),
			pnj.get("virginity", {}) as Dictionary,
			str(pnj.get("image_path", pnj.get("portrait_path", "")))
		)
		if not profile.is_empty():
			set_corruption(char_id, float(pnj.get("corruption", pnj.get("corruption_level", 0.0))), "legacy_migration")


func register_character(char_id: String, base_resistance: float = 50.0, traits: Array = [], sexual_orientation: int = 0, virginity: Dictionary = {}, image_path: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if key.is_empty():
		return {}
	if _profiles.has(key):
		return get_profile(key)
	var resistance := clampf(base_resistance, MIN_RESISTANCE, MAX_RESISTANCE)
	var profile := {
		"character_id": key, "level": 0.0, "stage": Enums.CorruptionStage.PURE,
		"resistance": resistance, "base_resistance": resistance, "obedience": 0.0,
		"arousal": 0.0, "perversion": 0.0, "shame": 0.0,
		"traits": traits.duplicate(true), "sexual_orientation": sexual_orientation,
		"virginity": _default_virginity(virginity), "fetishes": {}, "experiences": {},
		"image_path": image_path, "last_source": "", "is_adult": true,
	}
	_profiles[key] = profile
	_history[key] = []
	character_registered.emit(key, profile.duplicate(true))
	return profile.duplicate(true)


func unregister_character(char_id: String) -> bool:
	var key := char_id.strip_edges()
	_training_system.call("cancel", key)
	_assignments.erase(key)
	_bonds.erase(key)
	_history.erase(key)
	return _profiles.erase(key)


func get_profile(char_id: String) -> Dictionary:
	return (_profiles.get(char_id.strip_edges(), {}) as Dictionary).duplicate(true)


func has_character(char_id: String) -> bool:
	return _profiles.has(char_id.strip_edges())


func apply_corruption(char_id: String, amount: float, source: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	if amount <= 0.0:
		return {"ok": true, "profile": get_profile(key), "delta": 0.0}
	var profile := _profiles[key] as Dictionary
	var resistance := clampf(float(profile.get("resistance", 0.0)), MIN_RESISTANCE, MAX_RESISTANCE)
	var effective := amount * (1.0 - resistance / 100.0)
	return set_corruption(key, float(profile.get("level", 0.0)) + effective, source)


func set_corruption(char_id: String, level: float, source: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	var profile := (_profiles[key] as Dictionary).duplicate(true)
	var previous := float(profile.get("level", 0.0))
	var next_level := clampf(level, MIN_LEVEL, MAX_LEVEL)
	profile["level"] = next_level
	profile["stage"] = level_to_stage(next_level)
	profile["last_source"] = source
	_profiles[key] = profile
	_record(key, "corruption", {"source": source, "delta": next_level - previous, "level": next_level})
	if next_level > previous:
		character_corrupted.emit(key, next_level, int(profile["stage"]))
	return {"ok": true, "profile": profile.duplicate(true), "delta": next_level - previous}


func cleanse(char_id: String, amount: float) -> Dictionary:
	if amount <= 0.0:
		return {"ok": true, "profile": get_profile(char_id), "delta": 0.0}
	return set_corruption(char_id, get_corruption_level(char_id) - amount, "cleanse")


func get_corruption_level(char_id: String) -> float:
	return float((_profiles.get(char_id.strip_edges(), {}) as Dictionary).get("level", 0.0))


func get_corruption_stage(char_id: String) -> int:
	return level_to_stage(get_corruption_level(char_id))


func apply_submission(source: String, target: String, power: float, is_sexual: bool = false) -> Dictionary:
	var key := target.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	var normalized := maxf(0.0, power)
	var profile := (_profiles[key] as Dictionary).duplicate(true)
	var old_resistance := float(profile.get("resistance", 0.0))
	var old_obedience := float(profile.get("obedience", 0.0))
	profile["resistance"] = clampf(old_resistance - normalized, MIN_RESISTANCE, MAX_RESISTANCE)
	profile["obedience"] = clampf(old_obedience + normalized * (0.75 if is_sexual else 0.5), MIN_OBEDIENCE, MAX_OBEDIENCE)
	profile["last_source"] = source
	_profiles[key] = profile
	submission_applied.emit(source, key, normalized, is_sexual)
	if not is_equal_approx(old_obedience, float(profile["obedience"])):
		obedience_changed.emit(key, old_obedience, float(profile["obedience"]))
	if old_resistance > 0.0 and is_zero_approx(float(profile["resistance"])):
		resistance_broken.emit(key, source)
	return {"ok": true, "profile": profile.duplicate(true), "resistance_delta": float(profile["resistance"]) - old_resistance}


func restore_resistance(char_id: String, amount: float) -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	var profile := (_profiles[key] as Dictionary).duplicate(true)
	profile["resistance"] = clampf(float(profile.get("resistance", 0.0)) + maxf(0.0, amount), MIN_RESISTANCE, float(profile.get("base_resistance", MAX_RESISTANCE)))
	_profiles[key] = profile
	return {"ok": true, "profile": profile.duplicate(true)}


func get_obedience(char_id: String) -> float:
	return float((_profiles.get(char_id.strip_edges(), {}) as Dictionary).get("obedience", 0.0))


func modify_arousal(char_id: String, delta: float, source: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	var profile := (_profiles[key] as Dictionary).duplicate(true)
	profile["arousal"] = clampf(float(profile.get("arousal", 0.0)) + delta, MIN_AROUSAL, MAX_AROUSAL)
	profile["last_source"] = source
	_profiles[key] = profile
	arousal_changed.emit(key, float(profile["arousal"]))
	return {"ok": true, "profile": profile.duplicate(true)}


func apply_pleasure(char_id: String, intensity: float, exp_type: int) -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	modify_arousal(key, maxf(0.0, intensity), "pleasure")
	var profile := (_profiles[key] as Dictionary).duplicate(true)
	profile["perversion"] = clampf(float(profile.get("perversion", 0.0)) + maxf(0.0, intensity) * 0.2, MIN_PERVERSION, MAX_PERVERSION)
	var experiences := (profile.get("experiences", {}) as Dictionary).duplicate(true)
	var exp_key := str(exp_type)
	experiences[exp_key] = int(experiences.get(exp_key, 0)) + 1
	profile["experiences"] = experiences
	_profiles[key] = profile
	perversion_changed.emit(key, float(profile["perversion"]))
	experience_gained.emit(key, exp_type, {"intensity": intensity, "count": experiences[exp_key]})
	return {"ok": true, "profile": profile.duplicate(true)}


func get_perversion(char_id: String) -> float:
	return float((_profiles.get(char_id.strip_edges(), {}) as Dictionary).get("perversion", 0.0))


func has_virginity(char_id: String, kind: String) -> bool:
	var virginity := (_profiles.get(char_id.strip_edges(), {}) as Dictionary).get("virginity", {}) as Dictionary
	return bool(virginity.get(kind, false))


func get_fetish_level(char_id: String, fetish: String) -> float:
	var fetishes := (_profiles.get(char_id.strip_edges(), {}) as Dictionary).get("fetishes", {}) as Dictionary
	return clampf(float(fetishes.get(fetish, 0.0)), 0.0, 100.0)


func register_creature(creature_profile: Resource) -> bool:
	if creature_profile == null or not bool(creature_profile.call("is_valid")):
		return false
	_creatures[str(creature_profile.get("id"))] = creature_profile
	return true


func get_creature(creature_id: String) -> Resource:
	return _creatures.get(creature_id.strip_edges()) as Resource


func assign_creature_to_target(creature_id: String, target_id: String, assignment_type: int) -> Dictionary:
	var creature_key := creature_id.strip_edges()
	var target_key := target_id.strip_edges()
	if not _creatures.has(creature_key):
		return _error("creature_not_registered")
	if not _profiles.has(target_key):
		return _error("character_not_registered")
	if not Enums.is_valid_assignment_type(assignment_type):
		return _error("invalid_assignment_type")
	var assignment := {"creature_id": creature_key, "target_id": target_key, "assignment_type": assignment_type}
	_assignments[target_key] = assignment
	assignment_changed.emit(target_key, assignment.duplicate(true))
	creature_assigned.emit(creature_key, target_key, assignment_type)
	return {"ok": true, "assignment": assignment.duplicate(true)}


func remove_assignment(target_id: String) -> bool:
	var key := target_id.strip_edges()
	if not _assignments.erase(key):
		return false
	assignment_changed.emit(key, {})
	return true


func get_assignment(target_id: String) -> Dictionary:
	return (_assignments.get(target_id.strip_edges(), {}) as Dictionary).duplicate(true)


func start_training(char_id: String, training_type: int, creature_id: String = "") -> Dictionary:
	var key := char_id.strip_edges()
	if not _profiles.has(key):
		return _error("character_not_registered")
	if not Enums.is_valid_training_type(training_type) or training_type == Enums.TrainingType.NONE:
		return _error("invalid_training_type")
	var selected_id := creature_id.strip_edges()
	if selected_id.is_empty():
		selected_id = str(get_assignment(key).get("creature_id", ""))
	var efficiency := 1.0
	if not selected_id.is_empty():
		var creature := get_creature(selected_id)
		if creature == null:
			return _error("creature_not_registered")
		if not bool(creature.call("can_train", training_type)) or not bool(creature.call("is_compatible_with", get_profile(key))):
			return _error("training_incompatible")
		efficiency = float(creature.call("get_training_bonus", training_type))
	var result := _training_system.call("start", key, training_type, selected_id, efficiency) as Dictionary
	if bool(result.get("ok", false)):
		training_started.emit(key, training_type, selected_id)
	return result


func advance_training(char_id: String, delta_time: float) -> Dictionary:
	var key := char_id.strip_edges()
	var result := _training_system.call("advance", key, delta_time) as Dictionary
	if not bool(result.get("ok", false)):
		return result
	var state := result.get("state", {}) as Dictionary
	training_progress.emit(key, float(result.get("progress", 0.0)))
	if bool(result.get("completed", false)):
		var training_type := int(state.get("training_type", Enums.TrainingType.NONE))
		var creature_id := str(state.get("creature_id", ""))
		var creature := get_creature(creature_id)
		var corruption_amount := 5.0
		var submission_power := 5.0
		if creature != null:
			corruption_amount = float(creature.get("corruption_aura")) * float(creature.get("corruption_potency"))
			submission_power = float(creature.get("domination_power")) * 0.25
		var corruption_result := apply_corruption(key, corruption_amount, "training:%s" % creature_id)
		apply_submission(creature_id, key, submission_power, true)
		apply_pleasure(key, 10.0, _experience_for_training(training_type))
		var results := {"corruption": corruption_result, "creature_id": creature_id, "training_type": training_type}
		training_completed.emit(key, training_type, results.duplicate(true))
		result["results"] = results
	return result


func cancel_training(char_id: String) -> bool:
	return bool(_training_system.call("cancel", char_id.strip_edges()))


func is_training(char_id: String) -> bool:
	return bool(_training_system.call("has", char_id.strip_edges()))


func form_bond(master_id: String, slave_id: String, pact_type: int, conditions: Dictionary = {}) -> Dictionary:
	var slave_key := slave_id.strip_edges()
	if master_id.strip_edges().is_empty() or not _profiles.has(slave_key):
		return _error("invalid_bond_participant")
	if not Enums.is_valid_pact_type(pact_type) or pact_type == Enums.PactType.NONE:
		return _error("invalid_pact_type")
	var bond := {"master_id": master_id.strip_edges(), "slave_id": slave_key, "pact_type": pact_type, "conditions": conditions.duplicate(true)}
	_bonds[slave_key] = bond
	bond_formed.emit(str(bond["master_id"]), slave_key, pact_type)
	return {"ok": true, "bond": bond.duplicate(true)}


func break_bond(slave_id: String, reason: String = "") -> bool:
	var key := slave_id.strip_edges()
	if not _bonds.erase(key):
		return false
	bond_broken.emit(key, reason)
	return true


func get_bond(char_id: String) -> Dictionary:
	return (_bonds.get(char_id.strip_edges(), {}) as Dictionary).duplicate(true)


func is_bonded(char_id: String) -> bool:
	return _bonds.has(char_id.strip_edges())


func get_master(char_id: String) -> String:
	return str((_bonds.get(char_id.strip_edges(), {}) as Dictionary).get("master_id", ""))


func process_tick(delta: float, active_characters: Array = []) -> void:
	var allowed: Dictionary = {}
	for raw_id in active_characters:
		allowed[str(raw_id)] = true
	for raw_id in _training_system.call("active_ids") as Array:
		var char_id := str(raw_id)
		if allowed.is_empty() or allowed.has(char_id):
			advance_training(char_id, delta)


func export_state() -> Dictionary:
	return {
		"profiles": _profiles.duplicate(true), "assignments": _assignments.duplicate(true),
		"training": _training_system.call("export_state"), "bonds": _bonds.duplicate(true),
		"history": _history.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	_profiles.clear()
	_assignments.clear()
	_bonds.clear()
	_history.clear()
	var raw_profiles := state.get("profiles", state) as Dictionary
	for raw_id in raw_profiles:
		var raw := raw_profiles.get(raw_id, {}) as Dictionary
		var key := str(raw_id).strip_edges()
		if key.is_empty() or raw.is_empty():
			continue
		var resistance := clampf(float(raw.get("base_resistance", 50.0)), MIN_RESISTANCE, MAX_RESISTANCE)
		register_character(key, resistance, raw.get("traits", []) as Array, int(raw.get("sexual_orientation", 0)), raw.get("virginity", {}) as Dictionary, str(raw.get("image_path", "")))
		var profile := (_profiles[key] as Dictionary).duplicate(true)
		for field in ["level", "resistance", "obedience", "arousal", "perversion", "shame", "fetishes", "experiences", "last_source", "is_adult"]:
			if raw.has(field):
				profile[field] = (raw[field] as Dictionary).duplicate(true) if raw[field] is Dictionary else raw[field]
		profile["level"] = clampf(float(profile.get("level", 0.0)), MIN_LEVEL, MAX_LEVEL)
		profile["stage"] = level_to_stage(float(profile["level"]))
		profile["resistance"] = clampf(float(profile.get("resistance", resistance)), MIN_RESISTANCE, MAX_RESISTANCE)
		profile["obedience"] = clampf(float(profile.get("obedience", 0.0)), MIN_OBEDIENCE, MAX_OBEDIENCE)
		profile["arousal"] = clampf(float(profile.get("arousal", 0.0)), MIN_AROUSAL, MAX_AROUSAL)
		profile["perversion"] = clampf(float(profile.get("perversion", 0.0)), MIN_PERVERSION, MAX_PERVERSION)
		_profiles[key] = profile
	_assignments = _dictionary(state.get("assignments", {}))
	_bonds = _dictionary(state.get("bonds", {}))
	_history = _dictionary(state.get("history", {}))
	_training_system.call("import_state", state.get("training", {}) as Dictionary)


static func level_to_stage(level: float) -> int:
	var normalized_level := clampf(level, MIN_LEVEL, MAX_LEVEL)
	if normalized_level < 20.0:
		return Enums.CorruptionStage.PURE
	if normalized_level < 40.0:
		return Enums.CorruptionStage.TAINTED
	if normalized_level < 60.0:
		return Enums.CorruptionStage.BREAKING
	if normalized_level < 80.0:
		return Enums.CorruptionStage.SUBMISSIVE
	if normalized_level < 95.0:
		return Enums.CorruptionStage.CORRUPTED
	return Enums.CorruptionStage.LOST


static func stage_to_string(stage: int) -> String:
	return ["pure", "tainted", "breaking", "submissive", "corrupted", "lost"][clampi(stage, 0, 5)]


## Alias conservés pour les premiers appels du refactoring.
func get_level(char_id: String) -> float:
	return get_corruption_level(char_id)


func get_stage(char_id: String) -> int:
	return get_corruption_stage(char_id)


func set_level(char_id: String, level: float, source: String = "") -> Dictionary:
	return set_corruption(char_id, level, source)


func apply_purification(char_id: String, amount: float) -> Dictionary:
	return cleanse(char_id, amount)


func apply_corruption_batch(character_ids: Array, amount: float, source: String = "") -> Dictionary:
	var results: Array = []
	for raw_id in character_ids:
		results.append(apply_corruption(str(raw_id), amount, source))
	return {"ok": results.all(func(item): return bool((item as Dictionary).get("ok", false))), "results": results}


func apply_purification_batch(character_ids: Array, amount: float) -> Dictionary:
	var results: Array = []
	for raw_id in character_ids:
		results.append(cleanse(str(raw_id), amount))
	return {"ok": results.all(func(item): return bool((item as Dictionary).get("ok", false))), "results": results}


func corrupt_batch(character_ids: Array, amount: float, source: String = "") -> Dictionary:
	return apply_corruption_batch(character_ids, amount, source)


func purify_batch(character_ids: Array, amount: float) -> Dictionary:
	return apply_purification_batch(character_ids, amount)


func _record(char_id: String, event_type: String, details: Dictionary) -> void:
	var events := (_history.get(char_id, []) as Array).duplicate(true)
	events.append({"type": event_type, "details": details.duplicate(true)})
	_history[char_id] = events


static func _default_virginity(input: Dictionary) -> Dictionary:
	var result := {"vaginal": true, "anal": true, "oral": true}
	for key in input:
		result[str(key)] = bool(input[key])
	return result


static func _experience_for_training(training_type: int) -> int:
	match training_type:
		Enums.TrainingType.ORAL: return Enums.ExperienceType.ORAL
		Enums.TrainingType.ANAL: return Enums.ExperienceType.ANAL
		Enums.TrainingType.SUBMISSION, Enums.TrainingType.OBEDIENCE: return Enums.ExperienceType.SUBMISSIVE
		Enums.TrainingType.DOMINATION: return Enums.ExperienceType.DOMINANT
		Enums.TrainingType.EXHIBITION: return Enums.ExperienceType.EXHIBITION
		Enums.TrainingType.RESTRICTION: return Enums.ExperienceType.BONDAGE
	return Enums.ExperienceType.FETISH


static func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}

## Effets de l’exposition à l’Éther dans les expéditions. Ne modifie pas les stats de base.
func expedition_modifiers(char_id: String) -> Dictionary:
	var stage := get_corruption_stage(char_id)
	return {"initiative": -stage, "magie": -[0, 0, 1, 1, 2, 3][stage], "max_hp": -[0, 0, 0, 4, 8, 12][stage]}

static func stage_display_name(stage: int) -> String:
	return ["Stable", "Altéré", "Fragilisé", "Submergé", "Corrompu", "Critique"][clampi(stage, 0, 5)]

func expedition_description(char_id: String) -> String:
	var profile := get_profile(char_id)
	var modifiers := expedition_modifiers(char_id)
	return "Corruption : %.1f / 100 · %s\nRésistance à l’exposition : %.0f %% ; gain = exposition × (1 − résistance / 100).\nProchain combat : initiative %d, magie %d, PV maximum %d. Les caractéristiques de base restent intactes.\nAu refuge : purifier jusqu’à 10 points pour 4 mana et 1 nourriture. L’Architecture de l’Âme reste verrouillée." % [float(profile.get("level", 0.0)), stage_display_name(get_corruption_stage(char_id)), float(profile.get("resistance", 50.0)), int(modifiers.initiative), int(modifiers.magie), int(modifiers.max_hp)]
