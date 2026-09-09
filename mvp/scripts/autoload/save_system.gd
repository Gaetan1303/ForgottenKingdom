## autoload/save_system.gd
## Singleton de sauvegarde — persiste la progression par slot dans user://slots/<slot>/.
extends Node

## Use global class_name JsonPersistenceService for persistence utilities.

const SLOTS_ROOT_PATH := "user://slots"
const SLOTS_INDEX_PATH := "user://save_slots.json"
const DEFAULT_SLOT_ID := "slot_1"
const DEFAULT_SLOT_IDS := ["slot_1", "slot_2", "slot_3"]
const PROGRESS_FILE_NAME := "progress.json"
const CLAN_FILE_NAME := "clan.json"
const TMP_SUFFIX := ".tmp"
const BAK_SUFFIX := ".bak"

# Données de sauvegarde par défaut
var _save_data: Dictionary = {
	"last_chapter": 0,
	"last_scene": 0,
	"unlocked_chapters": [0],
	"visited_locations": [],
	"play_time_seconds": 0.0,
}

var _play_timer: float = 0.0
var _active_slot_id: String = DEFAULT_SLOT_ID
var _slots_index: Dictionary = {
	"active_slot": DEFAULT_SLOT_ID,
	"slots": {},
}


func _ready() -> void:
	_load_slots_index()
	_active_slot_id = str(_slots_index.get("active_slot", DEFAULT_SLOT_ID))
	load_save()


func _process(delta: float) -> void:
	_play_timer += delta
	if _play_timer >= 60.0:
		_play_timer = 0.0
		_save_data["play_time_seconds"] += 60.0


## Retourne la valeur d'une clé de sauvegarde.
func get_value(key: String, default = null) -> Variant:
	return _save_data.get(key, default)


func get_active_slot() -> String:
	return _active_slot_id


func set_active_slot(slot_id: String) -> void:
	var normalized := _normalize_slot_id(slot_id)
	if normalized == _active_slot_id:
		return
	_active_slot_id = normalized
	_slots_index["active_slot"] = normalized
	_ensure_slot_directory(normalized)
	_save_slots_index()
	load_save()


func get_progress_save_path(slot_id: String = "") -> String:
	var normalized := _normalize_slot_id(slot_id if not slot_id.is_empty() else _active_slot_id)
	return "%s/%s/%s" % [SLOTS_ROOT_PATH, normalized, PROGRESS_FILE_NAME]


func get_clan_save_path(slot_id: String = "") -> String:
	var normalized := _normalize_slot_id(slot_id if not slot_id.is_empty() else _active_slot_id)
	return "%s/%s/%s" % [SLOTS_ROOT_PATH, normalized, CLAN_FILE_NAME]


func slot_has_progress(slot_id: String = "") -> bool:
	return FileAccess.file_exists(get_progress_save_path(slot_id))


func slot_has_clan_save(slot_id: String = "") -> bool:
	return FileAccess.file_exists(get_clan_save_path(slot_id))


func list_slot_summaries() -> Array:
	var out: Array = []
	for sid_v in DEFAULT_SLOT_IDS:
		var sid := str(sid_v)
		out.append(get_slot_summary(sid))
	return out


func get_slot_summary(slot_id: String) -> Dictionary:
	var sid := _normalize_slot_id(slot_id)
	var progress := _read_json_dict(get_progress_save_path(sid))
	var clan := _read_json_dict(get_clan_save_path(sid))
	var slots := _slots_index.get("slots", {}) as Dictionary
	var meta := slots.get(sid, {}) as Dictionary
	var profil := clan.get("profil_personnage", {}) as Dictionary
	return {
		"slot_name": str(meta.get("name", "")),
		"slot_id": sid,
		"is_active": sid == _active_slot_id,
		"has_progress": not progress.is_empty(),
		"has_clan": not clan.is_empty(),
		"clan_id": str(clan.get("clan_id", "")),
		"nom_clan": str(clan.get("nom_clan", "")),
		"nom_personnage": str(clan.get("nom_personnage", "")),
		"tour_actuel": int(clan.get("tour_actuel", 0)),
		"portrait": (profil.get("portrait", {}) as Dictionary).duplicate(true),
		"play_time_seconds": float(progress.get("play_time_seconds", 0.0)),
		"last_chapter": int(progress.get("last_chapter", 0)),
		"last_scene": int(progress.get("last_scene", 0)),
		"updated_at_unix": int(meta.get("updated_at_unix", 0)),
	}


func clear_slot(slot_id: String) -> void:
	var sid := _normalize_slot_id(slot_id)
	var progress_path := get_progress_save_path(sid)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var clan_path := get_clan_save_path(sid)
	if FileAccess.file_exists(clan_path):
		DirAccess.remove_absolute(clan_path)
	var slots := (_slots_index.get("slots", {}) as Dictionary).duplicate(true)
	if slots.has(sid):
		var meta := (slots[sid] as Dictionary).duplicate(true)
		meta["updated_at_unix"] = int(Time.get_unix_time_from_system())
		meta["has_progress"] = false
		meta["has_clan"] = false
		# keep custom name if present
		meta["name"] = str(meta.get("name", ""))
		slots[sid] = meta
		_slots_index["slots"] = slots
	if sid == _active_slot_id:
		_save_data = _default_save_data()
	_save_slots_index()


func delete_slot(slot_id: String) -> void:
	clear_slot(slot_id)


## Définit une valeur dans la sauvegarde (sans écrire sur disque immédiatement).
func set_value(key: String, value: Variant) -> void:
	_save_data[key] = value


## Déverrouille un chapitre.
func unlock_chapter(chapter_id: int) -> void:
	var unlocked: Array = _save_data.get("unlocked_chapters", [])
	if chapter_id not in unlocked:
		unlocked.append(chapter_id)
		unlocked.sort()
		_save_data["unlocked_chapters"] = unlocked


## Marque un lieu de la carte comme visité.
func visit_location(location_id: String) -> void:
	var visited: Array = _save_data.get("visited_locations", [])
	if location_id not in visited:
		visited.append(location_id)
		_save_data["visited_locations"] = visited


## Sauvegarde la progression sur disque.
func save() -> void:
	_save_data["last_chapter"] = GameManager.current_chapter_id
	_save_data["last_scene"] = GameManager.current_scene_index
	_save_data["play_time_seconds"] += _play_timer
	_play_timer = 0.0

	_ensure_slot_directory(_active_slot_id)
	if not JsonPersistenceService.write_json_atomic(get_progress_save_path(), _save_data, BAK_SUFFIX, TMP_SUFFIX):
		push_error("SaveSystem: impossible d'écrire la progression du slot '%s'" % _active_slot_id)
		return
	_save_slots_index()


## Charge la sauvegarde depuis le disque.
func load_save() -> void:
	_save_data = _default_save_data()
	var save_path := get_progress_save_path()
	if not FileAccess.file_exists(save_path):
		return  # Première partie, pas de sauvegarde

	var parsed := JsonPersistenceService.read_json_with_backup(save_path, BAK_SUFFIX)
	if not parsed.is_empty():
		# Fusionne avec les valeurs par défaut pour compatibilité ascendante
		for key in _save_data:
			if not parsed.has(key):
				parsed[key] = _save_data[key]
		_save_data = parsed
	else:
		push_error("SaveSystem: fichier de sauvegarde corrompu")


## Supprime la sauvegarde et réinitialise.
func reset_save() -> void:
	_save_data = _default_save_data()
	var progress_path := get_progress_save_path()
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var clan_path := get_clan_save_path()
	if FileAccess.file_exists(clan_path):
		DirAccess.remove_absolute(clan_path)
	_save_slots_index()


func _default_save_data() -> Dictionary:
	return {
		"last_chapter": 0,
		"last_scene": 0,
		"unlocked_chapters": [0],
		"visited_locations": [],
		"play_time_seconds": 0.0,
	}


func _normalize_slot_id(slot_id: String) -> String:
	var trimmed := slot_id.strip_edges()
	if trimmed.is_empty():
		return DEFAULT_SLOT_ID
	return trimmed


func _ensure_slot_directory(slot_id: String) -> void:
	var normalized := _normalize_slot_id(slot_id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [SLOTS_ROOT_PATH, normalized]))


func _touch_slot_index(slot_id: String) -> void:
	var normalized := _normalize_slot_id(slot_id)
	var slots := (_slots_index.get("slots", {}) as Dictionary).duplicate(true)
	var existing := (slots.get(normalized, {}) as Dictionary).duplicate(true)
	existing["updated_at_unix"] = int(Time.get_unix_time_from_system())
	existing["has_progress"] = FileAccess.file_exists(get_progress_save_path(normalized))
	existing["has_clan"] = FileAccess.file_exists(get_clan_save_path(normalized))
	# preserve custom name if any
	existing["name"] = str(existing.get("name", ""))
	slots[normalized] = existing
	_slots_index["slots"] = slots


func set_slot_name(slot_id: String, slot_name: String) -> void:
	var sid := _normalize_slot_id(slot_id)
	var slots := (_slots_index.get("slots", {}) as Dictionary).duplicate(true)
	var meta := (slots.get(sid, {}) as Dictionary).duplicate(true)
	meta["name"] = str(slot_name)
	slots[sid] = meta
	_slots_index["slots"] = slots
	_save_slots_index()


func _load_slots_index() -> void:
	_slots_index = {
		"active_slot": DEFAULT_SLOT_ID,
		"slots": {},
	}
	if not FileAccess.file_exists(SLOTS_INDEX_PATH):
		return
	var file := FileAccess.open(SLOTS_INDEX_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_slots_index = parsed as Dictionary
	if not _slots_index.has("active_slot"):
		_slots_index["active_slot"] = DEFAULT_SLOT_ID
	if not _slots_index.has("slots"):
		_slots_index["slots"] = {}
	for sid_v in DEFAULT_SLOT_IDS:
		var sid := str(sid_v)
		var slots := (_slots_index.get("slots", {}) as Dictionary).duplicate(true)
		if not slots.has(sid):
			slots[sid] = {
				"updated_at_unix": 0,
				"has_progress": FileAccess.file_exists(get_progress_save_path(sid)),
				"has_clan": FileAccess.file_exists(get_clan_save_path(sid)),
				"name": "",
			}
		_slots_index["slots"] = slots


func _save_slots_index() -> void:
	_touch_slot_index(_active_slot_id)
	if not JsonPersistenceService.write_json_atomic(SLOTS_INDEX_PATH, _slots_index, BAK_SUFFIX, TMP_SUFFIX):
		push_error("SaveSystem: impossible d'écrire l'index des slots")
		return


func _read_json_dict(path: String) -> Dictionary:
	return JsonPersistenceService.read_json_dict(path)
