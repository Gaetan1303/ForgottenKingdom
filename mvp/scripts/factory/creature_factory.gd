## Fabrique les CreatureProfile à partir de données de domaine.
class_name CreatureFactory
extends RefCounted

const CreatureProfileClass = preload("res://scripts/data/creature_profile.gd")
const StatDefs = preload("res://scripts/data/stat_defs.gd")

var _sequence: int = 1


func create_from_dict(data: Dictionary) -> Resource:
	var normalized := data.duplicate(true)
	if str(normalized.get("id", normalized.get("creature_id", ""))).strip_edges().is_empty():
		normalized["id"] = _next_id(str(normalized.get("species_id", normalized.get("espece", "creature"))))
	if str(normalized.get("nom", normalized.get("display_name", ""))).strip_edges().is_empty():
		normalized["nom"] = str(normalized.get("species_id", normalized.get("espece", "Créature"))).capitalize()
	normalized["stats"] = _sanitize_stats(normalized.get("stats", {}) as Dictionary)
	return CreatureProfileClass.from_dict(normalized)


func create_from_species(species: Dictionary, overrides: Dictionary = {}) -> Resource:
	var data := {
		"species_id": str(species.get("id", "creature")),
		"nom": str(species.get("nom", "Créature")),
		"role": str(species.get("role", "auxiliaire")),
		"niveau": maxi(1, int(species.get("niveau", 1))),
		"stats": (species.get("stats", {}) as Dictionary).duplicate(true),
		"traits": (species.get("traits", []) as Array).duplicate(true),
		"capacites": (species.get("capacites", []) as Array).duplicate(true),
		"tags": (species.get("tags", []) as Array).duplicate(true),
		"source": str(species.get("source", "species")),
		"metadata": (species.get("metadata", {}) as Dictionary).duplicate(true),
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return create_from_dict(data)


func create_many(template: Dictionary, count: int) -> Array:
	var result: Array = []
	for _index in range(maxi(0, count)):
		result.append(create_from_dict(template))
	return result


func _next_id(species_id: String) -> String:
	var prefix := species_id.strip_edges().to_lower().replace(" ", "_")
	if prefix.is_empty():
		prefix = "creature"
	var generated := "%s_%04d" % [prefix, _sequence]
	_sequence += 1
	return generated


func _sanitize_stats(input: Dictionary) -> Dictionary:
	var result := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	for key in StatDefs.STAT_KEYS:
		if input.has(key):
			result[key] = clampi(
				int(input.get(key, StatDefs.CHARACTER_MIN_STAT)),
				StatDefs.CHARACTER_MIN_STAT,
				StatDefs.CHARACTER_MAX_STAT
			)
	return result


## API de compatibilité utilisée par ClanManager refactoré.
## Accepte un dictionnaire brut et des surcharges optionnelles sans muter l'entrée.
func generate_profile(data: Dictionary, overrides: Dictionary = {}, context: Dictionary = {}) -> Resource:
	var merged := data.duplicate(true)
	for key in overrides.keys():
		merged[key] = overrides[key]
	if not context.is_empty():
		var metadata := (merged.get("metadata", {}) as Dictionary).duplicate(true)
		for key in context.keys():
			metadata[key] = context[key]
		merged["metadata"] = metadata
	return create_from_dict(merged)
