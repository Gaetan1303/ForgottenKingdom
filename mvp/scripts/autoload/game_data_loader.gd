## autoload/game_data_loader.gd
## Singleton de chargement des données statiques du jeu.
## Lit les JSON des phases et les données de classes depuis les ressources.
extends Node

# ── Chemins (relatifs à res://) ──────────────────────────────────────
const PATH_CONFIG_TOUR := "res://data/phases/config_tour.json"
const PATH_CHARACTER_TRAITS := "res://data/character_traits.json"
const PATH_LIBRARY_ENTRIES := "res://data/library_entries.json"
const PATH_CLASSES := "res://data/classes.json"
const PATH_FEATS := "res://data/feats.json"

# ── Caches ───────────────────────────────────────────────────────────
var _config_tour:  Dictionary = {}
var _actions:      Dictionary = {}  # id → Dictionary
var _classes:      Dictionary = {}  # id → Dictionary (chargé depuis creation_personnage.yaml converti)
var _character_traits: Dictionary = {}
var _library_entries: Dictionary = {}
var _feats:         Dictionary = {}
var _abilities:     Dictionary = {}
signal reloaded


func _ready() -> void:
	_charger_config_tour()
	_charger_character_traits()
	_charger_library_entries()
	_charger_classes()
	_charger_feats()


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


func _charger_classes() -> void:
	var data := _lire_json(PATH_CLASSES)
	if data.is_empty():
		push_warning("GameDataLoader: classes.json introuvable — fallback vide.")
		_classes = {}
		return
	_classes = data


func _charger_feats() -> void:
	var data := _lire_json(PATH_FEATS)
	if data.is_empty():
		push_warning("GameDataLoader: feats.json introuvable — fallback vide.")
		_feats = {}
		return
	_feats = data


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


## Retourne toutes les classes chargées (id -> definition)
func get_classes() -> Dictionary:
	return _classes.duplicate(true)


## Retourne la définition d'une classe par son id
func get_class_by_id(id: String) -> Dictionary:
	return _classes.get(str(id), {}) as Dictionary


## Retourne toutes les définitions de feats/dons
func get_feats() -> Dictionary:
	return _feats.duplicate(true)


## Retourne la définition d'un don par son id
func get_feat(id: String) -> Dictionary:
	return _feats.get(str(id), {}) as Dictionary


## Retourne toutes les capacités connues (id -> definition)
func get_abilities() -> Dictionary:
	if _abilities.size() > 0:
		return _abilities.duplicate(true)

	# Si un fichier res://data/abilities.json existe, l'utiliser
	var path := "res://data/abilities.json"
	if FileAccess.file_exists(path):
		var parsed := _lire_json(path)
		if not parsed.is_empty():
			_abilities = parsed.duplicate(true)
			return _abilities.duplicate(true)

	# Sinon dériver des classes (starting_abilities)
	var out: Dictionary = {}
	for cid in _classes.keys():
		var entry := _classes[cid] as Dictionary
		var arr := entry.get("starting_abilities", []) as Array
		for a in arr:
			var name := str(a).strip_edges()
			var id := _slugify(name)
			if not out.has(id):
				out[id] = {
					"id": id,
					"name": name,
					"description": _find_library_entry_description(name),
					"from_classes": [cid],
				}
			else:
				var fc := out[id].get("from_classes", []) as Array
				if not fc.has(cid):
					fc.append(cid)
					out[id]["from_classes"] = fc

	_abilities = out
	return _abilities.duplicate(true)


func get_ability_by_id(id: String) -> Dictionary:
	var idn := str(id)
	var abs := get_abilities()
	return abs.get(idn, {}) as Dictionary


func get_feats_for_ability(ability_id: String) -> Dictionary:
	# Tentative: retourne les feats dont le nom ou la description contient le nom de la capacité.
	var abil := get_ability_by_id(ability_id)
	var aname := str(abil.get("name", "")).to_lower()
	var out: Dictionary = {}
	for fid in _feats.keys():
		var f := _feats[fid] as Dictionary
		var fname := str(f.get("name", "")).to_lower()
		var fdesc := str(f.get("description", "")).to_lower()
		if aname != "" and (fname.find(aname) != -1 or fdesc.find(aname) != -1):
			out[fid] = f

	if out.size() == 0:
		return _feats.duplicate(true)
	return out.duplicate(true)


## Helpers internes
func _slugify(s: String) -> String:
	return str(s).strip_edges().to_lower().replace(" ", "_").replace("-", "_")


func _find_library_entry_description(name: String) -> String:
	var title := str(name).strip_edges().to_lower()
	var secs := _library_entries.get("sections", []) as Array
	for sec in secs:
		var entries := sec.get("entries", []) as Array
		for e in entries:
			if str(e.get("title", "")).to_lower() == title:
				return str(e.get("text", ""))
	return ""


## Recharge dynamiquement toutes les données chargées par le GameDataLoader.
## Utilisez ceci pour forcer un rechargement lors du développement ou runtime.
func reload() -> void:
	_charger_config_tour()
	_charger_character_traits()
	_charger_library_entries()
	_charger_classes()
	_charger_feats()
	# Re-indexer les actions au cas où config_tour a changé
	_indexer_actions(_config_tour.get("actions", []) as Array)
	print("GameDataLoader: données rechargées.")
	emit_signal("reloaded")


# ── Résolution d'icônes de classes (automatique / chemins relatifs) ───
## Retourne un chemin `res://...` vers l'icône si trouvée, sinon chaîne vide.
func get_class_icon_path(class_id: String) -> String:
	var cid := str(class_id)
	if cid == "":
		return ""
	# Prefer explicit icon declared in class definition
	var entry := _classes.get(cid, {}) as Dictionary
	var explicit := str(entry.get("icon", "")).strip_edges()
	if explicit != "":
		if explicit.begins_with("res://"):
			if ResourceLoader.exists(explicit):
				return explicit
		else:
			var cand := "res://" + explicit.strip_edges()
			if ResourceLoader.exists(cand):
				return cand
			var cand2 := "res://mvp/" + explicit.strip_edges()
			if ResourceLoader.exists(cand2):
				return cand2

	# Cherche automatiquement dans des dossiers d'assets communs
	var icon_dirs: Array = [
		"res://assets/class_icons/",
		"res://mvp/assets/class_icons/",
		"res://mvp/assets/class_icons/",
	]
	var exts: Array = [".webp", ".png", ".jpg", ".jpeg"]
	for d in icon_dirs:
		for e in exts:
			var p: String = str(d) + str(cid) + str(e)
			if ResourceLoader.exists(p):
				return p

	# essayer variantes minuscules et snake_case
	var low := cid.to_lower()
	if low != cid:
		for d in icon_dirs:
			for e in exts:
				var p: String = str(d) + str(low) + str(e)
				if ResourceLoader.exists(p):
					return p
	var slug := cid.replace(" ", "_").to_lower()
	if slug != cid and slug != low:
		for d in icon_dirs:
			for e in exts:
				var p: String = str(d) + str(slug) + str(e)
				if ResourceLoader.exists(p):
					return p

	# fallback global (si présent)
	var fallback := "res://mvp/assets/class_icons/chevalier_sombre.png"
	if ResourceLoader.exists(fallback):
		return fallback
	return ""


## Retourne une `Texture2D` pour l'icône de classe, ou null si introuvable.
func get_class_icon(class_id: String) -> Texture2D:
	var path := get_class_icon_path(class_id)
	if path == "":
		return null
	var r := ResourceLoader.load(path)
	if r == null:
		return null
	if r is Texture2D:
		return r as Texture2D
	if r is Image:
		return ImageTexture.create_from_image(r)
	return null


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
