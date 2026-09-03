## Centralise la résolution des chemins res:// et user://.
## Les services peuvent dépendre de chemins logiques sans connaître l'arborescence exacte.
extends RefCounted
class_name ResourcePathResolver

const DATA_ROOT := "res://data"
const ASSET_ROOT := "res://assets"
const STORY_ROOT := "res://story"
const SCRIPT_ROOT := "res://scripts"
const IMPORTED_ROOT := "res://.godot/imported"


static func normalize(path: String) -> String:
	var value := path.strip_edges().replace("\\", "/")
	if value.is_empty():
		return ""
	if value.begins_with("res://") or value.begins_with("user://"):
		return value.simplify_path()
	return value.simplify_path()


static func join(base_path: String, child_path: String) -> String:
	var child := normalize(child_path)
	if child.begins_with("res://") or child.begins_with("user://"):
		return child
	var base := normalize(base_path).trim_suffix("/")
	if base.is_empty():
		return child
	return normalize("%s/%s" % [base, child.trim_prefix("/")])


static func data(relative_path: String) -> String:
	return join(DATA_ROOT, relative_path)


static func asset(relative_path: String) -> String:
	return join(ASSET_ROOT, relative_path)


static func story(relative_path: String) -> String:
	return join(STORY_ROOT, relative_path)


static func script(relative_path: String) -> String:
	return join(SCRIPT_ROOT, relative_path)


static func file_exists(path: String) -> bool:
	var resolved := normalize(path)
	return not resolved.is_empty() and FileAccess.file_exists(resolved)


static func first_existing(candidates: Array, base_path: String = "") -> String:
	for candidate in candidates:
		var raw := str(candidate)
		var resolved := normalize(raw) if base_path.is_empty() else join(base_path, raw)
		if file_exists(resolved):
			return resolved
	return ""


static func resolve_file(primary_path: String, fallback_paths: Array = []) -> String:
	var candidates: Array = [primary_path]
	candidates.append_array(fallback_paths)
	return first_existing(candidates)


static func require_file(primary_path: String, fallback_paths: Array = []) -> String:
	var resolved := resolve_file(primary_path, fallback_paths)
	if resolved.is_empty():
		push_error("ResourcePathResolver: fichier introuvable: %s" % primary_path)
	return resolved


## API générique utilisée par les loaders refactorés.
static func resolve(path: String, fallback_paths: Array = [], base_path: String = "") -> String:
	var primary := join(base_path, path) if not base_path.is_empty() else normalize(path)
	var fallbacks: Array = []
	for fallback in fallback_paths:
		var raw := str(fallback)
		fallbacks.append(join(base_path, raw) if not base_path.is_empty() else normalize(raw))
	return resolve_file(primary, fallbacks)


static func resolve_existing(path: String, fallback_paths: Array = [], base_path: String = "") -> String:
	return resolve(path, fallback_paths, base_path)


static func exists(path: String) -> bool:
	return file_exists(path)


## Charge une Texture2D depuis les assets du projet.
## Si le fichier source a été perdu mais que Godot possède encore son import .ctex,
## on utilise ce cache comme filet de sécurité. Ce fallback sert notamment aux
## illustrations narratives historiques du MVP.
static func load_texture(path_or_name: String, base_path: String = "res://assets/images") -> Texture2D:
	var candidates: Array[String] = _texture_candidates(path_or_name, base_path)

	# Les illustrations narratives peuvent exister comme fichiers image bruts sans
	# sidecar .import (par exemple après restauration depuis un ancien cache).
	# Dans ce cas ResourceLoader ne les voit pas forcément au premier lancement.
	# Image.load() lit directement le fichier source et évite cette dépendance au cache.
	for candidate: String in candidates:
		var direct_texture: Texture2D = _load_direct_image(candidate)
		if direct_texture != null:
			return direct_texture

	# Chemin Godot standard lorsqu'un import existe déjà.
	for candidate: String in candidates:
		if not ResourceLoader.exists(candidate):
			continue
		var resource: Resource = ResourceLoader.load(candidate)
		if resource is Texture2D:
			return resource as Texture2D

	# Dernier recours pour les anciens projets dont seul le cache .ctex subsiste.
	var imported_path: String = _find_imported_texture(path_or_name)
	if not imported_path.is_empty() and ResourceLoader.exists(imported_path):
		var imported_resource: Resource = ResourceLoader.load(imported_path)
		if imported_resource is Texture2D:
			return imported_resource as Texture2D
	return null


static func _load_direct_image(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var extension: String = path.get_extension().to_lower()
	if extension not in ["png", "webp", "jpg", "jpeg"]:
		return null
	var image: Image = Image.new()
	var load_error: Error = image.load(path)
	if load_error != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func _texture_candidates(path_or_name: String, base_path: String) -> Array[String]:
	var raw: String = normalize(path_or_name)
	if raw.is_empty():
		return []
	var primary: String = raw if raw.begins_with("res://") or raw.begins_with("user://") else join(base_path, raw)
	var result: Array[String] = [primary]
	var extension: String = primary.get_extension().to_lower()
	var base_no_ext: String = primary.get_basename()
	if extension.is_empty():
		for ext: String in ["png", "webp", "jpg", "jpeg", "svg"]:
			result.append("%s.%s" % [primary, ext])
	else:
		for ext: String in ["png", "webp", "jpg", "jpeg", "svg"]:
			var alternative: String = "%s.%s" % [base_no_ext, ext]
			if not result.has(alternative):
				result.append(alternative)
	return result


static func _find_imported_texture(path_or_name: String) -> String:
	var file_name: String = normalize(path_or_name).get_file()
	if file_name.is_empty():
		return ""
	var directory: DirAccess = DirAccess.open(IMPORTED_ROOT)
	if directory == null:
		return ""

	var prefixes: Array[String] = []
	if file_name.get_extension().is_empty():
		for ext: String in ["png", "webp", "jpg", "jpeg", "svg"]:
			prefixes.append("%s.%s-" % [file_name, ext])
	else:
		prefixes.append(file_name + "-")

	var files: PackedStringArray = directory.get_files()
	for imported_name: String in files:
		if not imported_name.ends_with(".ctex"):
			continue
		for prefix: String in prefixes:
			if imported_name.begins_with(prefix):
				return join(IMPORTED_ROOT, imported_name)
	return ""
