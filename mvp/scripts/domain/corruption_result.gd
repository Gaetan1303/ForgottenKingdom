class_name CorruptionResult
extends RefCounted

var character_id: String = ""
var source: String = ""
var requested_power: float = 0.0
var applied_power: float = 0.0
var previous_level: float = 0.0
var new_level: float = 0.0
var previous_stage: CorruptionStage.Type = CorruptionStage.Type.PURE
var new_stage: CorruptionStage.Type = CorruptionStage.Type.PURE


func stage_changed() -> bool:
	return previous_stage != new_stage


func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"source": source,
		"requested_power": requested_power,
		"applied_power": applied_power,
		"previous_level": previous_level,
		"new_level": new_level,
		"previous_stage": CorruptionStage.label(previous_stage),
		"new_stage": CorruptionStage.label(new_stage),
		"stage_changed": stage_changed(),
	}
