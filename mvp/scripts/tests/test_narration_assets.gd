extends SceneTree

const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")
const CHAPTER_DATA_PATH := "res://resources/chapters/data.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var file: FileAccess = FileAccess.open(CHAPTER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("NARRATION_ASSETS_FAIL: data.json introuvable")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		push_error("NARRATION_ASSETS_FAIL: data.json invalide")
		quit(1)
		return

	var names: Dictionary = {}
	var data: Dictionary = parsed as Dictionary
	for chapter_variant: Variant in data.get("chapitres", []) as Array:
		if not (chapter_variant is Dictionary):
			continue
		var chapter: Dictionary = chapter_variant as Dictionary
		_add_name(names, str(chapter.get("illustration", "")))
		for scene_variant: Variant in chapter.get("scenes", []) as Array:
			if scene_variant is Dictionary:
				_add_name(names, str((scene_variant as Dictionary).get("illustration", "")))

	var loaded_count: int = 0
	for name_variant: Variant in names.keys():
		var name: String = str(name_variant)
		var texture: Texture2D = ResourcePathResolverScript.load_texture(name, "res://assets/images")
		if texture == null:
			failures.append(name)
		else:
			loaded_count += 1

	if failures.is_empty():
		print("NARRATION_ASSETS_OK: %d illustrations chargeables" % loaded_count)
		quit(0)
		return
	for missing: String in failures:
		push_error("NARRATION_ASSETS_FAIL: %s" % missing)
	quit(1)


func _add_name(names: Dictionary, name: String) -> void:
	if not name.strip_edges().is_empty():
		names[name] = true
