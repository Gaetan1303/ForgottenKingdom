## autoload/chapter_loader.gd
## Singleton — charge et met en cache les données des chapitres depuis le YAML converti.
## Les chapitres sont stockés dans res://resources/chapters/ en tant que .tres (Dictionary).
extends Node

# Chemins des données (YAML converti en JSON natif Godot ou .tres)
# Pour le MVP, on encode les données directement en GDScript (source de vérité = chapitres_ingrid.yaml).
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
	# Fallback minimal — utiliser res://resources/chapters/data.json de préférence.
	_chapters.clear()
	_chapters.append({
		"id": 0,
		"titre": "Prologue — L'Ange Tombé",
		"periode": "Antiquité, Demon Realm",
		"illustration": "prologue_bg.png",
		"musique": "dark_ambient_01.ogg",
		"scenes": [
			{
				"texte": "[color=#cc99ff]Ingrid[/color] — autrefois une Sainte du Paradis, aujourd'hui exilée dans les Royaumes Démoniques. Sa beauté n'a d'égale que la puissance du feu violet qui consume ses ailes brisées.",
				"illustration": "ingrid_exile.png",
				"animation": "wings_break"
			},
			{
				"texte": "Les anciens textes la nomment [i]Schwarze Hexe[/i] — la Sorcière Noire. Mais pour les démons qui l'ont accueillie comme l'une des Neuf Nobles, elle est simplement... Ingrid.",
				"illustration": "ingrid_portrait_01.png",
				"animation": "idle"
			},
		]
	})
	_chapters.append({
		"id": 1,
		"titre": "Chapitre I — Le Sang du Pacte",
		"periode": "Antiquité",
		"illustration": "chapter01_bg.png",
		"musique": "demon_realm_theme.ogg",
		"scenes": [
			{
				"texte": "Dans les profondeurs des Royaumes Démoniques, Ingrid scella son premier pacte avec le sang. Une flamme violette naquit de sa paume — marque indélébile de sa nouvelle nature.",
				"illustration": "ingrid_pact.png",
				"animation": "flame_birth"
			},
		]
	})

	_locations.clear()
	_locations.append({
		"id": "demon_realm_citadel",
		"nom": "Citadelle des Nobles",
		"region": "Demon Realm",
		"pos_x": 0.52,
		"pos_y": 0.22,
		"chapitre_associe": 0,
		"description": "Forteresse ancestrale des Neuf Nobles du Royaume Démoniaque."
	})
	_locations.append({
		"id": "yomihara",
		"nom": "Yomihara",
		"region": "Japon contemporain",
		"pos_x": 0.85,
		"pos_y": 0.20,
		"chapitre_associe": 2,
		"description": "Ville japonaise à l'intersection du monde humain et du Royaume Démoniaque."
	})
	_locations.append({
		"id": "palais_tenebres_yomihara",
		"nom": "Palais des Ténèbres",
		"region": "Yomihara",
		"pos_x": 0.83,
		"pos_y": 0.24,
		"chapitre_associe": 2,
		"description": "Siège du clan d'Ingrid à Yomihara. Une bâtisse imposante qui cache son vrai visage aux humains."
	})
	_locations.append({
		"id": "blackport",
		"nom": "Blackport",
		"region": "Demon Realm",
		"pos_x": 0.08,
		"pos_y": 0.36,
		"chapitre_associe": -1,
		"description": "Port marchand sur la côte occidentale du Royaume Démoniaque."
	})
	_locations.append({
		"id": "corpse_lord",
		"nom": "Corpse Lord",
		"region": "Demon Realm",
		"pos_x": 0.18,
		"pos_y": 0.40,
		"chapitre_associe": -1,
		"description": "Région hantée gouvernée par les morts."
	})
	_locations.append({
		"id": "beowulf_territory",
		"nom": "Beowulf Territory",
		"region": "Demon Realm",
		"pos_x": 0.12,
		"pos_y": 0.68,
		"chapitre_associe": -1,
		"description": "Ancienne terra de guerriers et de bandits."
	})
	_locations.append({
		"id": "rollo_viscounty",
		"nom": "Rollo Viscounty",
		"region": "Demon Realm",
		"pos_x": 0.20,
		"pos_y": 0.70,
		"chapitre_associe": -1,
		"description": "Comté fortifié entre la côte et les plaines."
	})
	_locations.append({
		"id": "prime_minister",
		"nom": "Prime Minister",
		"region": "Demon Realm",
		"pos_x": 0.34,
		"pos_y": 0.78,
		"chapitre_associe": -1,
		"description": "Siège administratif proche des grandes routes."
	})
	_locations.append({
		"id": "gate_city",
		"nom": "Gate City",
		"region": "Demon Realm",
		"pos_x": 0.52,
		"pos_y": 0.60,
		"chapitre_associe": -1,
		"description": "Ville carrefour qui contrôle l'accès aux terres inconnues."
	})
	_locations.append({
		"id": "unknown_land",
		"nom": "Unknown Land",
		"region": "Demon Realm",
		"pos_x": 0.52,
		"pos_y": 0.46,
		"chapitre_associe": -1,
		"description": "Étendue mystérieuse aux frontières floues."
	})
	_locations.append({
		"id": "blood_lord",
		"nom": "Blood Lord",
		"region": "Demon Realm",
		"pos_x": 0.48,
		"pos_y": 0.16,
		"chapitre_associe": -1,
		"description": "Domaine central des seigneurs du sang."
	})
	_locations.append({
		"id": "lake_vivian",
		"nom": "Lake Vivian",
		"region": "Demon Realm",
		"pos_x": 0.74,
		"pos_y": 0.56,
		"chapitre_associe": -1,
		"description": "Lac mystérieux aux eaux changeantes."
	})
	_locations.append({
		"id": "flame_end",
		"nom": "Flame End",
		"region": "Demon Realm",
		"pos_x": 0.82,
		"pos_y": 0.44,
		"chapitre_associe": -1,
		"description": "Extrémité fumante de la côte orientale."
	})
	_locations.append({
		"id": "phantom_lord",
		"nom": "Phantom Lord",
		"region": "Demon Realm",
		"pos_x": 0.78,
		"pos_y": 0.12,
		"chapitre_associe": -1,
		"description": "Terres spectrales au nord-est."
	})
	_locations.append({
		"id": "kings_rock",
		"nom": "King's Rock",
		"region": "Demon Realm",
		"pos_x": 0.10,
		"pos_y": 0.86,
		"chapitre_associe": -1,
		"description": "Promontoire rocheux légendaire."
	})
	_locations.append({
		"id": "richster_territory",
		"nom": "Richster Territory",
		"region": "Demon Realm",
		"pos_x": 0.60,
		"pos_y": 0.82,
		"chapitre_associe": -1,
		"description": "Terres agricoles du sud-est."
	})
	_locations.append({
		"id": "wise_lord",
		"nom": "Wise Lord",
		"region": "Demon Realm",
		"pos_x": 0.56,
		"pos_y": 0.74,
		"chapitre_associe": -1,
		"description": "Domaine d'un ancien sage."
	})
	_locations.append({
		"id": "margrave_iclingas",
		"nom": "Margrave Iclingas Territory",
		"region": "Demon Realm",
		"pos_x": 0.18,
		"pos_y": 0.06,
		"chapitre_associe": -1,
		"description": "Région glacée au nord-ouest."
	})
	_locations.append({
		"id": "werewolves",
		"nom": "Werewolves",
		"region": "Demon Realm",
		"pos_x": 0.38,
		"pos_y": 0.08,
		"chapitre_associe": -1,
		"description": "Bois sauvages infâmes pour leurs meutes."
	})
	_locations.append({
		"id": "frost_demons",
		"nom": "Frost Demons",
		"region": "Demon Realm",
		"pos_x": 0.50,
		"pos_y": 0.02,
		"chapitre_associe": -1,
		"description": "Région polaire hantée par des démons de gel."
	})
	_locations.append({
		"id": "blackport",
		"nom": "Blackport",
		"region": "Demon Realm",
		"pos_x": 0.08,
		"pos_y": 0.36,
		"chapitre_associe": -1,
		"description": "Port marchand sur la côte occidentale du Royaume Démoniaque."
	})
	_locations.append({
		"id": "corpse_lord",
		"nom": "Corpse Lord",
		"region": "Demon Realm",
		"pos_x": 0.18,
		"pos_y": 0.40,
		"chapitre_associe": -1,
		"description": "Région hantée gouvernée par les morts."
	})
	_locations.append({
		"id": "beowulf_territory",
		"nom": "Beowulf Territory",
		"region": "Demon Realm",
		"pos_x": 0.12,
		"pos_y": 0.68,
		"chapitre_associe": -1,
		"description": "Ancienne terra de guerriers et de bandits."
	})
	_locations.append({
		"id": "rollo_viscounty",
		"nom": "Rollo Viscounty",
		"region": "Demon Realm",
		"pos_x": 0.20,
		"pos_y": 0.70,
		"chapitre_associe": -1,
		"description": "Comté fortifié entre la côte et les plaines."
	})
	_locations.append({
		"id": "prime_minister",
		"nom": "Prime Minister",
		"region": "Demon Realm",
		"pos_x": 0.34,
		"pos_y": 0.78,
		"chapitre_associe": -1,
		"description": "Siège administratif proche des grandes routes."
	})
	_locations.append({
		"id": "gate_city",
		"nom": "Gate City",
		"region": "Demon Realm",
		"pos_x": 0.52,
		"pos_y": 0.60,
		"chapitre_associe": -1,
		"description": "Ville carrefour qui contrôle l'accès aux terres inconnues."
	})
	_locations.append({
		"id": "unknown_land",
		"nom": "Unknown Land",
		"region": "Demon Realm",
		"pos_x": 0.52,
		"pos_y": 0.46,
		"chapitre_associe": -1,
		"description": "Étendue mystérieuse aux frontières floues."
	})
	_locations.append({
		"id": "blood_lord",
		"nom": "Blood Lord",
		"region": "Demon Realm",
		"pos_x": 0.48,
		"pos_y": 0.16,
		"chapitre_associe": -1,
		"description": "Domaine central des seigneurs du sang."
	})
	_locations.append({
		"id": "lake_vivian",
		"nom": "Lake Vivian",
		"region": "Demon Realm",
		"pos_x": 0.74,
		"pos_y": 0.56,
		"chapitre_associe": -1,
		"description": "Lac mystérieux aux eaux changeantes."
	})
	_locations.append({
		"id": "flame_end",
		"nom": "Flame End",
		"region": "Demon Realm",
		"pos_x": 0.82,
		"pos_y": 0.44,
		"chapitre_associe": -1,
		"description": "Extrémité fumante de la côte orientale."
	})
	_locations.append({
		"id": "phantom_lord",
		"nom": "Phantom Lord",
		"region": "Demon Realm",
		"pos_x": 0.78,
		"pos_y": 0.12,
		"chapitre_associe": -1,
		"description": "Terres spectrales au nord-est."
	})
	_locations.append({
		"id": "kings_rock",
		"nom": "King's Rock",
		"region": "Demon Realm",
		"pos_x": 0.10,
		"pos_y": 0.86,
		"chapitre_associe": -1,
		"description": "Promontoire rocheux légendaire."
	})
	_locations.append({
		"id": "richster_territory",
		"nom": "Richster Territory",
		"region": "Demon Realm",
		"pos_x": 0.60,
		"pos_y": 0.82,
		"chapitre_associe": -1,
		"description": "Terres agricoles du sud-est."
	})
	_locations.append({
		"id": "wise_lord",
		"nom": "Wise Lord",
		"region": "Demon Realm",
		"pos_x": 0.56,
		"pos_y": 0.74,
		"chapitre_associe": -1,
		"description": "Domaine d'un ancien sage."
	})
	_locations.append({
		"id": "margrave_iclingas",
		"nom": "Margrave Iclingas Territory",
		"region": "Demon Realm",
		"pos_x": 0.18,
		"pos_y": 0.06,
		"chapitre_associe": -1,
		"description": "Région glacée au nord-ouest."
	})
	_locations.append({
		"id": "werewolves",
		"nom": "Werewolves",
		"region": "Demon Realm",
		"pos_x": 0.38,
		"pos_y": 0.08,
		"chapitre_associe": -1,
		"description": "Bois sauvages infâmes pour leurs meutes."
	})
	_locations.append({
		"id": "frost_demons",
		"nom": "Frost Demons",
		"region": "Demon Realm",
		"pos_x": 0.50,
		"pos_y": 0.02,
		"chapitre_associe": -1,
		"description": "Région polaire hantée par des démons de gel."
	})
