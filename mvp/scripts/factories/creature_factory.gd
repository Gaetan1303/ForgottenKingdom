class_name CreatureFactory
extends RefCounted

func create(
	creature_id: String,
	display_name: String,
	creature_type: String,
	role: String,
	level: int,
	stats: Dictionary,
	traits: Array = [],
	equipment: Array = [],
	behavior: Dictionary = {}
) -> CreatureProfile:
	var profile := CreatureProfile.new()
	profile.id = creature_id
	profile.display_name = display_name
	profile.creature_type = creature_type
	profile.role = role
	profile.level = level
	profile.stats = stats.duplicate(true)
	for trait_value in traits:
		profile.traits.append(str(trait_value))
	profile.equipment = equipment.duplicate(true)
	profile.behavior = behavior.duplicate(true)
	profile.corruption = CorruptionProfile.new(
		creature_id,
		_default_resistance(stats),
		profile.traits
	)
	profile.sanitize()
	return profile


func from_dict(data: Dictionary) -> CreatureProfile:
	return CreatureProfile.from_dict(data)


func _default_resistance(stats: Dictionary) -> float:
	var keys := ["volonte", "commandement", "magie"]
	var total := 0.0
	var count := 0
	for key in keys:
		if stats.has(key):
			total += float(stats.get(key, StatDefs.CHARACTER_MIN_STAT))
			count += 1
	if count == 0:
		return 50.0
	return clampf((total / float(count)) * 10.0, 0.0, 100.0)
