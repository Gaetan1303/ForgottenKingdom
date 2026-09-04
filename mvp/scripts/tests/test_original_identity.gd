extends SceneTree

const NameGeneratorServiceScript = preload("res://scripts/services/name_generator_service.gd")

const HOUSES_PATH := "res://data/world/houses.json"
const CLASSES_PATH := "res://data/classes.json"
const FEATS_PATH := "res://data/feats.json"
const ABILITIES_PATH := "res://data/abilities.json"
const CHAPTERS_PATH := "res://resources/chapters/data.json"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_houses()
	_test_name_generator()
	_test_class_contracts()
	_test_story_identity()
	_finish()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("Fichier absent: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Impossible d'ouvrir: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_failures.append("JSON invalide: %s" % path)
		return {}
	return parsed as Dictionary

func _test_houses() -> void:
	var data := _read_json(HOUSES_PATH)
	var houses := data.get("houses", []) as Array
	if houses.size() != 9:
		_failures.append("Le monde doit contenir exactement 9 Couronnes, trouvé: %d" % houses.size())
	var slugs: Dictionary = {}
	var names: Dictionary = {}
	for item in houses:
		if not item is Dictionary:
			_failures.append("Définition de Maison invalide")
			continue
		var house := item as Dictionary
		var slug := str(house.get("slug", ""))
		var name := str(house.get("nom", ""))
		if slug.is_empty() or name.is_empty():
			_failures.append("Maison sans slug ou nom")
		if slugs.has(slug):
			_failures.append("Slug de Maison dupliqué: %s" % slug)
		if names.has(name):
			_failures.append("Nom de Maison dupliqué: %s" % name)
		slugs[slug] = true
		names[name] = true
		var combativity := int(house.get("combativite", -1))
		if combativity < 0 or combativity > 100:
			_failures.append("Combativité hors limites pour %s" % name)

func _test_name_generator() -> void:
	var generator: RefCounted = NameGeneratorServiceScript.new(1337)
	var generated_names: Dictionary = {}
	for _i in range(24):
		var identity: Dictionary = generator.call("generate_pnj_identity", "garde", "marches") as Dictionary
		var person_name := str(identity.get("nom", ""))
		if person_name.is_empty():
			_failures.append("Le générateur a produit un nom vide")
		var combativity := int(identity.get("combativite", -1))
		if combativity < 0 or combativity > 100:
			_failures.append("Combativité PNJ hors limites")
		if str(identity.get("temperament", "")).is_empty():
			_failures.append("Tempérament PNJ absent")
		generated_names[person_name] = true
	if generated_names.size() < 8:
		_failures.append("Variété de noms insuffisante: %d noms uniques sur 24" % generated_names.size())

	var minor_house: Dictionary = generator.call("generate_minor_house", "marches") as Dictionary
	if not str(minor_house.get("nom", "")).begins_with("Maison "):
		_failures.append("Nom de Maison procédurale invalide")

func _test_class_contracts() -> void:
	var classes := _read_json(CLASSES_PATH)
	var feats := _read_json(FEATS_PATH)
	var abilities := _read_json(ABILITIES_PATH)
	var feat_pool := feats.get("dons", {}) as Dictionary
	if classes.size() != 14:
		_failures.append("14 classes attendues, trouvé: %d" % classes.size())
	for class_id in classes.keys():
		var data := classes[class_id] as Dictionary
		for feat_id in data.get("starting_feats", []) as Array:
			if not feat_pool.has(str(feat_id)):
				_failures.append("%s référence un talent inconnu: %s" % [class_id, feat_id])
		for ability_name in data.get("starting_abilities", []) as Array:
			var found := false
			for ability_id in abilities.keys():
				var ability := abilities[ability_id] as Dictionary
				if str(ability.get("name", "")) == str(ability_name):
					found = true
					break
			if not found:
				_failures.append("%s référence une capacité inconnue: %s" % [class_id, ability_name])

func _test_story_identity() -> void:
	var chapters := _read_json(CHAPTERS_PATH)
	if str(chapters.get("world", "Veyr")) != "Veyr" and JSON.stringify(chapters).find("Veyr") == -1:
		_failures.append("Les chroniques ne référencent pas le monde canonique Veyr")
	var serialized := JSON.stringify(chapters)
	if serialized.find("Neuf Couronnes") == -1:
		_failures.append("Les Neuf Couronnes sont absentes des chroniques principales")

func _finish() -> void:
	if _failures.is_empty():
		print("ORIGINAL_IDENTITY_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	push_error("ORIGINAL_IDENTITY_FAIL: %d erreur(s)" % _failures.size())
	quit(1)
