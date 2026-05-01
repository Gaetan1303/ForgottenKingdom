## scripts/ui/clan_hub.gd
## Hub de gestion du clan — écran principal de la boucle de gameplay.
##
## Flux :
##  1. Affiche l'état du clan (ressources, tour, maisons nobles)
##  2. Le joueur choisit une action + une cible maison
##  3. Go to résolution_action → retour ici après
##  4. Fin de tour → produit ressources + événements → tour suivant
extends Control

## Données de cible mémorisées lors du retour depuis la résolution
var maison_cible_id: int   = -1
var action_en_cours: String = ""

## IDs de maisons connues/révélées pour l'affichage du dialogue
var _maisons_cache: Array = []

## Configuration des 6 slots d'action selon le moment de la journée
var _actions_jour := [
	{"id": "attaquer", "label": "Attaquer"},
	{"id": "espionner", "label": "Espionner"},
	{"id": "recruter", "label": "Recruter"},
	{"id": "diplomatie", "label": "Diplomatie"},
	{"id": "fortifier", "label": "Fortifier"},
	{"id": "recuperer", "label": "Récupérer"},
]

var _actions_nuit := [
	{"id": "espionner", "label": "Infiltration nocturne"},
	{"id": "diplomatie", "label": "Négocier dans l'ombre"},
	{"id": "recruter_pnj", "label": "Recruter un PNJ"},
	{"id": "fortifier", "label": "Renforcer les défenses"},
	{"id": "recuperer", "label": "Repos du clan"},
	{"id": "espionner", "label": "Observer les bastions"},
]

var _actions_actuelles: Array = []
var _vue_gauche: String = "maisons"

const PORTRAIT_HINTS := {
	"ingrid": "25_Ingrid",
	"marjaana": "marjaana",
	"mizuki": "mizuki",
	"cara": "cara",
	"ceres": "ceres",
}

const DISPLAY_LABELS := {
	"ritual_caster": "Magie des Pactes",
	"contract_summoner": "Invocation de Contrat",
	"shadow_operatives": "Opérations de l'Ombre",
}

var _fallback_house_portrait: Texture2D = null
var _icones_pretes: bool = false
var JsonPersistenceService = preload("res://scripts/services/json_persistence_service.gd")

# Icônes pixel art des ressources — header
const ICON_RES_HEADER := {
	"LabelOr":      "res://assets/icon/gold.png",
	"LabelSoldats": "res://assets/icon/soldat.png",
	"LabelMana":    "res://assets/icon/mana.png",
}

# Icônes pixel art des ressources avancées — panneau actions
const ICON_RES_AVANCEES := [
	{"key": "bois",        "icon": "res://assets/icon/wood.png",    "label": "Bois",        "color": Color(0.72, 0.55, 0.35, 1.0)},
	{"key": "fer",         "icon": "res://assets/icon/iron.png",    "label": "Fer",         "color": Color(0.75, 0.78, 0.82, 1.0)},
	{"key": "pierre",      "icon": "",                              "label": "Pierre",      "color": Color(0.65, 0.65, 0.65, 1.0)},
	{"key": "nourriture",  "icon": "res://assets/icon/food.png",    "label": "Nourriture", "color": Color(0.60, 0.88, 0.45, 1.0)},
	{"key": "essence",     "icon": "res://assets/icon/essence.png", "label": "Essence",    "color": Color(0.80, 0.40, 1.00, 1.0)},
]


# ─────────────────────────────────────────────────────────────────────
#  INITIALISATION
# ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	ClanManager.ressources_mises_a_jour.connect(_rafraichir_header)
	_connecter_boutons()
	_preparer_layout_actions()
	_rafraichir_tout()
	_init_resource_icons()

	# Debug helper: add a lightweight PNJ planning button to the actions area
	var action_container := $ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions
	if action_container != null and action_container.get_node_or_null("BtnPlanPNJ") == null:
		var btn := Button.new()
		btn.name = "BtnPlanPNJ"
		btn.text = "Plan PNJ"
		btn.toggle_mode = false
		btn.pressed.connect(_on_open_pnj_manager)
		action_container.add_child(btn)


func init_data(data: Dictionary) -> void:
	# Données reçues depuis la résolution d'action
	if data.has("message_retour"):
		_afficher_message(data["message_retour"] as String)


func _connecter_boutons() -> void:
	var cb0 := _on_action_slot_pressed.bind(0)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnAttaquer.pressed.connect(cb0)
	var cb1 := _on_action_slot_pressed.bind(1)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnEspionner.pressed.connect(cb1)
	var cb2 := _on_action_slot_pressed.bind(2)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnRecruter.pressed.connect(cb2)
	var cb3 := _on_action_slot_pressed.bind(3)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnDiplomatie.pressed.connect(cb3)
	var cb4 := _on_action_slot_pressed.bind(4)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnFortifier.pressed.connect(cb4)
	var cb5 := _on_action_slot_pressed.bind(5)
	$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnRecuperer.pressed.connect(cb5)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnFinTour.pressed.connect(_on_fin_tour)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnMenu.pressed.connect(_on_menu_principal)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnDonjon.pressed.connect(_on_donjon)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnProfil.pressed.connect(_on_profil)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnMaisons.pressed.connect(_on_vue_maisons)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnCoffre.pressed.connect(_on_coffre)
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnBibliotheque.pressed.connect(_on_bibliotheque)
	$DialogueCible.confirmed.connect(_on_cible_confirmee)


func _preparer_layout_actions() -> void:
	var conteneur := $ContenuPrincipal/PanneauActions/ContenuActions as VBoxContainer
	var sep_nav := conteneur.get_node_or_null("SepNavigation")
	if sep_nav == null:
		return

	var spacer := conteneur.get_node_or_null("SpacerActions") as Control
	if spacer == null:
		spacer = Control.new()
		spacer.name = "SpacerActions"
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		conteneur.add_child(spacer)

	# Keep navigation controls anchored at the bottom of the right panel.
	conteneur.move_child(spacer, sep_nav.get_index())


# ─────────────────────────────────────────────────────────────────────
#  AFFICHAGE
# ─────────────────────────────────────────────────────────────────────

func _rafraichir_tout() -> void:
	_configurer_actions_moment()
	_rafraichir_header()
	_rafraichir_colonne_gauche()


func _rafraichir_colonne_gauche() -> void:
	match _vue_gauche:
		"profil":
			_afficher_vue_profil()
		"coffre":
			_afficher_vue_coffre()
		"bibliotheque":
			_afficher_vue_bibliotheque()
		_:
			_rafraichir_liste_maisons()


func _vider_colonne_gauche() -> VBoxContainer:
	var liste := $ContenuPrincipal/PanneauMaisons/ListeMaisons as VBoxContainer
	for child in liste.get_children():
		child.queue_free()
	return liste


# ─────────────────────────────────────────────────────────────────────
#  ICÔNES RESSOURCES
# ─────────────────────────────────────────────────────────────────────

func _init_resource_icons() -> void:
	if _icones_pretes:
		return
	var header := $Header/BgHeader/InfoClan/RessourcesHeader as HBoxContainer
	if header == null:
		return
	for label_name in ICON_RES_HEADER:
		var lbl := header.get_node_or_null(label_name) as Label
		if lbl == null:
			continue
		var icon_path: String = ICON_RES_HEADER[label_name]
		if not ResourceLoader.exists(icon_path):
			continue
		var tex := load(icon_path) as Texture2D
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.name        = label_name + "Icon"
		tr.texture     = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(20, 20)
		header.add_child(tr)
		header.move_child(tr, lbl.get_index())
	_icones_pretes = true


func _rafraichir_header() -> void:
	var res := ClanManager.get_ressources()
	$Header/BgHeader/InfoClan/LabelNomClan.text = ClanManager.nom_clan
	var moment := "Jour" if ClanManager.moment_journee == "jour" else "Nuit"
	$Header/BgHeader/InfoClan/LabelTour.text    = "Tour %d — %s" % [ClanManager.tour_actuel, moment]
	$Header/BgHeader/InfoClan/RessourcesHeader/LabelOr.text       = "Or: %d" % int(res.get("or", 0))
	$Header/BgHeader/InfoClan/RessourcesHeader/LabelSoldats.text  = "Soldats: %d" % int(res.get("soldats", 0))
	$Header/BgHeader/InfoClan/RessourcesHeader/LabelMana.text     = "Mana: %d" % int(res.get("mana", 0))
	$Header/BgHeader/InfoClan/RessourcesHeader/LabelReputation.text = "Rep: %d" % int(res.get("reputation", 0))
	$Header/BgHeader/InfoClan/RessourcesHeader/LabelAme.text      = "Ame: %d%%" % ClanManager.barre_ame
	var phase_action := "Action utilisée" if ClanManager.action_deja_utilisee_pour_moment() else "Action disponible"
	$Header/BgHeader/InfoClan/LabelTour.text    = "Tour %d — %s (%s)" % [ClanManager.tour_actuel, moment, phase_action]
	$ContenuPrincipal/PanneauActions/ContenuActions/BtnFinTour.text = (
		"Passer à la Nuit" if ClanManager.moment_journee == "jour" else "Terminer le Tour"
	)
	_mettre_a_jour_infos_avancees(res)


func _mettre_a_jour_infos_avancees(res: Dictionary) -> void:
	var conteneur := $ContenuPrincipal/PanneauActions/ContenuActions

	# ── Ligne 1 : ressources avancées avec icônes ────────────────────
	var hbox_res := conteneur.get_node_or_null("HBoxRessourcesAvancees") as HBoxContainer
	if hbox_res == null:
		hbox_res = HBoxContainer.new()
		hbox_res.name = "HBoxRessourcesAvancees"
		hbox_res.add_theme_constant_override("separation", 8)
		conteneur.add_child(hbox_res)
		# Construire les paires icône + label UNE SEULE FOIS
		for entry in ICON_RES_AVANCEES:
			var col := HBoxContainer.new()
			col.name = "Col_" + str(entry["key"])
			col.add_theme_constant_override("separation", 3)
			hbox_res.add_child(col)
			# Icône si disponible
			var icon_path: String = entry["icon"]
			if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
				var tex := load(icon_path) as Texture2D
				if tex != null:
					var tr := TextureRect.new()
					tr.name        = "Icon"
					tr.texture     = tex
					tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
					tr.custom_minimum_size = Vector2(16, 16)
					col.add_child(tr)
			# Label valeur
			var lbl := Label.new()
			lbl.name = "Value"
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", entry["color"] as Color)
			col.add_child(lbl)
			# Séparateur sauf le dernier
			if entry != ICON_RES_AVANCEES.back():
				var sep_lbl := Label.new()
				sep_lbl.text = "│"
				sep_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.6))
				sep_lbl.add_theme_font_size_override("font_size", 11)
				hbox_res.add_child(sep_lbl)

	# Mettre à jour les valeurs
	for entry in ICON_RES_AVANCEES:
		var col := hbox_res.get_node_or_null("Col_" + str(entry["key"])) as HBoxContainer
		if col == null:
			continue
		var val_lbl := col.get_node_or_null("Value") as Label
		if val_lbl != null:
			val_lbl.text = str(int(res.get(entry["key"], 0)))

	# ── Ligne 2 : affinités PNJ (compact) ───────────────────────────
	var lbl_aff := conteneur.get_node_or_null("LabelAffinitesPNJ") as Label
	if lbl_aff == null:
		lbl_aff = Label.new()
		lbl_aff.name = "LabelAffinitesPNJ"
		lbl_aff.add_theme_font_size_override("font_size", 10)
		lbl_aff.add_theme_color_override("font_color", Color(0.70, 0.85, 0.70, 0.85))
		conteneur.add_child(lbl_aff)

	var aff := ClanManager.affinites_pnj
	var resume_traits := ClanManager.get_resume_traits_actifs().replace("Traits actifs: ", "")
	lbl_aff.text = "PNJ F:%d A:%d I:%d R:%d  |  %s" % [
		int(aff.get("forgeron", 0)),
		int(aff.get("alchimiste", 0)),
		int(aff.get("intendant", 0)),
		int(aff.get("arcaniste", 0)),
		resume_traits,
	]
	lbl_aff.visible = true

	# Positionnement avant SepActions
	var sep_actions := conteneur.get_node_or_null("SepActions")
	if sep_actions != null:
		var insert_index := sep_actions.get_index()
		conteneur.move_child(hbox_res, insert_index)
		conteneur.move_child(lbl_aff,  insert_index + 1)


func _configurer_actions_moment() -> void:
	_actions_actuelles = _actions_jour if ClanManager.moment_journee == "jour" else _actions_nuit
	var boutons := [
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnAttaquer,
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnEspionner,
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnRecruter,
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnDiplomatie,
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnFortifier,
		$ContenuPrincipal/PanneauActions/ContenuActions/BoutonActions/BtnRecuperer,
	]

	for i in range(boutons.size()):
		var action_data := _actions_actuelles[i] as Dictionary
		boutons[i].text = action_data.get("label", "Action") as String
		boutons[i].disabled = ClanManager.action_deja_utilisee_pour_moment()


func _rafraichir_liste_maisons() -> void:
	var liste := _vider_colonne_gauche()

	_maisons_cache = ClanManager.maisons_nobles

	for maison in _maisons_cache:
		var id      := int(maison.get("id", 0))
		var revelee := bool(maison.get("revelee", false))
		var statut  := maison.get("statut", "inconnue") as String

		var panneau := PanelContainer.new()
		panneau.clip_contents = true
		var vbox    := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		vbox.custom_minimum_size = Vector2(0, 240)

		var titre := Label.new()
		titre.add_theme_font_size_override("font_size", 14)

		if revelee:
			titre.text = "[%d] %s" % [id, maison.get("nom", "???")]
		else:
			titre.text = "[%d] Famille Inconnue" % id

		var puissance := int(maison.get("puissance", 0))
		if puissance <= 0:
			puissance = int((maison.get("bastions", []) as Array).size()) * 10
		var reputation := int(maison.get("reputation", 0))
		var chef := "???" if not revelee else str(maison.get("chef", "???"))
		var principal := "???" if not revelee else str(maison.get("personnage_principal", "Ingrid"))

		var lbl_identite := Label.new()
		lbl_identite.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_identite.text = "Chef/Cheffe: %s | Personnage principal: %s" % [chef, principal]

		var portrait := TextureRect.new()
		var portrait_frame := CenterContainer.new()
		portrait_frame.custom_minimum_size = Vector2(0, 124)
		portrait_frame.clip_contents = true
		portrait.custom_minimum_size = Vector2(208, 112)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var tex := _texture_for_character(principal)
		if tex == null:
			tex = _texture_for_character(chef)
		portrait.texture = tex
		portrait_frame.add_child(portrait)

		var lbl_stats := Label.new()
		lbl_stats.text = "Puissance: %d | Réputation: %d" % [puissance, reputation]
		lbl_stats.add_theme_color_override("font_color", Color(0.85, 0.82, 0.98, 0.95))

		var lbl_statut := Label.new()
		lbl_statut.text = _texte_statut(statut)
		lbl_statut.add_theme_color_override("font_color", _couleur_statut(statut))

		if revelee:
			var bastions: Array = maison.get("bastions", [])
			var conquis := 0
			for b in bastions:
				if b.get("conquis", false):
					conquis += 1
			var lbl_bastions := Label.new()
			# lbl_bastions.add_theme_font_size_override("font_size", 10)
			lbl_bastions.text = "Bastions conquis : %d / %d" % [conquis, bastions.size()]
			lbl_bastions.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 1))
			vbox.add_child(lbl_bastions)

		vbox.add_child(titre)
		if portrait.texture != null:
			vbox.add_child(portrait_frame)
		vbox.add_child(lbl_identite)
		vbox.add_child(lbl_stats)
		vbox.add_child(lbl_statut)
		panneau.add_child(vbox)
		liste.add_child(panneau)


func _afficher_vue_profil() -> void:
	var liste := _vider_colonne_gauche()
	liste.add_theme_constant_override("separation", 12)
	var profil := ClanManager.get_profil_personnage()
	var fiche := ClanManager.get_fiche_complete()

	# ── Header: nom, clan, niveau, bouton level-up ────────────────────
	var header := PanelContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	header.add_child(header_box)

	var name_lbl := Label.new()
	name_lbl.text = "%s — %s  |  Classe: %s  |  Niv. %d" % [
		str(ClanManager.nom_personnage),
		str(ClanManager.nom_clan),
		_to_display_name(ClanManager.classe),
		int(fiche.get("niveau", 1)),
	]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(name_lbl)

	# Le bouton de montée de niveau sera placé dans la colonne de droite (à côté de la fiche)
	var btn_lvlup := Button.new()
	btn_lvlup.name = "BtnLvlUp"
	btn_lvlup.text = "⬆ Monter de niveau"
	btn_lvlup.custom_minimum_size = Vector2(180, 0)

	liste.add_child(header)

	# ── Fiche personnage embarquée et colonne droite (portrait + actions) ─
	var sheet_scene: PackedScene = load("res://scenes/character_sheet.tscn") as PackedScene
	if sheet_scene == null:
		var fallback := Label.new()
		fallback.text = "[Erreur] Impossible de charger la scène character_sheet.tscn"
		liste.add_child(fallback)
		return

	var sheet := sheet_scene.instantiate() as Control
	print("clan_hub: instantiated character_sheet, sheet is", sheet, " children=", sheet.get_child_count())
	if sheet.has_method("set_embedded_mode"):
		sheet.set_embedded_mode(true)
	else:
		push_warning("clan_hub: instantiated sheet has no set_embedded_mode() method")
	if sheet.has_method("set_class_locked"):
		sheet.set_class_locked(true)
	else:
		push_warning("clan_hub: instantiated sheet has no set_class_locked() method")
	sheet.clip_contents = true
	sheet.custom_minimum_size = Vector2(0, 700)
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Créer un conteneur horizontal: fiche à gauche, colonne droite (bouton + portrait) à droite
	var content_h := HBoxContainer.new()
	content_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_h.custom_minimum_size = Vector2(0, 700)

	# Colonne droite
	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(260, 0)
	right_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_col.add_theme_constant_override("separation", 8)

	# Ajouter le bouton de montée de niveau en haut de la colonne droite
	right_col.add_child(btn_lvlup)

	# Barre XP (affiche progression vers le prochain niveau)
	var xp_bar := ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.min_value = 0
	xp_bar.custom_minimum_size = Vector2(220, 18)
	# set initial value and max using ClanManager
	xp_bar.max_value = ClanManager.get_personnage_xp_for_next_level()
	xp_bar.value = ClanManager.get_personnage_experience()
	# insert above the button
	right_col.add_child(xp_bar)
	right_col.move_child(xp_bar, 0)
	# Set button enabled state according to XP
	btn_lvlup.disabled = not ClanManager.is_personnage_xp_full()

	# Connect ClanManager signals to update XP bar and button when XP changes
	if ClanManager.has_signal("ressources_mises_a_jour"):
		if not ClanManager.ressources_mises_a_jour.is_connected(Callable(self, "_update_profile_xp_ui")):
			ClanManager.ressources_mises_a_jour.connect(Callable(self, "_update_profile_xp_ui"))
	if ClanManager.has_signal("niveau_montee"):
		if not ClanManager.niveau_montee.is_connected(Callable(self, "_update_profile_xp_ui")):
			ClanManager.niveau_montee.connect(Callable(self, "_update_profile_xp_ui"))
		if not ClanManager.niveau_montee.is_connected(Callable(self, "_on_niveau_montee")):
			ClanManager.niveau_montee.connect(Callable(self, "_on_niveau_montee"))


	# Portrait du personnage sous le bouton (utilise `profil` déjà déclaré)
	var portrait_payload := (profil.get("portrait", {}) as Dictionary)
	var portrait_tex := _texture_from_portrait_payload(portrait_payload)
	if portrait_tex == null:
		# fallback: try by name
		portrait_tex = _texture_for_character(str(ClanManager.nom_personnage))
	var portrait_rect := TextureRect.new()
	portrait_rect.texture = portrait_tex
	portrait_rect.name = "PortraitRect"
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.custom_minimum_size = Vector2(220, 220)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_col.add_child(portrait_rect)

	# Bouton pour changer le portrait
	var btn_change := Button.new()
	btn_change.text = "Changer"
	btn_change.custom_minimum_size = Vector2(220, 28)
	btn_change.name = "BtnChangePortrait"
	right_col.add_child(btn_change)

	# FileDialog pour sélectionner une image (attaché dynamiquement)
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = 0
	fd.add_filter("*.png ; PNG")
	fd.add_filter("*.jpg,*.jpeg ; JPEG")
	fd.add_filter("*.webp ; WEBP")
	add_child(fd)

	# Connect handlers
	btn_change.pressed.connect(Callable(fd, "popup_centered"))
	fd.file_selected.connect(Callable(self, "_on_clanhub_portrait_selected"))


	# Assembler contenu
	content_h.add_child(sheet)
	content_h.add_child(right_col)
	print("clan_hub: content_h children after add=", content_h.get_child_count())
	liste.add_child(content_h)
	print("clan_hub: liste children after add=", liste.get_child_count())

	var pts_restants := ClanManager.get_personnage_points_restants()
	print("clan_hub: calling sheet.setup (...) now")
	# Pass the raw character stats (stats_brutes) to the character sheet so
	# it doesn't sanitize clan-level final stats up to CHARACTER_MIN_STAT.
	var fiche_local := ClanManager.get_fiche_complete()
	print("clan_hub: fiche_local from ClanManager=", JSON.stringify(fiche_local))
	var raw_stats := (fiche_local.get("stats_brutes", {}) as Dictionary)
	print("clan_hub: raw_stats extracted=", JSON.stringify(raw_stats))
	if raw_stats.is_empty():
		print("clan_hub: raw_stats empty, reconstructing from final stats")
		# Fallback: reconstruct plausible raw scores from the clan-level final stats
		var final_stats := ClanManager.get_stats()
		raw_stats = {}
		for sk in StatDefs.STAT_KEYS:
			var mod := int(final_stats.get(sk, 0))
			var score := 10 + mod * 2
			raw_stats[sk] = clampi(score, StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT)
	sheet.setup(raw_stats, pts_restants, ClanManager.classe)
	print("clan_hub: after sheet.setup; sheet children=", sheet.get_child_count())
	sheet.connect("saved", Callable(self, "_on_profil_sheet_saved"))

	# Bouton montée de niveau : accorde 10 points supplémentaires et incrémente le niveau
	# ── Panneau Capacités, Magie & Talents ───────────────────────────
	var extras := _construire_panneau_capacites(profil)
	if extras != null:
		liste.add_child(extras)

	# Bouton montée de niveau
	var cb_lvlup := Callable(self, "_on_btn_lvlup_pressed").bind(btn_lvlup, sheet, name_lbl)
	btn_lvlup.pressed.connect(cb_lvlup)



func _on_profil_sheet_saved(stats: Dictionary, points_remaining: int, _char_class: String, feats: Array) -> void:
	# Persiste via API encapsulée du ClanManager
	ClanManager.apply_profile_sheet_update(stats, points_remaining, feats)
	# Persist the changes to disk so assigned points become the permanent
	# base for the character at level 1.
	ClanManager.sauvegarder()
	# Rafraîchit la vue pour refléter les nouvelles valeurs
	_afficher_vue_profil()


## Construit un panneau supplémentaire affichant capacités de départ, magie,
## archétype, talent, pouvoir et feats sélectionnés, à partir du profil du personnage
## et des données de classe chargées depuis classes.json / feats.json.
func _construire_panneau_capacites(profil: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.01, 0.12, 0.88)
	style.border_color = Color(0.55, 0.30, 0.80, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Titre
	var titre := Label.new()
	titre.text = "Capacités, Magie & Talents"
	titre.add_theme_font_size_override("font_size", 15)
	titre.add_theme_color_override("font_color", Color(0.80, 0.60, 1.0, 1.0))
	vbox.add_child(titre)

	# ── Profil magique / archétype ────────────────────────────────────
	var identity_grid := GridContainer.new()
	identity_grid.columns = 2
	identity_grid.add_theme_constant_override("h_separation", 12)
	identity_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(identity_grid)

	var id_fields := [
		["Pouvoir magique", str(profil.get("pouvoir_magique", "—"))],
		["Archétype",       str(profil.get("archetype_pathfinder", "—"))],
		["Don principal",   str(profil.get("don", "—"))],
		["Compétence",      str(profil.get("competence", "—"))],
	]
	for pair in id_fields:
		var key_lbl := Label.new()
		key_lbl.text = str(pair[0]) + ":"
		key_lbl.add_theme_color_override("font_color", Color(0.66, 0.54, 0.40, 1.0))
		key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		identity_grid.add_child(key_lbl)
		var val_lbl := Label.new()
		val_lbl.text = str(pair[1])
		val_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
		val_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity_grid.add_child(val_lbl)

	# ── Capacités de départ (competences_depart) ─────────────────────

	# Afficher les bonus calculés (PV/Mana) si présents
	var computed := profil.get("computed_effects", {}) as Dictionary
	if computed != null and (computed.get("pv_bonus", 0) != 0 or computed.get("mana_bonus", 0) != 0):
		var bonus_lbl := Label.new()
		bonus_lbl.text = "Bonus appliqués: PV %+d | Mana %+d" % [int(computed.get("pv_bonus", 0)), int(computed.get("mana_bonus", 0))]
		bonus_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
		vbox.add_child(bonus_lbl)

	var comp_list := profil.get("competences_depart", []) as Array
	if not comp_list.is_empty():
		var sep := HSeparator.new()
		vbox.add_child(sep)
		var comp_title := Label.new()
		comp_title.text = "Capacités de départ"
		comp_title.add_theme_color_override("font_color", Color(0.80, 0.60, 1.0, 1.0))
		vbox.add_child(comp_title)
		for c in comp_list:
			var lbl := Label.new()
			lbl.text = "• %s" % _to_display_name(str(c))
			lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
			vbox.add_child(lbl)

	# ── Classe : dons + capacités de départ depuis classes.json ──────
	var classe_id := ClanManager.classe.to_lower()
	var classes_data := _read_clan_json("res://data/classes.json")
	var class_entry := classes_data.get(classe_id, {}) as Dictionary
	if class_entry.is_empty():
		# Cherche par correspondance souple (nom)
		for ckey in classes_data.keys():
			var e: Dictionary = classes_data[ckey] as Dictionary
			if str(e.get("name", "")).to_lower() == classe_id:
				class_entry = e
				classe_id = str(ckey)
				break

	if not class_entry.is_empty():
		var sep2 := HSeparator.new()
		vbox.add_child(sep2)

		var class_section := Label.new()
		class_section.text = "Classe : %s" % str(class_entry.get("name", classe_id))
		class_section.add_theme_color_override("font_color", Color(0.80, 0.60, 1.0, 1.0))
		vbox.add_child(class_section)

		# Capacités (starting_abilities)
		var abilities := class_entry.get("starting_abilities", []) as Array
		if not abilities.is_empty():
			var ab_lbl := Label.new()
			ab_lbl.text = "Capacités : " + ", ".join(abilities)
			ab_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
			ab_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(ab_lbl)

		# Dons de départ (starting_feats) avec description
		var feats_data := _read_clan_json("res://data/feats.json")
		var starting_feats := class_entry.get("starting_feats", []) as Array
		if not starting_feats.is_empty():
			var ft_title := Label.new()
			ft_title.text = "Dons de départ :"
			ft_title.add_theme_color_override("font_color", Color(0.66, 0.54, 0.40, 1.0))
			vbox.add_child(ft_title)
			for fk in starting_feats:
				var fd: Dictionary = feats_data.get(str(fk), {}) as Dictionary
				var fname := str(fd.get("name", _to_display_name(str(fk))))
				var fdesc := str(fd.get("description", ""))
				var ft_lbl := Label.new()
				ft_lbl.text = "• %s%s" % [fname, " — " + fdesc if fdesc != "" else ""]
				ft_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
				ft_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(ft_lbl)

		# Stats primaires
		var primary := class_entry.get("primary", []) as Array
		if not primary.is_empty():
			var prim_lbl := Label.new()
			prim_lbl.text = "Stats primaires : " + ", ".join(primary).replace("_", " ").capitalize()
			prim_lbl.add_theme_color_override("font_color", Color(0.66, 0.54, 0.40, 1.0))
			vbox.add_child(prim_lbl)

	# ── Feats sélectionnés par le joueur ──────────────────────────────
	var player_feats := profil.get("feats", []) as Array
	if not player_feats.is_empty():
		var sep3 := HSeparator.new()
		vbox.add_child(sep3)
		var pf_title := Label.new()
		pf_title.text = "Dons choisis"
		pf_title.add_theme_color_override("font_color", Color(0.80, 0.60, 1.0, 1.0))
		vbox.add_child(pf_title)
		var feats_data2 := _read_clan_json("res://data/feats.json")
		for fk in player_feats:
			var fd: Dictionary = feats_data2.get(str(fk), {}) as Dictionary
			var fname := str(fd.get("name", _to_display_name(str(fk))))
			var fdesc := str(fd.get("description", ""))
			var ft_lbl := Label.new()
			ft_lbl.text = "• %s%s" % [fname, " — " + fdesc if fdesc != "" else ""]
			ft_lbl.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80, 1.0))
			ft_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(ft_lbl)

	return panel


## Charge un fichier JSON depuis un chemin res:// et retourne un Dictionary.
## Réutilise la même logique que dans CharacterSheet.
func _read_clan_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _afficher_vue_coffre() -> void:
	var liste := _vider_colonne_gauche()
	var r := ClanManager.get_ressources()

	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var titre := Label.new()
	titre.text = "Coffre du clan"
	titre.add_theme_font_size_override("font_size", 18)
	box.add_child(titre)

	for line in [
		"Or: %d" % int(r.get("or", 0)),
		"Mana: %d" % int(r.get("mana", 0)),
		"Soldats: %d" % int(r.get("soldats", 0)),
		"Bois: %d | Fer: %d | Pierre: %d" % [int(r.get("bois", 0)), int(r.get("fer", 0)), int(r.get("pierre", 0))],
		"Nourriture: %d | Essence: %d" % [int(r.get("nourriture", 0)), int(r.get("essence", 0))],
	]:
		var lbl := Label.new()
		lbl.text = line
		box.add_child(lbl)

	liste.add_child(panel)


func _afficher_vue_bibliotheque() -> void:
	var liste := _vider_colonne_gauche()
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var titre := Label.new()
	titre.text = "Bibliothèque"
	titre.add_theme_font_size_override("font_size", 18)
	box.add_child(titre)

	var data := GameDataLoader.get_library_entries()
	var sections := data.get("sections", []) as Array
	if sections.is_empty():
		var fallback := Label.new()
		fallback.text = "Aucune entrée disponible pour le moment."
		box.add_child(fallback)
	else:
		for section_v in sections:
			var section := section_v as Dictionary
			var st := Label.new()
			st.text = str(section.get("title", "Section"))
			st.add_theme_font_size_override("font_size", 15)
			st.add_theme_color_override("font_color", Color(0.83, 0.73, 0.98, 1))
			box.add_child(st)

			var entries := section.get("entries", []) as Array
			for entry_v in entries:
				var entry := entry_v as Dictionary
				var e_title := Label.new()
				e_title.text = "- %s" % str(entry.get("title", "Entrée"))
				e_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1))
				box.add_child(e_title)
				var e_text := Label.new()
				e_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				e_text.text = "  %s" % str(entry.get("text", ""))
				e_text.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 0.95))
				box.add_child(e_text)

	liste.add_child(panel)

func _on_btn_lvlup_pressed(btn: Button, sheet: Control, name_lbl: Label) -> void:
	# Simple throttle to avoid spam and ensure persistent updates.
	if btn == null or btn.disabled:
		return
	var result := ClanManager.level_up_personnage(10)
	var new_lvl := int(result.get("niveau", ClanManager.get_personnage_niveau()))
	var points := int(result.get("points_restants", ClanManager.get_personnage_points_restants()))

	# update label and embedded sheet
	name_lbl.text = "%s — %s  |  Classe: %s  |  Niv. %d" % [
		str(ClanManager.nom_personnage),
		str(ClanManager.nom_clan),
		_to_display_name(ClanManager.classe),
		new_lvl,
	]
	if sheet != null and sheet.has_method("setup"):
			var fiche2 := ClanManager.get_fiche_complete()
			var raw_stats2 := (fiche2.get("stats_brutes", {}) as Dictionary)
			if raw_stats2.is_empty():
				var SaveSys := get_node_or_null("/root/SaveSystem")
				if SaveSys != null:
					var save_path = SaveSys.get_clan_save_path()
					var persisted = JsonPersistenceService.read_json_with_backup(save_path)
					if not persisted.is_empty():
						var persisted_profil = (persisted.get("profil_personnage", {}) as Dictionary)
						var persisted_fiche = (persisted_profil.get("fiche_complete", {}) as Dictionary)
						var persisted_raw = (persisted_fiche.get("stats_brutes", {}) as Dictionary)
						if not persisted_raw.is_empty():
							raw_stats2 = persisted_raw.duplicate(true)
							print("clan_hub: recovered raw_stats from save file:", JSON.stringify(raw_stats2))
				if raw_stats2.is_empty():
					var final_stats := ClanManager.get_stats()
					raw_stats2 = {}
					for sk2 in StatDefs.STAT_KEYS:
						var mod2 := int(final_stats.get(sk2, 0))
						var score2 := 10 + mod2 * 2
						raw_stats2[sk2] = clampi(score2, StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT)
			sheet.setup(raw_stats2, points, ClanManager.classe)

	btn.disabled = true
	var t := get_tree().create_timer(0.6)
	var cb_re := Callable(self, "_reenable_button").bind(btn)
	t.timeout.connect(cb_re)


func _on_clanhub_portrait_selected(path: String) -> void:
	if path.strip_edges() == "":
		return
	# Load image and serialize as png_base64 payload
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("clan_hub: impossible de charger le portrait %s" % path)
		return
	var buf := img.save_png_to_buffer()
	if buf.is_empty():
		push_error("clan_hub: impossible d'encoder le portrait %s" % path)
		return
	var payload := {"file_name": path.get_file(), "encoding": "png_base64", "data": Marshalls.raw_to_base64(buf)}
	# Persist to in-memory profile but avoid forcing a disk save while the user
	# is editing the embedded character sheet (apply will save).
	ClanManager.set_personnage_portrait(payload, false)
	# Refresh view: simply re-open profile view to rebuild UI
	_afficher_vue_profil()


func _on_niveau_montee(nouveau_niveau: int) -> void:
	# Play a pulse animation on the portrait and XP bar when level increases
	var p := _find_node("PortraitRect") as TextureRect
	var xp_bar := _find_node("XPBar") as ProgressBar
	if p != null:
		var t = create_tween()
		# brighten then revert
		t.tween_property(p, "modulate", Color(1.6,1.6,1.6,1), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate", Color(1,1,1,1), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# small scale pulse if rect_scale exists
		if p.has_method("get_rect_scale") or p.has_method("set_rect_scale"):
			# try animating rect_scale safely
			var orig: Vector2 = p.rect_scale if p.has_property("rect_scale") else Vector2(1,1)
			t.tween_property(p, "rect_scale", orig * 1.08, 0.12)
			t.tween_property(p, "rect_scale", orig, 0.22)
	if xp_bar != null:
		# Quick XP fill pulse
		var t2 = _make_tween()
		t2.tween_property(xp_bar, "value", xp_bar.max_value, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t2.tween_property(xp_bar, "value", ClanManager.get_personnage_experience(), 0.4).set_delay(0.02)
		# Ensure a flame overlay exists and animate it
		var flame = xp_bar.get_node_or_null("XPFlame")
		if flame == null:
			flame = ColorRect.new()
			flame.name = "XPFlame"
			flame.anchor_left = 0.0
			flame.anchor_top = 0.0
			flame.anchor_right = 1.0
			flame.anchor_bottom = 1.0
			flame.margin_left = 0
			flame.margin_top = 0
			flame.margin_right = 0
			flame.margin_bottom = 0
			flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Shader for a simple flame effect using TIME and UV
			var sh := Shader.new()
			sh.code = """
shader_type canvas_item;
uniform float speed = 3.5;
void fragment(){
    vec2 uv = UV;
    float n = sin(uv.x * 40.0 + TIME * speed) * 0.5 + 0.5;
    float mask = pow(n, 1.2) * (1.0 - uv.y*1.25);
    vec3 col = mix(vec3(1.0,0.2,0.0), vec3(1.0,0.75,0.15), n);
    COLOR = vec4(col, clamp(mask, 0.0, 1.0));
}
"""
			var mat := ShaderMaterial.new()
			mat.shader = sh
			flame.material = mat
			xp_bar.add_child(flame)
			flame.z_index = xp_bar.z_index + 1
			flame.visible = false
		# animate flame: appear, pulse, vanish
		flame.visible = true
		flame.modulate = Color(1,1,1,0)
		var tf = _make_tween()
		tf.tween_property(flame, "modulate", Color(1,1,1,0.95), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tf.tween_property(flame, "modulate", Color(1,1,1,0.65), 0.18).set_delay(0.02)
		tf.tween_property(flame, "modulate", Color(1,1,1,0.0), 0.36).set_delay(0.02).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# hide at end
		tf.connect("finished", Callable(flame, "hide"))


func _update_profile_xp_ui(arg = null) -> void:
	# Find the XPBar and level-up button in the current profile view and refresh values
	var xp_bar := _find_node("XPBar") as ProgressBar
	var btn := _find_node("BtnLvlUp") as Button
	if xp_bar != null:
		var new_max := ClanManager.get_personnage_xp_for_next_level()
		var new_val := ClanManager.get_personnage_experience()
		xp_bar.max_value = new_max
		var old := float(xp_bar.value)
		if old != float(new_val):
			var tw = _make_tween()
			tw.tween_property(xp_bar, "value", float(new_val), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			xp_bar.value = new_val
	if btn != null:
		btn.disabled = not ClanManager.is_personnage_xp_full()
	# small visual update: if XP full, pulse the XPBar a bit
	if btn != null and not btn.disabled and xp_bar != null:
		var tw2 = _make_tween()
		tw2.tween_property(xp_bar, "modulate", Color(1.2,1.2,1.2,1), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw2.tween_property(xp_bar, "modulate", Color(1,1,1,1), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _reenable_button(btn: Button) -> void:
	if btn != null:
		btn.disabled = false


func _texture_from_portrait_payload(payload: Dictionary) -> Texture2D:
	if payload.is_empty():
		return null
	if str(payload.get("encoding", "")) != "png_base64":
		return null
	var encoded := str(payload.get("data", ""))
	if encoded.is_empty():
		return null
	var raw := Marshalls.base64_to_raw(encoded)
	if raw.is_empty():
		return null
	# Use a small cache key to avoid recreating textures repeatedly for the same payload
	var cache_key := String(encoded).sha256_text()
	if _portrait_texture_cache.has(cache_key):
		return _portrait_texture_cache[cache_key]
	var image := Image.new()
	if image.load_png_from_buffer(raw) != OK:
		return null
	var tex := ImageTexture.create_from_image(image)
	_portrait_texture_cache[cache_key] = tex
	return tex


func _exit_tree() -> void:
	# Clear cached textures to allow engine to free resources on shutdown
	if _portrait_texture_cache.size() > 0:
		print("clan_hub: clearing portrait texture cache (count=", _portrait_texture_cache.size(), ")")
		_portrait_texture_cache.clear()


func _texture_for_character(name: String) -> Texture2D:
	var norm := name.strip_edges().to_lower()
	if norm.is_empty() or norm == "???":
		return _default_house_portrait()

	var hint := str(PORTRAIT_HINTS.get(norm, norm.replace(" ", "_")))
	var candidates := [
		"res://assets/images/%s.png" % hint,
		"res://assets/images/%s.webp" % hint,
		"res://assets/images/%s.jpg" % hint,
	]

	for rpath in candidates:
		if not FileAccess.file_exists(rpath):
			continue
		var tex := ResourceLoader.load(rpath) as Texture2D
		if tex != null:
			return tex

	# Only load images from project assets. External lore images were removed.
	return _default_house_portrait()


func _default_house_portrait() -> Texture2D:
	if _fallback_house_portrait != null:
		return _fallback_house_portrait

	var res_path := "res://assets/images/defaut.png"
	if FileAccess.file_exists(res_path):
		var res_candidate := ResourceLoader.load(res_path) as Texture2D
		if res_candidate != null:
			_fallback_house_portrait = res_candidate
			return _fallback_house_portrait

	# Do not attempt to load external lore images (deleted). Use only res://assets/images/defaut.png if present.
	return _fallback_house_portrait


func _to_display_name(value: Variant) -> String:
	var raw := str(value).strip_edges()
	if raw.is_empty() or raw == "-":
		return "-"

	if DISPLAY_LABELS.has(raw):
		return str(DISPLAY_LABELS[raw])

	var cleaned := raw.replace("-", " ").replace("_", " ")
	var parts := cleaned.split(" ", false)
	for i in range(parts.size()):
		parts[i] = String(parts[i]).capitalize()
	return " ".join(parts)


func _make_tween():
	# Central helper to create a SceneTreeTween for this node. Kept as a small wrapper
	# so we can later centralize tween defaults (global speed/easing) here.
	return create_tween()


func _find_node(name: String, node: Node = null) -> Node:
	# Recursive search for a child node by name. Returns null if not found.
	if node == null:
		node = self
	if node.name == name:
		return node
	for c in node.get_children():
		if c is Node:
			var found := _find_node(name, c)
			if found != null:
				return found
	return null

# Simple runtime cache for dynamically created portrait textures (base64 payloads).
var _portrait_texture_cache: Dictionary = {}


func _texture_from_file_any(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var raw: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	if raw.is_empty():
		return null

	var img := Image.new()
	var ok := false
	if raw.size() >= 8 and raw[0] == 0x89 and raw[1] == 0x50 and raw[2] == 0x4E and raw[3] == 0x47:
		ok = img.load_png_from_buffer(raw) == OK
	elif raw.size() >= 3 and raw[0] == 0xFF and raw[1] == 0xD8 and raw[2] == 0xFF:
		ok = img.load_jpg_from_buffer(raw) == OK
	elif raw.size() >= 12 and raw[0] == 0x52 and raw[1] == 0x49 and raw[2] == 0x46 and raw[3] == 0x46 and raw[8] == 0x57 and raw[9] == 0x45 and raw[10] == 0x42 and raw[11] == 0x50:
		ok = img.load_webp_from_buffer(raw) == OK

	if not ok or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _texte_statut(statut: String) -> String:
	match statut:
		"inconnue":   return "Inconnue"
		"revelee":    return "Revelee"
		"hostile":    return "Hostile"
		"neutre":     return "Neutre"
		"alliee":     return "Alliee"
		"soumise":    return "Soumise"
	return "Statut inconnu"


func _couleur_statut(statut: String) -> Color:
	match statut:
		"inconnue":   return Color(0.5, 0.5, 0.5, 1)
		"revelee":    return Color(0.7, 0.7, 1, 1)
		"hostile":    return Color(1, 0.3, 0.3, 1)
		"neutre":     return Color(0.8, 0.8, 0.6, 1)
		"alliee":     return Color(0.4, 1, 0.6, 1)
		"soumise":    return Color(0.8, 0.4, 1, 1)
	return Color(0.7, 0.7, 0.7, 1)


func _afficher_message(msg: String) -> void:
	$Footer/BgFooter/MessageLog.text = msg


# ─────────────────────────────────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────────────────────────────────

func _lancer_action(action_id: String) -> void:
	if ClanManager.action_deja_utilisee_pour_moment():
		_afficher_message("Vous avez déjà effectué une action pour cette phase (%s)." % ClanManager.moment_journee)
		return

	if action_id == "recruter_pnj" and not ClanManager.magie_pactes_active():
		_afficher_message("Magie des Pactes inactive: impossible de recruter un PNJ.")
		return
	if action_id == "recruter_pnj" and not ClanManager.peut_recruter_pnj_domaine():
		_afficher_message("Tous les rôles de domaine sont déjà pourvus.")
		return

	var cout := GameDataLoader.get_cout_action(action_id)

	if not ClanManager.peut_payer(cout):
		_afficher_message("Ressources insuffisantes pour l'action '%s'." % action_id)
		return

	action_en_cours = action_id

	# Actions sans cible spécifique
	if action_id in ["recruter", "recruter_pnj", "recuperer", "fortifier"]:
		_aller_resolution(-1)
		return

	# Actions ciblant une maison — ouvre le dialogue de sélection
	_ouvrir_dialogue_cible(action_id)


func _on_action_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _actions_actuelles.size():
		return
	var action_data := _actions_actuelles[slot_index] as Dictionary
	_lancer_action(action_data.get("id", "") as String)


func _ouvrir_dialogue_cible(action_id: String) -> void:
	var liste_cibles := $DialogueCible/ListeCibles
	liste_cibles.clear()
	_maisons_cache = ClanManager.maisons_nobles

	var maisons_valides: Array = []
	for maison in _maisons_cache:
		var revelee := bool(maison.get("revelee", false))
		var statut  := maison.get("statut", "inconnue") as String

		match action_id:
			"attaquer":
				if revelee and statut in ["revelee", "hostile", "neutre"]:
					maisons_valides.append(maison)
			"espionner":
				# On peut espionner n'importe quelle maison non soumise
				if statut not in ["soumise", "alliee"]:
					maisons_valides.append(maison)
			"diplomatie":
				if revelee and statut in ["neutre", "hostile"]:
					maisons_valides.append(maison)
			_:
				if revelee:
					maisons_valides.append(maison)

	if maisons_valides.is_empty():
		_afficher_message("Aucune cible valide pour l'action '%s'." % action_id)
		return

	for m in maisons_valides:
		var nom: String = m.get("nom", "???") if bool(m.get("revelee", false)) else "Famille Inconnue"
		liste_cibles.add_item("%s (statut : %s)" % [nom, m.get("statut", "?")])
		liste_cibles.set_item_metadata(liste_cibles.item_count - 1, int(m.get("id", -1)))

	$DialogueCible.title = "Choisir la cible — %s" % action_en_cours.capitalize()
	$DialogueCible.popup_centered()


func _on_cible_confirmee() -> void:
	var liste := $DialogueCible/ListeCibles
	var items_selectionnes: PackedInt32Array = liste.get_selected_items()
	if items_selectionnes.is_empty():
		return
	maison_cible_id = int(liste.get_item_metadata(items_selectionnes[0]))
	_aller_resolution(maison_cible_id)


func _aller_resolution(cible_id: int) -> void:
	ClanManager.marquer_action_utilisee()
	var action_data := {
		"action_id":  action_en_cours,
		"maison_id":  cible_id,
	}
	GameManager.go_to("resolution_action", action_data)


# ─────────────────────────────────────────────────────────────────────
#  FIN DE TOUR
# ─────────────────────────────────────────────────────────────────────

func _on_fin_tour() -> void:
	if ClanManager.moment_journee == "jour":
		# Avant de passer à la nuit, résoudre les missions planifiées (après-midi)
		var report: Dictionary = ClanManager.resoudre_planning_pnj_journee()
		# Appliquer et sauvegarder est géré par ClanManager.resoudre_planning_pnj_journee
		var gains := report.get("resource_gains", {}) as Dictionary
		var report_msg := "Après-midi:"
		if not gains.is_empty():
			var parts := []
			for k in gains.keys():
				parts.append("%s %+d" % [str(k), int(gains.get(k, 0))])
			report_msg = "%s %s" % [report_msg, ", ".join(parts)]

		ClanManager.moment_journee = "nuit"
		ClanManager.reset_actions_pour_nuit()
		var msg_passifs := ClanManager.appliquer_passifs_nuit()
		ClanManager.sauvegarder()
		var msg_nuit := "La nuit tombe sur Yomihara. Les actions nocturnes sont disponibles."
		if not msg_passifs.is_empty():
			msg_nuit = "%s | %s" % [msg_nuit, msg_passifs]
		# Affiche d'abord le rapport d'après-midi puis le message de nuit
		_afficher_message("%s \n%s" % [report_msg, msg_nuit])
		_rafraichir_tout()
		return

	var production_base := GameDataLoader.get_production_par_tour()
	var production := ClanManager.get_production_totale(production_base)
	ClanManager.gagner(production)
	var msg_event := ClanManager.tirer_et_appliquer_evenement(GameDataLoader.get_evenements_aleatoires())

	var msg_tour := _construire_resume_tour(production)
	if not msg_event.is_empty():
		msg_tour = "%s | %s" % [msg_tour, msg_event]
	_afficher_message(msg_tour)

	ClanManager.tour_actuel += 1
	ClanManager.moment_journee = "jour"
	ClanManager.reset_actions_nouveau_tour()
	ClanManager.sauvegarder()
	_rafraichir_tout()

	# Vérification des conditions de victoire / défaite
	_verifier_fin_de_partie()


func _construire_resume_tour(production: Dictionary) -> String:
	var lignes := ["Tour %d terminé." % ClanManager.tour_actuel]
	lignes.append("Production : +%d or, +%d mana" % [int(production.get("or", 0)), int(production.get("mana", 0))])
	return " | ".join(lignes)


func _verifier_fin_de_partie() -> void:
	var etat := ClanManager.evaluer_etat_partie()
	if not bool(etat.get("terminee", false)):
		return

	var message := str(etat.get("message", "Fin de partie."))
	_afficher_message(message)


# ─────────────────────────────────────────────────────────────────────
#  NAVIGATION
# ─────────────────────────────────────────────────────────────────────

func _on_menu_principal() -> void:
	ClanManager.sauvegarder()
	GameManager.go_to("main_menu")


func _on_donjon() -> void:
	GameManager.open_dungeon()



func _on_open_pnj_manager() -> void:
	GameManager.go_to("pnj_manager")


func _on_profil() -> void:
	_vue_gauche = "profil"
	_rafraichir_colonne_gauche()


func _on_vue_maisons() -> void:
	_vue_gauche = "maisons"
	_rafraichir_colonne_gauche()


func _on_coffre() -> void:
	_vue_gauche = "coffre"
	_rafraichir_colonne_gauche()


func _on_bibliotheque() -> void:
	_vue_gauche = "bibliotheque"
	_rafraichir_colonne_gauche()
