## Central visual catalogue for Royaume Déchu — Les Cendres de Veyr.
## Semantic roles resolve only to assets that belong to the current original project.
extends RefCounted

const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")

const PERSON_ASSETS := {
    "pnj_female": "res://assets/images/PNJ/defaut/female.png",
    "pnj_male": "res://assets/images/PNJ/defaut/male.png",
    "kael": "res://assets/images/PNJ/defaut/Kael.png",
    "player_default": "res://assets/images/hero/defaut.png",
    "player_female": "res://assets/images/hero/femme/female.png",
    "player_male": "res://assets/images/hero/homme/male.png",
}


const FAMILY_ASSETS := {
    "mother": "res://assets/images/clan/mère/Okasa-sama (6).png",
    "father_alone": "res://assets/images/clan/Pere et fils/Ottosama_00002_.png",
    "mother_with_son": "res://assets/images/clan/mère/Mèreetfils.png",
    "father_with_daughter": "res://assets/images/clan/Pere et fille/Ottosama_00026_.png",
    "father_with_son": "res://assets/images/clan/Pere et fils/Ottosama_00003_.png",
    "heir_male": "res://assets/images/clan/hero-children/boy.png",
    "heir_female": "res://assets/images/clan/hero-children/girl (1).png",
}

const WORLD_ASSETS := {
    "clan": "res://assets/images/clan/defaut.png",
    "veyr_world": "res://assets/maps/veyr_world.png",
    "marches": "res://assets/maps/marches_cendrees.png",
}

const RESOURCE_ICONS := {
    "or": "res://assets/icon/gold.png",
    "soldats": "res://assets/icon/soldat.png",
    "mana": "res://assets/icon/mana.png",
    "nourriture": "res://assets/icon/food.png",
    "bois": "res://assets/icon/wood.png",
    "fer": "res://assets/icon/iron.png",
    "essence": "res://assets/icon/essence.png",
    "reputation": "res://assets/icon/reputation.png",
    "pierre": "res://assets/icon/stone.png",
}

const RESOURCE_LABELS := {
    "or": "Or",
    "soldats": "Soldats",
    "mana": "Mana",
    "nourriture": "Nourriture",
    "bois": "Bois",
    "fer": "Fer",
    "essence": "Essence",
}

const FAMILY_DIRECTORY := "res://assets/images/clan"
const MENU_ICON_DIRECTORY := "res://assets/ui/icons"

static func person_path(key: String) -> String:
    match key:
        "mother":
            return family_mother_path()
        "father":
            return father_with_child_path("")
        "heir_child_male":
            return heir_child_path("homme")
        "heir_child_female":
            return heir_child_path("femme")
        _:
            return str(PERSON_ASSETS.get(key, ""))

static func _existing_family_asset(key: String) -> String:
    var path: String = str(FAMILY_ASSETS.get(key, ""))
    if not path.is_empty() and (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
        return path
    return ""

static func family_mother_path() -> String:
    var direct: String = _existing_family_asset("mother")
    if not direct.is_empty():
        return direct
    return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["mère", "mere", "okasa"])

static func resolve_family_portrait(role: String, player_genre: String) -> String:
    match role.strip_edges().to_lower():
        "mother":
            return family_mother_path()
        "father_alone":
            var direct: String = _existing_family_asset("father_alone")
            if not direct.is_empty():
                return direct
            return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["ottosama 00002", "père seul", "pere seul"])
        "father":
            return father_with_child_path(player_genre)
        "child":
            return heir_child_path(player_genre)
        _:
            push_warning("Rôle de portrait familial inconnu : %s" % role)
            return ""

## Mapping preserved exactly from the project owner's family-asset convention.
## Homme -> « Pere et fille » ; otherwise -> « Pere et fils ».
static func father_with_child_path(player_genre: String) -> String:
    var normalized_genre: String = _normalize_name(player_genre)
    var key: String = "father_with_daughter" if normalized_genre == "homme" or normalized_genre == "male" else "father_with_son"
    var direct: String = _existing_family_asset(key)
    if not direct.is_empty():
        return direct
    if key == "father_with_daughter":
        return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["pere et fille", "père et fille", "ottosama 00026"])
    return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["pere et fils", "père et fils", "ottosama 00003"])

static func heir_child_path(player_genre: String) -> String:
    var normalized_genre: String = _normalize_name(player_genre)
    var key: String = "heir_female" if normalized_genre == "femme" or normalized_genre == "female" else "heir_male"
    var direct: String = _existing_family_asset(key)
    if not direct.is_empty():
        return direct
    if key == "heir_female":
        return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["girl", "fille"])
    return find_semantic_asset_recursive(FAMILY_DIRECTORY, ["boy", "garcon", "garçon", "fils"])

static func world_path(key: String) -> String:
    return str(WORLD_ASSETS.get(key, ""))

static func resource_icon_path(key: String) -> String:
    return str(RESOURCE_ICONS.get(key, ""))

static func resource_label(key: String) -> String:
    return str(RESOURCE_LABELS.get(key, key.capitalize()))

static func menu_icon_path(action: String) -> String:
    var aliases: Array[String] = []
    match action:
        "new_game": aliases = ["nouvelle partie", "nouvelle_partie", "nouvelle", "new game", "new_game", "jouer", "play"]
        "continue_game": aliases = ["continuer", "continue", "reprendre", "charger", "load"]
        "options": aliases = ["paramètres", "parametres", "options", "réglages", "reglages", "settings"]
        "encyclopedia": aliases = ["bibliothèque", "bibliotheque", "chroniques", "codex", "lore"]
        "quit": aliases = ["quitter", "quit", "exit", "fermer"]
        _: aliases = [action]
    return find_semantic_asset(MENU_ICON_DIRECTORY, aliases)

static func load_path(path: String) -> Texture2D:
    if path.is_empty():
        return null
    return ResourcePathResolver.load_texture(path, "res://assets/images")

static func texture_from_portrait_payload(payload: Dictionary) -> Texture2D:
    if payload.is_empty():
        return null
    var encoded: String = ""
    if payload.has("image_base64"):
        encoded = str(payload.get("image_base64", ""))
    elif str(payload.get("encoding", "")) == "png_base64":
        encoded = str(payload.get("data", ""))
    if not encoded.is_empty():
        var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
        if not raw.is_empty():
            var image: Image = Image.new()
            if image.load_png_from_buffer(raw) == OK and not image.is_empty():
                return ImageTexture.create_from_image(image)
    var path: String = str(payload.get("image_path", payload.get("path", ""))).strip_edges()
    if not path.is_empty():
        var direct: Texture2D = ResourcePathResolver.load_texture(path, "res://assets/images/hero")
        if direct != null:
            return direct
    return null

static func find_semantic_asset(directory_path: String, aliases: Array[String]) -> String:
    var directory: DirAccess = DirAccess.open(directory_path)
    if directory == null:
        return ""
    var normalized_aliases: Array[String] = []
    for alias: String in aliases:
        var normalized_alias: String = _normalize_name(alias)
        if not normalized_alias.is_empty() and not normalized_aliases.has(normalized_alias):
            normalized_aliases.append(normalized_alias)
    var best_path: String = ""
    var best_score: int = 0
    for file_name: String in directory.get_files():
        if file_name.ends_with(".import") or file_name.begins_with("."):
            continue
        var extension: String = file_name.get_extension().to_lower()
        if extension not in ["png", "jpg", "jpeg", "webp", "svg"]:
            continue
        var normalized_stem: String = _normalize_name(file_name.get_basename())
        for normalized_alias: String in normalized_aliases:
            var score: int = _semantic_match_score(normalized_stem, normalized_alias)
            if score > best_score:
                best_score = score
                best_path = "%s/%s" % [directory_path.trim_suffix("/"), file_name]
    return best_path

static func find_semantic_asset_recursive(directory_path: String, aliases: Array[String]) -> String:
    var normalized_aliases: Array[String] = []
    for alias: String in aliases:
        var normalized_alias: String = _normalize_name(alias)
        if not normalized_alias.is_empty() and not normalized_aliases.has(normalized_alias):
            normalized_aliases.append(normalized_alias)
    return _find_semantic_asset_recursive_impl(directory_path, normalized_aliases)

static func _find_semantic_asset_recursive_impl(directory_path: String, normalized_aliases: Array[String]) -> String:
    var directory: DirAccess = DirAccess.open(directory_path)
    if directory == null:
        return ""
    var best_path: String = ""
    var best_score: int = 0
    for file_name: String in directory.get_files():
        if file_name.ends_with(".import") or file_name.begins_with("."):
            continue
        var extension: String = file_name.get_extension().to_lower()
        if extension not in ["png", "jpg", "jpeg", "webp", "svg"]:
            continue
        var relative_candidate: String = "%s %s" % [directory_path.get_file(), file_name.get_basename()]
        var normalized_candidate: String = _normalize_name(relative_candidate)
        for normalized_alias: String in normalized_aliases:
            var score: int = _semantic_match_score(normalized_candidate, normalized_alias)
            if score > best_score:
                best_score = score
                best_path = "%s/%s" % [directory_path.trim_suffix("/"), file_name]
    for subdir: String in directory.get_directories():
        if subdir.begins_with("."):
            continue
        var nested: String = _find_semantic_asset_recursive_impl("%s/%s" % [directory_path.trim_suffix("/"), subdir], normalized_aliases)
        if not nested.is_empty():
            var nested_norm: String = _normalize_name("%s %s" % [nested.get_base_dir().get_file(), nested.get_file().get_basename()])
            for normalized_alias: String in normalized_aliases:
                var nested_score: int = _semantic_match_score(nested_norm, normalized_alias)
                if nested_score > best_score:
                    best_score = nested_score
                    best_path = nested
    return best_path

static func _semantic_match_score(candidate: String, alias: String) -> int:
    if candidate == alias: return 1000 + alias.length()
    if candidate.contains(alias): return 700 + alias.length()
    if alias.contains(candidate) and candidate.length() >= 4: return 400 + candidate.length()
    return 0

static func _normalize_name(value: String) -> String:
    var result: String = value.strip_edges().to_lower()
    for pair: Array in [
        ["à", "a"], ["â", "a"], ["ä", "a"], ["á", "a"], ["ç", "c"],
        ["é", "e"], ["è", "e"], ["ê", "e"], ["ë", "e"], ["î", "i"], ["ï", "i"], ["í", "i"],
        ["ô", "o"], ["ö", "o"], ["ó", "o"], ["ù", "u"], ["û", "u"], ["ü", "u"], ["ú", "u"], ["ÿ", "y"],
    ]:
        result = result.replace(str(pair[0]), str(pair[1]))
    for separator: String in ["_", "-", ".", "(", ")", "[", "]"]:
        result = result.replace(separator, " ")
    while result.contains("  "):
        result = result.replace("  ", " ")
    return result.strip_edges()

static func infer_kind(path: String) -> String:
    var p: String = path.to_lower()
    if p.contains("/pnj/") or p.contains("/hero/"):
        return "portrait"
    if p.contains("/images/clan/") and (p.contains("mere") or p.contains("mère") or p.contains("pere") or p.contains("père")):
        return "portrait"
    if p.contains("map") or p.contains("/maps/"):
        return "map"
    if p.contains("clan/"):
        return "symbol"
    if p.contains("/icon/") or p.contains("/ui/icons/"):
        return "resource"
    return "contain"

static func apply_fit(rect: TextureRect, kind: String) -> void:
    if rect == null:
        return
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    match kind:
        "landscape": rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        _: rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
