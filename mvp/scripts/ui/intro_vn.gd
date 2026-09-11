## scripts/ui/intro_vn.gd
## Trois tableaux : duel → Essence volée → mort supposée → souvenirs interactifs.
extends Control
const Refuge = preload("res://scripts/services/refuge_service.gd")
var _choices: VBoxContainer
var _finishing := false
var _opening_mode := false
var _text_tween: Tween
const AnimationController = preload("res://scripts/ui/tutorials/character_animation_controller.gd")
var _actor: AnimationController

const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")

# ─────────────────────────────────────────────────────────────────────
#  NŒUDS (construits dynamiquement dans _ready)
# ─────────────────────────────────────────────────────────────────────
var _bg:              ColorRect       = null
var _illus:           TextureRect     = null
var _resource_visual: PanelContainer  = null
var _resource_grid:   GridContainer   = null
var _gradient:        ColorRect       = null
var _label_periode:   Label           = null
var _label_speaker:   Label           = null
var _story_text:      RichTextLabel   = null
var _btn_continue:    Button          = null

# Tutorial overlay
var _tuto_layer:      CanvasLayer     = null
var _tuto_panel:      PanelContainer  = null
var _tuto_title:      Label           = null
var _tuto_body:       RichTextLabel   = null
var _btn_tuto_ok:     Button          = null

# Recrutement overlay
var _recruit_layer:   CanvasLayer     = null
var _recruit_panel:   PanelContainer  = null
var _recruit_title:   Label           = null
var _recruit_role:    Label           = null
var _recruit_portrait: TextureRect     = null
var _recruit_desc:    RichTextLabel   = null
var _recruit_stats:   VBoxContainer   = null
var _btn_recruit:     Button          = null

# ─────────────────────────────────────────────────────────────────────
#  ÉTAT
# ─────────────────────────────────────────────────────────────────────
var _scenes:          Array           = []
var _idx:             int             = 0
var _animating:       bool            = false
var _pending_recruit: Dictionary      = {}
var _visual_bindings: Dictionary      = {}
var _resource_card_keys: Array        = []

# Données joueur (résolues une fois)
var _player_name: String  = "Héritier"
var _clan_name:   String  = "votre Clan"
var _parent_name: String  = "Ton Père"
var _pere_name: String    = "Ton Père"
var _mere_name: String    = "Ta Mère"
var _player_portrait_path: String = ""
var _player_portrait_texture: Texture2D = null
var _player_genre: String = ""


# ─────────────────────────────────────────────────────────────────────
#  ICÔNES RESSOURCES (mapping pour BBCode)

# ─────────────────────────────────────────────────────────────────────
#  ICÔNES RESSOURCES (mapping pour BBCode)
# ─────────────────────────────────────────────────────────────────────
const ICONS_BBCODE = {
    "or":        "res://assets/icon/gold.png",
    "soldats":   "res://assets/icon/soldat.png",
    "mana":      "res://assets/icon/mana.png",
    "nourriture": "res://assets/icon/food.png",
    "bois":      "res://assets/icon/wood.png",
    "fer":       "res://assets/icon/iron.png",
    "essence":   "res://assets/icon/essence.png",
}

# Remplacement emojis → icônes pixel art dans le texte BBCode
func _inject_icons(text: String) -> String:
	return text \
		.replace("🪙", "[img width=18 height=18]" + ICONS_BBCODE["or"] + "[/img]") \
		.replace("⚔", "[img width=18 height=18]" + ICONS_BBCODE["soldats"] + "[/img]") \
		.replace("✨", "[img width=18 height=18]" + ICONS_BBCODE["mana"] + "[/img]") \
		.replace("🌿", "[img width=18 height=18]" + ICONS_BBCODE["nourriture"] + "[/img]") \
		.replace("🪵", "[img width=18 height=18]" + ICONS_BBCODE["bois"] + "[/img]") \
		.replace("⛏", "[img width=18 height=18]" + ICONS_BBCODE["fer"] + "[/img]") \
		.replace("💎", "[img width=18 height=18]" + ICONS_BBCODE["essence"] + "[/img]")


func _ready() -> void:
	_opening_mode = bool(SaveSystem.get_value("opening", {}).get("active", false))
	if not _opening_mode: Refuge.initialize(ClanManager)
	_resolve_player_data()
	_load_visual_bindings()
	_build_ui()
	_actor = AnimationController.new()
	_actor.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_actor.position = Vector2(-130, 95)
	_actor.size = Vector2(260, 220)
	add_child(_actor)
	FallenUI.apply(self, "intro")
	_load_scenes()
	if _scenes.is_empty():
		push_error("IntroVN: aucune scène chargée — vérifier data/intro_vn.json")
		GameManager.go_to("clan_hub")
		return
	_show_scene(clampi(int(SaveSystem.get_value("opening", {}).get("index", 0)) if _opening_mode else int(ClanManager.campaign.get("intro_index", 0)), 0, _scenes.size() - 1))


func _resolve_player_data() -> void:
	if _opening_mode: return
	var cm: Node = get_node_or_null("/root/ClanManager")
	if cm == null:
		return
	_player_name = str(cm.get("nom_personnage") if cm.get("nom_personnage") != "" else "Héritier")
	_clan_name = str(cm.get("nom_clan") if cm.get("nom_clan") != "" else "votre Clan")
	var profil: Dictionary = (cm.get("profil_personnage") as Dictionary)
	_pere_name = str(profil.get("pere_name", "Ton Père"))
	_mere_name = str(profil.get("mere_name", "Ta Mère"))

	# Portrait explicite sélectionné par le joueur : priorité absolue.
	var portrait_payload := profil.get("portrait", {}) as Dictionary
	_player_portrait_texture = _texture_from_portrait_payload(portrait_payload)
	_player_portrait_path = str(portrait_payload.get("image_path", portrait_payload.get("path", ""))).strip_edges()
	if _player_portrait_texture == null and not _player_portrait_path.is_empty():
		_player_portrait_texture = ResourcePathResolver.load_texture(_player_portrait_path, "res://assets/images/hero")

	# La création de personnage stocke l'identité visuelle dans `apparence`, pas dans `genre`.
	var appearance: String = str(profil.get("apparence", profil.get("appearance_id", ""))).to_lower()
	var genre: String = str(profil.get("genre", "")).to_lower()
	if appearance.contains("femme") or genre == "femme" or genre == "female":
		_player_genre = "femme"
	elif appearance.contains("homme") or genre == "homme" or genre == "male":
		_player_genre = "homme"
	else:
		_player_genre = ""
	if _player_portrait_texture == null:
		if appearance.contains("femme") or genre == "femme" or genre == "female":
			_player_portrait_path = VisualAssetCatalog.person_path("player_female")
		elif appearance.contains("homme") or genre == "homme" or genre == "male":
			_player_portrait_path = VisualAssetCatalog.person_path("player_male")
		else:
			# Pas d'image si le profil ne permet pas d'identifier le visuel : mieux vaut du vide qu'un faux portrait.
			_player_portrait_path = ""

	if appearance.contains("femme") or genre == "femme" or genre == "female":
		_parent_name = _mere_name
	elif appearance.contains("homme") or genre == "homme" or genre == "male":
		_parent_name = _pere_name
	else:
		_parent_name = "Ton Parent"


func _texture_from_portrait_payload(payload: Dictionary) -> Texture2D:
	if payload.is_empty():
		return null
	var encoded := ""
	if str(payload.get("encoding", "")) == "png_base64":
		encoded = str(payload.get("data", ""))
	elif payload.has("image_base64"):
		encoded = str(payload.get("image_base64", ""))
	if encoded.is_empty():
		return null
	var raw := Marshalls.base64_to_raw(encoded)
	if raw.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(raw) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _load_visual_bindings() -> void:
	var path := "res://data/ui_visual_bindings.json"
	if not FileAccess.file_exists(path):
		push_warning("IntroVN: ui_visual_bindings.json absent; les scènes sans illustration resteront volontairement vides.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var root := parsed as Dictionary
		_visual_bindings = (root.get("intro_vn", {}) as Dictionary).duplicate(true)
		_resource_card_keys = (root.get("resource_cards", []) as Array).duplicate()


func _load_scenes() -> void:
	var path := "res://data/intro_vn.json"
	# Les ouvertures d'avant cette version reprennent leurs cinq tableaux connus.
	if not _opening_mode or int(SaveSystem.get_value("opening", {}).get("version", 0)) < 2:
		path = "res://data/intro_vn_legacy.json"
	if not FileAccess.file_exists(path):
		push_error("IntroVN: intro_vn.json introuvable à %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("IntroVN: impossible d'ouvrir intro_vn.json")
		return
	var raw_data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not raw_data is Dictionary:
		push_error("IntroVN: JSON invalide dans intro_vn.json")
		return
	var raw_scenes: Array = (raw_data as Dictionary).get("scenes", [])
	_scenes.clear()
	for raw_s in raw_scenes:
		var s: Dictionary = (raw_s as Dictionary).duplicate(true)
		# Substitution des templates dans le texte principal
		s["texte"] = _sub(str(s.get("texte", "")))
		# Substitution dans le pnj si présent
		if s.has("pnj"):
			var pnj: Dictionary = (s.get("pnj", {}) as Dictionary).duplicate(true)
			pnj["texte_serment"] = _sub(str(pnj.get("texte_serment", "")))
			s["pnj"] = pnj
		_scenes.append(s)


func _sub(text: String) -> String:
	return text \
		.replace("{player_name}", _player_name) \
		.replace("{clan_name}",   _clan_name) \
		.replace("{pere_name}",   _pere_name) \
		.replace("{mere_name}",   _mere_name) \
		.replace("{parent_name}", _parent_name)


# ─────────────────────────────────────────────────────────────────────
#  CONSTRUCTION DE L'INTERFACE
# ─────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# --- Fond pleine page ---
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.04, 0.0, 0.1, 1)
	add_child(_bg)

	# --- Illustration (60% haut) ---
	_illus = TextureRect.new()
	_illus.name = "Illustration"
	_illus.anchor_left   = 0.0
	_illus.anchor_top    = 0.0
	_illus.anchor_right  = 1.0
	_illus.anchor_bottom = 0.67
	_illus.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_illus.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_illus)

	# Visualisation dédiée aux ressources : de vraies cartes avec les vraies icônes,
	# jamais un symbole de clan ou une image de personnage utilisée comme substitut.
	_resource_visual = PanelContainer.new()
	_resource_visual.name = "ResourceVisual"
	_resource_visual.anchor_left = 0.08
	_resource_visual.anchor_top = 0.07
	_resource_visual.anchor_right = 0.92
	_resource_visual.anchor_bottom = 0.58
	var resource_style := StyleBoxFlat.new()
	resource_style.bg_color = Color(0.025, 0.008, 0.055, 0.94)
	resource_style.border_color = Color(0.48, 0.22, 0.70, 0.72)
	resource_style.set_border_width_all(1)
	resource_style.set_corner_radius_all(10)
	_resource_visual.add_theme_stylebox_override("panel", resource_style)
	add_child(_resource_visual)

	var resource_margin := MarginContainer.new()
	resource_margin.add_theme_constant_override("margin_left", 20)
	resource_margin.add_theme_constant_override("margin_top", 16)
	resource_margin.add_theme_constant_override("margin_right", 20)
	resource_margin.add_theme_constant_override("margin_bottom", 16)
	_resource_visual.add_child(resource_margin)
	var resource_vbox := VBoxContainer.new()
	resource_vbox.add_theme_constant_override("separation", 12)
	resource_margin.add_child(resource_vbox)
	var resource_title := Label.new()
	resource_title.text = "RESSOURCES DU CLAN"
	resource_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_title.add_theme_font_size_override("font_size", 18)
	resource_title.add_theme_color_override("font_color", Color(0.92, 0.74, 0.34, 1.0))
	resource_vbox.add_child(resource_title)
	_resource_grid = GridContainer.new()
	_resource_grid.columns = 4
	_resource_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resource_grid.add_theme_constant_override("h_separation", 12)
	_resource_grid.add_theme_constant_override("v_separation", 10)
	resource_vbox.add_child(_resource_grid)
	_build_resource_cards()
	_resource_visual.visible = false

	# Dégradé bas de l'illustration vers la boîte de texte
	_gradient = ColorRect.new()
	_gradient.name = "Gradient"
	_gradient.anchor_left   = 0.0
	_gradient.anchor_top    = 0.54
	_gradient.anchor_right  = 1.0
	_gradient.anchor_bottom = 0.70
	_gradient.color = Color(0.04, 0.0, 0.1, 0.8)
	add_child(_gradient)

	# --- Boîte de dialogue (38% bas) ---
	var text_panel := PanelContainer.new()
	text_panel.name = "TextBox"
	text_panel.anchor_left   = 0.0
	text_panel.anchor_top    = 1.0
	text_panel.offset_top = -280.0
	text_panel.anchor_right  = 1.0
	text_panel.anchor_bottom = 1.0
	text_panel.offset_left   = 24.0
	text_panel.offset_right  = -24.0
	text_panel.offset_bottom = -16.0
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.06, 0.0, 0.14, 0.9)
	style_bg.corner_radius_top_left     = 8
	style_bg.corner_radius_top_right    = 8
	style_bg.corner_radius_bottom_left  = 8
	style_bg.corner_radius_bottom_right = 8
	style_bg.border_width_top    = 1
	style_bg.border_width_bottom = 1
	style_bg.border_width_left   = 1
	style_bg.border_width_right  = 1
	style_bg.border_color = Color(0.4, 0.1, 0.6, 0.6)
	text_panel.add_theme_stylebox_override("panel", style_bg)
	add_child(text_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "InnerVBox"
	vbox.add_theme_constant_override("separation", 6)
	text_panel.add_child(vbox)

	# --- Étiquette de période (ex: "Il y a quinze ans") ---
	_label_periode = Label.new()
	_label_periode.name = "LabelPeriode"
	_label_periode.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0, 0.8))
	_label_periode.add_theme_font_size_override("font_size", 12)
	_label_periode.text = ""
	_label_periode.visible = false
	vbox.add_child(_label_periode)

	# --- Nom du personnage qui parle ---
	_label_speaker = Label.new()
	_label_speaker.name = "LabelSpeaker"
	_label_speaker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	_label_speaker.add_theme_font_size_override("font_size", 16)
	_label_speaker.text = ""
	_label_speaker.visible = false
	vbox.add_child(_label_speaker)

	# --- Texte narratif ---
	_story_text = RichTextLabel.new()
	_story_text.name = "StoryText"
	_story_text.bbcode_enabled = true
	_story_text.scroll_active = true
	_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_text.add_theme_font_size_override("normal_font_size", 16)
	_story_text.add_theme_color_override("default_color", Color(0.92, 0.88, 1.0, 1.0))
	_story_text.custom_minimum_size = Vector2(0, 118)
	_story_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_story_text)

	_choices = VBoxContainer.new()
	vbox.add_child(_choices)

	# --- Navigation intégrée à la boîte de texte : aucun bouton flottant hors-écran ---
	var nav_row := HBoxContainer.new()
	nav_row.name = "NarrationNav"
	nav_row.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(nav_row)
	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_row.add_child(nav_spacer)
	_btn_continue = Button.new()
	_btn_continue.name = "BtnContinue"
	_btn_continue.text = "Continuer ▶"
	_btn_continue.custom_minimum_size = Vector2(170, 38)
	_btn_continue.disabled = true
	_btn_continue.pressed.connect(_on_continue)
	nav_row.add_child(_btn_continue)

	# ── Tutorial overlay ────────────────────────────────────────────
	_tuto_layer = CanvasLayer.new()
	_tuto_layer.name = "TutoLayer"
	_tuto_layer.layer = 10
	add_child(_tuto_layer)

	var tuto_dim := ColorRect.new()
	tuto_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	tuto_dim.color = Color(0.0, 0.0, 0.0, 0.75)
	_tuto_layer.add_child(tuto_dim)

	_tuto_panel = PanelContainer.new()
	_tuto_panel.name = "TutoPanel"
	_tuto_panel.set_anchors_preset(Control.PRESET_CENTER)
	_tuto_panel.custom_minimum_size = Vector2(560, 420)
	_tuto_panel.offset_left  = -280
	_tuto_panel.offset_top   = -210
	_tuto_panel.offset_right =  280
	_tuto_panel.offset_bottom = 210
	var style_tuto := StyleBoxFlat.new()
	style_tuto.bg_color = Color(0.08, 0.02, 0.18, 0.97)
	style_tuto.corner_radius_top_left     = 12
	style_tuto.corner_radius_top_right    = 12
	style_tuto.corner_radius_bottom_left  = 12
	style_tuto.corner_radius_bottom_right = 12
	style_tuto.border_width_top    = 2
	style_tuto.border_width_bottom = 2
	style_tuto.border_width_left   = 2
	style_tuto.border_width_right  = 2
	style_tuto.border_color = Color(0.6, 0.2, 0.9, 0.9)
	_tuto_panel.add_theme_stylebox_override("panel", style_tuto)
	_tuto_layer.add_child(_tuto_panel)

	var tuto_vbox := VBoxContainer.new()
	tuto_vbox.add_theme_constant_override("separation", 12)
	_tuto_panel.add_child(tuto_vbox)

	_tuto_title = Label.new()
	_tuto_title.name = "TutoTitle"
	_tuto_title.add_theme_font_size_override("font_size", 18)
	_tuto_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	_tuto_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tuto_title.text = ""
	tuto_vbox.add_child(_tuto_title)

	var tuto_sep := HSeparator.new()
	tuto_vbox.add_child(tuto_sep)

	_tuto_body = RichTextLabel.new()
	_tuto_body.name = "TutoBody"
	_tuto_body.bbcode_enabled = true
	_tuto_body.scroll_active = true
	_tuto_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tuto_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tuto_body.add_theme_font_size_override("normal_font_size", 13)
	_tuto_body.add_theme_color_override("default_color", Color(0.88, 0.85, 1.0, 1.0))
	tuto_vbox.add_child(_tuto_body)

	_btn_tuto_ok = Button.new()
	_btn_tuto_ok.name = "BtnTutoOk"
	_btn_tuto_ok.text = "Compris !"
	_btn_tuto_ok.custom_minimum_size = Vector2(140, 36)
	_btn_tuto_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn_tuto_ok.pressed.connect(_on_tuto_ok)
	tuto_vbox.add_child(_btn_tuto_ok)

	_tuto_layer.visible = false

	# ── Recrutement overlay ─────────────────────────────────────────
	_recruit_layer = CanvasLayer.new()
	_recruit_layer.name = "RecruitLayer"
	_recruit_layer.layer = 11
	add_child(_recruit_layer)

	var recruit_dim := ColorRect.new()
	recruit_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	recruit_dim.color = Color(0.0, 0.0, 0.0, 0.80)
	_recruit_layer.add_child(recruit_dim)

	_recruit_panel = PanelContainer.new()
	_recruit_panel.name = "RecruitPanel"
	_recruit_panel.set_anchors_preset(Control.PRESET_CENTER)
	_recruit_panel.custom_minimum_size = Vector2(600, 500)
	_recruit_panel.offset_left  = -300
	_recruit_panel.offset_top   = -250
	_recruit_panel.offset_right =  300
	_recruit_panel.offset_bottom = 250
	var style_rec := StyleBoxFlat.new()
	style_rec.bg_color = Color(0.05, 0.01, 0.12, 0.97)
	style_rec.corner_radius_top_left     = 12
	style_rec.corner_radius_top_right    = 12
	style_rec.corner_radius_bottom_left  = 12
	style_rec.corner_radius_bottom_right = 12
	style_rec.border_width_top    = 2
	style_rec.border_width_bottom = 2
	style_rec.border_width_left   = 2
	style_rec.border_width_right  = 2
	style_rec.border_color = Color(0.2, 0.5, 1.0, 0.8)
	_recruit_panel.add_theme_stylebox_override("panel", style_rec)
	_recruit_layer.add_child(_recruit_panel)

	var rec_vbox := VBoxContainer.new()
	rec_vbox.add_theme_constant_override("separation", 10)
	_recruit_panel.add_child(rec_vbox)

	var rec_header_lbl := Label.new()
	rec_header_lbl.text = "⚔  Premier Allié"
	rec_header_lbl.add_theme_font_size_override("font_size", 14)
	rec_header_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.8))
	rec_header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec_vbox.add_child(rec_header_lbl)

	_recruit_title = Label.new()
	_recruit_title.name = "RecruitTitle"
	_recruit_title.add_theme_font_size_override("font_size", 22)
	_recruit_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	_recruit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recruit_title.text = ""
	rec_vbox.add_child(_recruit_title)

	_recruit_role = Label.new()
	_recruit_role.name = "RecruitRole"
	_recruit_role.add_theme_font_size_override("font_size", 13)
	_recruit_role.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 0.9))
	_recruit_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recruit_role.text = ""
	rec_vbox.add_child(_recruit_role)

	_recruit_portrait = TextureRect.new()
	_recruit_portrait.name = "RecruitPortrait"
	_recruit_portrait.custom_minimum_size = Vector2(132, 132)
	_recruit_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	VisualAssetCatalog.apply_fit(_recruit_portrait, "portrait")
	rec_vbox.add_child(_recruit_portrait)

	rec_vbox.add_child(HSeparator.new())

	_recruit_desc = RichTextLabel.new()
	_recruit_desc.name = "RecruitDesc"
	_recruit_desc.bbcode_enabled = true
	_recruit_desc.scroll_active = true
	_recruit_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recruit_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recruit_desc.add_theme_font_size_override("normal_font_size", 13)
	_recruit_desc.add_theme_color_override("default_color", Color(0.88, 0.85, 1.0, 1.0))
	rec_vbox.add_child(_recruit_desc)

	rec_vbox.add_child(HSeparator.new())

	var stats_lbl := Label.new()
	stats_lbl.text = "Statistiques"
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
	rec_vbox.add_child(stats_lbl)

	_recruit_stats = VBoxContainer.new()
	_recruit_stats.name = "RecruitStats"
	rec_vbox.add_child(_recruit_stats)

	rec_vbox.add_child(HSeparator.new())

	_btn_recruit = Button.new()
	_btn_recruit.name = "BtnRecruit"
	_btn_recruit.text = "Accueillir dans le clan"
	_btn_recruit.custom_minimum_size = Vector2(200, 40)
	_btn_recruit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn_recruit.pressed.connect(_on_recruit)
	rec_vbox.add_child(_btn_recruit)

	_recruit_layer.visible = false


# ─────────────────────────────────────────────────────────────────────
#  AFFICHAGE DES SCÈNES
# ─────────────────────────────────────────────────────────────────────

func _show_scene(idx: int) -> void:
	if idx >= _scenes.size():
		_finish()
		return
	_idx = idx
	if _opening_mode:
		var opening: Dictionary = SaveSystem.get_value("opening", {})
		opening["index"] = idx
		SaveSystem.set_value("opening", opening)
		SaveSystem.save()
	else:
		ClanManager.campaign["intro_index"] = idx
		ClanManager.sauvegarder()
	var s: Dictionary = _scenes[idx]
	$TextBox.offset_top = -340.0 if str(s.get("type", "")) == "choice" else -280.0
	$TextBox/InnerVBox/NarrationNav.visible = str(s.get("type", "")) != "choice"

	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	# Fond couleur
	var fond: String = str(s.get("fond_couleur", "#0a000f"))
	_bg.color = Color.from_string(fond, Color(0.04, 0.0, 0.1, 1.0))

	# Période
	var periode: String = str(s.get("periode", ""))
	_label_periode.text = _sub(periode)
	_label_periode.visible = not periode.is_empty()

	# Illustration explicitement liée au contenu de la scène.
	_apply_scene_visual(s)

	# Musique (uniquement si définie dans la scène)
	var musique: String = str(s.get("musique", ""))
	if not musique.is_empty():
		AudioManager.play_music(musique)

	# Type de scène
	var type: String = str(s.get("type", "narration"))
	match type:
		"fin":
			_btn_continue.text = "Retrouver mes souvenirs ▶" if _opening_mode else "Entrer dans le refuge ▶"
			_show_narration(s)
		"recrutement":
			_show_narration(s)
			# L'overlay de recrutement s'ouvre après le clic "continuer"
			_pending_recruit = s.get("pnj", {}) as Dictionary
		_:
			_btn_continue.text = "Continuer  ▶"
			_show_narration(s)

	if str(s.get("type", "")) == "choice":
		_btn_continue.visible = false
		for choice in s.get("choices", []):
			var button := Button.new()
			button.text = str(choice.label)
			button.custom_minimum_size.y = 36
			button.pressed.connect(func():
				if _opening_mode:
					var opening: Dictionary = SaveSystem.get_value("opening", {})
					opening["choices"][str(s.id)] = choice.get("consequence", "")
					SaveSystem.set_value("opening", opening)
					SaveSystem.save()
				else:
					Refuge.intro_choice(ClanManager, str(s.id), choice)
				_advance()
			)
			_choices.add_child(button)
		if _choices.get_child_count() > 0:
			_choices.get_child(0).grab_focus()
	else:
		_btn_continue.grab_focus()


func _show_narration(s: Dictionary) -> void:
	_tuto_layer.visible   = false
	_recruit_layer.visible = false
	_btn_continue.visible  = true
	_btn_continue.disabled = true

	# Speaker
	var speaker_raw: String = str(s.get("speaker", "narrateur"))
	var speaker: String = _resolve_speaker(speaker_raw)
	if speaker.is_empty():
		_label_speaker.visible = false
	else:
		_label_speaker.visible = true
		_label_speaker.text    = speaker

	# Texte avec typewriter
	var texte: String = str(s.get("texte", ""))
	_typewrite(texte)


func _resolve_speaker(raw: String) -> String:
	match raw:
		"narrateur":  return ""
		"parent":     return _parent_name
		"mere":       return _mere_name
		"pere":       return _pere_name
		"personnage": return _player_name
		"kael":       return "Kael"
		_:            return raw


func _typewrite(text: String) -> void:
	_animating = true
	_btn_continue.disabled = false
	_story_text.bbcode_enabled = true
	_story_text.text = ""
	_story_text.append_text(text)
	_story_text.visible_ratio = 0.0
	if _text_tween != null: _text_tween.kill()
	var tween: Tween = create_tween()
	_text_tween = tween
	var duration: float = clampf(float(text.length()) * 0.025, 0.4, 4.5)
	tween.tween_property(_story_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(func() -> void:
		_animating = false
		_btn_continue.disabled = false
	)


func _build_resource_cards(keys: Array = []) -> void:
	if _resource_grid == null:
		return
	for child in _resource_grid.get_children():
		child.queue_free()
	var source_keys: Array = keys if not keys.is_empty() else _resource_card_keys
	for raw_key in source_keys:
		var key: String = str(raw_key)
		var icon_path: String = VisualAssetCatalog.resource_icon_path(key)
		if icon_path.is_empty():
			continue
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(190, 96)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.075, 0.025, 0.11, 0.90)
		style.border_color = Color(0.32, 0.16, 0.45, 0.8)
		style.set_border_width_all(1)
		style.set_corner_radius_all(7)
		card.add_theme_stylebox_override("panel", style)
		_resource_grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(58, 58)
		icon.texture = ResourcePathResolver.load_texture(icon_path, "res://assets/icon")
		VisualAssetCatalog.apply_fit(icon, "resource")
		row.add_child(icon)
		var label := Label.new()
		label.text = VisualAssetCatalog.resource_label(key)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.98, 1.0))
		row.add_child(label)


func _apply_scene_visual(scene_data: Dictionary) -> void:
	_actor.visible = scene_data.has("placeholder")
	if _actor.visible:
		_actor.play(str(scene_data.placeholder))
		_resource_visual.hide()
		_illus.hide()
		return
	_resource_visual.visible = false
	_illus.visible = true
	_illus.texture = null

	# Une illustration écrite dans la donnée narrative est toujours prioritaire.
	var explicit: String = str(scene_data.get("illustration", "")).strip_edges()
	if not explicit.is_empty():
		_load_illustration(explicit, VisualAssetCatalog.infer_kind(explicit))
		return

	var scene_id: String = str(scene_data.get("id", ""))
	var binding: Dictionary = _visual_bindings.get(scene_id, {}) as Dictionary
	if binding.is_empty():
		push_warning("IntroVN: aucune association visuelle explicite pour '%s'" % scene_id)
		return

	var visual: String = str(binding.get("visual", "@none"))
	var mode: String = str(binding.get("mode", "contain"))
	if visual == "@none":
		_illus.visible = false
		return
	if visual == "@resources":
		_illus.visible = false
		var scene_resources: Array = (binding.get("resources", []) as Array).duplicate()
		_build_resource_cards(scene_resources)
		_resource_visual.visible = true
		return

	if visual == "@player":
		if _player_portrait_texture != null:
			_illus.texture = _player_portrait_texture
			_illus.visible = true
			VisualAssetCatalog.apply_fit(_illus, "portrait")
			return
		if _player_portrait_path.is_empty():
			_illus.visible = false
			return

	var path: String = _resolve_visual_token(visual)
	if path.is_empty():
		push_warning("IntroVN: token visuel non résolu '%s' pour '%s'" % [visual, scene_id])
		_illus.visible = false
		return
	_load_illustration(path, mode)


func _resolve_visual_token(token: String) -> String:
	match token:
		"@mother": return VisualAssetCatalog.person_path("mother")
		"@father": return VisualAssetCatalog.father_with_child_path(_player_genre)
		"@heir_child": return VisualAssetCatalog.heir_child_path(_player_genre)
		"@kael": return VisualAssetCatalog.person_path("kael")
		"@player": return _player_portrait_path
		"@clan": return VisualAssetCatalog.world_path("clan")
		"@nobles_symbol": return ""
		"@nobles_group": return ""
		"@map": return VisualAssetCatalog.world_path("veyr_world")
		"@marches": return VisualAssetCatalog.world_path("marches")
		"@hell_knight": return ""
		_: return token if token.begins_with("res://") else ""


func _load_illustration(illus_name: String, mode: String = "contain") -> void:
	var texture: Texture2D = ResourcePathResolver.load_texture(illus_name, "res://assets/images")
	_illus.texture = texture
	_illus.visible = texture != null
	VisualAssetCatalog.apply_fit(_illus, mode)
	if texture == null:
		push_warning("IntroVN: illustration introuvable '%s'" % illus_name)


# ─────────────────────────────────────────────────────────────────────
#  INTERACTIONS
# ─────────────────────────────────────────────────────────────────────

func _on_continue() -> void:
	if _finishing or _scenes.is_empty() or str(_scenes[_idx].get("type", "")) == "choice":
		return
	# Si l'animation est en cours → révèle instantanément
	if _animating:
		if _text_tween != null: _text_tween.kill()
		_story_text.visible_ratio = 1.0
		_animating = false
		_btn_continue.disabled = false
		return

	var s: Dictionary   = _scenes[_idx]
	var type: String    = str(s.get("type", "narration"))

	match type:
		"tutorial":
			# Ouvre l'overlay tutoriel AVANT d'avancer
			_open_tutorial(str(s.get("tutorial_type", "")))
		"recrutement":
			# Ouvre le panneau de recrutement si pas encore fait
			if not _pending_recruit.is_empty():
				_open_recruitment(_pending_recruit)
				_pending_recruit = {}
			else:
				_advance()
		"fin":
			_finish()
		_:
			_advance()


func _advance() -> void:
	_show_scene(_idx + 1)


# ─── Input clavier ────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _tuto_layer.visible or _recruit_layer.visible or not event is InputEventKey:
		return
	if event.is_action_pressed("ui_accept"):
		_on_continue()
		get_viewport().set_input_as_handled()


# ─────────────────────────────────────────────────────────────────────
#  OVERLAY TUTORIEL
# ─────────────────────────────────────────────────────────────────────


func _open_tutorial(ttype: String) -> void:
	_btn_continue.visible = false
	_tuto_layer.visible   = true
	match ttype:
		"ressources":
			_tuto_title.text = "Les Ressources du Clan"
			_tuto_body.text  = _inject_icons(_tuto_text_ressources())
		"actions":
			_tuto_title.text = "Le Cycle de Jeu"
			_tuto_body.text  = _inject_icons(_tuto_text_actions())
		"recrutement_pnj":
			_tuto_title.text = "Les Alliés du Clan"
			_tuto_body.text  = _inject_icons(_tuto_text_recrutement())
		_:
			_tuto_title.text = "Aide"
			_tuto_body.text  = "Aucune information disponible."


func _on_tuto_ok() -> void:
	_tuto_layer.visible   = false
	_btn_continue.visible = true
	_advance()


# ─── Contenus tutoriels ───────────────────────────────────────────────

func _tuto_text_ressources() -> String:
	return """[b][color=#ffdd66]Toutes les ressources de ton clan :[/color][/b]

[color=#ffcc44]🪙 Or[/color] — Monnaie principale. Recruter des soldats, bâtir des structures, négocier des alliances.
[color=#cc4444]⚔ Soldats[/color] — Force militaire. Consommés lors des attaques et des expéditions.
[color=#9966ff]✨ Mana[/color] — Énergie mystique. Nécessaire pour les pactes, rituels et sorts.
[color=#44aaff]⭐ Réputation[/color] — Influence politique. Ouvre des options diplomatiques.
[color=#88cc44]🌿 Nourriture[/color] — Nourrit tes soldats et tes PNJ. Sans nourriture, ton clan s'affaiblit.
[color=#aa8844]🪵 Bois[/color] — Construction de base.
[color=#888888]⛏ Fer[/color] — Armes et armures (Forgeron).
[color=#aaaaaa]🪨 Pierre[/color] — Fortifications.
[color=#cc66ff]💎 Essence[/color] — Ressource rare, nécessaire pour les pactes les plus puissants.

[color=#888888]Chaque tour, ton clan produit automatiquement des ressources selon ses PNJ et ses bâtiments.[/color]"""


func _tuto_text_actions() -> String:
	return """[b][color=#ffdd66]Les trois phases d'une journée :[/color][/b]

[color=#ffdd66]☀  MATIN — Planification[/color]
Tu choisis ton action principale. C'est ta décision stratégique du jour.
Actions disponibles :
  • [b]Attaquer[/b] — Assaille un bastion ennemi (coûte des soldats)
  • [b]Espionner[/b] — Révèle les forces d'une Maison Noble (coûte or + mana)
  • [b]Recruter[/b] — Renforce tes troupes en soldats (coûte de l'or)
  • [b]Diplomatie[/b] — Propose une trêve ou une alliance (coûte or + réputation)
  • [b]Fortifier[/b] — Renforce les défenses de ton bastion (coûte or)
  • [b]Repos[/b] — Récupère des ressources passives

[color=#ff9944]⚔  APRÈS-MIDI — Résolution[/color]
Tes [b]statistiques[/b] (Force, Magie, Commandement...) + un [b]jet de dé (d20)[/b] déterminent le résultat.
Plus tes stats sont élevées, plus tes chances de réussite sont grandes.

[color=#9966ff]🌙  SOIR — Gestion[/color]
Gère tes [b]PNJ alliés[/b] : envoie-les en mission, en support ou en expédition.
C'est aussi le moment des [b]pactes[/b] et du renforcement des alliances."""


func _tuto_text_recrutement() -> String:
	return """[b][color=#ffdd66]Les PNJ — piliers de ton clan :[/color][/b]

[b]Types de PNJ :[/b]
  • [color=#cc99ff]Scénario[/color] — Personnages narratifs importants (comme Kael)
  • [color=#88aaff]Recruté[/color] — PNJ générés selon tes besoins en cours de jeu

[b]Rôles Domaine (bonus de production par tour) :[/b]
  • [color=#888888]Forgeron[/color] → +Fer, +Pierre
  • [color=#cc66ff]Alchimiste[/color] → +Mana, +Essence
  • [color=#ffcc44]Intendant[/color] → +Or, +Nourriture
  • [color=#9966ff]Arcaniste[/color] → +Mana (et +Essence au niveau 5+)

[b][color=#88ddff]Affinité :[/color][/b]
Chaque interaction positive avec un PNJ augmente son [i]affinité[/i] envers toi.
Plus l'affinité est élevée, plus ses bonus sont puissants.

[b]Le soir, tu peux :[/b]
  • L'envoyer en [b]Support[/b] (bonus à ton action du lendemain)
  • L'envoyer en [b]Expédition[/b] (mini-donjon auto, récompenses possibles)"""


# ─────────────────────────────────────────────────────────────────────
#  OVERLAY RECRUTEMENT
# ─────────────────────────────────────────────────────────────────────

func _open_recruitment(pnj_data: Dictionary) -> void:
	if pnj_data.is_empty():
		_advance()
		return

	_btn_continue.visible  = false
	_recruit_layer.visible = true

	_recruit_title.text = str(pnj_data.get("nom", "Allié"))
	if _recruit_portrait != null:
		var pnj_id := str(pnj_data.get("id", "")).to_lower()
		var portrait_path := VisualAssetCatalog.person_path("kael") if pnj_id == "pnj_kael" else ""
		_recruit_portrait.texture = VisualAssetCatalog.load_path(portrait_path) if not portrait_path.is_empty() else null
		_recruit_portrait.visible = _recruit_portrait.texture != null
	_recruit_role.text  = "%s  —  Niveau %d" % [
		str(pnj_data.get("role", "Guerrier")).capitalize(),
		int(pnj_data.get("niveau", 1))
	]

	var desc: String    = str(pnj_data.get("description", ""))
	var serment: String = str(pnj_data.get("texte_serment", ""))
	_recruit_desc.text = desc + ("\n\n" + serment if not serment.is_empty() else "")

	# Statistiques
	for child in _recruit_stats.get_children():
		_recruit_stats.remove_child(child)
		child.queue_free()
	var stat_display := {
		"force": "Force",
		"magie": "Magie",
		"espionnage": "Espionnage",
		"artisanat": "Artisanat",
		"diplomatie": "Diplomatie",
		"commandement": "Commandement",
	}
	var pnj_stats: Dictionary = pnj_data.get("stats", {}) as Dictionary
	var stats_hbox := HFlowContainer.new()
	stats_hbox.add_theme_constant_override("h_separation", 12)
	stats_hbox.add_theme_constant_override("v_separation", 8)
	_recruit_stats.add_child(stats_hbox)
	for key in stat_display.keys():
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(78, 0)
		var name_lbl := Label.new()
		name_lbl.text = stat_display[key]
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 0.9))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_lbl)
		var val_lbl := Label.new()
		val_lbl.text = str(int(pnj_stats.get(key, 0)))
		val_lbl.add_theme_font_size_override("font_size", 14)
		val_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 1.0))
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(val_lbl)
		stats_hbox.add_child(col)

	_btn_recruit.set_meta("pnj_data", pnj_data)
	_btn_recruit.text = "Accueillir %s" % str(pnj_data.get("nom", "PNJ"))


func _on_recruit() -> void:
	var pnj_data: Dictionary = _btn_recruit.get_meta("pnj_data", {}) as Dictionary
	if not pnj_data.is_empty():
		var cm: Node = get_node_or_null("/root/ClanManager")
		if cm != null and cm.has_method("ajouter_pnj_gere"):
			cm.ajouter_pnj_gere(
				str(pnj_data.get("id",      "pnj_kael")),
				str(pnj_data.get("nom",     "Kael")),
				str(pnj_data.get("type",    "scenario")),
				str(pnj_data.get("role",    "garde")),
				int(pnj_data.get("niveau",  2)),
				pnj_data.get("stats", {}) as Dictionary
			)
		# Petit bonus d'affinité de départ pour le forgeron (Kael est un guerrier artisan)
		if cm != null and cm.has_method("modifier_affinite_pnj"):
			cm.modifier_affinite_pnj("forgeron", 5)

	_recruit_layer.visible = false
	_btn_continue.visible  = true
	_pending_recruit       = {}
	_advance()


# ─────────────────────────────────────────────────────────────────────
#  FIN DE L'INTRO
# ─────────────────────────────────────────────────────────────────────

func _finish() -> void:
	if _finishing: return
	_finishing = true
	_btn_continue.disabled = true
	if _opening_mode:
		var opening: Dictionary = SaveSystem.get_value("opening", {})
		opening["stage"] = "memories" if int(opening.get("version", 0)) >= 2 else "creation"
		opening["finished"] = str(opening.stage) == "creation"
		if str(opening.stage) == "memories" and not opening.has("memories"):
			opening["memories"] = preload("res://scripts/services/memory_tutorial_service.gd").fresh()
		SaveSystem.set_value("opening", opening)
	else:
		ClanManager.campaign["intro_done"] = true
		ClanManager.sauvegarder()
	SaveSystem.set_value("intro_done", true)
	SaveSystem.save()
	# Fondu léger avant la transition
	var tween: Tween = create_tween()
	tween.tween_property(_bg, "color", Color(0, 0, 0, 1), 1.2)
	await tween.finished
	if _opening_mode:
		GameManager.resume_campaign()
	else:
		GameManager.go_to("clan_hub")
