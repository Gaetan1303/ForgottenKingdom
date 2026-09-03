## Central visual catalogue for Royaume déchu.
## Semantic roles resolve to exact assets when they exist. Family/menu assets are
## discovered by their filenames so accented names and minor separators stay robust.
extends RefCounted

const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")

const PERSON_ASSETS := {
	"pnj_female": "res://assets/images/PNJ/defaut/female.png",
	"pnj_male": "res://assets/images/PNJ/defaut/male.png",
	"kael": "res://assets/images/PNJ/defaut/Kael.png",
	"player_default": "res://assets/images/hero/defaut.png",
	"player_female": "res://assets/images/hero/femme/female.png",
	"player_male": "res://assets/images/hero/homme/male.png",
	"ingrid": "res://assets/images/ingrid_39_1024.png",
	"edwin_black": "res://assets/images/edwin_black_1024.png",
	"ceres": "res://assets/images/lore/ceres_1024.webp",
}

const WORLD_ASSETS := {
	"clan": "res://assets/images/clan/defaut.png",
	"nobles_symbol": "res://assets/images/clan/nine_nobles.png",
	"nobles_group": "res://assets/images/nine_nobles_1024.png",
	"demon_realm_map": "res://assets/images/demon_realm_map_1024.png",
	"yomihara": "res://assets/images/yomihara_1024.png",
	"hell_knight": "res://assets/images/lore/hell_knight_1024.webp",
}

const RESOURCE_ICONS := {
	"or": "res://assets/icon/gold.png",
	"soldats": "res://assets/icon/soldat.png",
	"mana": "res://assets/icon/mana.png",
	"nourriture": "res://assets/icon/food.png",
	"bois": "res://assets/icon/wood.png",
	"fer": "res://assets/icon/iron.png",
	"pierre": "res://assets/icon/stone.png",
	"essence": "res://assets/icon/essence.png",
	"reputation": "res://assets/icon/reputation.png",
}

const RESOURCE_LABELS := {
	"or": "Or",
	"soldats": "Soldats",
	"mana": "Mana",
	"nourriture": "Nourriture",
	"bois": "Bois",
	"fer": "Fer",
	"pierre": "Pierre",
	"essence": "Essence",
	"reputation": "Réputation",
}

const FAMILY_DIRECTORY := "res://assets/images/clan"
const MENU_ICON_DIRECTORY := "res://assets/ui/icons"
const FAMILY_MOTHER := "res://assets/images/clan/mère/Okasa-sama (6).png"
const FAMILY_FATHER_ALONE := "res://assets/images/clan/Pere et fils/Ottosama_00002_.png"
const FAMILY_FATHER_WITH_DAUGHTER := "res://assets/images/clan/Pere et fille/Ottosama_00026_.png"
const FAMILY_FATHER_WITH_SON := "res://assets/images/clan/Pere et fils/Ottosama_00003_.png"
const FAMILY_CHILD_BOY := "res://assets/images/clan/hero-children/boy.png"
const FAMILY_CHILD_GIRL := "res://assets/images/clan/hero-children/girl (1).png"


static func person_path(key: String) -> String:
	match key:
		"mother":
			return resolve_family_portrait("mother", "")
		"father":
			push_warning("VisualAssetCatalog: le portrait du père requiert le genre du protagoniste.")
			return ""
		_:
			return str(PERSON_ASSETS.get(key, ""))


static func family_mother_path() -> String:
	return resolve_family_portrait("mother", "")


## Mapping intentionally follows the project owner's naming rule:
## Homme -> "Père et fille", otherwise -> "Père et fils".
static func father_with_child_path(player_genre: String) -> String:
	return resolve_family_portrait("father", player_genre)


## Resolve only verified human family portraits. The father mapping intentionally
## follows the project's business rule: Homme -> father/daughter, otherwise ->
## father/son. Missing assets never fall back to a clan symbol or generic NPC.
static func resolve_family_portrait(role: String, player_gender: String) -> String:
	var normalized_role: String = _normalize_name(role)
	var normalized_gender: String = _normalize_name(player_gender)
	var path: String = ""
	match normalized_role:
		"mother", "mere":
			path = FAMILY_MOTHER
		"father", "pere":
			path = FAMILY_FATHER_WITH_DAUGHTER if normalized_gender in ["homme", "male"] else FAMILY_FATHER_WITH_SON
		"father alone", "pere seul":
			path = FAMILY_FATHER_ALONE
		"child", "enfant", "hero", "heros", "player", "protagonist", "fils", "fille":
			path = FAMILY_CHILD_BOY if normalized_gender in ["homme", "male"] else FAMILY_CHILD_GIRL
		_:
			push_warning("VisualAssetCatalog: rôle familial inconnu '%s'; aucun portrait affiché." % role)
			return ""

	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
		push_warning("VisualAssetCatalog: portrait familial '%s' introuvable à '%s'; aucun portrait affiché." % [role, path])
		return ""
	return path


static func world_path(key: String) -> String:
	return str(WORLD_ASSETS.get(key, ""))


static func resource_icon_path(key: String) -> String:
	return str(RESOURCE_ICONS.get(key, ""))


static func resource_label(key: String) -> String:
	return str(RESOURCE_LABELS.get(key, key.capitalize()))


static func menu_icon_path(action: String) -> String:
	var aliases: Array[String] = []
	match action:
		"new_game":
			aliases = ["nouvelle partie", "nouvelle_partie", "nouvelle", "new game", "new_game", "jouer", "play"]
		"continue_game":
			aliases = ["continuer", "continue", "reprendre", "charger", "load"]
		"options":
			aliases = ["paramètres", "parametres", "options", "réglages", "reglages", "settings"]
		"encyclopedia":
			aliases = ["encyclopédie", "encyclopedie", "chroniques", "lore", "codex"]
		"quit":
			aliases = ["quitter", "quit", "exit", "fermer"]
		_:
			aliases = [action]
	return find_semantic_asset(MENU_ICON_DIRECTORY, aliases)


static func load_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return ResourcePathResolver.load_texture(path, "res://assets/images")


## Rebuild the actual portrait chosen during character creation. Supports both
## the creation payload (image_base64/image_path) and the later clan-hub payload
## (encoding=png_base64/data).
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
	var files: PackedStringArray = directory.get_files()
	for file_name: String in files:
		if file_name.ends_with(".import") or file_name.begins_with("."):
			continue
		var extension: String = file_name.get_extension().to_lower()
		if extension not in ["png", "jpg", "jpeg", "webp", "svg"]:
			continue
		var stem: String = file_name.get_basename()
		var normalized_stem: String = _normalize_name(stem)
		for normalized_alias: String in normalized_aliases:
			var score: int = _semantic_match_score(normalized_stem, normalized_alias)
			if score > best_score:
				best_score = score
				best_path = "%s/%s" % [directory_path.trim_suffix("/"), file_name]
	return best_path


static func _semantic_match_score(candidate: String, alias: String) -> int:
	if candidate == alias:
		return 1000 + alias.length()
	if candidate.contains(alias):
		return 700 + alias.length()
	if alias.contains(candidate) and candidate.length() >= 4:
		return 400 + candidate.length()
	return 0


static func _normalize_name(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	for pair: Array in [
		["à", "a"], ["â", "a"], ["ä", "a"], ["á", "a"],
		["ç", "c"],
		["é", "e"], ["è", "e"], ["ê", "e"], ["ë", "e"],
		["î", "i"], ["ï", "i"], ["í", "i"],
		["ô", "o"], ["ö", "o"], ["ó", "o"],
		["ù", "u"], ["û", "u"], ["ü", "u"], ["ú", "u"],
		["ÿ", "y"],
	]:
		result = result.replace(str(pair[0]), str(pair[1]))
	for separator: String in ["_", "-", ".", "(", ")", "[", "]"]:
		result = result.replace(separator, " ")
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()


static func infer_kind(path: String) -> String:
	var p: String = path.to_lower()
	if p.contains("/pnj/") or p.contains("/hero/") or p.contains("ingrid") or p.contains("edwin") or p.contains("ceres"):
		return "portrait"
	if p.contains("/images/clan/") and (p.contains("mere") or p.contains("mère") or p.contains("pere") or p.contains("père")):
		return "portrait"
	if p.contains("hell_knight"):
		return "group"
	if p.contains("map"):
		return "map"
	if p.contains("clan/"):
		return "symbol"
	if p.contains("nine_nobles"):
		return "group"
	if p.contains("yomihara"):
		return "landscape"
	if p.contains("/icon/") or p.contains("/ui/icons/"):
		return "resource"
	return "contain"


static func apply_fit(rect: TextureRect, kind: String) -> void:
	if rect == null:
		return
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	match kind:
		"landscape":
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_:
			# Portraits, maps, emblems, groups and resources remain fully visible.
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
