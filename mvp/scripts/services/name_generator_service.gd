extends RefCounted
class_name NameGeneratorService

const DATA_PATH := "res://data/generation/name_fragments.json"

var _rng := RandomNumberGenerator.new()
var _data: Dictionary = {}

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_data = _load_data()

func generate_person_name(culture: String = "marches") -> String:
	var cultures: Dictionary = _data.get("cultures", {}) as Dictionary
	var selected: Dictionary = cultures.get(culture, cultures.get("marches", {})) as Dictionary
	var first := _compose(selected.get("first_prefix", []) as Array, selected.get("first_suffix", []) as Array)
	var family := _compose(selected.get("family_prefix", []) as Array, selected.get("family_suffix", []) as Array)
	if first.is_empty():
		first = "Aren"
	if family.is_empty():
		family = "Veyr"
	return "%s %s" % [first, family]

func generate_house_name(culture: String = "marches") -> String:
	var cultures: Dictionary = _data.get("cultures", {}) as Dictionary
	var selected: Dictionary = cultures.get(culture, cultures.get("marches", {})) as Dictionary
	var family := _compose(selected.get("family_prefix", []) as Array, selected.get("family_suffix", []) as Array)
	if family.is_empty():
		family = "Veyr"
	return "Maison %s" % family

func generate_minor_house(culture: String = "marches") -> Dictionary:
	var epithets: Array = _data.get("house_epithets", []) as Array
	var name := generate_house_name(culture)
	var epithet := "des Marches"
	if not epithets.is_empty():
		epithet = str(epithets[_rng.randi_range(0, epithets.size() - 1)])
	var combativity := _rng.randi_range(20, 90)
	return {
		"nom": name,
		"titre": "Maison mineure %s" % epithet,
		"combativite": combativity,
		"temperament": temperament_from_combativity(combativity),
	}

func generate_pnj_identity(role: String = "", culture: String = "marches") -> Dictionary:
	var combativity := _combativity_for_role(role)
	combativity = clampi(combativity + _rng.randi_range(-15, 15), 0, 100)
	return {
		"nom": generate_person_name(culture),
		"combativite": combativity,
		"temperament": temperament_from_combativity(combativity),
	}

func temperament_from_combativity(value: int) -> String:
	if value >= 85:
		return "implacable"
	if value >= 70:
		return "belliqueux"
	if value >= 55:
		return "combatif"
	if value >= 40:
		return "résolu"
	if value >= 25:
		return "mesuré"
	return "prudent"

func _combativity_for_role(role: String) -> int:
	match role:
		"ennemi": return 80
		"garde": return 68
		"stratege": return 58
		"eclaireur": return 52
		"mage": return 44
		"diplomate": return 30
		"marchand": return 24
		"villageois": return 20
		_: return 45

func _compose(prefixes: Array, suffixes: Array) -> String:
	if prefixes.is_empty() or suffixes.is_empty():
		return ""
	var prefix := str(prefixes[_rng.randi_range(0, prefixes.size() - 1)])
	var suffix := str(suffixes[_rng.randi_range(0, suffixes.size() - 1)])
	return "%s%s" % [prefix, suffix]

func _load_data() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("NameGeneratorService: fichier de fragments absent: %s" % DATA_PATH)
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	push_warning("NameGeneratorService: JSON invalide")
	return {}
