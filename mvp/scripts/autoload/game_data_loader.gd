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
const PATH_ABILITIES := "res://data/abilities.json"
const PATH_EQUIPMENT := "res://data/equipment.json"
const PATH_PROGRESSION_DIR := "res://data/progression"

# ── Caches ───────────────────────────────────────────────────────────
var _config_tour:  Dictionary = {}
var _actions:      Dictionary = {}  # id → Dictionary
var _classes:      Dictionary = {}  # id → Dictionary (chargé depuis creation_personnage.yaml converti)
var _character_traits: Dictionary = {}
var _library_entries: Dictionary = {}
var _feats:         Dictionary = {}
var _abilities:     Dictionary = {}
var _equipment:     Dictionary = {}
var _class_progressions: Dictionary = {}
signal reloaded


func _ready() -> void:
	_charger_config_tour()
	_charger_character_traits()
	_charger_library_entries()
	_charger_classes()
	_charger_class_progressions()
	_charger_feats()
	_charger_equipment()


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


func _charger_class_progressions() -> void:
	_class_progressions = {}
	if not DirAccess.dir_exists_absolute(PATH_PROGRESSION_DIR):
		push_warning("GameDataLoader: dossier progression introuvable — fallback vide.")
		return

	var dir := DirAccess.open(PATH_PROGRESSION_DIR)
	if dir == null:
		push_warning("GameDataLoader: impossible d'ouvrir le dossier progression.")
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.to_lower().ends_with(".csv"):
			var full_path := "%s/%s" % [PATH_PROGRESSION_DIR, fname]
			var rows := _lire_progression_csv(full_path)
			if rows.size() > 0:
				var class_id := _resolve_class_id_from_progression_filename(fname)
				if class_id != "":
					_class_progressions[class_id] = rows
		fname = dir.get_next()
	dir.list_dir_end()


const PROGRESSION_FILENAME_TO_CLASS_ID := {
	"berserkdemon": "berserker_demon",
	"infernalartificier": "infernal_artificer",
}

func _resolve_class_id_from_progression_filename(file_name: String) -> String:
	var base_name := file_name.get_basename().to_lower()
	if PROGRESSION_FILENAME_TO_CLASS_ID.has(base_name):
		return PROGRESSION_FILENAME_TO_CLASS_ID[base_name]
	var target := _normalize_id_token(base_name)
	for key in _classes.keys():
		if _normalize_id_token(str(key)) == target:
			return str(key)
	return ""


func _normalize_id_token(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("_", "").replace("-", "")


func _split_csv_line(line: String) -> Array[String]:
	var out: Array[String] = []
	var current := ""
	var in_quotes := false
	for i in range(line.length()):
		var ch := line.substr(i, 1)
		if ch == '"':
			in_quotes = not in_quotes
			continue
		if ch == "," and not in_quotes:
			out.append(current.strip_edges())
			current = ""
			continue
		current += ch
	out.append(current.strip_edges())
	return out


func _lire_progression_csv(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []

	var rows: Array = []
	var is_header := true
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		if is_header:
			is_header = false
			continue

		var cols := _split_csv_line(line)
		if cols.size() < 15:
			continue

		var talents := str(cols[14])
		var lore := ""
		if cols.size() >= 16:
			if cols.size() > 16:
				talents = ", ".join(cols.slice(14, cols.size() - 1))
			lore = str(cols[cols.size() - 1])

		rows.append({
			"niveau": int(cols[0]),
			"force": int(cols[1]),
			"magie": int(cols[2]),
			"espionnage": int(cols[3]),
			"artisanat": int(cols[4]),
			"diplomatie": int(cols[5]),
			"commandement": int(cols[6]),
			"attaque": int(cols[7]),
			"defense": int(cols[8]),
			"resistance": int(cols[9]),
			"initiative": int(cols[10]),
			"jet_vigueur": int(cols[11]),
			"jet_volonte": int(cols[12]),
			"jet_reflexes": int(cols[13]),
			"talents": talents,
			"lore": lore,
		})

	file.close()
	return rows


func _charger_feats() -> void:
	var data := _lire_json(PATH_FEATS)
	if data.is_empty():
		push_warning("GameDataLoader: feats.json introuvable — fallback vide.")
		_feats = {}
		return
	_feats = data


func _charger_abilities() -> void:
	var data := _lire_json(PATH_ABILITIES)
	if data.is_empty():
		push_warning("GameDataLoader: abilities.json introuvable — fallback sur classes.json.")
		_abilities = {}
		return
	_abilities = data


func _charger_equipment() -> void:
	var data := _lire_json(PATH_EQUIPMENT)
	if data.is_empty():
		push_warning("GameDataLoader: equipment.json introuvable — fallback vide.")
		_equipment = {"items": []}
		return
	_equipment = data


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


func get_class_progression(class_id: String) -> Array:
	return (_class_progressions.get(str(class_id), []) as Array).duplicate(true)


func get_class_progressions() -> Dictionary:
	return _class_progressions.duplicate(true)


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
			var entry_name := str(a).strip_edges()
			var id := _slugify(entry_name)
			if not out.has(id):
				out[id] = {
					"id": id,
					"name": entry_name,
					"description": _find_library_entry_description(entry_name),
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
	var abilities_map := get_abilities()
	return abilities_map.get(idn, {}) as Dictionary


func get_equipment() -> Dictionary:
	if _equipment.is_empty():
		_charger_equipment()
	return _equipment.duplicate(true)


func get_equipment_items() -> Array:
	var equipment_map := get_equipment()
	if not equipment_map.has("items"):
		return []
	return (equipment_map["items"] as Array).duplicate(true)


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


func _find_library_entry_description(entry_name: String) -> String:
	var title := str(entry_name).strip_edges().to_lower()
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
	_charger_class_progressions()
	_charger_abilities()
	_charger_feats()
	_charger_equipment()
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
