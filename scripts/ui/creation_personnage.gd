## scripts/ui/creation_personnage.gd
## Copied to satisfy scene ext_resource references.
extends Control

func _clan_manager() -> Node:
	return get_node_or_null("/root/ClanManager")


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _game_data_loader() -> Node:
	return get_node_or_null("/root/GameDataLoader")
# Les définitions de classes sont centralisées dans `res://mvp/data/classes.json` via l'autoload `GameDataLoader`.
# Suppression de la définition locale `CLASSES` pour éviter les doublons.

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

const POINTS_FICHE_BASE := 18
var _fiche_points_restants: int = POINTS_FICHE_BASE
var _fiche_stats := {
	"force": 8,
	"magie": 8,
	"espionnage": 8,
	"artisanat": 8,
	"diplomatie": 8,
	"commandement": 8,
}
var _fiche_feats: Array = []
var _embedded_sheet: Node = null
var _portrait_data: Dictionary = {}


func _build_grid() -> GridContainer:
	return get_node_or_null("PanneauCentre/CreationBody/ColGauche/SectionBuild/GrilleBuild") as GridContainer


# Recherche un OptionButton par nom, où qu'il soit dans l'arbre (grille ou vbox)
func _find_option(option_name: String) -> OptionButton:
	return find_child(option_name, true, false) as OptionButton


func _build_section() -> VBoxContainer:
	return $PanneauCentre/CreationBody/ColGauche/SectionBuild as VBoxContainer


func _cards_container() -> GridContainer:
	return $PanneauCentre/CreationBody/ColGauche/CartesScroll/CartesClasses as GridContainer


func _class_label() -> Label:
	return $PanneauCentre/CreationBody/ColGauche/LabelClasseChoisie as Label


func _error_label() -> Label:
	return $PanneauCentre/CreationBody/ColGauche/LabelErreur as Label


func _build_resume_label() -> Label:
	return $PanneauCentre/CreationBody/ColGauche/SectionBuild/LabelBuildResume as Label


func _sheet_host() -> MarginContainer:
	return $PanneauCentre/CreationBody/ColDroite/RightScroll/FicheHostPanel/FicheHost as MarginContainer


func _portrait_preview() -> TextureRect:
	return $PanneauCentre/CreationBody/ColDroite/PortraitPanel/PortraitContent/PortraitPreview as TextureRect


func _portrait_path_label() -> Label:
	return $PanneauCentre/CreationBody/ColDroite/PortraitPanel/PortraitContent/PortraitPathLabel as Label


func _portrait_file_dialog() -> FileDialog:
	return $PortraitFileDialog as FileDialog


func _ready() -> void:
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


func _configurer_portrait_panel() -> void:
	_rafraichir_portrait_ui()


func _connecter_boutons() -> void:
	# Les boutons de classe sont connectés dynamiquement dans _build_class_cards()
	# Top button row is intentionally hidden; connect bottom action bar instead.

	# Les cartes sont créées et connectées dynamiquement dans _build_class_cards()

	$PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage.text_changed.connect(_on_texte_change)
	$PanneauCentre/LigneNoms/ColNomClan/NomClan.text_changed.connect(_on_texte_change)

	for opt_name in ["OptionGenre", "OptionApparence", "OptionPouvoir", "OptionArchetype", "OptionDon", "OptionCompetence", "OptionEquipement"]:
		var opt := _find_option(opt_name)
		if opt:
			opt.item_selected.connect(_on_selection_build_change)

	# Connexions pour la barre d'actions en bas (si présente)
	var btn_retour_bottom := get_node_or_null("ActionBar/ActionButtons/BtnRetourBottom")
	if btn_retour_bottom:
		btn_retour_bottom.pressed.connect(_on_retour)
	var btn_commencer_bottom := get_node_or_null("ActionBar/ActionButtons/BtnCommencerBottom")
	if btn_commencer_bottom:
		btn_commencer_bottom.pressed.connect(_on_commencer)
	var btn_upload_portrait := get_node_or_null("PanneauCentre/CreationBody/ColDroite/PortraitPanel/PortraitContent/PortraitButtons/BtnUploadPortrait") as Button
	if btn_upload_portrait:
		btn_upload_portrait.pressed.connect(_ouvrir_selection_portrait)
	var btn_reset_portrait := get_node_or_null("PanneauCentre/CreationBody/ColDroite/PortraitPanel/PortraitContent/PortraitButtons/BtnResetPortrait") as Button
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
	for opt_name in ["OptionGenre", "OptionApparence", "OptionPouvoir", "OptionArchetype", "OptionDon", "OptionCompetence", "OptionEquipement"]:
		var opt := _find_option(opt_name)
		if opt and opt.item_count > 0 and opt.selected < 0:
			opt.select(0)


func _sync_all_option_button_texts() -> void:
	for opt_name in ["OptionGenre", "OptionApparence", "OptionPouvoir", "OptionArchetype", "OptionDon", "OptionCompetence", "OptionEquipement"]:
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


func _appliquer_portrait_depuis_chemin(path: String) -> void:
	if path.strip_edges().is_empty():
		return
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		_error_label().text = "Impossible de charger l'image du portrait."
		return
	_portrait_data = _serialiser_portrait(image, path.get_file())
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
		c.queue_free()

	var classes := GameDataLoader.get_classes()
	if classes.is_empty():
		push_warning("creation_personnage: aucune classe chargée — vérifiez res://mvp/data/classes.json ou GameDataLoader.")
		return

	var keys := classes.keys()
	keys.sort()
	for key in keys:
		var entry := classes[key] as Dictionary
		var panel := PanelContainer.new()
		panel.name = "Card_%s" % str(key)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(name_lbl)

		var desc := Label.new()
		desc.text = str(entry.get("description", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# desc.add_theme_font_size_override("font_size", 11)
		v.add_child(desc)

		var btn := Button.new()
		btn.text = "Choisir"
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
	var scene: PackedScene = load("res://mvp/scenes/character_sheet.tscn") as PackedScene
	if scene == null:
		_error_label().text = "Impossible de charger la fiche JDR."
		push_warning("Impossible de charger la scène de fiche personnage")
		return
	var sheet: Node = scene.instantiate()
	if sheet == null:
		_error_label().text = "Impossible d'ouvrir la fiche JDR."
		return
	_embedded_sheet = sheet
	_sheet_host().add_child(sheet)
	if sheet.has_method("set_embedded_mode"):
		sheet.set_embedded_mode(true)
	if sheet.has_method("setup"):
		sheet.setup(_fiche_stats.duplicate(true), _fiche_points_restants, _classe_choisie)
	sheet.connect("saved", Callable(self, "_on_character_sheet_saved"))


func _on_character_sheet_saved(stats: Dictionary, points_remaining: int, char_class: String, feats: Array) -> void:
	# Appliquer les modifications depuis la fiche
	_fiche_stats = stats.duplicate(true)
	_fiche_points_restants = int(points_remaining)
	_fiche_feats = feats.duplicate(true)
	if char_class != "":
		# si l'utilisateur a sélectionné une classe (id ou nom), on essaie de la mapper
		_classe_choisie = char_class
		_class_label().text = "Classe choisie : %s" % char_class
	_mettre_a_jour_resume_build()


func _on_selection_build_change(_index: int) -> void:
	_sync_all_option_button_texts()
	_mettre_a_jour_resume_build()


func _mettre_a_jour_resume_build() -> void:
	if not _find_option("OptionGenre"):
		return
	var genre := _texte_option(_find_option("OptionGenre"))
	var apparence := _texte_option(_find_option("OptionApparence"))
	var pouvoir := _texte_option(_find_option("OptionPouvoir"))
	var archetype := _texte_option(_find_option("OptionArchetype"))
	var don := _texte_option(_find_option("OptionDon"))
	var competence := _texte_option(_find_option("OptionCompetence"))
	var equipement := _texte_option(_find_option("OptionEquipement"))

	_build_resume_label().text = (
		"Profil: %s | %s | Pouvoir: %s | Archétype: %s | Don: %s | Compétence: %s | Équipement: %s | Pacte: %s\n" %
		[genre, apparence, pouvoir, archetype, don, competence, equipement, MAGIE_PACTES]
	)
	_build_resume_label().text += (
		"Fiche JDR (pts restants: %d) — FOR %d MAG %d ESP %d ART %d DIP %d COM %d" % [
			_fiche_points_restants,
			int(_fiche_stats["force"]),
			int(_fiche_stats["magie"]),
			int(_fiche_stats["espionnage"]),
			int(_fiche_stats["artisanat"]),
			int(_fiche_stats["diplomatie"]),
			int(_fiche_stats["commandement"]),
		]
	)


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
	_valider_formulaire()


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


func _valider_formulaire() -> void:
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String  = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var ok: bool = nom_perso.length() >= 2 and nom_clan.length() >= 2 and _classe_choisie != ""
	$PanneauCentre/LigneBoutons/BtnCommencer.disabled = not ok
	var btn_bottom := get_node_or_null("ActionBar/ActionButtons/BtnCommencerBottom") as Button
	if btn_bottom:
		btn_bottom.disabled = not ok


# ── Actions ─────────────────────────────────────────────────────────

func _on_commencer() -> void:
	var nom_perso: String = ($PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage as LineEdit).text.strip_edges()
	var nom_clan: String  = ($PanneauCentre/LigneNoms/ColNomClan/NomClan as LineEdit).text.strip_edges()
	var erreur := _verifier_saisies(nom_perso, nom_clan)

	if erreur != "":
		_error_label().text = erreur
		return

	var classe_data := _get_class_data(_classe_choisie)
	var profil := _construire_profil_personnage()
	var stats_finales := (classe_data["stats_bonus"] as Dictionary).duplicate(true)
	for cle_stat in _fiche_stats.keys():
		stats_finales[cle_stat] = int(stats_finales.get(cle_stat, 0)) + _stat_modificateur(int(_fiche_stats[cle_stat]))
	var bonus_comp := _bonus_competence(str(profil.get("competence_id", "")))
	for cle in bonus_comp:
		stats_finales[cle] = int(stats_finales.get(cle, 0)) + int(bonus_comp[cle])
	var bonus_archetype := _bonus_archetype(str(profil.get("archetype_pathfinder", "")))
	for cle2 in bonus_archetype:
		stats_finales[cle2] = int(stats_finales.get(cle2, 0)) + int(bonus_archetype[cle2])

	profil["competences_depart"] = _competences_depart(classe_data, profil)

	var clan_mgr := _clan_manager()
	var game_mgr := _game_manager()
	if clan_mgr == null or game_mgr == null:
		_error_label().text = "Services du jeu introuvables (autoload)."
		push_error("Autoload manquant: ClanManager ou GameManager")
		return
	clan_mgr.nouvelle_partie(nom_perso, nom_clan, _classe_choisie, stats_finales, profil)
	game_mgr.go_to("clan_hub")


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
	_fiche_points_restants = POINTS_FICHE_BASE
	_fiche_stats = {
		"force": 8,
		"magie": 8,
		"espionnage": 8,
		"artisanat": 8,
		"diplomatie": 8,
		"commandement": 8,
	}

	match classe_id:
		"chevalier_sombre":
			_distribuer_points(["force", "commandement", "force", "diplomatie", "magie"], 12)
		"mage_du_pacte":
			_distribuer_points(["magie", "artisanat", "diplomatie", "magie", "commandement"], 12)
		"stratege_des_ombres":
			_distribuer_points(["espionnage", "diplomatie", "commandement", "artisanat", "espionnage"], 12)
		_:
			_distribuer_points(["force", "magie", "espionnage", "artisanat", "diplomatie", "commandement"], 10)


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
	var mods := {
		"force": _stat_modificateur(int(_fiche_stats["force"])),
		"magie": _stat_modificateur(int(_fiche_stats["magie"])),
		"espionnage": _stat_modificateur(int(_fiche_stats["espionnage"])),
		"artisanat": _stat_modificateur(int(_fiche_stats["artisanat"])),
		"diplomatie": _stat_modificateur(int(_fiche_stats["diplomatie"])),
		"commandement": _stat_modificateur(int(_fiche_stats["commandement"])),
	}

	var pv_base := 10
	if _classe_choisie == "chevalier_sombre":
		pv_base = 14
	elif _classe_choisie == "mage_du_pacte":
		pv_base = 8
	elif _classe_choisie == "stratege_des_ombres":
		pv_base = 10

	return {
		"classe": _classe_choisie,
		"niveau": 1,
		"points_a_distribuer_base": POINTS_FICHE_BASE,
		"points_restants": _fiche_points_restants,
		"stats_brutes": _fiche_stats.duplicate(true),
		"modificateurs": mods,
		"pv_max": pv_base + int(mods["commandement"]),
		"initiative": int(mods["espionnage"]),
		"defense": 10 + int(mods["espionnage"]),
		"jet_vigueur": int(mods["force"]),
		"jet_volonte": int(mods["magie"]),
		"jet_reflexes": int(mods["espionnage"]),
	}


func _get_class_data(classe_id: String) -> Dictionary:
	# Récupère la définition depuis GameDataLoader (single source of truth)
	var classes := GameDataLoader.get_classes()
	if classes.has(classe_id):
		var entry := classes[classe_id] as Dictionary
		var stats_bonus := {
			"force": 0, "magie": 0, "espionnage": 0,
			"artisanat": 0, "diplomatie": 0, "commandement": 0
		}
		return {
			"nom": str(entry.get("name", classe_id)),
			"stats_bonus": stats_bonus,
			"equipement": entry.get("starting_abilities", []),
			"competences": entry.get("starting_feats", []),
		}

	# fallback minimal
	return {
		"nom": classe_id,
		"stats_bonus": {
			"force": 0,
			"magie": 0,
			"espionnage": 0,
			"artisanat": 0,
			"diplomatie": 0,
			"commandement": 0,
		},
		"equipement": [],
		"competences": [],
	}


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


func _on_retour() -> void:
	var game_mgr := _game_manager()
	if game_mgr:
		game_mgr.go_to("main_menu")

