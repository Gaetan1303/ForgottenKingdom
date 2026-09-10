extends SceneTree

const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")

func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var failures: Array[String] = []
    var checks: Dictionary = {
        "mother": VisualAssetCatalog.family_mother_path(),
        "father_homme": VisualAssetCatalog.father_with_child_path("homme"),
        "father_femme": VisualAssetCatalog.father_with_child_path("femme"),
        "heir_homme": VisualAssetCatalog.heir_child_path("homme"),
        "heir_femme": VisualAssetCatalog.heir_child_path("femme"),
    }
    for key: String in checks.keys():
        var path: String = str(checks[key])
        if path.is_empty():
            failures.append("%s: chemin vide" % key)
            continue
        if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
            failures.append("%s: fichier absent %s" % [key, path])
            continue
        var texture: Texture2D = ResourcePathResolver.load_texture(path, "res://assets/images/clan")
        if texture == null:
            failures.append("%s: texture non chargeable %s" % [key, path])
    if failures.is_empty():
        print("FAMILY_VISUAL_ASSETS_OK: 5/5")
        quit(0)
        return
    for failure: String in failures:
        push_error(failure)
    quit(1)
