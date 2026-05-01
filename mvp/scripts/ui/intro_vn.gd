## scripts/ui/intro_vn.gd
## Séquence d'introduction — Visual Novel + tutoriel intégré.
## Jouée une seule fois après la création du personnage.
## Flux : Passé (tutoriel) → La Chute → Serment → clan_hub
extends Control

# ─────────────────────────────────────────────────────────────────────
#  NŒUDS (construits dynamiquement dans _ready)
# ─────────────────────────────────────────────────────────────────────
var _bg:              ColorRect       = null
var _illus:           TextureRect     = null
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

# Données joueur (résolues une fois)
var _player_name: String  = "Héritier"
var _clan_name:   String  = "votre Clan"
var _parent_name: String  = "Ton Père"
var _pere_name: String    = "Ton Père"
var _mere_name: String    = "Ta Mère"


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
	_resolve_player_data()
	_build_ui()
	_load_scenes()
	if _scenes.is_empty():
		push_error("IntroVN: aucune scène chargée — vérifier data/intro_vn.json")
		GameManager.go_to("clan_hub")
		return
	_show_scene(0)


func _resolve_player_data() -> void:
	var cm: Node = get_node_or_null("/root/ClanManager")
	if cm == null:
		return
	_player_name = str(cm.get("nom_personnage") if cm.get("nom_personnage") != "" else "Héritier")
	_clan_name   = str(cm.get("nom_clan")       if cm.get("nom_clan")       != "" else "votre Clan")
	var profil: Dictionary = (cm.get("profil_personnage") as Dictionary)
	var genre: String = str(profil.get("genre", ""))
	# prefer explicit parent names from profile if present
	_pere_name = str(profil.get("pere_name", "Ton Père"))
	_mere_name = str(profil.get("mere_name", "Ta Mère"))
	if genre == "Femme":
		_parent_name = _mere_name
	elif genre == "Homme":
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
	_bg.color = Color(0.04, 0.0, 0.1, 1)
	add_child(_bg)

	# --- Illustration (60% haut) ---
	_illus = TextureRect.new()
	_illus.name = "Illustration"
	_illus.layout_mode = 1
	_illus.anchor_left   = 0.0
	_illus.anchor_top    = 0.0
	_illus.anchor_right  = 1.0
	_illus.anchor_bottom = 0.62
	_illus.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illus.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_illus)

	# Dégradé bas de l'illustration vers la boîte de texte
	_gradient = ColorRect.new()
	_gradient.name = "Gradient"
	_gradient.layout_mode = 1
	_gradient.anchor_left   = 0.0
	_gradient.anchor_top    = 0.50
	_gradient.anchor_right  = 1.0
	_gradient.anchor_bottom = 0.65
	_gradient.color = Color(0.04, 0.0, 0.1, 0.8)
	add_child(_gradient)

	# --- Boîte de dialogue (38% bas) ---
	var text_panel := PanelContainer.new()
	text_panel.name = "TextBox"
	text_panel.layout_mode = 1
	text_panel.anchor_left   = 0.0
	text_panel.anchor_top    = 0.62
	text_panel.anchor_right  = 1.0
	text_panel.anchor_bottom = 1.0
	text_panel.offset_left   = 20.0
	text_panel.offset_right  = -20.0
	text_panel.offset_bottom = -10.0
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
	_btn_continue.layout_mode = 1
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
	_tuto_panel.layout_mode = 0
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
	_recruit_panel.layout_mode = 0
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

	# Illustration
	_load_illustration(str(s.get("illustration", "")))

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
		"personnage": return _player_name
		"kael":       return "Kael"
		_:            return raw


func _typewrite(text: String) -> void:
	_animating = true
	_story_text.bbcode_enabled = true
	_story_text.text = ""
	_story_text.append_text(text)
	_story_text.visible_ratio = 0.0
	var tween: Tween = create_tween()
	var duration: float = clampf(float(text.length()) * 0.025, 0.4, 4.5)
	tween.tween_property(_story_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(func() -> void:
		_animating = false
		_btn_continue.disabled = false
	)


func _load_illustration(illus_name: String) -> void:
	if illus_name.is_empty():
		_illus.texture = null
		return
	for ext in ["", ".png", ".jpg", ".svg", ".webp"]:
		var path: String = "res://assets/images/" + illus_name + ext if ext != "" else "res://assets/images/" + illus_name
		if ResourceLoader.exists(path):
			_illus.texture = load(path)
			return
	_illus.texture = null


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
	_show_scene(_idx + 1)


# ─── Input clavier ────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _tuto_layer.visible or _recruit_layer.visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_next"):
		_on_continue()


# ─────────────────────────────────────────────────────────────────────
#  OVERLAY TUTORIEL
# ─────────────────────────────────────────────────────────────────────


func _open_tutorial(ttype: String) -> void:
	_btn_continue.visible = false
	_tuto_layer.visible   = true
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
