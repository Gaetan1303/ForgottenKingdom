extends SceneTree

const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	# The actual custom protagonist portrait must be reconstructed from the same
	# payload format produced by character creation.
	var image: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.2, 0.5, 1.0))
	var encoded: String = Marshalls.raw_to_base64(image.save_png_to_buffer())
	var payload: Dictionary = {"image_base64": encoded, "file_name": "test.png"}
	var portrait: Texture2D = VisualAssetCatalog.texture_from_portrait_payload(payload)
	if portrait == null:
		failures.append("portrait personnage principal non reconstructible")

	# Family/menu assets are user-authored assets. Validate them when they are
	# present in the project rather than silently substituting unrelated artwork.
	var mother_path: String = VisualAssetCatalog.family_mother_path()
	var father_girl_path: String = VisualAssetCatalog.father_with_child_path("Homme")
	var father_boy_path: String = VisualAssetCatalog.father_with_child_path("Femme")
	if mother_path.is_empty():
		push_warning("SEMANTIC_VISUAL_ASSETS: asset mère absent de assets/images/clan")
	if father_girl_path.is_empty():
		push_warning("SEMANTIC_VISUAL_ASSETS: asset Père et fille absent de assets/images/clan")
	if father_boy_path.is_empty():
		push_warning("SEMANTIC_VISUAL_ASSETS: asset Père et fils absent de assets/images/clan")

	var resolved_menu_icons: int = 0
	for action: String in ["new_game", "continue_game", "options", "encyclopedia", "quit"]:
		if not VisualAssetCatalog.menu_icon_path(action).is_empty():
			resolved_menu_icons += 1
	if resolved_menu_icons < 5:
		push_warning("SEMANTIC_VISUAL_ASSETS: %d/5 icônes menu trouvées dans assets/ui/icons" % resolved_menu_icons)

	if failures.is_empty():
		print("SEMANTIC_VISUAL_MAPPING_OK: portrait joueur + résolution sémantique active")
		quit(0)
		return
	for failure: String in failures:
		push_error("SEMANTIC_VISUAL_MAPPING_FAIL: %s" % failure)
	quit(1)
