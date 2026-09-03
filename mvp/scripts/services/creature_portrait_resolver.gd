class_name CreaturePortraitResolver
extends RefCounted

const ROOT := "res://assets/images/PNJ"
const EXTENSIONS := [".png", ".jpg", ".jpeg", ".webp", ".svg"]


static func resolve(profile: Dictionary) -> Texture2D:
	var basename := _basename_from_profile(profile)
	var role := str(profile.get("classe", profile.get("role", ""))).to_lower()

	var texture := _load_exact_id(basename)
	if texture != null:
		return texture

	texture = _search_subfolders_for_basename(basename)
	if texture != null:
		return texture

	texture = _load_role_texture(role)
	if texture != null:
		return texture

	return _load_gender_default(profile)


static func resized(texture: Texture2D, size: Vector2i) -> Texture2D:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture
	image.resize(maxi(1, size.x), maxi(1, size.y), Image.INTERPOLATE_LANCZOS)
	var resized_texture := ImageTexture.create_from_image(image)
	return resized_texture if resized_texture != null else texture


static func _basename_from_profile(profile: Dictionary) -> String:
	var raw_id := str(profile.get("id", "")).to_lower().strip_edges()
	if raw_id.is_empty():
		return ""
	return raw_id.replace("pnj_", "").replace(".pnj", "")


static func _load_exact_id(basename: String) -> Texture2D:
	if basename.is_empty():
		return null
	for extension in EXTENSIONS:
		var nested := "%s/%s/%s%s" % [ROOT, basename, basename, extension]
		var texture := _load_texture(nested)
		if texture != null:
			return texture

		var direct := "%s/%s%s" % [ROOT, basename, extension]
		texture = _load_texture(direct)
		if texture != null:
			return texture
	return null


static func _search_subfolders_for_basename(basename: String) -> Texture2D:
	if basename.is_empty():
		return null
	var root_dir := DirAccess.open(ROOT)
	if root_dir == null:
		return null

	root_dir.list_dir_begin()
	var entry := root_dir.get_next()
	while not entry.is_empty():
		if root_dir.current_is_dir() and entry not in [".", ".."]:
			var sub_path := "%s/%s" % [ROOT, entry]
			var sub_dir := DirAccess.open(sub_path)
			if sub_dir != null:
				sub_dir.list_dir_begin()
				var filename := sub_dir.get_next()
				while not filename.is_empty():
					if not sub_dir.current_is_dir():
						var lowered := filename.to_lower()
						for extension in EXTENSIONS:
							if lowered == basename + extension:
								sub_dir.list_dir_end()
								root_dir.list_dir_end()
								return _load_texture("%s/%s" % [sub_path, filename])
					filename = sub_dir.get_next()
				sub_dir.list_dir_end()
		entry = root_dir.get_next()
	root_dir.list_dir_end()
	return null


static func _load_role_texture(role: String) -> Texture2D:
	if role.is_empty():
		return null
	for extension in EXTENSIONS:
		var exact := "%s/%s/%s%s" % [ROOT, role, role, extension]
		var texture := _load_texture(exact)
		if texture != null:
			return texture

	var role_dir := DirAccess.open("%s/%s" % [ROOT, role])
	if role_dir == null:
		return null
	role_dir.list_dir_begin()
	var filename := role_dir.get_next()
	while not filename.is_empty():
		if not role_dir.current_is_dir():
			for extension in EXTENSIONS:
				if filename.to_lower().ends_with(extension):
					role_dir.list_dir_end()
					return _load_texture("%s/%s/%s" % [ROOT, role, filename])
		filename = role_dir.get_next()
	role_dir.list_dir_end()
	return null


static func _load_gender_default(profile: Dictionary) -> Texture2D:
	var gender := str(profile.get("sexe", profile.get("gender", profile.get("genre", "")))).to_lower()
	var is_female := gender.contains("femme") or gender.contains("female") or gender.begins_with("f")
	var filename := "female.png" if is_female else "male.png"
	return _load_texture("%s/defaut/%s" % [ROOT, filename])


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var resource := ResourceLoader.load(path)
	return resource as Texture2D
