class_name ResourcePathResolver
extends RefCounted

## Normalise les anciens chemins issus de l'époque où le projet Godot vivait
## dans un sous-dossier "mvp". La racine courante est déjà res://mvp/, donc
## "res://mvp/..." est invalide dans ce projet.

static func normalize(path: String) -> String:
	var value := path.strip_edges().replace("\\", "/")
	if value.is_empty():
		return ""
	if value.begins_with("res://mvp/"):
		return "res://" + value.trim_prefix("res://mvp/")
	if value.begins_with("mvp/"):
		return "res://" + value.trim_prefix("mvp/")
	if value.begins_with("res://"):
		return value
	return "res://" + value.trim_prefix("./")


static func resolve_existing(path: String) -> String:
	var normalized := normalize(path)
	if not normalized.is_empty() and ResourceLoader.exists(normalized):
		return normalized
	return ""


static func first_existing(paths: Array) -> String:
	for raw in paths:
		var resolved := resolve_existing(str(raw))
		if not resolved.is_empty():
			return resolved
	return ""
