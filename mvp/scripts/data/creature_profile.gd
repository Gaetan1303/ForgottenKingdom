## Profil de domaine sérialisable pour une créature recrutée, alliée ou ennemie.
class_name CreatureProfile
extends Resource

@export var creature_id: String = ""
@export var display_name: String = ""
@export var species_id: String = ""
@export var role: String = "auxiliaire"
@export var level: int = 1
@export var state: String = "disponible"
@export var loyalty: int = 0
@export var corruption: int = 0
@export var stats: Dictionary = {}
@export var traits: Array = []
@export var tags: Array = []
@export var abilities: Array = []
@export var source: String = ""
@export var metadata: Dictionary = {}

const VALID_STATES := ["disponible", "assigne", "en_expedition", "blesse", "indisponible", "ennemi"]


func configure(data: Dictionary) -> CreatureProfile:
	creature_id = str(data.get("id", data.get("creature_id", creature_id))).strip_edges()
	display_name = str(data.get("nom", data.get("display_name", display_name))).strip_edges()
	species_id = str(data.get("species_id", data.get("espece", species_id))).strip_edges()
	role = str(data.get("role", role)).strip_edges()
	level = maxi(1, int(data.get("niveau", data.get("level", level))))
	state = _sanitize_state(str(data.get("etat", data.get("state", state))))
	loyalty = clampi(int(data.get("loyaute", data.get("loyalty", loyalty))), -100, 100)
	corruption = clampi(int(data.get("corruption", corruption)), 0, 100)
	stats = (data.get("stats", {}) as Dictionary).duplicate(true)
	traits = (data.get("traits", []) as Array).duplicate(true)
	tags = (data.get("tags", []) as Array).duplicate(true)
	abilities = (data.get("capacites", data.get("abilities", [])) as Array).duplicate(true)
	source = str(data.get("source", source))
	metadata = (data.get("metadata", {}) as Dictionary).duplicate(true)
	return self


func to_dict() -> Dictionary:
	return {
		"id": creature_id,
		"nom": display_name,
		"species_id": species_id,
		"role": role,
		"niveau": level,
		"etat": state,
		"loyaute": loyalty,
		"corruption": corruption,
		"stats": stats.duplicate(true),
		"traits": traits.duplicate(true),
		"tags": tags.duplicate(true),
		"capacites": abilities.duplicate(true),
		"source": source,
		"metadata": metadata.duplicate(true),
	}


func is_valid() -> bool:
	return not creature_id.is_empty() and not display_name.is_empty()


func is_available() -> bool:
	return state == "disponible"


func set_state(next_state: String) -> bool:
	var sanitized := _sanitize_state(next_state)
	if sanitized != next_state.strip_edges().to_lower():
		return false
	state = sanitized
	return true


static func from_dict(data: Dictionary) -> CreatureProfile:
	return CreatureProfile.new().configure(data)


static func _sanitize_state(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if VALID_STATES.has(normalized):
		return normalized
	return "disponible"
