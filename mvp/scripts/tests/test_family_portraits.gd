extends SceneTree

const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")
const PortraitPayload = preload("res://scripts/ui/character_creation/portrait_payload.gd")

const EXPECTED_MOTHER := "res://assets/images/clan/mère/Okasa-sama (6).png"
const EXPECTED_FATHER_ALONE := "res://assets/images/clan/Pere et fils/Ottosama_00002_.png"
const EXPECTED_FATHER_FOR_MAN := "res://assets/images/clan/Pere et fille/Ottosama_00026_.png"
const EXPECTED_FATHER_FOR_OTHER := "res://assets/images/clan/Pere et fils/Ottosama_00003_.png"
const CLAN_SYMBOLS := [
	"res://assets/images/clan/defaut.png",
	"res://assets/images/clan/nine_nobles.png",
]
const GENERIC_NPC_PORTRAITS := [
	"res://assets/images/PNJ/defaut/male.png",
	"res://assets/images/PNJ/defaut/female.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var portraits := {
		"mère": VisualAssetCatalog.resolve_family_portrait("mother", "Homme"),
		"père seul": VisualAssetCatalog.resolve_family_portrait("father_alone", "Homme"),
		"père pour Homme": VisualAssetCatalog.resolve_family_portrait("father", "Homme"),
		"père pour autre sexe": VisualAssetCatalog.resolve_family_portrait("father", "Femme"),
		"enfant Homme": VisualAssetCatalog.resolve_family_portrait("child", "Homme"),
		"enfant autre sexe": VisualAssetCatalog.resolve_family_portrait("child", "Femme"),
	}

	_expect_path(portraits["mère"], EXPECTED_MOTHER, "mère", failures)
	_expect_path(portraits["père seul"], EXPECTED_FATHER_ALONE, "père seul", failures)
	_expect_path(portraits["père pour Homme"], EXPECTED_FATHER_FOR_MAN, "père pour Homme", failures)
	_expect_path(portraits["père pour autre sexe"], EXPECTED_FATHER_FOR_OTHER, "père pour autre sexe", failures)

	for label: String in portraits:
		var path: String = str(portraits[label])
		_assert_loadable(path, label, failures)
		if path in CLAN_SYMBOLS:
			failures.append("%s utilise un symbole du clan: %s" % [label, path])
		if path in GENERIC_NPC_PORTRAITS or path.contains("/PNJ/defaut/"):
			failures.append("%s utilise un fallback PNJ générique: %s" % [label, path])

	_assert_created_player_portrait(failures)
	_assert_import_resize(failures)
	_test_narrative_bindings(failures)
	if failures.is_empty():
		print("FAMILY_PORTRAITS_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error("FAMILY_PORTRAITS_FAIL: %s" % failure)
	quit(1)


func _expect_path(actual: String, expected: String, label: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s: chemin '%s', attendu '%s'" % [label, actual, expected])


func _assert_loadable(path: String, label: String, failures: Array[String]) -> void:
	if path.is_empty():
		failures.append("%s: aucun chemin résolu" % label)
		return
	if not path.begins_with("res://assets/images/clan/"):
		failures.append("%s: chemin hors des assets familiaux: %s" % [label, path])
		return
	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
		failures.append("%s: fichier inexistant: %s" % [label, path])
		return
	var texture: Resource = ResourceLoader.load(path)
	if not texture is Texture2D:
		failures.append("%s: image non chargeable: %s" % [label, path])


func _assert_created_player_portrait(failures: Array[String]) -> void:
	var image: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.2, 0.5, 1.0))
	var payload := {"image_base64": Marshalls.raw_to_base64(image.save_png_to_buffer())}
	if VisualAssetCatalog.texture_from_portrait_payload(payload) == null:
		failures.append("portrait réellement associé au personnage créé non chargeable")


func _assert_import_resize(failures: Array[String]) -> void:
	var source: Image = Image.create(2048, 1024, false, Image.FORMAT_RGBA8)
	var resized: Image = PortraitPayload.resize_for_import(source)
	if resized == null or resized.get_size() != Vector2i(512, 256):
		failures.append("redimensionnement import invalide: %s" % [resized.get_size() if resized != null else Vector2i.ZERO])


func _test_narrative_bindings(failures: Array[String]) -> void:
	var path := "res://data/ui_visual_bindings.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("bindings narratifs introuvables: %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		failures.append("bindings narratifs JSON invalides")
		return
	var bindings: Dictionary = (parsed as Dictionary).get("intro_vn", {}) as Dictionary
	for scene_id: String in ["famille_01", "famille_04", "lecon_06"]:
		var binding: Dictionary = bindings.get(scene_id, {}) as Dictionary
		if str(binding.get("visual", "")) != "@child":
			failures.append("%s doit utiliser le portrait enfant" % scene_id)
	for scene_id: String in ["famille_02", "lecon_04", "lecon_05", "kael_01", "conclave_03", "chute_04", "chute_05"]:
		var binding: Dictionary = bindings.get(scene_id, {}) as Dictionary
		if str(binding.get("visual", "")) != "@mother":
			failures.append("%s doit utiliser le portrait mère" % scene_id)
	for scene_id: String in ["famille_03", "lecon_01", "lecon_02", "lecon_03", "conclave_02", "chute_03", "chute_06"]:
		var binding: Dictionary = bindings.get(scene_id, {}) as Dictionary
		if str(binding.get("visual", "")) != "@father_alone":
			failures.append("%s doit utiliser le portrait père seul" % scene_id)
