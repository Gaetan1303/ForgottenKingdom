## scripts/ui/intro_vn.gd
## Séquence d'introduction — Visual Novel + tutoriel intégré.
## Jouée une seule fois après la création du personnage.
## Flux : Passé (tutoriel) → La Chute → Serment → clan_hub
extends Control

signal slide_changed(from_idx: int, to_idx: int)

@export_range(0.60, 0.85, 0.01) var screen_image_ratio: float = 0.75
@export var taimanin_night_tint: Color = Color("#170a35")
@export var taimanin_deep_blue_tint: Color = Color("#0f193f")
@export var taimanin_gold_border_color: Color = Color("#c8a84b")
@export_range(4, 6, 1) var taimanin_gold_border_px: int = 5
@export_range(0.1, 2.0, 0.05) var slide_fade_in_duration: float = 0.30
@export_range(0.1, 2.0, 0.05) var slide_fade_out_duration: float = 0.30
@export_range(0.2, 1.2, 0.05) var portrait_enter_duration: float = 0.36
@export_range(20.0, 400.0, 1.0) var portrait_enter_offset_x: float = 140.0
@export_range(2.0, 8.0, 0.5) var portrait_idle_bob_amplitude: float = 4.0
@export_range(0.6, 6.0, 0.1) var portrait_idle_bob_period: float = 2.0
@export_range(1.0, 4.0, 0.5) var portrait_outline_size: float = 2.5
@export var portrait_outline_color: Color = Color(0, 0, 0, 1)
@export var parallax_sky_texture: Texture2D = preload("res://assets/backgrounds/background_menu.png")
@export var parallax_front_texture: Texture2D = preload("res://assets/images/clan/defaut.png")
@export var dialogue_parchment_texture: Texture2D = preload("res://assets/backgrounds/background_menu.png")

# ─────────────────────────────────────────────────────────────────────
#  NŒUDS (construits dynamiquement dans _ready)
# ─────────────────────────────────────────────────────────────────────
var _bg:              ColorRect       = null
var _parallax_bg:     ParallaxBackground = null
var _parallax_sky:    Sprite2D        = null
var _parallax_front:  Sprite2D        = null
var _illus_prev:      TextureRect     = null
var _illus:           TextureRect     = null
var _gradient:        ColorRect       = null
var _char_left:       TextureRect     = null
var _char_right:      TextureRect     = null
var _text_panel:      PanelContainer  = null
var _text_panel_frame: Panel          = null
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
var _recruit_desc:    RichTextLabel   = null
var _recruit_stats:   VBoxContainer   = null
var _btn_recruit:     Button          = null
var _transition_layer: CanvasLayer    = null
var _transition_rect: ColorRect       = null
var _transition_anim: AnimationPlayer = null
var _portrait_outline_material: ShaderMaterial = null

# ─────────────────────────────────────────────────────────────────────
#  ÉTAT
# ─────────────────────────────────────────────────────────────────────
var _scenes:          Array           = []
var _idx:             int             = 0
var _animating:       bool            = false
var _pending_recruit: Dictionary      = {}
var _illus_tween:     Tween           = null
var _shake_tween:     Tween           = null
var _text_panel_origin: Vector2       = Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _last_dialogue_speaker: String = ""
var _left_portrait_key: String = ""
var _right_portrait_key: String = ""
var _portrait_texture_cache: Dictionary = {}
var _portrait_bob_players: Dictionary = {}

const SCREEN_TEXT_RATIO := 0.30
const PORTRAIT_TOP_RATIO := 0.00
const PORTRAIT_SOLO_LEFT := 0.15
const PORTRAIT_SOLO_RIGHT := 0.85
const PORTRAIT_DUO_LEFT_LEFT := 0.00
const PORTRAIT_DUO_LEFT_RIGHT := 0.50
const PORTRAIT_DUO_RIGHT_LEFT := 0.50
const PORTRAIT_DUO_RIGHT_RIGHT := 1.00
const ENABLE_PORTRAIT_BG_REMOVAL := false

# Données joueur (résolues une fois)
var _player_name: String  = "Héritier"
var _clan_name:   String  = "votre Clan"
var _parent_name: String  = "Ton Père"
var _pere_name: String    = "Ton Père"
var _mere_name: String    = "Ta Mère"
var _player_gender: String = ""


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

const SPEAKER_COLORS = {
	"mere": Color(1.00, 0.66, 0.80, 1.0),
	"pere": Color(1.00, 0.80, 0.52, 1.0),
	"personnage": Color(0.82, 0.60, 1.00, 1.0),
	"kael": Color(0.56, 0.87, 1.00, 1.0),
	"narrateur": Color(1.00, 0.85, 0.40, 1.0),
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
	_rng.randomize()
	set_process(true)
	_resolve_player_data()
	_build_ui()
	resized.connect(_on_viewport_resized)
	_load_scenes()
	if _scenes.is_empty():
		push_error("IntroVN: aucune scène chargée — vérifier data/intro_vn.json")
		GameManager.go_to("clan_hub")
		return
	_show_scene(0)


func _on_viewport_resized() -> void:
	_apply_layout_ratios()


func _resolve_player_data() -> void:
	var cm: Node = get_node_or_null("/root/ClanManager")
	if cm == null:
		return
	_player_name = str(cm.get("nom_personnage") if cm.get("nom_personnage") != "" else "Héritier")
	_clan_name   = str(cm.get("nom_clan")       if cm.get("nom_clan")       != "" else "votre Clan")
	var profil: Dictionary = (cm.get("profil_personnage") as Dictionary)
	_player_gender = str(profil.get("genre", ""))

	# Intro canon demandée: les parents prennent le nom de clan saisi.
	var clan_suffix := _clan_name.strip_edges()
	if clan_suffix == "" or clan_suffix.to_lower() == "votre clan":
		_pere_name = "Orcus"
		_mere_name = "Dorothy"
	else:
		_pere_name = "Orcus %s" % clan_suffix
		_mere_name = "Dorothy %s" % clan_suffix

	if _player_gender == "Femme":
		_parent_name = _mere_name
	elif _player_gender == "Homme":
		_parent_name = _pere_name
	else:
		_parent_name = "Ton Parent"


func _load_scenes() -> void:
	var path := "res://data/intro_vn.json"
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
	_bg.color = taimanin_night_tint
	add_child(_bg)
	_setup_parallax_background()

	# --- Illustration (70% haut) ---
	_illus_prev = TextureRect.new()
	_illus_prev.name = "IllustrationPrev"
	_illus_prev.anchor_left   = 0.0
	_illus_prev.anchor_top    = 0.0
	_illus_prev.anchor_right  = 1.0
	_illus_prev.anchor_bottom = screen_image_ratio
	_illus_prev.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illus_prev.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	_illus_prev.modulate = Color(1, 1, 1, 0)
	add_child(_illus_prev)

	_illus = TextureRect.new()
	_illus.name = "Illustration"
	_illus.anchor_left   = 0.0
	_illus.anchor_top    = 0.0
	_illus.anchor_right  = 1.0
	_illus.anchor_bottom = screen_image_ratio
	_illus.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illus.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_illus)

	# Dégradé bas de l'illustration vers la boîte de texte
	_gradient = ColorRect.new()
	_gradient.name = "Gradient"
	_gradient.anchor_left   = 0.0
	_gradient.anchor_top    = screen_image_ratio - 0.14
	_gradient.anchor_right  = 1.0
	_gradient.anchor_bottom = screen_image_ratio + 0.02
	_gradient.color = Color(taimanin_night_tint.r, taimanin_night_tint.g, taimanin_night_tint.b, 0.82)
	add_child(_gradient)

	# Duo portraits style VN (gauche/droite), façon dialogue taimanin.
	_char_left = TextureRect.new()
	_char_left.name = "CharacterLeft"
	_char_left.anchor_left = 0.00
	_char_left.anchor_top = PORTRAIT_TOP_RATIO
	_char_left.anchor_right = 0.46
	_char_left.anchor_bottom = screen_image_ratio
	_char_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_char_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_left.modulate = Color(1, 1, 1, 0)
	_char_left.visible = false
	add_child(_char_left)

	_char_right = TextureRect.new()
	_char_right.name = "CharacterRight"
	_char_right.anchor_left = 0.54
	_char_right.anchor_top = PORTRAIT_TOP_RATIO
	_char_right.anchor_right = 1.00
	_char_right.anchor_bottom = screen_image_ratio
	_char_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_char_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_right.modulate = Color(1, 1, 1, 0)
	_char_right.visible = false
	add_child(_char_right)

	# --- Boîte de dialogue (30% bas) ---
	_text_panel = PanelContainer.new()
	_text_panel.name = "TextBox"
	_text_panel.anchor_left   = 0.0
	_text_panel.anchor_top    = screen_image_ratio
	_text_panel.anchor_right  = 1.0
	_text_panel.anchor_bottom = 1.0
	_text_panel.offset_left   = 20.0
	_text_panel.offset_right  = -20.0
	_text_panel.offset_bottom = -10.0
	_setup_taimanin_panel()
	add_child(_text_panel)
	_text_panel_origin = _text_panel.position

	var vbox := VBoxContainer.new()
	vbox.name = "InnerVBox"
	vbox.add_theme_constant_override("separation", 6)
	_text_panel.add_child(vbox)

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
	_label_speaker.add_theme_font_size_override("font_size", 15)
	_label_speaker.text = ""
	_label_speaker.visible = false
	vbox.add_child(_label_speaker)

	# --- Texte narratif ---
	_story_text = RichTextLabel.new()
	_story_text.name = "StoryText"
	_story_text.bbcode_enabled = true
	_story_text.scroll_active = false
	_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_text.add_theme_font_size_override("normal_font_size", 15)
	_story_text.add_theme_color_override("default_color", Color(0.92, 0.88, 1.0, 1.0))
	_story_text.custom_minimum_size = Vector2(0, 100)
	_story_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_story_text)

	# --- Bouton continuer ---
	_btn_continue = Button.new()
	_btn_continue.name = "BtnContinue"
	_btn_continue.text = "Continuer ▶"
	_btn_continue.anchor_left   = 1.0
	_btn_continue.anchor_top    = 1.0
	_btn_continue.anchor_right  = 1.0
	_btn_continue.anchor_bottom = 1.0
	_btn_continue.offset_left   = -160.0
	_btn_continue.offset_top    = -44.0
	_btn_continue.offset_bottom = -10.0
	_btn_continue.offset_right  = -20.0
	_btn_continue.disabled = true
	_btn_continue.pressed.connect(_on_continue)
	add_child(_btn_continue)

	_setup_transition_overlay()

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
	_tuto_body.scroll_active = false
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
	_btn_tuto_ok.focus_mode = Control.FOCUS_ALL
	_btn_tuto_ok.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	_recruit_panel.custom_minimum_size = Vector2(520, 440)
	_recruit_panel.offset_left  = -260
	_recruit_panel.offset_top   = -220
	_recruit_panel.offset_right =  260
	_recruit_panel.offset_bottom = 220
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

	rec_vbox.add_child(HSeparator.new())

	_recruit_desc = RichTextLabel.new()
	_recruit_desc.name = "RecruitDesc"
	_recruit_desc.bbcode_enabled = true
	_recruit_desc.scroll_active = false
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
	_apply_layout_ratios()
	_setup_portrait_outline_material()


func _setup_parallax_background() -> void:
	_parallax_bg = ParallaxBackground.new()
	_parallax_bg.name = "taimaninParallax"
	_parallax_bg.scroll_base_scale = Vector2.ONE
	add_child(_parallax_bg)

	var sky_layer := ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.12, 0.04)
	_parallax_bg.add_child(sky_layer)
	_parallax_sky = Sprite2D.new()
	_parallax_sky.name = "SkyLayer"
	_parallax_sky.centered = false
	_parallax_sky.modulate = taimanin_night_tint.lightened(0.24)
	_parallax_sky.texture = parallax_sky_texture
	sky_layer.add_child(_parallax_sky)

	var front_layer := ParallaxLayer.new()
	front_layer.motion_scale = Vector2(0.26, 0.10)
	_parallax_bg.add_child(front_layer)
	_parallax_front = Sprite2D.new()
	_parallax_front.name = "FrontLayer"
	_parallax_front.centered = false
	_parallax_front.modulate = taimanin_deep_blue_tint.darkened(0.12)
	_parallax_front.texture = parallax_front_texture
	front_layer.add_child(_parallax_front)


func _setup_transition_overlay() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.name = "SlideTransitionLayer"
	_transition_layer.layer = 12
	add_child(_transition_layer)

	_transition_rect = ColorRect.new()
	_transition_rect.name = "SlideFade"
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.color = Color(0, 0, 0, 0)
	_transition_layer.add_child(_transition_rect)

	_transition_anim = AnimationPlayer.new()
	_transition_anim.name = "SlideTransitionAnimation"
	_transition_layer.add_child(_transition_anim)
	_rebuild_transition_animations()


func _rebuild_transition_animations() -> void:
	if _transition_anim == null:
		return
	for n in ["fade_in", "fade_out"]:
		if _transition_anim.has_animation(n):
			_transition_anim.remove_animation_library("")
			break
	var lib := AnimationLibrary.new()

	var fade_in := Animation.new()
	fade_in.length = slide_fade_in_duration
	var in_track := fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(in_track, NodePath("../SlideFade:color"))
	fade_in.track_insert_key(in_track, 0.0, Color(0, 0, 0, 0))
	fade_in.track_insert_key(in_track, slide_fade_in_duration, Color(0, 0, 0, 1))
	lib.add_animation("fade_in", fade_in)

	var fade_out := Animation.new()
	fade_out.length = slide_fade_out_duration
	var out_track := fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(out_track, NodePath("../SlideFade:color"))
	fade_out.track_insert_key(out_track, 0.0, Color(0, 0, 0, 1))
	fade_out.track_insert_key(out_track, slide_fade_out_duration, Color(0, 0, 0, 0))
	lib.add_animation("fade_out", fade_out)

	_transition_anim.add_animation_library("", lib)


func _setup_portrait_outline_material() -> void:
	var outline_shader := Shader.new()
	outline_shader.code = """
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size = 2.5;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE * outline_size;
	float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	a = max(a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	vec4 outlined = vec4(outline_color.rgb, a * outline_color.a);
	COLOR = mix(outlined, base, base.a);
}
"""
	_portrait_outline_material = ShaderMaterial.new()
	_portrait_outline_material.shader = outline_shader
	_portrait_outline_material.set_shader_parameter("outline_size", portrait_outline_size)
	_portrait_outline_material.set_shader_parameter("outline_color", portrait_outline_color)


func _setup_taimanin_panel() -> void:
	if _text_panel == null:
		return
	var style_bg: StyleBox
	if dialogue_parchment_texture != null:
		var parchment := StyleBoxTexture.new()
		parchment.texture = dialogue_parchment_texture
		parchment.texture_margin_left = 16
		parchment.texture_margin_right = 16
		parchment.texture_margin_top = 16
		parchment.texture_margin_bottom = 16
		parchment.expand_margin_left = 14.0
		parchment.expand_margin_right = 14.0
		parchment.expand_margin_top = 10.0
		parchment.expand_margin_bottom = 10.0
		style_bg = parchment
	else:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = taimanin_deep_blue_tint
		fallback.corner_radius_top_left = 14
		fallback.corner_radius_top_right = 14
		fallback.corner_radius_bottom_left = 14
		fallback.corner_radius_bottom_right = 14
		style_bg = fallback

	_text_panel.add_theme_stylebox_override("panel", style_bg)

	if _text_panel_frame != null and is_instance_valid(_text_panel_frame):
		_text_panel_frame.queue_free()
	_text_panel_frame = Panel.new()
	_text_panel_frame.name = "TextBoxFrame"
	_text_panel_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_panel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_panel.add_child(_text_panel_frame)

	var border := StyleBoxFlat.new()
	border.bg_color = Color(0.02, 0.02, 0.05, 0.0)
	border.corner_radius_top_left = 16
	border.corner_radius_top_right = 16
	border.corner_radius_bottom_left = 16
	border.corner_radius_bottom_right = 16
	border.border_width_top = taimanin_gold_border_px
	border.border_width_bottom = taimanin_gold_border_px
	border.border_width_left = taimanin_gold_border_px
	border.border_width_right = taimanin_gold_border_px
	border.border_color = taimanin_gold_border_color
	_text_panel_frame.add_theme_stylebox_override("panel", border)


func play_character_enter(portrait_node: TextureRect, side: String) -> void:
	if portrait_node == null:
		return
	if _portrait_outline_material != null:
		portrait_node.material = _portrait_outline_material.duplicate(true)

	var dir := -1.0 if side == "left" else 1.0
	portrait_node.visible = true
	portrait_node.modulate.a = 0.0
	portrait_node.position = Vector2(dir * portrait_enter_offset_x, 0.0)

	var enter := create_tween()
	enter.set_parallel(true)
	enter.tween_property(portrait_node, "position", Vector2.ZERO, portrait_enter_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	enter.tween_property(portrait_node, "modulate:a", 1.0, portrait_enter_duration * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	enter.finished.connect(func() -> void:
		_ensure_idle_bob(portrait_node)
	)


func _ensure_idle_bob(portrait_node: TextureRect) -> void:
	if portrait_node == null:
		return
	var key := portrait_node.name
	var anim_player: AnimationPlayer = _portrait_bob_players.get(key, null)
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "IdleBobPlayer"
		portrait_node.add_child(anim_player)
		_portrait_bob_players[key] = anim_player

	if anim_player.has_animation("idle_bob"):
		anim_player.stop()
		if anim_player.has_animation_library(""):
			anim_player.remove_animation_library("")

	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = portrait_idle_bob_period
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("..:position:y"))
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, portrait_idle_bob_period * 0.5, -portrait_idle_bob_amplitude)
	anim.track_insert_key(track, portrait_idle_bob_period, 0.0)

	var lib := AnimationLibrary.new()
	lib.add_animation("idle_bob", anim)
	anim_player.add_animation_library("", lib)
	anim_player.play("idle_bob")


func _fit_parallax_to_viewport() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var layers: Array[Sprite2D] = []
	if _parallax_sky != null:
		layers.append(_parallax_sky)
	if _parallax_front != null:
		layers.append(_parallax_front)

	for s: Sprite2D in layers:
		if s.texture == null:
			continue
		var tex_size: Vector2 = s.texture.get_size()
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			continue
		var scale_x: float = vp.x / tex_size.x
		var scale_y: float = vp.y / tex_size.y
		var k: float = maxf(scale_x, scale_y)
		s.scale = Vector2(k, k)
		s.position = Vector2.ZERO


func _process(delta: float) -> void:
	if _parallax_bg == null:
		return
	_parallax_bg.scroll_offset.x += 16.0 * delta
	_parallax_bg.scroll_offset.y += 5.0 * delta


func transition_slide(from_idx: int, to_idx: int) -> void:
	if _transition_anim == null or _transition_rect == null:
		_show_scene(to_idx)
		slide_changed.emit(from_idx, to_idx)
		return

	_rebuild_transition_animations()
	_transition_anim.play("fade_in")
	await _transition_anim.animation_finished

	slide_changed.emit(from_idx, to_idx)
	_show_scene(to_idx)

	_transition_anim.play("fade_out")
	await _transition_anim.animation_finished


func _apply_layout_ratios() -> void:
	if _illus_prev != null:
		_illus_prev.anchor_top = 0.0
		_illus_prev.anchor_bottom = screen_image_ratio
	if _illus != null:
		_illus.anchor_top = 0.0
		_illus.anchor_bottom = screen_image_ratio
	if _gradient != null:
		_gradient.anchor_top = maxf(0.0, screen_image_ratio - 0.14)
		_gradient.anchor_bottom = minf(1.0, screen_image_ratio + 0.02)
	if _text_panel != null:
		var vp_w := get_viewport_rect().size.x
		var margin := clampf(vp_w * 0.016, 12.0, 28.0)
		_text_panel.anchor_top = screen_image_ratio
		_text_panel.anchor_bottom = 1.0
		_text_panel.offset_left = margin
		_text_panel.offset_right = -margin
		_text_panel.offset_bottom = -maxf(8.0, margin * 0.45)
		_text_panel_origin = _text_panel.position
	_fit_parallax_to_viewport()
	if _btn_continue != null:
		var vp_w2 := get_viewport_rect().size.x
		var margin2 := clampf(vp_w2 * 0.016, 12.0, 28.0)
		_btn_continue.offset_left = -160.0
		_btn_continue.offset_top = -44.0
		_btn_continue.offset_right = -margin2
		_btn_continue.offset_bottom = -maxf(8.0, margin2 * 0.45)


# ─────────────────────────────────────────────────────────────────────
#  AFFICHAGE DES SCÈNES
# ─────────────────────────────────────────────────────────────────────

func _show_scene(idx: int) -> void:
	if idx >= _scenes.size():
		_finish()
		return
	_idx = idx
	var s: Dictionary = _scenes[idx]

	# Fond couleur
	var fond: String = str(s.get("fond_couleur", "#0a000f"))
	_bg.color = Color.from_string(fond, Color(0.04, 0.0, 0.1, 1.0))

	# Période
	var periode: String = str(s.get("periode", ""))
	_label_periode.text = periode
	_label_periode.visible = not periode.is_empty()

	# Illustration (désactivée en mode dialogue duo pour éviter une 3e image de fond)
	var speaker_raw_scene: String = str(s.get("speaker", "narrateur"))
	var duo_mode_scene := _is_dialogue_speaker(speaker_raw_scene)
	print("IntroVN: show_scene idx=%d speaker=%s duo_mode=%s" % [_idx, speaker_raw_scene, str(duo_mode_scene)])
	if duo_mode_scene:
		if _illus:
			_illus.visible = false
		if _illus_prev:
			_illus_prev.visible = false
	else:
		var illus_key := str(s.get("illustration", "")).strip_edges()
		if illus_key.is_empty():
			illus_key = _default_illustration_for_scene(s)
		_apply_illustration_transition(illus_key, s)

	# Musique (uniquement si définie dans la scène)
	var musique: String = str(s.get("musique", ""))
	if not musique.is_empty():
		AudioManager.play_music(musique)

	# Type de scène
	var type: String = str(s.get("type", "narration"))
	match type:
		"fin":
			_btn_continue.text = "Commencer l'aventure  ▶"
			_show_narration(s)
		"recrutement":
			_show_narration(s)
			# L'overlay de recrutement s'ouvre après le clic "continuer"
			_pending_recruit = s.get("pnj", {}) as Dictionary
		_:
			_btn_continue.text = "Continuer  ▶"
			_show_narration(s)


func _show_narration(s: Dictionary) -> void:
	_tuto_layer.visible   = false
	_recruit_layer.visible = false
	_btn_continue.visible  = true
	_btn_continue.disabled = true

	# Speaker
	var speaker_raw: String = str(s.get("speaker", "narrateur"))
	var speaker: String = _resolve_speaker(speaker_raw)
	var duo_mode := _is_dialogue_speaker(speaker_raw)
	_set_dialogue_visual_mode(duo_mode)
	_update_duo_portraits(speaker_raw)
	_label_speaker.add_theme_color_override("font_color", _speaker_color(speaker_raw))
	if speaker.is_empty():
		_label_speaker.visible = false
	else:
		_label_speaker.visible = true
		_label_speaker.text    = speaker

	# Texte avec typewriter
	var texte: String = str(s.get("texte", ""))
	_typewrite(texte, s)
	if _is_dramatic_scene(s):
		_play_scene_impact(s)


func _resolve_speaker(raw: String) -> String:
	match raw:
		"narrateur":  return ""
		"parent":     return _parent_name
		"mere":       return _mere_name
		"pere":       return _pere_name
		"personnage": return _player_name
		"kael":       return "Kael"
		_:            return raw


func _speaker_color(raw: String) -> Color:
	var key := raw.to_lower()
	if SPEAKER_COLORS.has(key):
		return SPEAKER_COLORS[key]
	return SPEAKER_COLORS["narrateur"]


func _set_dialogue_visual_mode(duo_mode: bool) -> void:
	if _illus != null:
		_illus.visible = not duo_mode
	if _illus_prev != null:
		_illus_prev.visible = not duo_mode
	if _char_left != null:
		_char_left.visible = duo_mode and _char_left.texture != null
	if _char_right != null:
		_char_right.visible = duo_mode and _char_right.texture != null


func _default_illustration_for_scene(scene_data: Dictionary) -> String:
	var speaker_raw := str(scene_data.get("speaker", "")).to_lower()
	match speaker_raw:
		"mere":
			return "clan/mère/Okasa-sama (6).png"
		"pere":
			return _default_father_illustration()
		"personnage":
			return _default_hero_illustration()
		"parent":
			return "clan/mère/Okasa-sama (6).png" if _player_gender == "Femme" else _default_father_illustration()
		"kael":
			return "PNJ/defaut/Kael.png"

	var sid := str(scene_data.get("id", "")).to_lower()
	if sid.begins_with("famille") or sid.begins_with("lecon") or sid.begins_with("chute") or sid.begins_with("serment") or sid.begins_with("exil"):
		return _default_hero_illustration()
	return ""


func _default_hero_illustration() -> String:
	if _player_gender == "Femme":
		return "clan/hero-children/girl (1).png"
	return "clan/hero-children/boy.png"


func _default_father_illustration() -> String:
	# Image de base demandee pour le pere.
	if ResourceLoader.exists("res://assets/images/clan/Pere et fils/Ottosama_00002_.png"):
		return "clan/Pere et fils/Ottosama_00002_.png"
	if ResourceLoader.exists("res://assets/images/clan/Pere et fille/Ottosama_00002_.png"):
		return "clan/Pere et fille/Ottosama_00002_.png"
	return "clan/Pere et fils/Ottosama_00028_.png"


func _is_dialogue_speaker(raw: String) -> bool:
	var key := raw.to_lower()
	return key == "mere" or key == "pere" or key == "personnage" or key == "kael" or key == "parent"


func _normalized_speaker_key(raw: String) -> String:
	var key := raw.to_lower()
	if key == "parent":
		return "mere" if _player_gender == "Femme" else "pere"
	if _is_dialogue_speaker(key):
		return key
	return ""


func _default_counterpart_for(key: String) -> String:
	match key:
		"mere": return "personnage"
		"pere": return "personnage"
		"kael": return "personnage"
		"personnage": return "pere"
		_:
			return ""


func _speaker_prefers_left(key: String) -> bool:
	match key:
		"mere":
			return true
		"personnage":
			return true
		"pere":
			return false
		"kael":
			return false
		_:
			return true


func _portrait_path_for_speaker(key: String) -> String:
	match key:
		"mere":
			return "clan/mère/Okasa-sama (6).png"
		"pere":
			return _default_father_illustration()
		"personnage":
			return _default_hero_illustration()
		"kael":
			return "PNJ/defaut/Kael.png"
		_:
			return ""


func _apply_portrait_slot(slot: TextureRect, key: String, is_left: bool, solo_mode: bool = false) -> void:
	if slot == null:
		return

	# Portrait unique = grand cadre central. Duo = deux cadres larges et symetriques.
	if solo_mode:
		slot.anchor_left = PORTRAIT_SOLO_LEFT
		slot.anchor_right = PORTRAIT_SOLO_RIGHT
		slot.offset_left = 0.0
		slot.offset_right = 0.0
	else:
		if is_left:
			slot.anchor_left = PORTRAIT_DUO_LEFT_LEFT
			slot.anchor_right = PORTRAIT_DUO_LEFT_RIGHT
			slot.offset_left = 0.0
			slot.offset_right = -2.0
		else:
			slot.anchor_left = PORTRAIT_DUO_RIGHT_LEFT
			slot.anchor_right = PORTRAIT_DUO_RIGHT_RIGHT
			slot.offset_left = 2.0
			slot.offset_right = 0.0
	slot.anchor_top = PORTRAIT_TOP_RATIO
	slot.anchor_bottom = screen_image_ratio
	slot.offset_top = 0.0
	slot.offset_bottom = 0.0
	slot.scale = Vector2.ONE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var p := _portrait_path_for_speaker(key)
	if p == "":
		slot.visible = false
		slot.texture = null
		return
	var tex := _resolve_portrait_texture(p)
	if tex == null:
		slot.visible = false
		slot.texture = null
		return

	slot.visible = true
	var changed := slot.texture != tex
	slot.texture = tex

	if changed:
		slot.scale = Vector2.ONE
		slot.pivot_offset = slot.size * 0.5
		play_character_enter(slot, "left" if is_left else "right")
	else:
		slot.pivot_offset = slot.size * 0.5
		slot.position = Vector2.ZERO
		slot.modulate = Color(1, 1, 1, 1)
		_ensure_idle_bob(slot)


func _set_active_portrait_focus(active_key: String, left_key: String, right_key: String) -> void:
	if _char_left == null or _char_right == null:
		return
	var left_active := left_key == active_key and left_key != ""
	var right_active := right_key == active_key and right_key != ""
	var tl := create_tween()
	tl.set_parallel(true)
	tl.tween_property(_char_left, "modulate", Color(1, 1, 1, 1.0) if left_active else Color(0.48, 0.48, 0.52, 0.64), 0.16)
	tl.tween_property(_char_right, "modulate", Color(1, 1, 1, 1.0) if right_active else Color(0.48, 0.48, 0.52, 0.64), 0.16)
	tl.tween_property(_char_left, "scale", Vector2(1.00, 1.00), 0.16)
	tl.tween_property(_char_right, "scale", Vector2(1.00, 1.00), 0.16)
	_play_speaking_pulse(active_key, left_key, right_key)


func _play_speaking_pulse(active_key: String, left_key: String, right_key: String) -> void:
	var target: TextureRect = null
	if left_key == active_key:
		target = _char_left
	elif right_key == active_key:
		target = _char_right
	if target == null or not target.visible:
		return
	var origin := target.position
	var pulse := create_tween()
	pulse.tween_property(target, "position", origin + Vector2(0, -3.0), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(target, "position", origin, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _update_duo_portraits(speaker_raw: String) -> void:
	var current := _normalized_speaker_key(speaker_raw)
	if current == "":
		if _char_left:
			_char_left.visible = false
		if _char_right:
			_char_right.visible = false
		return

	var other := ""
	if _last_dialogue_speaker != "" and _last_dialogue_speaker != current:
		other = _last_dialogue_speaker
	else:
		other = _default_counterpart_for(current)
	if other == current:
		other = _default_counterpart_for(current)

	var left_key := current if _speaker_prefers_left(current) else other
	var right_key := other if _speaker_prefers_left(current) else current
	var duo_mode := left_key != "" and right_key != "" and left_key != right_key

	if duo_mode:
		_apply_portrait_slot(_char_left, left_key, true, false)
		_apply_portrait_slot(_char_right, right_key, false, false)
		_set_active_portrait_focus(current, left_key, right_key)
	else:
		var solo_key := left_key if left_key != "" else right_key
		if solo_key == "":
			solo_key = current
		_apply_portrait_slot(_char_left, solo_key, true, true)
		if _char_right != null:
			_char_right.visible = false
		_set_active_portrait_focus(current, solo_key, "")

	_left_portrait_key = left_key
	_right_portrait_key = right_key
	_last_dialogue_speaker = current


func _typewrite(text: String, scene_data: Dictionary = {}) -> void:
	_animating = true
	_story_text.bbcode_enabled = true
	_story_text.text = ""
	_story_text.append_text(text)
	_story_text.visible_ratio = 0.0
	var tween: Tween = create_tween()
	var speed_factor := _type_speed_factor(scene_data)
	var duration: float = float(text.length()) * 0.025 * speed_factor
	if _is_dramatic_scene(scene_data):
		duration += min(1.0, float(_count_punctuation_hits(text)) * 0.03)
	duration = clampf(duration, 0.30, 6.20)
	tween.tween_property(_story_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(func() -> void:
		_animating = false
		_btn_continue.disabled = false
	)


func _count_punctuation_hits(text: String) -> int:
	var hits := 0
	for c in text:
		if c == "!" or c == "?" or c == "…":
			hits += 1
	return hits


func _type_speed_factor(scene_data: Dictionary) -> float:
	if scene_data.has("type_speed"):
		var explicit := float(scene_data.get("type_speed", 1.0))
		if explicit > 0.05:
			return explicit

	var sid := str(scene_data.get("id", "")).to_lower()
	var stype := str(scene_data.get("type", "narration")).to_lower()
	var factor := 1.0

	match stype:
		"tutorial":
			factor *= 0.82
		"dialogue":
			factor *= 0.95
		"fin":
			factor *= 1.20
		_:
			factor *= 1.0

	if sid.begins_with("chute_"):
		factor *= 1.35
	elif sid.begins_with("serment_"):
		factor *= 1.28
	elif sid.begins_with("exil_"):
		factor *= 1.08
	elif sid.begins_with("kael_"):
		factor *= 0.92

	if _is_dramatic_scene(scene_data):
		factor *= 1.10

	return factor


func _is_dramatic_scene(scene_data: Dictionary) -> bool:
	if bool(scene_data.get("dramatic", false)):
		return true
	var sid := str(scene_data.get("id", "")).to_lower()
	if sid.begins_with("chute_") or sid.begins_with("serment_") or sid.begins_with("conclave_"):
		return true
	return false


func _play_scene_impact(scene_data: Dictionary) -> void:
	var intensity := float(scene_data.get("shake_intensity", 11.0))
	var duration := float(scene_data.get("shake_duration", 0.22))
	_shake_dialogue_box(intensity, duration)


func _shake_dialogue_box(intensity: float = 10.0, duration: float = 0.22) -> void:
	if _text_panel == null:
		return
	if _shake_tween != null and _shake_tween.is_running():
		_shake_tween.kill()
	_text_panel.position = _text_panel_origin
	var steps := maxi(4, int(round(duration / 0.04)))
	var step_time := duration / float(steps)
	_shake_tween = create_tween()
	for _i in range(steps):
		var dx := _rng.randf_range(-intensity, intensity)
		var dy := _rng.randf_range(-intensity * 0.35, intensity * 0.35)
		_shake_tween.tween_property(_text_panel, "position", _text_panel_origin + Vector2(dx, dy), step_time)
	_shake_tween.tween_property(_text_panel, "position", _text_panel_origin, 0.06)


func _apply_illustration_transition(illus_name: String, scene_data: Dictionary) -> void:
	var next_tex := _resolve_illustration_texture(illus_name)
	if _illus == null:
		return

	if _idx == 0 or _illus.texture == null or _illus_prev == null:
		_illus.texture = next_tex
		_illus.position = Vector2.ZERO
		_illus.modulate = Color(1, 1, 1, 1)
		if _illus_prev != null:
			_illus_prev.texture = null
			_illus_prev.modulate = Color(1, 1, 1, 0)
		return

	if _illus.texture == next_tex:
		return

	if _illus_tween != null and _illus_tween.is_running():
		_illus_tween.kill()

	_illus_prev.texture = _illus.texture
	_illus_prev.position = Vector2.ZERO
	_illus_prev.modulate = Color(1, 1, 1, 1)

	_illus.texture = next_tex
	var dramatic := _is_dramatic_scene(scene_data)
	var travel := 44.0 if dramatic else 26.0
	var fade_dur := 0.36 if dramatic else 0.24
	_illus.position = Vector2(travel, 0)
	_illus.modulate = Color(1, 1, 1, 0)

	_illus_tween = create_tween()
	_illus_tween.set_parallel(true)
	_illus_tween.tween_property(_illus_prev, "position", Vector2(-travel * 0.75, 0), fade_dur)
	_illus_tween.tween_property(_illus_prev, "modulate:a", 0.0, fade_dur)
	_illus_tween.tween_property(_illus, "position", Vector2.ZERO, fade_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_illus_tween.tween_property(_illus, "modulate:a", 1.0, fade_dur)
	_illus_tween.finished.connect(func() -> void:
		if _illus_prev != null:
			_illus_prev.texture = null
			_illus_prev.position = Vector2.ZERO
			_illus_prev.modulate = Color(1, 1, 1, 0)
	)


func _load_illustration(illus_name: String) -> void:
	_illus.texture = _resolve_illustration_texture(illus_name)
	_illus.position = Vector2.ZERO
	_illus.modulate = Color(1, 1, 1, 1)


func _resolve_illustration_texture(illus_name: String) -> Texture2D:
	if illus_name.is_empty():
		return null

	if illus_name.begins_with("res://"):
		if ResourceLoader.exists(illus_name):
			return load(illus_name) as Texture2D
		var ext_candidates_abs: PackedStringArray = PackedStringArray([".png", ".jpg", ".svg", ".webp"])
		for ext2: String in ext_candidates_abs:
			var p2: String = illus_name + ext2
			if ResourceLoader.exists(p2):
				return load(p2) as Texture2D
		return null

	var ext_candidates_rel: PackedStringArray = PackedStringArray(["", ".png", ".jpg", ".svg", ".webp"])
	for ext: String in ext_candidates_rel:
		var path: String = "res://assets/images/" + illus_name + ext if ext != "" else "res://assets/images/" + illus_name
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _resolve_portrait_texture(illus_name: String) -> Texture2D:
	var cache_key := "portrait::%s" % illus_name
	if _portrait_texture_cache.has(cache_key):
		return _portrait_texture_cache[cache_key] as Texture2D
	var raw := _resolve_illustration_texture(illus_name)
	if raw == null:
		return null
	var out_tex: Texture2D = raw
	if ENABLE_PORTRAIT_BG_REMOVAL:
		var cleaned := _remove_portrait_background(raw)
		if cleaned != null:
			out_tex = cleaned
	_portrait_texture_cache[cache_key] = out_tex
	return out_tex


func _remove_portrait_background(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return tex
	if img.get_width() < 4 or img.get_height() < 4:
		return tex

	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var bg := img.get_pixel(0, 0)
	if bg.a <= 0.04:
		return tex

	var max_dist := 0.18
	var removed := 0
	var total := img.get_width() * img.get_height()

	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			var d := _rgb_distance(c, bg)
			if d <= max_dist and absf(c.a - bg.a) <= 0.45:
				var alpha_scale := clampf((d / max_dist), 0.0, 1.0)
				var new_a := c.a * alpha_scale
				if new_a < 0.08:
					new_a = 0.0
				if absf(new_a - c.a) > 0.001:
					removed += 1
				c.a = new_a
				img.set_pixel(x, y, c)

	if removed < int(float(total) * 0.01):
		return tex

	return ImageTexture.create_from_image(img)


func _rgb_distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


# ─────────────────────────────────────────────────────────────────────
#  INTERACTIONS
# ─────────────────────────────────────────────────────────────────────

func _on_continue() -> void:
	# Si l'animation est en cours → révèle instantanément
	if _animating:
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
	transition_slide(_idx, _idx + 1)


# ─── Input clavier ────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Les overlays sont modaux, mais ils doivent toujours rester validables au
	# clavier/manette. Sans cela, un bouton hors zone visible ou sans focus
	# peut bloquer définitivement la narration (notamment dans le Web Editor).
	if _tuto_layer.visible:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_next"):
			_on_tuto_ok()
			get_viewport().set_input_as_handled()
		return
	if _recruit_layer.visible:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_next"):
			_on_recruit()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_next"):
		_on_continue()


# ─────────────────────────────────────────────────────────────────────
#  OVERLAY TUTORIEL
# ─────────────────────────────────────────────────────────────────────


func _open_tutorial(ttype: String) -> void:
	_btn_continue.visible = false
	_tuto_layer.visible   = true
	# Le popup tutoriel prend explicitement le focus : indispensable pour le
	# clavier/manette et plus fiable dans l'éditeur Web.
	if _btn_tuto_ok != null:
		_btn_tuto_ok.disabled = false
		_btn_tuto_ok.grab_focus()
	match ttype:
		"ressources":
			_tuto_title.text = "[img width=18 height=18]%s[/img]  Les Ressources du Clan" % ICONS_BBCODE["or"]
			_tuto_body.text  = _inject_icons(_tuto_text_ressources())
		"actions":
			_tuto_title.text = "[img width=18 height=18]%s[/img]  Le Cycle de Jeu" % ICONS_BBCODE["soldats"]
			_tuto_body.text  = _inject_icons(_tuto_text_actions())
		"recrutement_pnj":
			_tuto_title.text = "[img width=18 height=18]%s[/img]  Les Alliés du Clan" % ICONS_BBCODE["nourriture"]
			_tuto_body.text  = _inject_icons(_tuto_text_recrutement())
		_:
			_tuto_title.text = "Aide"
			_tuto_body.text  = "Aucune information disponible."


func _on_tuto_ok() -> void:
	# Garde anti-double validation : un clic + ui_accept dans la même frame ne
	# doit pas avancer de deux scènes.
	if not _tuto_layer.visible:
		return
	_tuto_layer.visible = false
	if _btn_tuto_ok != null:
		_btn_tuto_ok.release_focus()
	_btn_continue.visible = true
	_btn_continue.disabled = false
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
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 16)
	_recruit_stats.add_child(stats_hbox)
	for key in stat_display.keys():
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_btn_recruit.text = "Accueillir %s dans le %s" % [
		str(pnj_data.get("nom", "PNJ")),
		_clan_name
	]


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
	SaveSystem.set_value("intro_done", true)
	SaveSystem.save()
	# Fondu léger avant la transition
	var tween: Tween = create_tween()
	tween.tween_property(_bg, "color", Color(0, 0, 0, 1), 1.2)
	await tween.finished
	GameManager.go_to("clan_hub")
