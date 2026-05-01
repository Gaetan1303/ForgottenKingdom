## Service utilitaire de persistance JSON (atomique + backup).
class_name JsonPersistenceService
extends RefCounted


static func ensure_parent_directory(path: String) -> void:
	var dir_path := path.get_base_dir()
	if dir_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))


static func read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


static func read_json_with_backup(path: String, backup_suffix: String = ".bak") -> Dictionary:
	var primary := read_json_dict(path)
	if not primary.is_empty():
		return primary
	return read_json_dict(path + backup_suffix)


static func write_json_atomic(
	path: String,
	data: Dictionary,
	backup_suffix: String = ".bak",
	tmp_suffix: String = ".tmp"
) -> bool:
	ensure_parent_directory(path)
	var tmp_path := path + tmp_suffix
	var backup_path := path + backup_suffix

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)

	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(path, backup_path) != OK:
			DirAccess.remove_absolute(tmp_path)
			return false

	if DirAccess.rename_absolute(tmp_path, path) != OK:
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, path)
		return false

	return true
