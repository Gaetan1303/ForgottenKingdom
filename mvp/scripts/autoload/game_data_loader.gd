## autoload/game_data_loader.gd
## Singleton de chargement des données statiques du jeu.
## Lit les JSON des phases et les données de classes depuis les ressources.
extends Node

# ── Chemins (relatifs à res://) ──────────────────────────────────────
const PATH_CONFIG_TOUR := "res://data/phases/config_tour.json"
const PATH_CHARACTER_TRAITS := "res://data/character_traits.json"
const PATH_LIBRARY_ENTRIES := "res://data/library_entries.json"

# ── Caches ───────────────────────────────────────────────────────────
var _config_tour:  Dictionary = {}
var _actions:      Dictionary = {}  # id → Dictionary
var _classes:      Dictionary = {}  # id → Dictionary (chargé depuis creation_personnage.yaml converti)
var _character_traits: Dictionary = {}
var _library_entries: Dictionary = {}


func _ready() -> void:
	_charger_config_tour()
	_charger_character_traits()
	_charger_library_entries()


# ─────────────────────────────────────────────────────────────────────
#  CHARGEMENT
# ─────────────────────────────────────────────────────────────────────

func _charger_config_tour() -> void:
	var data := _lire_json(PATH_CONFIG_TOUR)
	if data.is_empty():
		push_warning("GameDataLoader: config_tour.json introuvable — chemins relatifs à vérifier.")
		_charger_config_tour_fallback()
		return

	_config_tour = data
	_indexer_actions(data.get("actions", []) as Array)


func _charger_character_traits() -> void:
	var data := _lire_json(PATH_CHARACTER_TRAITS)
	if data.is_empty():
		push_warning("GameDataLoader: character_traits.json introuvable — fallback vide.")
		_character_traits = {
			"dons": {},
			"pouvoirs": {},
			"competences": {},
		}
		return
	_character_traits = data


func _charger_library_entries() -> void:
	var data := _lire_json(PATH_LIBRARY_ENTRIES)
	if data.is_empty():
		push_warning("GameDataLoader: library_entries.json introuvable — fallback vide.")
		_library_entries = {
			"sections": []
		}
		return
	_library_entries = data


## Index les actions par leur ID pour un accès O(1).
func _indexer_actions(liste: Array) -> void:
	_actions.clear()
	for action in liste:
		var d := action as Dictionary
		_actions[d.get("id", "")] = d


## Données de fallback si le JSON n'est pas trouvé (path relatif).
func _charger_config_tour_fallback() -> void:
	_actions = {
		"attaquer":    { "id": "attaquer",    "nom": "Attaquer",     "icone": "", "cout": {"soldats": 10} },
		"espionner":   { "id": "espionner",   "nom": "Espionner",    "icone": "", "cout": {"or": 50, "mana": 10} },
		"recruter":    { "id": "recruter",    "nom": "Recruter",     "icone": "", "cout": {"or": 200} },
		"recruter_pnj":{ "id": "recruter_pnj", "nom": "Recruter PNJ", "icone": "", "cout": {"mana": 45} },
		"diplomatie":{ "id": "diplomatie","nom": "Diplomatie", "icone": "", "cout": {"or": 100, "reputation": 5} },
		"fortifier":   { "id": "fortifier",   "nom": "Fortifier",    "icone": "", "cout": {"or": 300} },
		"recuperer":   { "id": "recuperer",   "nom": "Repos",        "icone": "", "cout": {} },
	}


# ─────────────────────────────────────────────────────────────────────
#  ACCÈS AUX DONNÉES
# ─────────────────────────────────────────────────────────────────────

## Retourne la liste de toutes les actions disponibles.
func get_toutes_actions() -> Array:
	return _actions.values()


## Retourne les données d'une action par son ID.
func get_action(id: String) -> Dictionary:
	return _actions.get(id, {})


## Retourne le coût d'une action pour une classe donnée.
func get_cout_action(action_id: String) -> Dictionary:
	var action := get_action(action_id)
	return action.get("cout", {}) as Dictionary


## Retourne le bonus de classe pour une action donnée.
func get_bonus_classe(action_id: String, classe_id: String) -> int:
	var action := get_action(action_id)
	var bonus_map := action.get("classes_bonus", {}) as Dictionary
	return int(bonus_map.get(classe_id, 0))


## Calcule le seuil de résultat d'une action.
## Retourne : "victoire_eclatante" | "victoire" | "succes_critique" | "succes" |
##            "echec_partiel" | "echec_detecte" | "echec" | "defaite_partielle" | "defaite_totale"
func evaluer_resultat(action_id: String, score: int, resistance: int) -> String:
	var action := get_action(action_id)
	var seuils := action.get("seuils", {}) as Dictionary
	var delta   := score - resistance

	# Pas de seuils définis → l'action réussit toujours (ex : repos, recrutement)
	if seuils.is_empty():
		var resultats := action.get("resultats", {}) as Dictionary
		if resultats.has("succes"):
			return "succes"
		elif not resultats.is_empty():
			return str(resultats.keys()[0])
		return "succes"

	# Ordre d'évaluation du plus favorable au moins favorable
	var ordre := [
		"victoire_eclatante", "succes_critique",
		"victoire",           "succes",
		"echec_partiel",      "defaite_partielle",
		"echec_detecte",      "defaite_totale",
		"echec",
	]

	var dernier_valide: String = ordre[-1]
	for cle in ordre:
		if seuils.has(cle):
			if delta >= int(seuils[cle]):
				return cle
			dernier_valide = cle

	return dernier_valide


## Retourne les effets d'un résultat pour une action.
func get_effets(action_id: String, resultat_id: String) -> Dictionary:
	var action    := get_action(action_id)
	var resultats := action.get("resultats", {}) as Dictionary
	var res_data  := resultats.get(resultat_id, {}) as Dictionary
	return res_data.get("effets", {}) as Dictionary


## Retourne le texte de résultat.
func get_texte_resultat(action_id: String, resultat_id: String) -> String:
	var action    := get_action(action_id)
	var resultats := action.get("resultats", {}) as Dictionary
	var res_data  := resultats.get(resultat_id, {}) as Dictionary
	return res_data.get("texte", "Résultat inconnu.") as String


## Retourne la production par tour depuis la config.
func get_production_par_tour() -> Dictionary:
	return _config_tour.get("production_par_tour", {
		"or": 120, "soldats": 0, "mana": 20, "reputation": 0, "renseignements": 0
	}) as Dictionary


## Retourne la table d'événements aléatoires du tour.
func get_evenements_aleatoires() -> Array:
	return _config_tour.get("evenements_aleatoires", []) as Array


## Retourne les conditions de victoire/défaite.
func get_conditions_victoire() -> Dictionary:
	return _config_tour.get("conditions_victoire", {}) as Dictionary


## Retourne la définition data-driven des effets de création de personnage.
func get_character_traits() -> Dictionary:
	return _character_traits.duplicate(true)


func get_library_entries() -> Dictionary:
	return _library_entries.duplicate(true)


# ─────────────────────────────────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────────────────────────────────

func _lire_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed as Dictionary
