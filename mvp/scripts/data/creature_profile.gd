## Modèle unique d'une créature. Les alias legacy sont conservés à la frontière
## de sérialisation pour que les anciens rosters restent chargeables.
class_name CreatureProfile
extends Resource

const Enums = preload("res://scripts/core/enums.gd")

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var species_id: String = ""
@export var creature_type: int = Enums.CreatureType.LESSER_DEMON
@export var roles: Array[int] = []
@export var capabilities: Array[int] = []
@export var role: String = "auxiliaire"
@export var state: String = "disponible"

@export_group("Stats")
@export var level: int = 1
@export var corruption_aura: float = 10.0
@export var corruption_potency: float = 1.0
@export var domination_power: float = 20.0
@export var domination_presence: float = 15.0
@export var training_efficiency: float = 1.0
@export var loyalty: float = 50.0
@export var corruption: float = 0.0
@export var stats: Dictionary = {}
@export var traits: Array = []
@export var tags: Array = []
@export var abilities: Array = []

@export_group("Sexual")
@export var sexual_orientation: int = 0
@export var pheromone_strength: float = 0.0
@export var physical_endurance: float = 50.0
@export var technique_level: int = 1
@export var fertility: float = 0.0
@export var addictive_fluids: bool = false
@export var preferred_trainings: Array[int] = []
@export var forbidden_trainings: Array[int] = []

@export_group("Visual")
@export var portrait_path: String = ""
@export var cg_paths: Dictionary = {}
@export var animation_path: String = ""

@export_group("AI")
@export var aggression: float = 50.0
@export var patience: float = 50.0
@export var creativity: float = 50.0

@export_group("Compatibility")
@export var source: String = ""
@export var metadata: Dictionary = {}
@export var equipment: Array = []
@export var behavior: Dictionary = {}

const VALID_STATES := ["disponible", "assigne", "en_expedition", "blesse", "indisponible", "ennemi"]

## Alias de lecture pour le format historique.
var creature_id: String:
	get:
		return id
	set(value):
		id = value


func configure(data: Dictionary) -> CreatureProfile:
	id = str(data.get("id", data.get("creature_id", id))).strip_edges()
	display_name = str(data.get("nom", data.get("display_name", display_name))).strip_edges()
	description = str(data.get("description", description))
	species_id = str(data.get("species_id", data.get("espece", species_id))).strip_edges()
	creature_type = int(data.get("creature_type", creature_type))
	roles = _to_int_array(data.get("roles", roles))
	capabilities = _to_int_array(data.get("capabilities", capabilities))
	role = str(data.get("role", role)).strip_edges()
	state = _sanitize_state(str(data.get("etat", data.get("state", state))))
	level = maxi(1, int(data.get("niveau", data.get("level", level))))
	corruption_aura = maxf(0.0, float(data.get("corruption_aura", corruption_aura)))
	corruption_potency = maxf(0.0, float(data.get("corruption_potency", corruption_potency)))
	domination_power = maxf(0.0, float(data.get("domination_power", domination_power)))
	domination_presence = maxf(0.0, float(data.get("domination_presence", domination_presence)))
	training_efficiency = maxf(0.0, float(data.get("training_efficiency", training_efficiency)))
	loyalty = clampf(float(data.get("loyaute", data.get("loyalty", loyalty))), -100.0, 100.0)
	corruption = clampf(float(data.get("corruption", corruption)), 0.0, 100.0)
	stats = _dict(data.get("stats", stats))
	traits = _array(data.get("traits", traits))
	tags = _array(data.get("tags", tags))
	abilities = _array(data.get("capacites", data.get("abilities", abilities)))
	sexual_orientation = int(data.get("sexual_orientation", data.get("orientation", sexual_orientation)))
	pheromone_strength = clampf(float(data.get("pheromone_strength", pheromone_strength)), 0.0, 100.0)
	physical_endurance = clampf(float(data.get("physical_endurance", physical_endurance)), 0.0, 100.0)
	technique_level = maxi(1, int(data.get("technique_level", technique_level)))
	fertility = clampf(float(data.get("fertility", fertility)), 0.0, 100.0)
	addictive_fluids = bool(data.get("addictive_fluids", addictive_fluids))
	preferred_trainings = _to_int_array(data.get("preferred_trainings", preferred_trainings))
	forbidden_trainings = _to_int_array(data.get("forbidden_trainings", forbidden_trainings))
	portrait_path = str(data.get("portrait_path", data.get("image_path", portrait_path)))
	cg_paths = _dict(data.get("cg_paths", cg_paths))
	animation_path = str(data.get("animation_path", animation_path))
	aggression = clampf(float(data.get("aggression", aggression)), 0.0, 100.0)
	patience = clampf(float(data.get("patience", patience)), 0.0, 100.0)
	creativity = clampf(float(data.get("creativity", creativity)), 0.0, 100.0)
	source = str(data.get("source", source))
	metadata = _dict(data.get("metadata", metadata))
	equipment = _array(data.get("equipment", equipment))
	behavior = _dict(data.get("behavior", behavior))
	return self


func to_dict() -> Dictionary:
	return {
		"id": id, "creature_id": id, "nom": display_name, "display_name": display_name,
		"description": description, "species_id": species_id, "creature_type": creature_type,
		"roles": roles.duplicate(), "capabilities": capabilities.duplicate(), "role": role,
		"etat": state, "niveau": level, "corruption_aura": corruption_aura,
		"corruption_potency": corruption_potency, "domination_power": domination_power,
		"domination_presence": domination_presence, "training_efficiency": training_efficiency,
		"loyaute": loyalty, "corruption": corruption, "stats": stats.duplicate(true),
		"traits": traits.duplicate(true), "tags": tags.duplicate(true),
		"capacites": abilities.duplicate(true), "sexual_orientation": sexual_orientation,
		"pheromone_strength": pheromone_strength, "physical_endurance": physical_endurance,
		"technique_level": technique_level, "fertility": fertility,
		"addictive_fluids": addictive_fluids,
		"preferred_trainings": preferred_trainings.duplicate(),
		"forbidden_trainings": forbidden_trainings.duplicate(), "portrait_path": portrait_path,
		"cg_paths": cg_paths.duplicate(true), "animation_path": animation_path,
		"aggression": aggression, "patience": patience, "creativity": creativity,
		"source": source, "metadata": metadata.duplicate(true),
		"equipment": equipment.duplicate(true), "behavior": behavior.duplicate(true),
	}


func is_valid() -> bool:
	return not id.is_empty() and not display_name.is_empty()


func is_available() -> bool:
	return state == "disponible"


func set_state(next_state: String) -> bool:
	var normalized := next_state.strip_edges().to_lower()
	if normalized not in VALID_STATES:
		return false
	state = normalized
	return true


func can_train(training_type: int) -> bool:
	return Enums.is_valid_training_type(training_type) and training_type != Enums.TrainingType.NONE and training_type not in forbidden_trainings


func is_compatible_with(target_profile: Dictionary) -> bool:
	if not bool(target_profile.get("is_adult", true)):
		return false
	var blocked_tags := target_profile.get("forbidden_creature_tags", []) as Array
	for tag in tags:
		if tag in blocked_tags:
			return false
	return true


func calculate_corruption_output(target_stage: int, delta: float) -> float:
	var stage_factor := clampf(1.0 - float(target_stage) * 0.08, 0.5, 1.0)
	return maxf(0.0, corruption_aura * corruption_potency * maxf(0.0, delta) * stage_factor)


func get_training_bonus(training_type: int) -> float:
	if not can_train(training_type):
		return 0.0
	var preference_bonus := 0.25 if training_type in preferred_trainings else 0.0
	return maxf(0.0, training_efficiency + preference_bonus + float(technique_level - 1) * 0.05)


func generate_training_scene(training_type: int, target_profile: Dictionary) -> Dictionary:
	if not can_train(training_type) or not is_compatible_with(target_profile):
		return {"ok": false, "error": "training_incompatible"}
	return {
		"ok": true, "scene_id": "%s_training_%d" % [id, training_type], "creature_id": id,
		"target_id": str(target_profile.get("character_id", target_profile.get("id", ""))),
		"training_type": training_type, "animation_path": animation_path,
		"cg_path": str(cg_paths.get(training_type, cg_paths.get(str(training_type), ""))),
		"effects": {"corruption": corruption_aura * corruption_potency, "submission": domination_power, "arousal": pheromone_strength},
	}


static func from_dict(data: Dictionary) -> CreatureProfile:
	return CreatureProfile.new().configure(data)


static func _sanitize_state(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	return normalized if normalized in VALID_STATES else "disponible"


static func _array(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


static func _dict(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _to_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(int(item))
	return result
