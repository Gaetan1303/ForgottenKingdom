extends PanelContainer
class_name PnjCard

const FKHelpers = preload("res://scripts/utils/fk_helpers.gd")

var _profile: Dictionary = {}

var _lbl_name: Label
var _lbl_role: Label
var _portrait: TextureRect
var _btn_support: Button
var _btn_exped: Button
var _btn_details: Button
var _details_panel: VBoxContainer
var _lbl_equip: Label
var _lbl_behavior: Label
var _detail_portrait: TextureRect
var _detail_stats: VBoxContainer

signal changed()

func _get_node_fallback(primary_path: String, fallback_path: String):
	var n = get_node_or_null(primary_path)
	if n:
		return n
	return get_node_or_null(fallback_path)

func _ready() -> void:
	_lbl_name = _get_node_fallback("HBox/Left/LabelName", "Left/LabelName")
	_lbl_role = _get_node_fallback("HBox/Left/LabelRole", "Left/LabelRole")
	_portrait = _get_node_fallback("HBox/Left/Portrait", "Left/Portrait")
	_btn_support = _get_node_fallback("HBox/Right/BtnSupport", "Right/BtnSupport")
	_btn_exped = _get_node_fallback("HBox/Right/BtnExpedition", "Right/BtnExpedition")
	_btn_details = _get_node_fallback("HBox/Right/BtnDetails", "Right/BtnDetails")
	_details_panel = get_node_or_null("DetailsPanel")
	_lbl_equip = get_node_or_null("DetailsPanel/DetailRow/DetailStats/StatList/LabelEquip")
	_lbl_behavior = get_node_or_null("DetailsPanel/DetailRow/DetailStats/StatList/LabelBehavior")
	_detail_portrait = get_node_or_null("DetailsPanel/DetailRow/DetailPortrait")
	_detail_stats = get_node_or_null("DetailsPanel/DetailRow/DetailStats/StatList")

	if _btn_support and not _btn_support.is_connected("pressed", Callable(self, "_on_support_pressed")):
		_btn_support.connect("pressed", Callable(self, "_on_support_pressed"))
	if _btn_exped and not _btn_exped.is_connected("pressed", Callable(self, "_on_exped_pressed")):
		_btn_exped.connect("pressed", Callable(self, "_on_exped_pressed"))
	if _btn_details and not _btn_details.is_connected("pressed", Callable(self, "_on_toggle_details")):
		_btn_details.connect("pressed", Callable(self, "_on_toggle_details"))

	# Force very small portrait sizes to ensure UI does not stretch large images
	if _portrait:
		_portrait.stretch_mode = 3
		_portrait.custom_minimum_size = Vector2(8, 8)
		_portrait.size_flags_horizontal = 0
		_portrait.size_flags_vertical = 0
	if _detail_portrait:
		_detail_portrait.stretch_mode = 3
		_detail_portrait.custom_minimum_size = Vector2(8, 8)
		_detail_portrait.size_flags_horizontal = 0
		_detail_portrait.size_flags_vertical = 0

	_apply_profile_to_ui()

func setup(profile: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_apply_profile_to_ui()

func _apply_profile_to_ui() -> void:
	if _profile.is_empty():
		return

	if _lbl_name:
		_lbl_name.text = "%s" % str(_profile.get("nom", _profile.get("id", "PNJ")))
	if _lbl_role:
		_lbl_role.text = "%s (niv.%d)" % [str(_profile.get("role", "?")), int(_profile.get("niveau", 1))]
	if _lbl_equip:
		var eq = _profile.get("equipment", [])
		if typeof(eq) == TYPE_ARRAY:
			_lbl_equip.text = "Equipement: %s" % FKHelpers.join_array(eq, ", ")
		else:
			_lbl_equip.text = "Equipement: -"
	if _lbl_behavior:
		var beh = _profile.get("behavior", {})
		if typeof(beh) == TYPE_DICTIONARY:
			_lbl_behavior.text = "Comportement: %s" % str(beh.get("behavior", "-"))
		else:
			_lbl_behavior.text = "Comportement: -"

	# Load portrait: exact match, then any file in class folder, then gender default
	# Load portrait: try PNJ-id based images first, then class folder, then gender default
	var pnj_class = str(_profile.get("classe", _profile.get("role", ""))).to_lower()
	var pnj_id_raw := str(_profile.get("id", "")).to_lower()
	var pnj_basename := ""
	if pnj_id_raw != "":
		pnj_basename = pnj_id_raw.replace("pnj_", "").replace(".pnj", "")
	var exts = [".png", ".jpg", ".svg", ".webp"]
	var found := false
	# 1) Try id-based exact
	if pnj_basename != "":
		for e in exts:
			var p_id = "res://assets/images/PNJ/%s/%s" % [pnj_basename, pnj_basename] + e
			if ResourceLoader.exists(p_id) and _portrait:
				_portrait.texture = load(p_id)
				found = true
				break
		if not found:
			for e in exts:
				var p_id2 = "res://assets/images/PNJ/%s" % pnj_basename + e
				if ResourceLoader.exists(p_id2) and _portrait:
					_portrait.texture = load(p_id2)
					found = true
					break
	# 1b) Search all subfolders of assets/images/PNJ for a file matching basename (case-insensitive)
	if not found and pnj_basename != "":
		var root = DirAccess.open("res://assets/images/PNJ")
		if root != null:
			root.list_dir_begin()
			var entry = root.get_next()
			while entry != "":
				if root.current_is_dir():
					var sub = DirAccess.open("res://assets/images/PNJ/%s" % entry)
					if sub != null:
						sub.list_dir_begin()
						var fname2 = sub.get_next()
						while fname2 != "":
							if not sub.current_is_dir():
								var lower_fname = fname2.to_lower()
								for e2 in exts:
									if lower_fname.ends_with(e2) and lower_fname.substr(0, lower_fname.length() - e2.length()) == pnj_basename:
										var p2 = "res://assets/images/PNJ/%s/%s" % [entry, fname2]
										if ResourceLoader.exists(p2) and _portrait:
											_portrait.texture = load(p2)
											found = true
											break
								if found:
									break
							fname2 = sub.get_next()
						sub.list_dir_end()
						if found:
							break
				entry = root.get_next()
			root.list_dir_end()
	# 2) Try class-based lookup
	if not found and pnj_class != "":
		var base = "res://assets/images/PNJ/%s/%s" % [pnj_class, pnj_class]
		for e in exts:
			var p = base + e
			if ResourceLoader.exists(p) and _portrait:
				_portrait.texture = load(p)
				found = true
				break
		if not found:
			var dir = DirAccess.open("res://assets/images/PNJ/%s" % pnj_class)
			if dir != null:
				dir.list_dir_begin()
				var fname = dir.get_next()
				while fname != "":
					if not dir.current_is_dir():
						for e2 in exts:
							if fname.to_lower().ends_with(e2):
								var p2 = "res://assets/images/PNJ/%s/%s" % [pnj_class, fname]
								if ResourceLoader.exists(p2) and _portrait:
									_portrait.texture = load(p2)
									found = true
									break
							if found:
								break
					fname = dir.get_next()
					dir.list_dir_end()

	if not found:
		var gender_val = str(_profile.get("sexe", _profile.get("gender", _profile.get("genre", "")))).to_lower()
		var is_female = (gender_val.find("f") != -1 or gender_val.find("femme") != -1 or gender_val.find("female") != -1)
		var tried = []
		if is_female:
			tried = [
				"res://assets/images/PNJ/defaut/femme_pnj.png",
				"res://assets/images/PNJ/defaut/femme_pnj.jpg",
				"res://assets/images/PNJ/defaut/female.png",
				"res://assets/images/PNJ/defaut/female.jpg",
			]
		else:
			tried = [
				"res://assets/images/PNJ/defaut/homme_pnj.png",
				"res://assets/images/PNJ/defaut/homme_pnj.jpg",
				"res://assets/images/PNJ/defaut/male.png",
				"res://assets/images/PNJ/defaut/male.jpg",
			]
		for p in tried:
			if ResourceLoader.exists(p) and _portrait:
				var tex2 = load(p)
				if tex2:
					_portrait.texture = tex2
					found = true
					break

	if _detail_portrait and _portrait and _portrait.texture:
		_detail_portrait.texture = _portrait.texture

	# Force a tiny texture copy (8x8) so the image always displays very small
	# even if layout/containers try to expand the control.
	if _portrait and _portrait.texture and typeof(_portrait.texture) != TYPE_NIL:
		var orig_tex = _portrait.texture
		if orig_tex is Texture2D:
			var img: Image = orig_tex.get_image()
			if img:
				img.resize(128, 128, Image.INTERPOLATE_NEAREST)
				var tiny = ImageTexture.create_from_image(img)
				if tiny:
					_portrait.texture = tiny
					if _detail_portrait:
						_detail_portrait.texture = tiny

	if _detail_stats:
		for child in _detail_stats.get_children():
			_detail_stats.remove_child(child)
			child.queue_free()
		var stats = _profile.get("stats", {}) as Dictionary
		if stats and typeof(stats) == TYPE_DICTIONARY:
			for k in stats.keys():
				var lbl = Label.new()
				lbl.text = "%s: %s" % [str(k).capitalize(), str(stats.get(k))]
				_detail_stats.add_child(lbl)

func _on_support_pressed() -> void:
	var pnj_id = str(_profile.get("id", ""))
	if pnj_id == "":
		return
	var cm = null
	if typeof(ClanManager) != TYPE_NIL:
		cm = ClanManager
	elif Engine.has_singleton("ClanManager"):
		cm = Engine.get_singleton("ClanManager")
	if cm and cm.has_method("assigner_pnj_support_journee"):
			var role = str(_profile.get("role", "")).to_lower()
			var role_map = {
				"garde": "attaquer",
				"stratege": "attaquer",
				"eclaireur": "espionner",
				"mage": "recuperer",
				"diplomate": "diplomatie",
				"marchand": "recuperer",
				"ennemi": "attaquer",
				"villageois": "recuperer",
			}
			var action = role_map.get(role, "attaquer")
			var res = cm.assigner_pnj_support_journee(pnj_id, action)
			if bool(res.get("ok", false)):
				emit_signal("changed")

func _on_exped_pressed() -> void:
	var pnj_id = str(_profile.get("id", ""))
	if pnj_id == "":
		return
	var cm = null
	if typeof(ClanManager) != TYPE_NIL:
		cm = ClanManager
	elif Engine.has_singleton("ClanManager"):
		cm = Engine.get_singleton("ClanManager")
	if cm and cm.has_method("assigner_pnj_expedition_journee"):
		var res = cm.assigner_pnj_expedition_journee(pnj_id, -1)
		if bool(res.get("ok", false)):
			emit_signal("changed")

func _on_toggle_details() -> void:
	if _details_panel:
		_details_panel.visible = not _details_panel.visible
 
