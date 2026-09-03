extends SceneTree

const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")
const CHAPTER_DATA_PATH := "res://resources/chapters/data.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var names: Array[String] = _read_illustration_names()
	if names.is_empty():
		push_error("CHAPTER_VIEW_ILLUSTRATIONS_FAIL: aucune illustration déclarée")
		quit(1)
		return

	var rect: TextureRect = TextureRect.new()
	get_root().add_child(rect)
	var loaded_count: int = 0
	var failures: Array[String] = []

	for illustration_name: String in names:
		var texture: Texture2D = ResourcePathResolverScript.load_texture(illustration_name, "res://assets/images")
		rect.texture = texture
		if rect.texture == null:
			failures.append(illustration_name)
		else:
			loaded_count += 1

	rect.queue_free()
	if failures.is_empty():
		print("CHAPTER_VIEW_ILLUSTRATIONS_OK: %d/%d" % [loaded_count, names.size()])
		quit(0)
		return

	for failed_name: String in failures:
		push_error("CHAPTER_VIEW_ILLUSTRATIONS_FAIL: %s" % failed_name)
	quit(1)


func _read_illustration_names() -> Array[String]:
	var result: Array[String] = []
	var file: FileAccess = FileAccess.open(CHAPTER_DATA_PATH, FileAccess.READ)
	if file == null:
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return result
	var data: Dictionary = parsed as Dictionary
	for chapter_variant: Variant in data.get("chapitres", []) as Array:
		if not (chapter_variant is Dictionary):
			continue
		var chapter: Dictionary = chapter_variant as Dictionary
		_append_unique(result, str(chapter.get("illustration", "")))
		for scene_variant: Variant in chapter.get("scenes", []) as Array:
			if scene_variant is Dictionary:
				_append_unique(result, str((scene_variant as Dictionary).get("illustration", "")))
	return result


func _append_unique(items: Array[String], value: String) -> void:
	var cleaned: String = value.strip_edges()
	if not cleaned.is_empty() and not items.has(cleaned):
		items.append(cleaned)
