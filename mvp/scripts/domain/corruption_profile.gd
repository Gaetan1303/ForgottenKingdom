class_name CorruptionProfile
extends Resource

@export var character_id: String = ""
@export_range(0.0, 100.0, 0.1) var level: float = 0.0
@export_range(0.0, 100.0, 0.1) var base_resistance: float = 50.0
@export var traits: Array[String] = []
@export var stage: CorruptionStage.Type = CorruptionStage.Type.PURE


func _init(
	p_character_id: String = "",
	p_base_resistance: float = 50.0,
	p_traits: Array[String] = []
) -> void:
	character_id = p_character_id
	base_resistance = clampf(p_base_resistance, 0.0, 100.0)
	traits = p_traits.duplicate()
	recompute_stage()


func set_level(value: float) -> void:
	level = clampf(value, CorruptionStage.MIN_LEVEL, CorruptionStage.MAX_LEVEL)
	recompute_stage()


func recompute_stage() -> void:
	level = clampf(level, CorruptionStage.MIN_LEVEL, CorruptionStage.MAX_LEVEL)
	base_resistance = clampf(base_resistance, 0.0, 100.0)
	stage = CorruptionStage.from_level(level)


func to_dict() -> Dictionary:
	recompute_stage()
	return {
		"character_id": character_id,
		"level": level,
		"base_resistance": base_resistance,
		"traits": traits.duplicate(),
		"stage": CorruptionStage.label(stage),
	}


static func from_dict(data: Dictionary, fallback_id: String = "") -> CorruptionProfile:
	var profile := CorruptionProfile.new(
		str(data.get("character_id", fallback_id)),
		float(data.get("base_resistance", 50.0)),
		_to_string_array(data.get("traits", []))
	)
	profile.level = clampf(float(data.get("level", 0.0)), 0.0, 100.0)
	profile.recompute_stage()
	return profile


static func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
