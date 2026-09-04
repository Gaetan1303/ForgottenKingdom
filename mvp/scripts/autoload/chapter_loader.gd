## autoload/chapter_loader.gd
## Singleton — charge et met en cache les données des chapitres depuis le YAML converti.
## Les chapitres sont stockés dans res://resources/chapters/ en tant que .tres (Dictionary).
extends Node

# Chemins des données (YAML converti en JSON natif Godot ou .tres)
# Le runtime charge resources/chapters/data.json. Le fallback ci-dessous reste entièrement original.
# À terme, un outil de build convertira le YAML → .tres automatiquement.

var _chapters: Array[Dictionary] = []
var _locations: Array[Dictionary] = []
var _is_loaded: bool = false


func _ready() -> void:
	_load_data()


## Retourne tous les chapitres.
func get_chapters() -> Array[Dictionary]:
	return _chapters


## Retourne un chapitre par son index (0-based).
func get_chapter(index: int) -> Dictionary:
	if index < 0 or index >= _chapters.size():
		push_error("ChapterLoader: index %d hors limites (%d chapitres)" % [index, _chapters.size()])
		return {}
	return _chapters[index]


## Retourne le nombre total de chapitres.
func chapter_count() -> int:
	return _chapters.size()


## Retourne tous les lieux de la carte.
func get_locations() -> Array[Dictionary]:
	return _locations


## Retourne un lieu par son identifiant.
func get_location(loc_id: String) -> Dictionary:
	for loc in _locations:
		if loc.get("id", "") == loc_id:
			return loc
	return {}


# --- Chargement interne ---

func _load_data() -> void:
	if _is_loaded:
		return

	# Tente de charger depuis un fichier JSON généré (res://resources/chapters/data.json)
	var json_path := "res://resources/chapters/data.json"
	if ResourceLoader.exists(json_path):
		_load_from_json(json_path)
	else:
		# Fallback : données embarquées (sous-ensemble pour le développement)
		_load_embedded_data()

	_is_loaded = true
	print("ChapterLoader: %d chapitres, %d lieux chargés." % [_chapters.size(), _locations.size()])


func _load_from_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ChapterLoader: impossible d'ouvrir '%s'" % path)
		_load_embedded_data()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		if parsed.has("chapitres"):
			for ch in parsed["chapitres"]:
				_chapters.append(ch)
		if parsed.has("lieux"):
			for loc in parsed["lieux"]:
				_locations.append(loc)
	else:
		push_error("ChapterLoader: JSON invalide dans '%s'" % path)
		_load_embedded_data()


func _load_embedded_data() -> void:
	_chapters.clear()
	_locations.clear()
	_chapters.append({
		"id": 0,
		"titre": "Prologue — La Nuit des Cendres",
		"periode": "Douze ans plus tôt, Marches Libres",
		"illustration": "",
		"musique": "main_theme.ogg",
		"scenes": [
			{"texte": "Le Synode des Neuf Couronnes condamne votre Maison libre. Votre bastion brûle, mais l’héritier survit avec Kael.", "illustration": "", "animation": "idle"},
		]
	})
	_chapters.append({
		"id": 1,
		"titre": "Chapitre I — Le Refuge des Cendres",
		"periode": "Présent, Étendues Grises",
		"illustration": "",
		"musique": "main_theme.ogg",
		"scenes": [
			{"texte": "Un relais minier abandonné devient le premier bastion de votre Maison renaissante.", "illustration": "", "animation": "idle"},
		]
	})
	_locations.append({
		"id": "refuge_des_cendres", "nom": "Refuge des Cendres", "region": "Marches Libres",
		"pos_x": 0.48, "pos_y": 0.68, "chapitre_associe": 1,
		"description": "Premier bastion du clan renaissant."
	})
	_locations.append({
		"id": "citadelle_ivoire", "nom": "Citadelle d’Ivoire", "region": "Domaine Vhalcor",
		"pos_x": 0.72, "pos_y": 0.18, "chapitre_associe": 0,
		"description": "Forteresse de la Maison Vhalcor."
	})
