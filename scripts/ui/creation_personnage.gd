## scripts/ui/creation_personnage.gd
## Copied to satisfy scene ext_resource references.
extends Control

# Controller pour l'interface de création de personnage.
# Utilise les scripts de données définis ailleurs (via class_name).

func _clan_manager() -> Node:
	return get_node_or_null("/root/ClanManager")


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _game_data_loader() -> Node:
	return get_node_or_null("/root/GameDataLoader")
# Les définitions de classes sont désormais centralisées dans `res://mvp/data/classes.json`
# et accessibles via l'autoload `GameDataLoader`. Les définitions locales ont été retirées
# pour éviter les doublons de données.

var _classe_choisie: String = ""

const DESKTOP_BREAKPOINT: int = 900

const CHOIX_GENRE := ["Homme", "Femme", "Non-binaire"]
const CHOIX_APPARENCE := ["Vétéran balafré", "Noble exilé", "Arcaniste tatoué", "Mercenaire masqué"]
const CHOIX_POUVOIR := [
	{"id": "pyrokinesis", "nom": "Pyrokynésie"},
	{"id": "telekinesis", "nom": "Télékinésie"},
	{"id": "shadow_step", "nom": "Pas d'Ombre"},
	{"id": "demon_invocation", "nom": "Invocation Démoniaque"},
	{"id": "thunder_chain", "nom": "Chaîne de Foudre"},
	{"id": "blood_shield", "nom": "Bouclier de Sang"},
	{"id": "mind_crush", "nom": "Écrasement Mental"},
	{"id": "earth_tremor", "nom": "Tremblement de Terre"},
]
const CHOIX_ARCHETYPE := [
	"Lame jurée (inspiration Guerrier)",
	"Ensorceleur abyssal (inspiration Magicien)",
	"Traqueur des ruines (inspiration Rôdeur)",
	"Prédicateur noir (inspiration Clerc)",
	"Ombrelame (inspiration Roublard)",
	"Alchimiste de siège (inspiration Alchimiste)",
]
const CHOIX_DON := [
	{"id": "regeneration", "nom": "Régénération Démoniaque"},
	{"id": "demon_vision", "nom": "Vision Démoniaque"},
	{"id": "monster_empathy", "nom": "Empathie des Monstres"},
	{"id": "iron_will", "nom": "Volonté de Fer"},
	{"id": "noble_presence", "nom": "Présence Nobiliaire"},
	{"id": "battlefield_tactician", "nom": "Tacticien de Champ de Bataille"},
	{"id": "craftsman_soul", "nom": "Âme d'Artisan"},
]
const CHOIX_COMPETENCE := [
	{"id": "maitrise_martiale", "nom": "Maîtrise martiale"},
	{"id": "rituel_occulte", "nom": "Rituel occulte"},
	{"id": "diplomatie_de_guerre", "nom": "Diplomatie de guerre"},
	{"id": "infiltration", "nom": "Infiltration"},
]
const CHOIX_EQUIPEMENT := [
	{"id": "arme_lourde_bouclier", "nom": "Arme lourde + bouclier"},
	{"id": "catalyseur_runique", "nom": "Catalyseur runique"},
	{"id": "lames_jumelles", "nom": "Lames jumelles"},
	{"id": "lance_de_guerre", "nom": "Lance de guerre"},
	{"id": "potion_energie_x3", "nom": "Potions d'Énergie Mystique ×3"},
	{"id": "carte_espion", "nom": "Carte d'agent infiltré"},
	{"id": "blueprint_caserne", "nom": "Plans de Caserne Avancée"},
	{"id": "rune_protection", "nom": "Rune de Protection Ancestrale"},
	{"id": "traite_alliance", "nom": "Traité d'Alliance Provisoire"},
]
const MAGIE_PACTES := "Magie des Pactes"
const CREATION_GOLD := Color(0.90, 0.78, 0.42, 1.0)
const CREATION_GOLD_DIM := Color(0.78, 0.64, 0.29, 1.0)
const CREATION_TEXT_MAIN := Color(0.93, 0.88, 0.78, 1.0)
const CREATION_TEXT_MUTED := Color(0.68, 0.56, 0.44, 1.0)
const CREATION_SLIDES := [
	{
		"title": "Etape 1/5",
		"subtitle": "Classe, identite et portrait",
		"build_title": "Identite et apparence",
		"options": ["OptionGenre", "OptionApparence"],
		"show_names": true,
		"show_class_cards": true,
		"show_portrait": true,
		"show_sheet": false,
	},
	{
		"title": "Etape 2/5",
		"subtitle": "Dons et capacites",
		"build_title": "Dons et capacites",
		"options": [],
		"show_names": false,
		"show_class_cards": false,
		"show_portrait": false,
		"show_sheet": true,
	},
	{
		"title": "Etape 3/5",
		"subtitle": "Stats et pouvoirs raciaux",
		"build_title": "Stats et pouvoirs raciaux",
		"options": ["OptionPouvoir"],
		"show_names": false,
		"show_class_cards": false,
		"show_portrait": false,
		"show_sheet": true,
	},
	{
		"title": "Etape 4/5",
		"subtitle": "Equipements",
		"build_title": "Equipements de depart",
		"options": ["OptionEquipement"],
		"show_names": false,
		"show_class_cards": false,
		"show_portrait": false,
		"show_sheet": true,
	},
	{
		"title": "Etape 5/5",
		"subtitle": "Resume du personnage",
		"build_title": "Resume final",
		"options": [],
		"show_names": false,
		"show_class_cards": false,
		"show_portrait": true,
		"show_sheet": true,
	},
]
const BUILD_OPTION_NAMES := ["OptionGenre", "OptionApparence", "OptionPouvoir", "OptionArchetype", "OptionDon", "OptionCompetence", "OptionEquipement"]
const DEFAULT_OPTION_LABELS := {
	"LabelGenre": "Genre",
	"LabelApparence": "Apparence",
	"LabelPouvoir": "Pouvoir magique",
	"LabelArchetype": "Archetype",
	"LabelDon": "Don",
	"LabelCompetence": "Competence",
	"LabelEquipement": "Equipement de depart",
}

# Class panel color presets
const CLASS_PANEL_FORCE_BG := Color(0.12, 0.02, 0.02, 0.85)
const CLASS_PANEL_FORCE_BORDER := Color(0.80, 0.28, 0.28, 0.40)
const CLASS_ACCENT_FORCE := Color(0.95, 0.52, 0.45, 1.0)

const CLASS_PANEL_MAGIC_BG := Color(0.18, 0.12, 0.06, 0.85)
const CLASS_PANEL_MAGIC_BORDER := Color(0.78, 0.64, 0.29, 0.45)
const CLASS_ACCENT_MAGIC := Color(0.95, 0.82, 0.40, 1.0)

const CLASS_PANEL_OTHER_BG := Color(0.03, 0.15, 0.08, 0.85)
const CLASS_PANEL_OTHER_BORDER := Color(0.05, 0.45, 0.30, 0.35)
const CLASS_ACCENT_OTHER := Color(0.18, 0.75, 0.55, 1.0)

const TOOLTIP_POUVOIR := {
	"pyrokinesis": "Projette des flammes. Fort en attaque directe, coûte du mana.",
	"telekinesis": "Manipule objets et ennemis à distance. Contrôle de zone.",
	"shadow_step": "Déplacement instantané court. Excellent pour l'infiltration.",
	"demon_invocation": "Invoque un démon temporaire. Puissant mais coûteux.",
	"thunder_chain": "Foudre qui rebondit entre cibles proches.",
	"blood_shield": "Convertit de l'énergie en protection défensive.",
	"mind_crush": "Attaque psychique ciblée, efficace contre élites.",
	"earth_tremor": "Onde de choc terrestre pour contrôler la mêlée.",
}

const TOOLTIP_DON := {
	"regeneration": "Régénère progressivement la vitalité hors combat.",
	"demon_vision": "Révèle menaces et détails cachés.",
	"monster_empathy": "Améliore les interactions avec créatures hostiles.",
	"iron_will": "Résistance accrue aux effets mentaux.",
	"noble_presence": "Bonus social auprès des maisons nobles.",
	"battlefield_tactician": "Améliore coordination et impact des actions de guerre.",
	"craftsman_soul": "Bonus à l'artisanat et optimisation des ressources.",
}

const TOOLTIP_COMPETENCE := {
	"maitrise_martiale": "Maîtrise des armes et meilleure tenue en première ligne.",
	"rituel_occulte": "Accès à des effets magiques avancés via rituels.",
	"diplomatie_de_guerre": "Négociation et influence en contexte conflictuel.",
	"infiltration": "Discrétion, sabotage et collecte de renseignements.",
}

const POINTS_FICHE_RESTANTS_CIBLE := 10
var _fiche_points_restants: int = POINTS_FICHE_RESTANTS_CIBLE
var _fiche_stats := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
var _fiche_feats: Array = []
var _embedded_sheet: Node = null
var _portrait_data: Dictionary = {}
var _slide_index: int = 0
var _selected_ability_id: String = ""
var _selected_feat_id: String = ""
var _abilities_list_ids: Array = []
var _feats_list_ids: Array = []


func _build_grid() -> GridContainer:
	return find_child("GrilleBuild", true, false) as GridContainer


# Recherche un OptionButton par nom, où qu'il soit dans l'arbre (grille ou vbox)
func _find_option(option_name: String) -> OptionButton:
	return find_child(option_name, true, false) as OptionButton


func _build_section() -> VBoxContainer:
	return find_child("SectionBuild", true, false) as VBoxContainer


func _cards_container() -> GridContainer:
	return find_child("CartesClasses", true, false) as GridContainer


func _class_label() -> Label:
	return find_child("LabelClasseChoisie", true, false) as Label


func _error_label() -> Label:
	return find_child("LabelErreur", true, false) as Label


func _build_resume_label() -> Label:
	return find_child("LabelBuildResume", true, false) as Label


func _sheet_host() -> MarginContainer:
	return find_child("FicheHost", true, false) as MarginContainer


func _portrait_preview() -> TextureRect:
	return find_child("PortraitPreview", true, false) as TextureRect


func _portrait_path_label() -> Label:
	return find_child("PortraitPathLabel", true, false) as Label


func _portrait_file_dialog() -> FileDialog:
	return $PortraitFileDialog as FileDialog


func _subtitle_label() -> Label:
	return get_node_or_null("PanneauCentre/SousTitre") as Label


func _back_button() -> Button:
	return get_node_or_null("ActionBar/ActionButtons/BtnRetourBottom") as Button


func _primary_button() -> Button:
	return get_node_or_null("ActionBar/ActionButtons/BtnCommencerBottom") as Button


func _ready() -> void:
	_appliquer_style_creation()
	_configurer_build_inputs()
	_configurer_portrait_panel()
	_initialiser_options_personnage()
	# Construire dynamiquement les cartes de classes (depuis res://data/classes.json)
	_build_class_cards()
	_connecter_boutons()
	# Auto-open the embedded character sheet if available (guarded)
	if has_method("_open_character_sheet"):
		_open_character_sheet()
	_mettre_a_jour_resume_build()

	# Responsive layout initialisation
	_update_responsive_layout()
	# Mettre à jour quand la taille de la fenêtre change
	# Connect directly to the viewport size_changed signal (safer)
	var vp := get_viewport()
	if vp:
		vp.connect("size_changed", Callable(self, "_update_responsive_layout"))
	_configurer_flux_par_slides()
	_aller_a_slide(0)
	var fiche := _sheet_host()
	if fiche == null:
		return

	# Debug helper: show current name/clan overlay and highlight fields (temporary)
	# debug overlay removed; label will show name & clan instead


	# Créer le bloc des descriptions de la slide 2 uniquement s'il n'existe pas
	if fiche.get_node_or_null("Slide2Descriptions") == null:
		# séparer le tableau et placer les descriptions directement sous le tableau
		fiche.add_child(HSeparator.new())

		# Bloc descriptions (labels nommés pour mise à jour rapide sans recréer)
		var vbox := VBoxContainer.new()
		vbox.name = "Slide2Descriptions"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		vbox.custom_minimum_size = Vector2(0, 160)
		fiche.add_child(vbox)

		var abil_title := Label.new()
		abil_title.name = "AbilTitleLabel"
		abil_title.add_theme_font_size_override("font_size", 14)
		abil_title.add_theme_color_override("font_color", CREATION_GOLD)
		vbox.add_child(abil_title)

		var abil_desc := RichTextLabel.new()
		abil_desc.name = "AbilDescLabel"
		abil_desc.bbcode_enabled = false
		abil_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(abil_desc)

		var feat_title := Label.new()
		feat_title.name = "FeatTitleLabel"
		feat_title.add_theme_font_size_override("font_size", 14)
		feat_title.add_theme_color_override("font_color", CREATION_GOLD)
		vbox.add_child(feat_title)

		var feat_desc := RichTextLabel.new()
		feat_desc.name = "FeatDescLabel"
		feat_desc.bbcode_enabled = false
		feat_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(feat_desc)


	# Met à jour ensuite les descriptions (existant ou nouvellement créées)
	_refresh_slide2_descriptions()


func _color_from_value(val, fallback: Color) -> Color:
	if typeof(val) == TYPE_ARRAY:
		if val.size() >= 3:
			var a := 1.0
			if val.size() >= 4:
				a = float(val[3])
			return Color(float(val[0]), float(val[1]), float(val[2]), a)
		return fallback
	if typeof(val) == TYPE_DICTIONARY:
		if val.has("r") and val.has("g") and val.has("b"):
			var aa := 1.0
			if val.has("a"):
				aa = float(val.get("a"))
			return Color(float(val.get("r")), float(val.get("g")), float(val.get("b")), aa)
		return fallback
	if val is Color:
		return val
	return fallback


func _make_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style


func _appliquer_style_creation() -> void:
	var titre := get_node_or_null("PanneauCentre/Titre") as Label
	if titre:
		titre.add_theme_color_override("font_color", CREATION_GOLD)
		titre.add_theme_font_size_override("font_size", 28)
	var sous_titre := get_node_or_null("PanneauCentre/SousTitre") as Label
	if sous_titre:
		sous_titre.add_theme_color_override("font_color", CREATION_TEXT_MUTED)

	var section_build := _build_section()
	if section_build:
		var build_title := section_build.get_node_or_null("LabelBuild") as Label
		if build_title:
			build_title.add_theme_color_override("font_color", CREATION_GOLD_DIM)
		var resume := _build_resume_label()
		if resume:
			resume.add_theme_color_override("font_color", CREATION_TEXT_MAIN)

	var portrait_panel := find_child("PortraitPanel", true, false) as PanelContainer
	if portrait_panel:
		portrait_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.01, 0.12, 0.85), Color(0.78, 0.64, 0.29, 0.45)))
	var fiche_panel := find_child("FicheHostPanel", true, false) as PanelContainer
	if fiche_panel:
		fiche_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.01, 0.10, 0.85), Color(0.78, 0.64, 0.29, 0.35)))

	# Remove the dark background of the bottom action bar for a cleaner creation UI
	var action_bar := get_node_or_null("ActionBar") as PanelContainer
	if action_bar:
		var sb := StyleBoxFlat.new()
		# fully transparent background and no border
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(0, 0, 0, 0)
		action_bar.add_theme_stylebox_override("panel", sb)

	for opt_name in ["OptionGenre", "OptionApparence", "OptionPouvoir", "OptionArchetype", "OptionDon", "OptionCompetence", "OptionEquipement"]:
		var opt := _find_option(opt_name)
		if opt:
			opt.custom_minimum_size = Vector2(0, 34)
			opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Décaler davantage la zone Nom/Clan vers le bas pour éviter qu'elle ne sorte
	var ligne_noms := get_node_or_null("PanneauCentre/LigneNoms") as HBoxContainer
	if ligne_noms:
		ligne_noms.add_theme_constant_override("margin_top", 80)

	var label_nom_perso := get_node_or_null("PanneauCentre/LigneNoms/ColNomPerso/LabelNomPerso") as Label
	if label_nom_perso:
		label_nom_perso.text = "Nom / prenom"
		label_nom_perso.visible = true
	var label_nom_clan := get_node_or_null("PanneauCentre/LigneNoms/ColNomClan/LabelNomClan") as Label
	if label_nom_clan:
		label_nom_clan.text = "Nom du clan"
		label_nom_clan.visible = true


func _configurer_flux_par_slides() -> void:
	var titre_fiche := find_child("LabelFiche", true, false) as Label
	if titre_fiche:
		titre_fiche.text = "Fiche et apercus"
	var bouton_principal := _primary_button()
	if bouton_principal:
		bouton_principal.custom_minimum_size = Vector2(260, 36)


func _configurer_portrait_panel() -> void:
	_rafraichir_portrait_ui()


func _slide_courante() -> Dictionary:
	return CREATION_SLIDES[clampi(_slide_index, 0, CREATION_SLIDES.size() - 1)] as Dictionary


func _set_build_options_visible(visible_options: Array) -> void:
	for opt_name in BUILD_OPTION_NAMES:
		var opt := _find_option(opt_name)
		if opt == null:
			continue
		var row := opt.get_parent()
		if row:
			row.visible = visible_options.has(opt_name)


func _set_build_labels_defaults() -> void:
	for label_name in DEFAULT_OPTION_LABELS.keys():
		var label := find_child(str(label_name), true, false) as Label
		if label:
			label.text = str(DEFAULT_OPTION_LABELS[label_name])


func _refresh_action_buttons() -> void:
	var bouton_retour := _back_button()
	if bouton_retour:
		bouton_retour.text = "Retour au menu" if _slide_index == 0 else "Etape precedente"
	var bouton_principal := _primary_button()
	if bouton_principal:
		bouton_principal.text = "Suivant" if _slide_index < CREATION_SLIDES.size() - 1 else "Commencer l'aventure"
	_valider_formulaire()


func _refresh_slide_layout() -> void:
	var slide := _slide_courante()
	var sous_titre := _subtitle_label()
	if sous_titre:
		sous_titre.text = "%s · %s" % [str(slide.get("title", "")), str(slide.get("subtitle", ""))]

	var ligne_noms := get_node_or_null("PanneauCentre/LigneNoms") as Control
	if ligne_noms:
		ligne_noms.visible = bool(slide.get("show_names", false))

	var label_classe := find_child("LabelClasse", true, false) as Control
	if label_classe:
		label_classe.visible = bool(slide.get("show_class_cards", false))
	var cartes_scroll := find_child("CartesScroll", true, false) as Control
	if cartes_scroll:
		cartes_scroll.visible = bool(slide.get("show_class_cards", false))
	var classe_choisie_label := _class_label()
	if classe_choisie_label:
		classe_choisie_label.visible = bool(slide.get("show_class_cards", false)) or _slide_index == CREATION_SLIDES.size() - 1
	var separateur_classe := find_child("Separateur2", true, false) as Control
	if separateur_classe:
		separateur_classe.visible = bool(slide.get("show_class_cards", false))

	var portrait_label := find_child("LabelPortrait", true, false) as Control
	if portrait_label:
		portrait_label.visible = bool(slide.get("show_portrait", false))
	var portrait_panel := find_child("PortraitPanel", true, false) as Control
	if portrait_panel:
		portrait_panel.visible = bool(slide.get("show_portrait", false))
	var fiche_label := find_child("LabelFiche", true, false) as Label
	if fiche_label:
		fiche_label.visible = bool(slide.get("show_sheet", false))
		match _slide_index:
			1:
				fiche_label.text = "Fiche, dons et capacites"
			2:
				fiche_label.text = "Fiche de stats et pouvoirs"
			3:
				fiche_label.text = "Apercu de l'equipement"
			4:
				fiche_label.text = "Apercu final du personnage"
			_:
				fiche_label.text = "Fiche et apercus"
	var fiche_scroll := find_child("RightScroll", true, false) as Control
	if fiche_scroll:
		fiche_scroll.visible = bool(slide.get("show_sheet", false))

	var build_title := find_child("LabelBuild", true, false) as Label
	if build_title:
		build_title.text = str(slide.get("build_title", "Profil RPG"))
	var pacte_label := find_child("LabelPacteFixe", true, false) as Label
	if pacte_label:
		pacte_label.visible = _slide_index > 0

	_set_build_labels_defaults()
	var label_pouvoir := find_child("LabelPouvoir", true, false) as Label
	if label_pouvoir and _slide_index == 2:
		label_pouvoir.text = "Pouvoir racial"

	var options := slide.get("options", []) as Array
	_set_build_options_visible(options)
	var resume := _build_resume_label()
	if resume:
		resume.visible = true

	# Slide 2 : ColDroite (gauche visuel) = listes ; ColGauche (droite visuel) = fiche+descriptions
	if _slide_index == 1:
		# Masquer RightScroll (FicheHost standard) en slide 2
		if fiche_scroll:
			fiche_scroll.visible = false
		# Libérer l'éventuelle fiche embarquée orpheline
		if _embedded_sheet != null and is_instance_valid(_embedded_sheet):
			var _ep := _embedded_sheet.get_parent()
			if _ep != null:
				_ep.remove_child(_embedded_sheet)
			_embedded_sheet.free()
			_embedded_sheet = null
		_build_capabilities_panel()
		_build_slide2_right_pane()
	else:
		# Nettoyer les panneaux créés pour le slide 2
		var col_d := find_child("ColDroite", true, false) as VBoxContainer
		if col_d:
			var pane_a := col_d.get_node_or_null("Slide2AbilitiesPane")
			if pane_a:
				pane_a.queue_free()
		var col_g := find_child("ColGauche", true, false) as VBoxContainer
		if col_g:
			var pane_s := col_g.get_node_or_null("Slide2SheetPane")
			if pane_s:
				pane_s.queue_free()
		if _embedded_sheet != null and is_instance_valid(_embedded_sheet):
			var _ep2 := _embedded_sheet.get_parent()
			if _ep2 != null:
				_ep2.remove_child(_embedded_sheet)
			_embedded_sheet.free()
			_embedded_sheet = null
		# Réafficher RightScroll pour les autres slides
		if fiche_scroll:
			fiche_scroll.visible = bool(slide.get("show_sheet", false))
		if bool(slide.get("show_sheet", false)):
			_open_character_sheet()

	_refresh_action_buttons()


func _aller_a_slide(index: int) -> void:
	_slide_index = clampi(index, 0, CREATION_SLIDES.size() - 1)
	_refresh_slide_layout()
	_mettre_a_jour_resume_build()


func _verifier_slide_courante() -> String:
	if _slide_index != 0:
		return ""
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	return _verifier_saisies(nom_perso, nom_clan)


func _on_action_principale() -> void:
	if _slide_index < CREATION_SLIDES.size() - 1:
		var erreur := _verifier_slide_courante()
		if erreur != "":
			_error_label().text = erreur
			return
		_error_label().text = ""
		_aller_a_slide(_slide_index + 1)
		return
	_on_commencer()


func _format_string_list(values: Array) -> String:
	if values.is_empty():
		return "—"
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return _join_array(parts, ", ")


func _join_array(arr: Array, sep: String = ", ") -> String:
	if arr == null or arr.size() == 0:
		return ""
	var out := ""
	for i in range(arr.size()):
		out += str(arr[i])
		if i < arr.size() - 1:
			out += sep
	return out


func _connecter_boutons() -> void:
	# Les boutons de classe sont connectés dynamiquement dans _build_class_cards()
	# Top button row is intentionally hidden; connect bottom action bar instead.

	# Les cartes sont créées et connectées dynamiquement dans _build_class_cards()

	$PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage.text_changed.connect(_on_texte_change)
	$PanneauCentre/LigneNoms/ColNomClan/NomClan.text_changed.connect(_on_texte_change)

	for opt_name in BUILD_OPTION_NAMES:
		var opt := _find_option(opt_name)
		if opt:
			opt.item_selected.connect(_on_selection_build_change)

	# Connexions pour la barre d'actions en bas (si présente)
	var btn_retour_bottom := get_node_or_null("ActionBar/ActionButtons/BtnRetourBottom")
	if btn_retour_bottom:
		btn_retour_bottom.pressed.connect(_on_retour)
	var btn_commencer_bottom := get_node_or_null("ActionBar/ActionButtons/BtnCommencerBottom")
	if btn_commencer_bottom:
		btn_commencer_bottom.pressed.connect(_on_action_principale)
	var btn_upload_portrait := find_child("BtnUploadPortrait", true, false) as Button
	if btn_upload_portrait:
		btn_upload_portrait.pressed.connect(_ouvrir_selection_portrait)
	var btn_reset_portrait := find_child("BtnResetPortrait", true, false) as Button
	if btn_reset_portrait:
		btn_reset_portrait.pressed.connect(_reinitialiser_portrait)
	var portrait_dialog := _portrait_file_dialog()
	portrait_dialog.file_selected.connect(_on_portrait_file_selected)


func _initialiser_options_personnage() -> void:
	if not _find_option("OptionGenre"):
		push_warning("creation_personnage: options introuvables")
		return
	_remplir_option_button(_find_option("OptionGenre"), CHOIX_GENRE)
	_remplir_option_button(_find_option("OptionApparence"), CHOIX_APPARENCE)
	_remplir_option_button_entries(_find_option("OptionPouvoir"), CHOIX_POUVOIR)
	_remplir_option_button(_find_option("OptionArchetype"), CHOIX_ARCHETYPE)
	_remplir_option_button_entries(_find_option("OptionDon"), CHOIX_DON)
	_remplir_option_button_entries(_find_option("OptionCompetence"), CHOIX_COMPETENCE)
	_remplir_option_button_entries(_find_option("OptionEquipement"), CHOIX_EQUIPEMENT)
	_forcer_selection_options_build()
	_sync_all_option_button_texts()


func _configurer_build_inputs() -> void:
	var grille := _build_grid()
	if not grille:
		return  # layout already converted (ou nœud absent dans la scène)
	var parent := grille.get_parent()
	var pairs := [
		["OptionGenre", "LabelGenre"],
		["OptionApparence", "LabelApparence"],
		["OptionPouvoir", "LabelPouvoir"],
		["OptionArchetype", "LabelArchetype"],
		["OptionDon", "LabelDon"],
		["OptionCompetence", "LabelCompetence"],
		["OptionEquipement", "LabelEquipement"],
	]
	# Create a new VBox to replace the GridContainer for clearer alignment
	var vbox := VBoxContainer.new()
	vbox.name = "GrilleBuildRows"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# remove original grid and reparent children into rows
	parent.remove_child(grille)
	for pair in pairs:
		var opt_node = null
		var lbl_node = null
		if grille.has_node(pair[0]):
			opt_node = grille.get_node(pair[0])
		if grille.has_node(pair[1]):
			lbl_node = grille.get_node(pair[1])
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if opt_node:
			grille.remove_child(opt_node)
			row.add_child(opt_node)
			# ensure option fills left space
			opt_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opt_node.custom_minimum_size = Vector2(220, 36)
		if lbl_node:
			grille.remove_child(lbl_node)
			row.add_child(lbl_node)
		vbox.add_child(row)
	parent.add_child(vbox)


func _forcer_selection_options_build() -> void:
	for opt_name in BUILD_OPTION_NAMES:
		var opt := _find_option(opt_name)
		if opt and opt.item_count > 0 and opt.selected < 0:
			opt.select(0)


func _sync_all_option_button_texts() -> void:
	for opt_name in BUILD_OPTION_NAMES:
		var opt := _find_option(opt_name)
		if opt:
			_sync_option_button_text(opt)


func _sync_option_button_text(option: OptionButton) -> void:
	if option.item_count <= 0:
		option.text = ""
		return
	var idx := option.selected
	if idx < 0 or idx >= option.item_count:
		idx = 0
		option.select(0)
	option.text = option.get_item_text(idx)
	_update_option_tooltip(option, idx)


func _update_option_tooltip(option: OptionButton, idx: int) -> void:
	var meta: Variant = option.get_item_metadata(idx)
	var key := ""
	if meta != null:
		key = str(meta)
	var txt := ""
	match option.name:
		"OptionPouvoir":
			txt = str(TOOLTIP_POUVOIR.get(key, "Pouvoir magique du personnage."))
		"OptionDon":
			txt = str(TOOLTIP_DON.get(key, "Don passif offrant des bonus de progression."))
		"OptionCompetence":
			txt = str(TOOLTIP_COMPETENCE.get(key, "Compétence active utile en mission et gestion."))
		"OptionArchetype":
			txt = "Archétype orientant le style de jeu et les synergies."
		_:
			txt = ""
	option.tooltip_text = txt


func _update_responsive_layout() -> void:
	# Définit le nombre de colonnes selon la largeur de la fenêtre
	var width := int(get_viewport_rect().size.x)
	var cols := 3 if width >= DESKTOP_BREAKPOINT else 1
	var grille := _build_grid()
	if grille:
		grille.columns = cols
	var cartes := _cards_container()
	if cartes:
		cartes.columns = cols


func _ouvrir_selection_portrait() -> void:
	_portrait_file_dialog().popup_centered_ratio(0.7)


func _reinitialiser_portrait() -> void:
	_portrait_data = {}
	_rafraichir_portrait_ui()


func _on_portrait_file_selected(path: String) -> void:
	_appliquer_portrait_depuis_chemin(path)


func _normaliser_chemin_fichier(path: String) -> String:
	var out := path.strip_edges()
	if out.begins_with("file://"):
		out = out.substr(7)
	return out.uri_decode()


func _charger_image_depuis_chemin(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var raw: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	if raw.is_empty():
		return null

	var image := Image.new()
	var err := ERR_PARSE_ERROR

	# Detect format by signature instead of extension because some wiki assets
	# are WebP files saved with a .png suffix.
	var is_png := raw.size() >= 8 and raw[0] == 0x89 and raw[1] == 0x50 and raw[2] == 0x4E and raw[3] == 0x47
	var is_jpg := raw.size() >= 3 and raw[0] == 0xFF and raw[1] == 0xD8 and raw[2] == 0xFF
	var is_webp := raw.size() >= 12 and raw[0] == 0x52 and raw[1] == 0x49 and raw[2] == 0x46 and raw[3] == 0x46 and raw[8] == 0x57 and raw[9] == 0x45 and raw[10] == 0x42 and raw[11] == 0x50

	if is_png:
		err = image.load_png_from_buffer(raw)
	elif is_jpg:
		err = image.load_jpg_from_buffer(raw)
	elif is_webp:
		err = image.load_webp_from_buffer(raw)
	else:
		return null

	if err != OK or image.is_empty():
		return null
	return image


func _appliquer_portrait_depuis_chemin(path: String) -> void:
	if path.strip_edges().is_empty():
		return
	var normalized_path := _normaliser_chemin_fichier(path)
	var image := _charger_image_depuis_chemin(normalized_path)
	if image == null or image.is_empty():
		_error_label().text = "Impossible de charger l'image du portrait (%s)." % normalized_path
		return
	_portrait_data = _serialiser_portrait(image, normalized_path.get_file())
	if _portrait_data.is_empty():
		_error_label().text = "Impossible d'encoder l'image du portrait."
		return
	_rafraichir_portrait_ui()


func _rafraichir_portrait_ui() -> void:
	var preview := _portrait_preview()
	var label := _portrait_path_label()
	if _portrait_data.is_empty():
		preview.texture = null
		label.text = "Aucune image sélectionnée"
		return
	var texture := _texture_portrait_depuis_payload(_portrait_data)
	if texture == null:
		preview.texture = null
		label.text = "Portrait interne invalide"
		return
	preview.texture = texture
	label.text = str(_portrait_data.get("file_name", "portrait_interne.png"))


func _serialiser_portrait(image: Image, file_name: String) -> Dictionary:
	var buffer: PackedByteArray = image.save_png_to_buffer()
	if buffer.is_empty():
		return {}
	return {
		"file_name": file_name,
		"encoding": "png_base64",
		"data": Marshalls.raw_to_base64(buffer),
	}


func _texture_portrait_depuis_payload(payload: Dictionary) -> Texture2D:
	if payload.is_empty():
		return null
	var encoding := str(payload.get("encoding", ""))
	var encoded_data := str(payload.get("data", ""))
	if encoding != "png_base64" or encoded_data.is_empty():
		return null
	var raw: PackedByteArray = Marshalls.base64_to_raw(encoded_data)
	if raw.is_empty():
		return null
	var image := Image.new()
	var err := image.load_png_from_buffer(raw)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _format_prerequisite(pr: Variant) -> String:
	if pr == null:
		return "Aucun"
	if typeof(pr) == TYPE_DICTIONARY:
		var parts: Array = []
		var stats := pr.get("stats", {}) as Dictionary
		if stats.size() > 0:
			var sarr: Array = []
			for k in stats.keys():
				sarr.append("%s >= %s" % [str(k), str(stats[k])])
			parts.append("Stats: %s" % _join_array(sarr, ", "))
		var feats := pr.get("feats", []) as Array
		if feats.size() > 0:
			var names: Array = []
			for fid in feats:
				var fdata := GameDataLoader.get_feats().get(str(fid), {}) as Dictionary
				names.append(str(fdata.get("name", str(fid))))
			parts.append("Dons requis: %s" % _join_array(names, ", "))
		return _join_array(parts, "\n") if parts.size() > 0 else "Aucun"
	elif typeof(pr) == TYPE_ARRAY:
		var names2: Array = []
		for fid in pr:
			var fdata2 := GameDataLoader.get_feats().get(str(fid), {}) as Dictionary
			names2.append(str(fdata2.get("name", str(fid))))
		return "Dons requis: %s" % _join_array(names2, ", ")
	return str(pr)


func _format_effects(effects: Variant) -> String:
	if effects == null:
		return "Aucun"
	if typeof(effects) != TYPE_DICTIONARY:
		return str(effects)
	var out: Array = []
	if effects.has("stats"):
		var st := effects.get("stats", {}) as Dictionary
		for k in st.keys():
			out.append("%+d %s" % [int(st[k]), str(k)])
	if effects.has("pv_bonus"):
		out.append("PV %+d" % int(effects.get("pv_bonus", 0)))
	if effects.has("mana_bonus"):
		out.append("Mana %+d" % int(effects.get("mana_bonus", 0)))
	# autres clefs éventuelles
	for key in effects.keys():
		if key in ["stats", "pv_bonus", "mana_bonus"]:
			continue
		out.append("%s: %s" % [str(key), str(effects.get(key))])
	return _join_array(out, ", ") if out.size() > 0 else "Aucun"


func _on_carte_gui_input(ev: InputEvent, classe_id: String) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_choisir_classe(classe_id)


func _read_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed as Dictionary


func _build_class_cards() -> void:
	var container := _cards_container()
	# Clear existing cards (static or previous dynamic)
	for c in container.get_children():
		# Use immediate free to avoid one-frame duplicates from legacy scene cards.
		c.free()

	var classes: Dictionary = GameDataLoader.get_classes()
	if classes.is_empty():
		push_warning("creation_personnage: aucune classe chargée — vérifiez res://mvp/data/classes.json ou GameDataLoader.")
		return

	var keys: Array = classes.keys()
	keys.sort()
	for key in keys:
		var entry := classes[key] as Dictionary
		var panel := PanelContainer.new()
		panel.name = "Card_%s" % str(key)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(0, 150)
		# Determine default colors by class primary (force/magie/other), allow overrides from data
		var primaries: Array = entry.get("primary", []) as Array
		var p_norm: Array = []
		if typeof(primaries) == TYPE_ARRAY:
			for p in primaries:
				p_norm.append(str(p).to_lower())
		var default_bg := CLASS_PANEL_OTHER_BG
		var default_border := CLASS_PANEL_OTHER_BORDER
		var default_accent := CLASS_ACCENT_OTHER
		if p_norm.has("force"):
			default_bg = CLASS_PANEL_FORCE_BG
			default_border = CLASS_PANEL_FORCE_BORDER
			default_accent = CLASS_ACCENT_FORCE
		elif p_norm.has("magie"):
			default_bg = CLASS_PANEL_MAGIC_BG
			default_border = CLASS_PANEL_MAGIC_BORDER
			default_accent = CLASS_ACCENT_MAGIC
		var panel_bg := _color_from_value(entry.get("panel_bg_color", null), default_bg)
		var panel_border := _color_from_value(entry.get("panel_border_color", null), default_border)
		panel.add_theme_stylebox_override("panel", _make_panel_style(panel_bg, panel_border))
		# tooltip with description for hover
		if panel.has_method("set_custom_tooltip"):
			panel.hint_tooltip = str(entry.get("description", ""))
		else:
			# fallback: set a generic tooltip property if available
			if panel.has_method("set_tooltip"):
				panel.set_tooltip(str(entry.get("description", "")))
		var v := VBoxContainer.new()
		if v.has_method("add_theme_constant_override"):
			v.add_theme_constant_override("separation", 8)
		panel.add_child(v)

		# Récupération centralisée de l'icône via GameDataLoader
		var tex: Texture2D = GameDataLoader.get_class_icon(str(key))
		if tex:
			var texr := TextureRect.new()
			texr.texture = tex
			texr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texr.custom_minimum_size = Vector2(0, 64)
			v.add_child(texr)
		else:
			var ico := Label.new()
			ico.text = "[ %s ]" % str(entry.get("name", key))
			ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(ico)

		var name_lbl := Label.new()
		name_lbl.text = str(entry.get("name", key))
		# keep default font sizing to avoid theme override issues
		# name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_font_size_override("font_size", 15)
		var accent_col := _color_from_value(entry.get("accent_color", null), default_accent)
		name_lbl.add_theme_color_override("font_color", accent_col)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(name_lbl)

		var desc := Label.new()
		# Remove explicit "+N" stat indicators from class descriptions for UI clarity
		var desc_text := str(entry.get("description", ""))
		var re := RegEx.new()
		if re.compile("\\+\\d+") == OK:
			desc_text = re.sub(desc_text, "")
		desc.text = desc_text.strip_edges()
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.clip_text = true
		var desc_col := _color_from_value(entry.get("text_color", null), CREATION_TEXT_MAIN)
		desc.add_theme_color_override("font_color", desc_col)
		# desc.add_theme_font_size_override("font_size", 11)
		v.add_child(desc)

		var btn := Button.new()
		btn.text = "Choisir cette classe"
		btn.custom_minimum_size = Vector2(0, 30)
		btn.pressed.connect(_choisir_classe.bind(str(key)))
		v.add_child(btn)

		# whole-panel click
		panel.gui_input.connect(Callable(self, "_on_carte_gui_input").bind(str(key)))

		container.add_child(panel)


func _remplir_option_button(option: OptionButton, valeurs: Array) -> void:
	option.clear()
	for v in valeurs:
		option.add_item(str(v))
	option.select(0)
	_sync_option_button_text(option)


func _remplir_option_button_entries(option: OptionButton, entrees: Array) -> void:
	option.clear()
	for e in entrees:
		var entry := e as Dictionary
		var idx := option.item_count
		option.add_item(str(entry.get("nom", "")))
		option.set_item_metadata(idx, str(entry.get("id", "")))
	option.select(0)
	_sync_option_button_text(option)


func _add_character_sheet_button() -> void:
	return


func _open_character_sheet() -> void:
	if _embedded_sheet != null and is_instance_valid(_embedded_sheet):
		return
	var scene: PackedScene = load("res://scenes/character_sheet.tscn") as PackedScene
	if scene == null:
		_error_label().text = "Impossible de charger la fiche JDR."
		push_warning("Impossible de charger la scène de fiche personnage")
		return
	var sheet: Node = scene.instantiate()
	if sheet == null:
		_error_label().text = "Impossible d'ouvrir la fiche JDR."
		return
	if sheet.has_method("set_embedded_mode"):
		sheet.set_embedded_mode(true)
	_embedded_sheet = sheet
	_sheet_host().add_child(sheet)
	if sheet.has_method("setup"):
		sheet.setup(_fiche_stats.duplicate(true), _fiche_points_restants, _classe_choisie)
	if sheet.has_method("set_selected_class"):
		sheet.set_selected_class(_classe_choisie)
	if sheet.has_method("set_class_locked"):
		sheet.set_class_locked(true)
	sheet.connect("saved", Callable(self, "_on_character_sheet_saved"))


func _on_character_sheet_saved(stats: Dictionary, points_remaining: int, char_class: String, feats: Array) -> void:
	# Appliquer les modifications depuis la fiche
	_fiche_stats = StatDefs.sanitize_stats(
		stats,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)
	_fiche_points_restants = int(points_remaining)
	_fiche_feats = feats.duplicate(true)
	if char_class != "":
		_classe_choisie = char_class
		_class_label().text = "Classe choisie : %s" % _get_class_data(char_class).get("nom", char_class)
		_mettre_a_jour_surbrillance(_classe_choisie)
	_mettre_a_jour_resume_build()


func _on_selection_build_change(_index: int) -> void:
	_sync_all_option_button_texts()
	_mettre_a_jour_resume_build()


func _mettre_a_jour_resume_build() -> void:
	if not _find_option("OptionGenre"):
		return
	# Display the entered character name and clan in the build section with vitals
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String  = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var classe_label := "Aucune"
	if not _classe_choisie.is_empty():
		var classe_data_top := _get_class_data(_classe_choisie)
		classe_label = str(classe_data_top.get("nom", _classe_choisie))
	var genre := _texte_option(_find_option("OptionGenre"))
	var pouvoir := _texte_option(_find_option("OptionPouvoir"))
	var don := _texte_option(_find_option("OptionDon"))
	var competence := _texte_option(_find_option("OptionCompetence"))

	# Build stats/vitals preview from current point-buy
	var fiche := _construire_fiche_complete()
	var pv_max := int(fiche.get("pv_max", 0))
	var defense := int(fiche.get("defense", 0))
	var initiative := int(fiche.get("initiative", 0))
	# calculer les bonus PV/Mana provenant des dons de classe et des dons sélectionnés
	var total_pv_bonus_preview := 0
	var total_mana_bonus_preview := 0
	var feats_defs_preview: Dictionary = GameDataLoader.get_feats()
	if not _classe_choisie.is_empty():
		var classe_data_preview := _get_class_data(_classe_choisie)
		var class_feats_preview := (classe_data_preview.get("competences", []) as Array)
		for cf in class_feats_preview:
			var cf_def_preview := feats_defs_preview.get(str(cf), {}) as Dictionary
			var ceff_preview := cf_def_preview.get("effects", {}) as Dictionary
			if ceff_preview.has("pv_bonus"):
				total_pv_bonus_preview += int(ceff_preview.get("pv_bonus", 0))
			if ceff_preview.has("mana_bonus"):
				total_mana_bonus_preview += int(ceff_preview.get("mana_bonus", 0))
	for f in _fiche_feats:
		var fdef_preview := feats_defs_preview.get(str(f), {}) as Dictionary
		var eff_preview := fdef_preview.get("effects", {}) as Dictionary
		if eff_preview.has("pv_bonus"):
			total_pv_bonus_preview += int(eff_preview.get("pv_bonus", 0))
		if eff_preview.has("mana_bonus"):
			total_mana_bonus_preview += int(eff_preview.get("mana_bonus", 0))
	var stats_line := ""
	if _fiche_stats != null:
		stats_line = "Stats: FOR %d | MAG %d | ESP %d | ART %d | DIP %d | COM %d" % [
			int(_fiche_stats.get("force", StatDefs.CHARACTER_MIN_STAT)),
			int(_fiche_stats.get("magie", StatDefs.CHARACTER_MIN_STAT)),
			int(_fiche_stats.get("espionnage", StatDefs.CHARACTER_MIN_STAT)),
			int(_fiche_stats.get("artisanat", StatDefs.CHARACTER_MIN_STAT)),
			int(_fiche_stats.get("diplomatie", StatDefs.CHARACTER_MIN_STAT)),
			int(_fiche_stats.get("commandement", StatDefs.CHARACTER_MIN_STAT)),
		]
	var clan_mgr := _clan_manager()
	var mana := 0
	var ame_pct := 0
	if clan_mgr != null:
		mana = int(clan_mgr.ressources.get("mana", 0))
		# Compute mana bonus from selected feats and class starting feats for preview
		var total_mana_bonus := 0
		var feats_defs: Dictionary = GameDataLoader.get_feats()
		if not _classe_choisie.is_empty():
			var classe_data_mana := _get_class_data(_classe_choisie)
			var class_feats := (classe_data_mana.get("competences", []) as Array)
			for cf in class_feats:
				var cf_def := feats_defs.get(str(cf), {}) as Dictionary
				var ceff := cf_def.get("effects", {}) as Dictionary
				if ceff.has("mana_bonus"):
					total_mana_bonus += int(ceff.get("mana_bonus", 0))
		for f in _fiche_feats:
			var fdef := feats_defs.get(str(f), {}) as Dictionary
			var eff := fdef.get("effects", {}) as Dictionary
			if eff.has("mana_bonus"):
				total_mana_bonus += int(eff.get("mana_bonus", 0))
		mana += total_mana_bonus
		ame_pct = int(clan_mgr.barre_ame)

	var summary_text := "Nom: %s | Clan: %s\nClasse: %s · Genre: %s\nPouvoir: %s | Don: %s | Compétence: %s\n%s\nPV Max: %d (%+d) | Défense: %d | Initiative: %d | Mana: %d (%+d) | Âme: %d%%" % [
		nom_perso if not nom_perso.is_empty() else "—",
		nom_clan if not nom_clan.is_empty() else "—",
		classe_label,
		genre,
		pouvoir,
		don,
		competence,
		(stats_line if stats_line != "" else ""),
		pv_max,
		total_pv_bonus_preview,
		defense,
		initiative,
		mana,
		total_mana_bonus_preview,
		ame_pct,
	]
	var classe_data_info := _get_class_data(_classe_choisie)
	var equipements_classe := _format_string_list(classe_data_info.get("equipement", []) as Array)
	var feats_resume := _format_string_list(_fiche_feats)
	var portrait_resume := "Image importee" if not _portrait_data.is_empty() else "Aucun portrait"
	match _slide_index:
		0:
			_build_resume_label().text = "Classe: %s\nStyle: %s · %s\nPortrait: %s" % [
				classe_label,
				genre,
				_texte_option(_find_option("OptionApparence")),
				portrait_resume,
			]
		1:
			_build_resume_label().text = "Archetype: %s\nDon: %s\nCompetence: %s\nFeats de fiche: %s" % [
				_texte_option(_find_option("OptionArchetype")),
				don,
				competence,
				feats_resume,
			]
		2:
			_build_resume_label().text = "Pouvoir racial: %s\n%s\nPV Max: %d | Defense: %d | Initiative: %d" % [
				pouvoir,
				stats_line if stats_line != "" else "Stats non disponibles",
				pv_max,
				defense,
				initiative,
			]
		3:
			_build_resume_label().text = "Equipement choisi: %s\nEquipements lies a la classe: %s" % [
				_texte_option(_find_option("OptionEquipement")),
				equipements_classe,
			]
		_:
			_build_resume_label().text = summary_text

	# Mettre à jour le tableau résumé compact s'il est visible
	_update_compact_sheet_summary()


func _texte_option(option: OptionButton) -> String:
	if option == null or option.item_count <= 0:
		return ""
	var idx := maxi(0, option.selected)
	return option.get_item_text(idx)


# ── Sélection de classe ──────────────────────────────────────────────

func _choisir_classe(classe_id: String) -> void:
	_classe_choisie = classe_id
	var data := _get_class_data(classe_id)
	_appliquer_point_buy_classe(classe_id)

	_class_label().text = "Classe choisie : %s" % data["nom"]
	_class_label().modulate = Color(0.9, 0.7, 1, 1)
	_error_label().text = ""

	# Mise en surbrillance de la carte sélectionnée
	_mettre_a_jour_surbrillance(classe_id)
	if _embedded_sheet != null and is_instance_valid(_embedded_sheet):
		if _embedded_sheet.has_method("setup"):
			_embedded_sheet.setup(_fiche_stats.duplicate(true), _fiche_points_restants, _classe_choisie)
		if _embedded_sheet.has_method("set_selected_class"):
			_embedded_sheet.set_selected_class(classe_id)
		if _embedded_sheet.has_method("set_class_locked"):
			_embedded_sheet.set_class_locked(true)
	_valider_formulaire()
	_mettre_a_jour_resume_build()


func _mettre_a_jour_surbrillance(classe_choisie: String) -> void:
	var container := _cards_container()
	for child in container.get_children():
		var id := str(child.name).replace("Card_", "")
		if id == classe_choisie:
			child.modulate = Color(1.1, 1.1, 1.1, 1)
		else:
			child.modulate = Color(0.7, 0.7, 0.7, 1)


# ── Validation du formulaire ─────────────────────────────────────────

func _on_texte_change(_text: String) -> void:
	_valider_formulaire()
	_mettre_a_jour_resume_build()


func _valider_formulaire() -> void:
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String  = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var ok: bool = nom_perso.length() >= 2 and nom_clan.length() >= 2 and _classe_choisie != ""
	$PanneauCentre/LigneBoutons/BtnCommencer.disabled = not ok
	var btn_bottom := get_node_or_null("ActionBar/ActionButtons/BtnCommencerBottom") as Button
	if btn_bottom:
		btn_bottom.disabled = not ok if _slide_index == CREATION_SLIDES.size() - 1 else false


# ── Actions ─────────────────────────────────────────────────────────

func _on_commencer() -> void:
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String  = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var erreur := _verifier_saisies(nom_perso, nom_clan)

	if erreur != "":
		_error_label().text = erreur
		return

	var classe_data_final := _get_class_data(_classe_choisie)
	var profil := _construire_profil_personnage()
	var bonus_comp := _bonus_competence(str(profil.get("competence_id", "")))
	var bonus_archetype := _bonus_archetype(str(profil.get("archetype_pathfinder", "")))

	# Calculer les bonus plats de stats provenant des dons (feats) et des dons de classe
	var feats_defs: Dictionary = GameDataLoader.get_feats()
	var feats_bonus: Dictionary = {}
	# inclure les feats de départ de la classe (si présents)
	var class_feats := (classe_data_final.get("competences", []) as Array)
	for cf in class_feats:
		var cf_def := feats_defs.get(str(cf), {}) as Dictionary
		var eff := cf_def.get("effects", {}) as Dictionary
		var stats_eff := eff.get("stats", {}) as Dictionary
		for sk in stats_eff.keys():
			feats_bonus[sk] = int(feats_bonus.get(sk, 0)) + int(stats_eff[sk])
	# inclure les feats sélectionnés dans la fiche
	for f in _fiche_feats:
		var fdef := feats_defs.get(str(f), {}) as Dictionary
		var eff := fdef.get("effects", {}) as Dictionary
		var stats_eff := eff.get("stats", {}) as Dictionary
		for sk in stats_eff.keys():
			feats_bonus[sk] = int(feats_bonus.get(sk, 0)) + int(stats_eff[sk])

	var stats_finales := CharacterBuildService.compute_final_stats(
		(classe_data_final.get("stats_bonus", {}) as Dictionary),
		_fiche_stats,
		bonus_comp,
		bonus_archetype,
		feats_bonus
	)

	profil["competences_depart"] = _competences_depart(classe_data_final, profil)

	# --- User-requested defaults: set parents' given names
	profil["pere_name"] = "Vincent"
	profil["mere_name"] = "Aurys"

	# Compose full player name as "Prénom NomDeClan" (use clan as family name)
	var prenom := nom_perso.strip_edges()
	var _nom_complet := prenom
	if nom_clan.strip_edges() != "":
		_nom_complet = "%s %s" % [prenom, nom_clan]

	var clan_mgr := _clan_manager()
	var game_mgr := _game_manager()
	if clan_mgr == null or game_mgr == null:
		_error_label().text = "Services du jeu introuvables (autoload)."
		push_error("Autoload manquant: ClanManager ou GameManager")
		return

	# Ensure the profile is persisted in ClanManager before navigating away.
	# This guards against flows where the UI navigation may rebuild clan_hub
	# before the in-memory profile is picked up.
	var fiche_complete := _construire_fiche_complete()
	var feats_list := _fiche_feats.duplicate(true)
	var pts := int(fiche_complete.get("points_restants", 0))
	clan_mgr.apply_profile_sheet_update(fiche_complete.get("stats_brutes", {}), pts, feats_list)
	clan_mgr.sauvegarder()

	clan_mgr.nouvelle_partie(nom_perso, nom_clan, _classe_choisie, stats_finales, profil)
	game_mgr.go_to("intro_vn")


func _construire_profil_personnage() -> Dictionary:
	var fiche_complete := _construire_fiche_complete()
	var traits_gameplay := _construire_traits_gameplay()
	return {
		"genre": _texte_option(_find_option("OptionGenre")),
		"apparence": _texte_option(_find_option("OptionApparence")),
		"portrait": _portrait_data.duplicate(true),
		"pouvoir_magique": _texte_option(_find_option("OptionPouvoir")),
		"pouvoir_magique_id": _id_option(_find_option("OptionPouvoir")),
		"archetype_pathfinder": _texte_option(_find_option("OptionArchetype")),
		"don": _texte_option(_find_option("OptionDon")),
		"don_id": _id_option(_find_option("OptionDon")),
		"competence": _texte_option(_find_option("OptionCompetence")),
		"competence_id": _id_option(_find_option("OptionCompetence")),
		"equipement_depart": _texte_option(_find_option("OptionEquipement")),
		"equipement_depart_id": _id_option(_find_option("OptionEquipement")),
		"feats": _fiche_feats.duplicate(true),
		"magie_pactes": true,
		"traits_gameplay": traits_gameplay,
		"fiche_complete": fiche_complete,
	}


func _construire_traits_gameplay() -> Dictionary:
	var data_loader := _game_data_loader()
	if data_loader == null:
		push_warning("GameDataLoader introuvable, traits par défaut utilisés")
		return {
			"mana_cost_reduction_pct": 0,
			"soldats_cost_reduction_attaquer_pct": 0,
			"bonus_score_actions": {},
			"night_soul_regen": 0,
			"night_reputation_gain": 0,
		}
	var traits_data = data_loader.get_character_traits()
	var traits := {
		"mana_cost_reduction_pct": 0,
		"soldats_cost_reduction_attaquer_pct": 0,
		"bonus_score_actions": {},
		"night_soul_regen": 0,
		"night_reputation_gain": 0,
	}

	var don_id := _id_option(_find_option("OptionDon"))
	var pouvoir_id := _id_option(_find_option("OptionPouvoir"))
	var competence_id := _id_option(_find_option("OptionCompetence"))

	var dons := traits_data.get("dons", {}) as Dictionary
	var pouvoirs := traits_data.get("pouvoirs", {}) as Dictionary
	var competences := traits_data.get("competences", {}) as Dictionary

	_fusionner_effets_traits(traits, (dons.get(don_id, {}) as Dictionary).get("effects", {}) as Dictionary)
	_fusionner_effets_traits(traits, (pouvoirs.get(pouvoir_id, {}) as Dictionary).get("effects", {}) as Dictionary)
	_fusionner_effets_traits(traits, (competences.get(competence_id, {}) as Dictionary).get("effects", {}) as Dictionary)

	var caps := traits_data.get("caps", {}) as Dictionary
	return _appliquer_caps_traits(traits, caps)


func _fusionner_effets_traits(destination: Dictionary, effets: Dictionary) -> void:
	if effets.is_empty():
		return

	for k in effets.keys():
		if k == "bonus_score_actions":
			var dest_map := (destination.get("bonus_score_actions", {}) as Dictionary).duplicate(true)
			var src_map := effets.get("bonus_score_actions", {}) as Dictionary
			for action_id in src_map.keys():
				dest_map[action_id] = int(dest_map.get(action_id, 0)) + int(src_map[action_id])
			destination["bonus_score_actions"] = dest_map
		else:
			destination[k] = int(destination.get(k, 0)) + int(effets[k])


func _appliquer_caps_traits(traits: Dictionary, caps: Dictionary) -> Dictionary:
	var out := traits.duplicate(true)
	out["mana_cost_reduction_pct"] = clampi(
		int(out.get("mana_cost_reduction_pct", 0)),
		0,
		maxi(0, int(caps.get("mana_cost_reduction_pct", 35)))
	)
	out["soldats_cost_reduction_attaquer_pct"] = clampi(
		int(out.get("soldats_cost_reduction_attaquer_pct", 0)),
		0,
		maxi(0, int(caps.get("soldats_cost_reduction_attaquer_pct", 20)))
	)
	out["night_soul_regen"] = clampi(
		int(out.get("night_soul_regen", 0)),
		0,
		maxi(0, int(caps.get("night_soul_regen", 4)))
	)
	out["night_reputation_gain"] = clampi(
		int(out.get("night_reputation_gain", 0)),
		0,
		maxi(0, int(caps.get("night_reputation_gain", 2)))
	)

	var per_action_cap := maxi(0, int(caps.get("bonus_per_action_max", 3)))
	var map_bonus := (out.get("bonus_score_actions", {}) as Dictionary).duplicate(true)
	for action_id in map_bonus.keys():
		map_bonus[action_id] = clampi(int(map_bonus[action_id]), -per_action_cap, per_action_cap)
	out["bonus_score_actions"] = map_bonus

	return out


func _stat_modificateur(score: int) -> int:
	return int(floor((score - 10) / 2.0))


func _appliquer_point_buy_classe(classe_id: String) -> void:
	_fiche_points_restants = POINTS_FICHE_RESTANTS_CIBLE
	_fiche_stats = StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	var classes: Dictionary = GameDataLoader.get_classes()
	if classes.has(classe_id) and classes[classe_id] is Dictionary:
		var class_def := classes[classe_id] as Dictionary
		var base_stats := _resolve_base_stats_for_class(class_def)
		_fiche_stats = StatDefs.sanitize_stats(
			base_stats,
			StatDefs.CHARACTER_MIN_STAT,
			StatDefs.CHARACTER_MAX_STAT,
			StatDefs.CHARACTER_MIN_STAT
		)
		_fiche_points_restants = POINTS_FICHE_RESTANTS_CIBLE
		return

	# Fallback legacy si une classe n'a pas de base_stats
	_distribuer_points(["force", "magie", "espionnage", "artisanat", "diplomatie", "commandement"], 10)
	_fiche_points_restants = POINTS_FICHE_RESTANTS_CIBLE


	## Debug utilities (temporary)
func _debug_show_names() -> void:
	# Create an overlay label in the scene showing the current name/clan for visual debugging
	var root := get_tree().root
	if not root:
		return
	# Avoid duplicate debug label
	if has_node("/root/DebugNameOverlay"):
		var existing := get_node("/root/DebugNameOverlay")
		existing.queue_free()
	var dbg := Label.new()
	dbg.name = "DebugNameOverlay"
	dbg.anchor_left = 0.0
	dbg.anchor_top = 0.0
	dbg.anchor_right = 0.0
	dbg.anchor_bottom = 0.0
	dbg.offset_left = 12
	dbg.offset_top = 6
	dbg.add_theme_font_size_override("font_size", 14)
	dbg.modulate = Color(1, 0.9, 0.2, 1)
	root.add_child(dbg)

	# Highlight the LineEdit fields so they are easy to spot
	var np := $PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit
	var nc := $PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit
	# Compute text now that we have references
	var perso_str := ""
	var clan_str := ""
	if np:
		perso_str = np.text
	if nc:
		clan_str = nc.text
	dbg.text = "Perso: %s  |  Clan: %s" % [perso_str, clan_str]
	if np:
		np.add_theme_color_override("font_color", Color(1,1,1,1))
		np.modulate = Color(1, 1, 1, 1)
	if nc:
		nc.add_theme_color_override("font_color", Color(1,1,1,1))
		nc.modulate = Color(1, 1, 1, 1)


func _distribuer_points(priorites: Array, max_spent: int) -> void:
	var spent := 0
	var idx := 0
	while spent < max_spent and _fiche_points_restants > 0 and idx < 48:
		var stat := str(priorites[idx % priorites.size()])
		if int(_fiche_stats.get(stat, 8)) < 16:
			_fiche_stats[stat] = int(_fiche_stats[stat]) + 1
			_fiche_points_restants -= 1
			spent += 1
		idx += 1


func _construire_fiche_complete() -> Dictionary:
	var mods := CharacterBuildService.build_modifiers(_fiche_stats)
	var derived := CharacterBuildService.build_derived_stats(mods)

	var pv_base := 10
	if _classe_choisie == "chevalier_sombre":
		pv_base = 14
	elif _classe_choisie == "mage_du_pacte":
		pv_base = 8
	elif _classe_choisie == "stratege_des_ombres":
		pv_base = 10

	var points_spent := 0
	for k in StatDefs.STAT_KEYS:
		points_spent += max(0, int(_fiche_stats.get(k, StatDefs.CHARACTER_MIN_STAT)) - StatDefs.CHARACTER_MIN_STAT)
	var points_pool_total := points_spent + _fiche_points_restants

	return {
		"classe": _classe_choisie,
		"niveau": 1,
		"points_a_distribuer_base": points_pool_total,
		"points_restants": _fiche_points_restants,
		"stats_brutes": _fiche_stats.duplicate(true),
		"modificateurs": mods,
		"pv_max": pv_base + int(mods["commandement"]),
		"initiative": int(derived["initiative"]),
		"defense": int(derived["defense"]),
		"attaque": int(derived["attaque"]),
		"resistance": int(derived["resistance"]),
		"jet_vigueur": int(derived["jet_vigueur"]),
		"jet_volonte": int(derived["jet_volonte"]),
		"jet_reflexes": int(derived["jet_reflexes"]),
	}


func _get_class_data(classe_id: String) -> Dictionary:
	# Récupère la définition depuis GameDataLoader (single source of truth)
	var classes: Dictionary = GameDataLoader.get_classes()
	if classes.has(classe_id):
		var entry := classes[classe_id] as Dictionary
		var stats_bonus := _derive_stats_bonus_from_base(_resolve_base_stats_for_class(entry))
		return {
			"nom": str(entry.get("name", classe_id)),
			"stats_bonus": stats_bonus,
			"equipement": entry.get("starting_abilities", []),
			"competences": entry.get("starting_feats", []),
		}

	# fallback minimal
	return {
		"nom": classe_id,
		"stats_bonus": StatDefs.make_default_stats(0),
		"equipement": [],
		"competences": [],
	}


func _derive_stats_bonus_from_base(base_stats: Dictionary) -> Dictionary:
	# Convertit les stats brutes de classe (8..16+) en bonus de clan centrés sur 10.
	# Exemple: 13 -> +3, 8 -> -2, 10 -> 0
	var out := StatDefs.make_default_stats(0)
	if base_stats.is_empty():
		return out
	for key in StatDefs.STAT_KEYS:
		var score := int(base_stats.get(key, 10))
		out[key] = score - 10
	return out


func _resolve_base_stats_for_class(class_def: Dictionary) -> Dictionary:
	var explicit_base := class_def.get("base_stats", {}) as Dictionary
	if not explicit_base.is_empty():
		return explicit_base
	return _build_base_stats_from_class_def(class_def)


func _build_base_stats_from_class_def(class_def: Dictionary) -> Dictionary:
	# Génère un pool de départ différent par classe à partir des tags primary/secondary.
	var out := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	var primary := class_def.get("primary", []) as Array
	var secondary := class_def.get("secondary", []) as Array
	var hit_die := int(class_def.get("hit_die", 8))

	for stat in primary:
		var key := str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 3
	for stat in secondary:
		var key := str(stat)
		if out.has(key):
			out[key] = int(out[key]) + 2

	# Petite signature selon la robustesse de classe
	if hit_die >= 10:
		out["force"] = int(out.get("force", 8)) + 1
		out["commandement"] = int(out.get("commandement", 8)) + 1
	elif hit_die <= 6:
		out["magie"] = int(out.get("magie", 8)) + 1

	return StatDefs.sanitize_stats(
		out,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)


func _bonus_competence(competence_id: String) -> Dictionary:
	match competence_id:
		"maitrise_martiale":
			return {"force": 1, "commandement": 1}
		"rituel_occulte":
			return {"magie": 2}
		"diplomatie_de_guerre":
			return {"diplomatie": 1, "commandement": 1}
		"infiltration":
			return {"espionnage": 2}
	return {}


func _id_option(option: OptionButton) -> String:
	if option == null or option.item_count <= 0:
		return ""
	var idx := maxi(0, option.selected)
	if idx >= option.item_count:
		idx = option.item_count - 1
	var meta: Variant = option.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta)


func _bonus_archetype(archetype: String) -> Dictionary:
	match archetype:
		"Lame jurée (inspiration Guerrier)":
			return {"force": 2}
		"Ensorceleur abyssal (inspiration Magicien)":
			return {"magie": 2}
		"Traqueur des ruines (inspiration Rôdeur)":
			return {"espionnage": 1, "force": 1}
		"Prédicateur noir (inspiration Clerc)":
			return {"diplomatie": 1, "magie": 1}
		"Ombrelame (inspiration Roublard)":
			return {"espionnage": 2}
		"Alchimiste de siège (inspiration Alchimiste)":
			return {"artisanat": 2}
	return {}


func _competences_depart(classe_data: Dictionary, profil: Dictionary) -> Array:
	var competences: Array = (classe_data.get("competences", []) as Array).duplicate(true)
	var comp := str(profil.get("competence", ""))
	if not comp.is_empty():
		competences.append(comp)
	# Toujours disponible pour le recrutement de PNJ.
	competences.append(MAGIE_PACTES)
	return competences


func _verifier_saisies(nom_perso: String, nom_clan: String) -> String:
	if nom_perso.length() < 2:
		return "Le nom du personnage doit contenir au moins 2 caractères."
	if nom_clan.length() < 2:
		return "Le nom du clan doit contenir au moins 2 caractères."
	if _classe_choisie == "":
		return "Veuillez choisir une classe avant de continuer."
	return ""


## ── Slide 2 : ColDroite (gauche visuel) = listes capacités+dons
func _build_capabilities_panel() -> void:
	var col_d := find_child("ColDroite", true, false) as VBoxContainer
	if col_d == null:
		return

	# Supprimer l'ancien panneau si présent
	var existing := col_d.get_node_or_null("Slide2AbilitiesPane")
	if existing:
		existing.queue_free()

	var pane := VBoxContainer.new()
	pane.name = "Slide2AbilitiesPane"
	pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_d.add_child(pane)

	var title := Label.new()
	title.text = "Capacités"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", CREATION_GOLD)
	pane.add_child(title)

	var abilities_list := ItemList.new()
	abilities_list.name = "AbilitiesList"
	abilities_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abilities_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pane.add_child(abilities_list)
	abilities_list.item_selected.connect(Callable(self, "_on_abilities_list_selected"))

	var feats_label := Label.new()
	feats_label.text = "Dons disponibles"
	feats_label.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	pane.add_child(feats_label)

	var feats_list := ItemList.new()
	feats_list.name = "FeatsList"
	feats_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feats_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pane.add_child(feats_list)
	feats_list.item_selected.connect(Callable(self, "_on_feats_list_selected"))

	# Peuplage des capacités
	_abilities_list_ids.clear()
	_feats_list_ids.clear()
	var abilities: Dictionary = GameDataLoader.get_abilities()
	var keys: Array = abilities.keys()
	keys.sort()
	for aid in keys:
		var a := abilities[aid] as Dictionary
		abilities_list.add_item(str(a.get("name", aid)))
		_abilities_list_ids.append(str(aid))

	if _abilities_list_ids.size() > 0:
		_on_abilities_list_selected(0)


func _on_abilities_list_selected(index: int) -> void:
	if index < 0 or index >= _abilities_list_ids.size():
		return
	_selected_ability_id = _abilities_list_ids[index]
	_selected_feat_id = ""

	# Mettre à jour la liste des dons pour la capacité sélectionnée
	var feats_list := find_child("FeatsList", true, false) as ItemList
	if feats_list == null:
		return
	feats_list.clear()
	_feats_list_ids = []
	var feat_defs: Dictionary = GameDataLoader.get_feats_for_ability(_selected_ability_id)
	var fkeys: Array = feat_defs.keys()
	fkeys.sort()
	for fid in fkeys:
		var f := feat_defs[fid] as Dictionary
		feats_list.add_item(str(f.get("name", fid)))
		_feats_list_ids.append(str(fid))

	if _feats_list_ids.size() > 0:
		_on_feats_list_selected(0)
	else:
		_selected_feat_id = ""

	# Actualiser les descriptions (capacité + don) pour la slide 2
	_refresh_slide2_descriptions()

	# Mettre à jour aussi le résumé compact (capacité potentiellement sans don)
	_update_compact_sheet_summary()


func _on_feats_list_selected(index: int) -> void:
	if index < 0 or index >= _feats_list_ids.size():
		return
	_selected_feat_id = _feats_list_ids[index]
	_refresh_slide2_descriptions()

	# Mettre à jour le tableau résumé compact s'il existe
	_update_compact_sheet_summary()


## ── Slide 2 : ColGauche (droite visuel) = fiche slide1 + descriptions
func _build_slide2_right_pane() -> void:
	var col_g := find_child("ColGauche", true, false) as VBoxContainer
	if col_g == null:
		return

	# Supprimer l'ancien panneau si présent
	var existing := col_g.get_node_or_null("Slide2SheetPane")
	if existing:
		existing.queue_free()
		_embedded_sheet = null

	var pane := VBoxContainer.new()
	pane.name = "Slide2SheetPane"
	pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_g.add_child(pane)

	# Fiche compacte : résumé des infos de l'étape 1 (nom, clan, classe, genre, apparence)
	var fiche := VBoxContainer.new()
	fiche.name = "CompactSheet"
	fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fiche.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pane.add_child(fiche)

	var fiche_title := Label.new()
	fiche_title.text = "Fiche (résumé)"
	fiche_title.add_theme_font_size_override("font_size", 16)
	fiche_title.add_theme_color_override("font_color", CREATION_GOLD)
	fiche.add_child(fiche_title)

	var nom_perso := ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan := ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var classe_nom := "Aucune"
	if not _classe_choisie.is_empty():
		classe_nom = str(_get_class_data(_classe_choisie).get("nom", _classe_choisie))
	var genre := _texte_option(_find_option("OptionGenre"))
	var apparence := _texte_option(_find_option("OptionApparence"))
	var _portrait_resume := "Image importee" if not _portrait_data.is_empty() else "Aucun portrait"

	var fiche_body := RichTextLabel.new()
	fiche_body.bbcode_enabled = false
	fiche_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Tableau récapitulatif (2 colonnes) — réutilisable entre slides
	var grid := GridContainer.new()
	grid.columns = 2
	grid.name = "CompactSummaryGrid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fiche.add_child(grid)

	var lbl = Label.new()
	lbl.text = "Nom:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	var val = Label.new()
	val.name = "Compact_Name"
	val.text = nom_perso if not nom_perso.is_empty() else "—"
	val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
	grid.add_child(val)

	lbl = Label.new()
	lbl.text = "Clan:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	val = Label.new()
	val.name = "Compact_Clan"
	val.text = nom_clan if not nom_clan.is_empty() else "—"
	val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
	grid.add_child(val)

	lbl = Label.new()
	lbl.text = "Classe:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	val = Label.new()
	val.name = "Compact_Class"
	val.text = classe_nom
	val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
	grid.add_child(val)

	lbl = Label.new()
	lbl.text = "Genre:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	val = Label.new()
	val.name = "Compact_Genre"
	val.text = genre if not genre.is_empty() else "—"
	val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
	grid.add_child(val)

	lbl = Label.new()
	lbl.text = "Apparence:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	val = Label.new()
	val.name = "Compact_Apparence"
	val.text = apparence if not apparence.is_empty() else "—"
	val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
	grid.add_child(val)

	lbl = Label.new()
	lbl.text = "Portrait:"
	lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
	grid.add_child(lbl)
	val = TextureRect.new()
	val.name = "Compact_Portrait"
	# afficher la texture si disponible
	var t := _texture_portrait_depuis_payload(_portrait_data)
	val.texture = t
	val.expand = true
	val.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	val.custom_minimum_size = Vector2(64, 64)
	if val.has_method("set_tooltip"):
		val.set_tooltip(str(_portrait_data.get("file_name", "")))
	grid.add_child(val)

	# Créer les widgets du résumé compact uniquement s'ils n'existent pas déjà
	if grid.get_node_or_null("Compact_Ability") == null:
		# Capacité (nom) — résumé compact
		lbl = Label.new()
		lbl.text = "Capacité:"
		lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
		grid.add_child(lbl)
		val = Label.new()
		val.name = "Compact_Ability"
		val.text = "—"
		val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
		grid.add_child(val)

		# Don (nom) — résumé compact
		lbl = Label.new()
		lbl.text = "Don:"
		lbl.add_theme_color_override("font_color", CREATION_TEXT_MUTED)
		grid.add_child(lbl)
		val = Label.new()
		val.name = "Compact_Feat"
		val.text = "—"
		val.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
		grid.add_child(val)

	# S'assurer que la description compacte existe (sous 'fiche')
	if fiche.get_node_or_null("Compact_FeatsDesc") == null:
		var compact_desc := RichTextLabel.new()
		compact_desc.name = "Compact_FeatsDesc"
		compact_desc.bbcode_enabled = false
		compact_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		compact_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		compact_desc.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
		compact_desc.custom_minimum_size = Vector2(0, 80)
		fiche.add_child(compact_desc)

	# séparer le tableau et placer les descriptions directement sous le tableau
	fiche.add_child(HSeparator.new())

	# Bloc descriptions (labels nommés pour mise à jour rapide sans recréer)
	var vbox := VBoxContainer.new()
	vbox.name = "Slide2Descriptions"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.custom_minimum_size = Vector2(0, 160)
	fiche.add_child(vbox)

	var abil_title := Label.new()
	abil_title.name = "AbilTitleLabel"
	abil_title.add_theme_font_size_override("font_size", 14)
	abil_title.add_theme_color_override("font_color", CREATION_GOLD)
	vbox.add_child(abil_title)

	var abil_desc := RichTextLabel.new()
	abil_desc.name = "AbilDescLabel"
	abil_desc.bbcode_enabled = false
	abil_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(abil_desc)


	var feat_title := Label.new()
	feat_title.name = "FeatTitleLabel"
	feat_title.add_theme_font_size_override("font_size", 14)
	feat_title.add_theme_color_override("font_color", CREATION_GOLD)
	vbox.add_child(feat_title)

	var feat_desc := RichTextLabel.new()
	feat_desc.name = "FeatDescLabel"
	feat_desc.bbcode_enabled = false
	feat_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(feat_desc)

	_refresh_slide2_descriptions()


func _refresh_slide2_descriptions() -> void:
	# Met à jour uniquement les labels de description sans recréer la fiche
	var vbox := find_child("Slide2Descriptions", true, false) as VBoxContainer
	if vbox == null:
		return

	var abil_title := vbox.get_node_or_null("AbilTitleLabel") as Label
	var abil_desc := vbox.get_node_or_null("AbilDescLabel") as RichTextLabel
	var feat_title := vbox.get_node_or_null("FeatTitleLabel") as Label
	var feat_desc := vbox.get_node_or_null("FeatDescLabel") as RichTextLabel

	# (debug logs removed)

	# Ensure description labels are visible and use readable color
	if abil_desc != null:
		abil_desc.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
		abil_desc.visible = true
	if feat_desc != null:
		feat_desc.add_theme_color_override("font_color", CREATION_TEXT_MAIN)
		feat_desc.visible = true

	if abil_title != null:
		if _selected_ability_id != "":
			var ad: Dictionary = GameDataLoader.get_ability_by_id(_selected_ability_id) as Dictionary
			abil_title.text = str(ad.get("name", "Capacité"))
			if abil_desc != null:
				abil_desc.text = str(ad.get("description", "Aucune description disponible."))
		else:
			abil_title.text = "Capacité"
			if abil_desc != null:
				abil_desc.text = "Aucune capacité sélectionnée"

	if feat_title != null:
		if _selected_feat_id != "":
			var fd: Dictionary = GameDataLoader.get_feats().get(_selected_feat_id, {}) as Dictionary
			feat_title.text = str(fd.get("name", "Don"))
			if feat_desc != null:
				var fdesc: String = str(fd.get("description", "Aucune description disponible."))
				var prereq: Dictionary = fd.get("prerequisite", {}) as Dictionary
				var effects: Dictionary = fd.get("effects", {}) as Dictionary
				var prereq_text: String = _format_prerequisite(prereq)
				var effects_text: String = _format_effects(effects)
				feat_desc.text = "%s\n\nPrerequis:\n%s\n\nEffets:\n%s" % [fdesc, prereq_text, effects_text]
		else:
			feat_title.text = "Don"
			if feat_desc != null:
				feat_desc.text = "Aucun don sélectionné"


func _update_compact_sheet_summary() -> void:
	# Met à jour le tableau résumé (CompactSummaryGrid) s'il est présent
	var grid := find_child("CompactSummaryGrid", true, false) as GridContainer
	if grid == null:
		return

	var name_lbl := grid.get_node_or_null("Compact_Name") as Label
	var clan_lbl := grid.get_node_or_null("Compact_Clan") as Label
	var class_lbl := grid.get_node_or_null("Compact_Class") as Label
	var genre_lbl := grid.get_node_or_null("Compact_Genre") as Label
	var apparence_lbl := grid.get_node_or_null("Compact_Apparence") as Label

	var nom_perso := ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan := ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var classe_nom := "Aucune"
	if not _classe_choisie.is_empty():
		classe_nom = str(_get_class_data(_classe_choisie).get("nom", _classe_choisie))
	var genre := _texte_option(_find_option("OptionGenre"))
	var apparence := _texte_option(_find_option("OptionApparence"))

	if name_lbl != null:
		name_lbl.text = nom_perso if not nom_perso.is_empty() else "—"
	if clan_lbl != null:
		clan_lbl.text = nom_clan if not nom_clan.is_empty() else "—"
	if class_lbl != null:
		class_lbl.text = classe_nom
	if genre_lbl != null:
		genre_lbl.text = genre if not genre.is_empty() else "—"
	if apparence_lbl != null:
		apparence_lbl.text = apparence if not apparence.is_empty() else "—"

	# Portrait (texte résumé)
	var portrait_tex := grid.get_node_or_null("Compact_Portrait") as TextureRect
	var tex := _texture_portrait_depuis_payload(_portrait_data)
	if portrait_tex != null:
		portrait_tex.texture = tex
		if portrait_tex.has_method("set_tooltip"):
			portrait_tex.set_tooltip(str(_portrait_data.get("file_name", "")))

	# Mettre à jour nom de capacité / don dans la fiche compacte
	var ability_lbl := grid.get_node_or_null("Compact_Ability") as Label
	var feat_lbl := grid.get_node_or_null("Compact_Feat") as Label
	var compact_desc := find_child("Compact_FeatsDesc", true, false) as RichTextLabel

	var ability_name := "—"
	var ability_desc := ""
	if _selected_ability_id != "":
		var ad := GameDataLoader.get_ability_by_id(_selected_ability_id) as Dictionary
		ability_name = str(ad.get("name", "—"))
		ability_desc = str(ad.get("description", ""))

	var feat_name := "—"
	var feat_desc := ""
	if _selected_feat_id != "":
		var fd := GameDataLoader.get_feats().get(_selected_feat_id, {}) as Dictionary
		feat_name = str(fd.get("name", "—"))
		feat_desc = str(fd.get("description", ""))

	if ability_lbl != null:
		ability_lbl.text = ability_name if ability_name != "" else "—"
	if feat_lbl != null:
		feat_lbl.text = feat_name if feat_name != "" else "—"

	if compact_desc != null:
		var short_desc := ""
		if ability_desc.strip_edges() != "":
			short_desc += "%s: %s\n" % [ability_name, ability_desc]
		if feat_desc.strip_edges() != "":
			if short_desc != "":
				short_desc += "\n"
			short_desc += "%s: %s\n" % [feat_name, feat_desc]
		if short_desc == "":
			short_desc = "Aucune description disponible."
		compact_desc.text = short_desc


func _on_retour() -> void:
	if _slide_index > 0:
		_error_label().text = ""
		_aller_a_slide(_slide_index - 1)
		return
	var game_mgr := _game_manager()
	if game_mgr:
		game_mgr.go_to("main_menu")

