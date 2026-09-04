## Cycle de training indépendant. Il produit des résultats métier mais ne modifie
## jamais directement ClanManager ni les profils de corruption.
class_name TrainingSystem
extends RefCounted

const DEFAULT_DURATION := 100.0
var _states: Dictionary = {}


func start(char_id: String, training_type: int, creature_id: String, efficiency: float = 1.0) -> Dictionary:
	var key := char_id.strip_edges()
	if key.is_empty():
		return {"ok": false, "error": "invalid_character_id"}
	if _states.has(key):
		return {"ok": false, "error": "training_already_active"}
	var state := {
		"character_id": key,
		"training_type": training_type,
		"creature_id": creature_id.strip_edges(),
		"progress": 0.0,
		"duration": DEFAULT_DURATION,
		"efficiency": maxf(0.1, efficiency),
	}
	_states[key] = state
	return {"ok": true, "state": state.duplicate(true)}


func advance(char_id: String, delta_time: float) -> Dictionary:
	var key := char_id.strip_edges()
	if not _states.has(key):
		return {"ok": false, "error": "training_not_active"}
	var state := (_states[key] as Dictionary).duplicate(true)
	var previous := float(state.get("progress", 0.0))
	var duration := maxf(1.0, float(state.get("duration", DEFAULT_DURATION)))
	var gain := maxf(0.0, delta_time) * maxf(0.1, float(state.get("efficiency", 1.0)))
	var progress := clampf(previous + gain / duration, 0.0, 1.0)
	state["progress"] = progress
	var completed := progress >= 1.0
	if completed:
		_states.erase(key)
	else:
		_states[key] = state
	return {"ok": true, "state": state.duplicate(true), "progress": progress, "completed": completed}


func cancel(char_id: String) -> bool:
	return _states.erase(char_id.strip_edges())


func has(char_id: String) -> bool:
	return _states.has(char_id.strip_edges())


func get_state(char_id: String) -> Dictionary:
	return (_states.get(char_id.strip_edges(), {}) as Dictionary).duplicate(true)


func active_ids() -> Array:
	return _states.keys().duplicate()


func export_state() -> Dictionary:
	return _states.duplicate(true)


func import_state(state: Dictionary) -> void:
	_states.clear()
	for raw_id in state:
		var key := str(raw_id).strip_edges()
		var raw := state.get(raw_id, {}) as Dictionary
		if key.is_empty() or raw.is_empty():
			continue
		_states[key] = {
			"character_id": key,
			"training_type": int(raw.get("training_type", 0)),
			"creature_id": str(raw.get("creature_id", "")),
			"progress": clampf(float(raw.get("progress", 0.0)), 0.0, 0.999999),
			"duration": maxf(1.0, float(raw.get("duration", DEFAULT_DURATION))),
			"efficiency": maxf(0.1, float(raw.get("efficiency", 1.0))),
		}
