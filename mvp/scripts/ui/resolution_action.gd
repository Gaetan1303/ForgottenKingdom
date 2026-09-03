## scripts/ui/resolution_action.gd
## Scène de résolution d'action — dé lancé, résultat affiché, effets appliqués.
##
## Reçoit via init_data() :
##   { "action_id": String, "maison_id": int }
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const EventResultPresenter = preload("res://scripts/ui/event_result_presenter.gd")

signal result_confirmed

# ── Données de l'action en cours ─────────────────────────────────────
var _action_id:  String = ""
var _maison_id:  int    = -1
var _action_cfg: Dictionary = {}

# ── Résultats calculés ───────────────────────────────────────────────
var _score_joueur:   int    = 0
var _resistance:     int    = 0
var _resultat_id:    String = ""
var _effets:         Dictionary = {}

# ── Animation ────────────────────────────────────────────────────────
var _anim_step: int = 0
var _message_retour_extra: String = ""
var _anim_score_joueur: float = 0.0
var _anim_score_resistance: float = 0.0
var _already_confirmed: bool = false
var _effects_applied: bool = false

const CLAN_ICON_SIZE: Vector2 = Vector2(48, 48)
const DEBUG_CONTINUE_BTN: bool = false
const RES_ANIMATOR = preload("res://scripts/ui/resolution_animator.gd")
var _animator: Node = null

# ─────────────────────────────────────────────────────────────────────
#  INITIALISATION
# ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	FallenUI.apply(self, "clan")
	$PanneauCentre/ActionBarBottom/BtnContinuer.pressed.connect(_on_continuer)
	$PanneauCentre/ActionBarBottom/BtnContinuer.visible = true
	$PanneauCentre/ActionBarBottom/BtnContinuer.disabled = true
	$PanneauCentre/PanneauEffets.visible = false
	# Instantiate animator helper
	_animator = RES_ANIMATOR.new()
	add_child(_animator)
	var journal := _journal_node()
	if journal != null:
		journal.text = ""

func init_data(data: Dictionary) -> void:
	_already_confirmed = false
	_effects_applied = false
	_action_id = data.get("action_id", "") as String
	_maison_id = int(data.get("maison_id", -1))
	_action_cfg = GameDataLoader.get_action((_action_id) if not _action_id.is_empty() else "recuperer")

	if _action_cfg.is_empty():
		_afficher_erreur()
		return

	_mettre_a_jour_entete()
	_calculer_resolution()
	_demarrer_animation()

func _mettre_a_jour_entete() -> void:
	var nom_action := _action_cfg.get("nom", _action_id) as String
	$PanneauCentre/TitreAction.text = nom_action

	var maison := ClanManager.get_maison(_maison_id)

	# --- Portrait du héros (portrait réellement choisi, puis fallback de genre) ---
	var profil := ClanManager.profil_personnage as Dictionary
	var portrait_payload: Dictionary = profil.get("portrait", {}) as Dictionary
	var hero_texture: Texture2D = VisualAssetCatalog.texture_from_portrait_payload(portrait_payload)
	if hero_texture == null:
		var genre := str(profil.get("genre", "")).to_lower()
		if genre.is_empty():
			var appearance := str(profil.get("apparence", "")).to_lower()
			if appearance.contains("femme"):
				genre = "femme"
			elif appearance.contains("homme"):
				genre = "homme"
		var hero_img_path: String = VisualAssetCatalog.person_path("player_default")
		if genre == "femme":
			hero_img_path = VisualAssetCatalog.person_path("player_female")
		elif genre == "homme":
			hero_img_path = VisualAssetCatalog.person_path("player_male")
		hero_texture = ResourcePathResolver.load_texture(hero_img_path, "res://assets/images")
	var joueur_icon := $PanneauCentre/PanneauStats/ContenuStats/ColJoueur/IconeClanJoueur as TextureRect
	joueur_icon.texture = hero_texture
	VisualAssetCatalog.apply_fit(joueur_icon, "portrait")
	joueur_icon.custom_minimum_size = CLAN_ICON_SIZE

	# --- Image de la cible (dépend de l'action) ---
	var icone_cible_path = "res://assets/images/clan/nine_nobles.png"
	if _action_id in ["attaquer", "espionner"]:
		if maison.has("icone"):
			icone_cible_path = maison["icone"]
		elif maison.has("nom"):
			var maison_nom = maison["nom"].to_lower().replace(" ", "_")
			var tentative = "res://assets/images/clan/%s.png" % maison_nom
			if ResourceLoader.exists(tentative):
				icone_cible_path = tentative
	if not ResourceLoader.exists(icone_cible_path):
		icone_cible_path = "res://assets/images/clan/nine_nobles.png"
	var cible_icon = $PanneauCentre/PanneauStats/ContenuStats/ColResistance/IconeClanCible
	cible_icon.texture = load(icone_cible_path)
	cible_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cible_icon.custom_minimum_size = CLAN_ICON_SIZE

	# --- Sous-titre cible ---
	if maison.is_empty() or _maison_id < 0:
		$PanneauCentre/SousTitreAction.text = "Action générale"
	elif bool(maison.get("revelee", false)):
		$PanneauCentre/SousTitreAction.text = "Cible : %s" % maison.get("nom", "???")
	else:
		$PanneauCentre/SousTitreAction.text = "Cible : Famille Inconnue"

	_append_journal("Action: %s" % nom_action)
	_append_journal($PanneauCentre/SousTitreAction.text)

# ─────────────────────────────────────────────────────────────────────
#  CALCUL DE LA RÉSOLUTION
# ─────────────────────────────────────────────────────────────────────

func _calculer_resolution() -> void:
	var _sp: Variant = _action_cfg.get("stat_principale", "force")
	var stat_princ: String = _sp if _sp is String else "force"
	var _ss: Variant = _action_cfg.get("stat_secondaire", "")
	var stat_sec: String = _ss if _ss is String else ""
	_score_joueur  = ClanManager.calculer_score_action(stat_princ, stat_sec)

	# Bonus de classe
	var bonus_classe := GameDataLoader.get_bonus_classe(_action_id, ClanManager.classe)
	_score_joueur += bonus_classe
	_score_joueur += ClanManager.get_bonus_score_action(_action_id)

	# Résistance : basée sur la cible
	_resistance = _calculer_resistance()

	# Évaluation du résultat
	_resultat_id = GameDataLoader.evaluer_resultat(_action_id, _score_joueur, _resistance)
	_effets       = GameDataLoader.get_effets(_action_id, _resultat_id)
	_append_journal("Score calculé: %d | Résistance: %d" % [_score_joueur, _resistance])

	# Affichage des scores
	$PanneauCentre/PanneauStats/ContenuStats/ColJoueur/LblJoueurDetail.text = (
		"%s %s+ Dé (d20)" % [stat_princ.capitalize(), ("+ " + stat_sec.capitalize() + " ") if stat_sec != "" else ""]
	)
	$PanneauCentre/PanneauStats/ContenuStats/ColResistance/LblResDetail.text = _detail_resistance()

func _calculer_resistance() -> int:
	# Compute a deterministic base resistance depending on action and target
	var base: int = 10
	match _action_id:
		"attaquer":
			var maison := ClanManager.get_maison(_maison_id)
			if maison.is_empty():
				base = 15
			else:
				var bastions: Array = maison.get("bastions", [])
				if bastions.is_empty():
					base = 10
				else:
					base = 10
					for b in bastions:
						if not bool(b.get("conquis", false)):
							base = int(b.get("defense", 5)) * 2
							break
		"espionner":
			base = 10  # Résistance fixe aux renseignements
		"diplomatie":
			var maison := ClanManager.get_maison(_maison_id)
			if maison.is_empty():
				base = 12
			else:
				base = 12 + ClanManager.get_ressource("reputation", 0) / 5
		"recruter":
			base = 0
		"recruter_pnj":
			base = 0
		"fortifier":
			base = 0
		"recuperer":
			base = 0

	# Add a difficulty roll: 1d20 + difficulty modifier
	var roll := randi_range(1, 20) + _difficulty_modifier()
	_append_journal("Jet difficulté (1d20 + mod): %d (mod %d)" % [roll, _difficulty_modifier()])
	return base + int(roll)

func _detail_resistance() -> String:
	match _action_id:
		"attaquer":    return "Défense bastion × 2"
		"espionner":   return "Vigilance de la maison"
		"diplomatie": return "Seuil diplomatique (12)"
		"recruter_pnj": return "Rituel de pacte"
	return "Seuil de base"


func _difficulty_modifier() -> int:
	var diff := str(SaveSystem.get_value("settings/difficulty", "Normal"))
	match diff:
		"Facile": return -2
		"Normal": return 0
		"Difficile": return 2
	return 0

# ─────────────────────────────────────────────────────────────────────
#  ANIMATION DU RÉSULTAT
# ─────────────────────────────────────────────────────────────────────

func _demarrer_animation() -> void:
	_anim_step = 0
	_anim_score_joueur = 0.0
	_anim_score_resistance = 0.0
	$PanneauCentre/BarreAnimation.value = 0
	$PanneauCentre/LabelResultat.scale = Vector2.ONE
	$PanneauCentre/LabelResultat.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	$PanneauCentre/LabelResultat.text = "Résolution en cours..."
	$PanneauCentre/LabelDescription.text = ""
	_append_journal("Début de la résolution…")
	if _animator == null:
		_animator = RES_ANIMATOR.new()
		add_child(_animator)
	_animator.play_resolution(
		$PanneauCentre/BarreAnimation,
		$PanneauCentre/PanneauStats/ContenuStats/ColJoueur/LblJoueurScore,
		$PanneauCentre/PanneauStats/ContenuStats/ColResistance/LblResScore,
		_score_joueur,
		_resistance,
		Callable(self, "_afficher_resultat")
	)



func _afficher_resultat() -> void:
	$PanneauCentre/BarreAnimation.value = 100.0

	# Scores Finals
	$PanneauCentre/PanneauStats/ContenuStats/ColJoueur/LblJoueurScore.text    = str(_score_joueur)
	$PanneauCentre/PanneauStats/ContenuStats/ColResistance/LblResScore.text   = str(_resistance)

	# Texte du résultat
	var texte := GameDataLoader.get_texte_resultat(_action_id, _resultat_id)
	$PanneauCentre/LabelResultat.text = _titre_resultat()
	$PanneauCentre/LabelResultat.add_theme_color_override("font_color", _couleur_resultat())
	$PanneauCentre/LabelResultat.scale = Vector2.ONE
	$PanneauCentre/LabelDescription.text = texte
	_append_journal("Résultat: %s" % _titre_resultat())
	if not texte.is_empty():
		_append_journal(texte)

	# Play result animations
	if _animator == null:
		_animator = RES_ANIMATOR.new()
		add_child(_animator)
	_animator.play_result($PanneauCentre/LabelResultat, _couleur_resultat())
	_animator.pulse($PanneauCentre/LabelResultat, _couleur_resultat())
	if _action_id == "attaquer":
		_animator.shake($PanneauCentre)

	# Le presenter peut être rappelé (resize/test), mais les conséquences métier
	# ne doivent être appliquées qu'une seule fois.
	if not _effects_applied:
		_effects_applied = true
		_appliquer_effets_clan()

	# Affichage des effets (après application pour inclure les effets calculés dynamiquement)
	_afficher_effets()
	var effets_resume := _effets_vers_texte()
	for e in effets_resume:
		_append_journal(e)

	# Le bouton appartient au layout du panneau et reste toujours dans le viewport.
	var btn := $PanneauCentre/ActionBarBottom/BtnContinuer as Button
	btn.visible = true
	btn.disabled = false
	btn.custom_minimum_size = Vector2(180, 40)

func _titre_resultat() -> String:
	match _resultat_id:
		"victoire_eclatante": return "Victoire Éclatante !"
		"succes_critique":    return "Succès Critique !"
		"victoire":           return "Victoire !"
		"succes":             return "Succès"
		"echec_partiel":      return "Succès Partiel"
		"defaite_partielle":  return "Défaite Partielle"
		"echec_detecte":      return "Échec — Vous êtes Détecté !"
		"defaite_totale":     return "Défaite Totale"
		"echec":              return "Échec"
	return "Résultat inconnu"

func _icone_resultat() -> String:
	return ""

func _couleur_resultat() -> Color:
	match _resultat_id:
		"victoire_eclatante", "succes_critique": return Color(0.3, 1, 0.6, 1)
		"victoire", "succes":                    return Color(0.6, 1, 0.7, 1)
		"echec_partiel", "defaite_partielle":    return Color(1, 0.85, 0.3, 1)
		"echec", "echec_detecte":                return Color(1, 0.4, 0.4, 1)
		"defaite_totale":                        return Color(1, 0.1, 0.1, 1)
	return Color(0.8, 0.8, 0.8, 1)

func _afficher_effets() -> void:
	var liste := $PanneauCentre/PanneauEffets/ContenuEffets/EffetsScroll/ListeEffets
	for child in liste.get_children():
		child.queue_free()

	var effets_normalises := EventResultPresenter.normalize_effects(_effets)
	if effets_normalises.is_empty():
		$PanneauCentre/PanneauEffets.visible = false
		return

	$PanneauCentre/PanneauEffets.visible = true

	for effect_value in effets_normalises:
		var effect := effect_value as Dictionary
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon_path := str(effect.get("icon_path", ""))
		if not icon_path.is_empty():
			var tex := TextureRect.new()
			tex.texture = EventResultPresenter.resolve_illustration(icon_path)
			tex.custom_minimum_size = Vector2(18, 18)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if tex.texture != null:
				hbox.add_child(tex)
		var lbl := Label.new()
		lbl.text = str(effect.get("text", ""))
		lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85, 1))
		hbox.add_child(lbl)
		liste.add_child(hbox)

func _effets_vers_texte() -> Array:
	var lines: Array = []
	for effect_value in EventResultPresenter.normalize_effects(_effets):
		lines.append(str((effect_value as Dictionary).get("text", "")))
	return lines

func _append_journal(line: String) -> void:
	var journal := _journal_node()
	if journal == null:
		return
	if journal.text.is_empty():
		journal.text = line
	else:
		journal.text += "\n" + line

func _journal_node() -> RichTextLabel:
	var direct := get_node_or_null("PanneauCentre/JournalResolution") as RichTextLabel
	if direct != null:
		return direct
	return get_node_or_null("PanneauCentre/JournalResolutionScroll/JournalResolution") as RichTextLabel

func _appliquer_effets_clan() -> void:
	# Débiter le coût
	var cout_base := GameDataLoader.get_cout_action(_action_id)
	var cout := ClanManager.get_action_cout_modifie(_action_id, cout_base)
	ClanManager.payer(cout)

	# Les effets dynamiques doivent être calculés avant application globale.
	if _action_id == "recruter_pnj":
		_traiter_recrutement_pnj()

	# Appliquer les gains et pertes
	ClanManager._appliquer_effets(_effets)

	# Évaluer les formules de gain (ex : recrutement)
	if _effets.has("soldats_gain_formule"):
		var gain := _calculer_gain_recrutement(_effets)
		ClanManager.gagner({"soldats": gain})
		_effets["soldats_gain"] = gain  # pour affichage

	# Cas particuliers
	if _action_id == "attaquer" and _resultat_id in ["victoire_eclatante", "victoire", "succes_critique"]:
		_traiter_conquete_bastion()

	if _action_id == "espionner" and _resultat_id in ["victoire_eclatante", "succes_critique"]:
		ClanManager.espionner_maison(_maison_id, true)
	elif _action_id == "espionner" and _resultat_id in ["victoire", "succes", "echec_partiel"]:
		ClanManager.espionner_maison(_maison_id, false)

	if _action_id == "diplomatie" and _resultat_id in ["victoire_eclatante", "victoire", "succes_critique", "succes"]:
		var relation := str(_effets.get("relation", "alliee"))
		ClanManager.modifier_relation(_maison_id, relation)
	elif _action_id == "diplomatie" and _resultat_id in ["echec_detecte"]:
		ClanManager.modifier_relation(_maison_id, "hostile")

	# Recrutement PNJ déjà traité avant _appliquer_effets.

func _calculer_gain_recrutement(effets: Dictionary) -> int:
	var cmd := clampi(ClanManager.get_stat("commandement", 5), 1, 20)
	var base_gain := cmd + randi_range(1, 6) + 4

	var soldats_actuels := ClanManager.get_ressource("soldats", 0)
	var soft_cap := maxi(0, int(effets.get("soldats_soft_cap", 120)))
	var penalty_step := maxi(1, int(effets.get("soldats_soft_penalty_step", 40)))
	var penalty_per_step := maxi(0, int(effets.get("soldats_soft_penalty_per_step", 2)))

	var penalty := 0
	if soldats_actuels > soft_cap and penalty_per_step > 0:
		var over := soldats_actuels - soft_cap
		var steps := int(ceil(float(over) / float(penalty_step)))
		penalty = steps * penalty_per_step

	var gain := base_gain - penalty
	var gain_min := maxi(0, int(effets.get("soldats_gain_min", 3)))
	var gain_max := maxi(gain_min, int(effets.get("soldats_gain_max", 16)))
	return clampi(gain, gain_min, gain_max)

func _traiter_recrutement_pnj() -> void:
	if not ClanManager.magie_pactes_active():
		_message_retour_extra = "Rituel interrompu (Magie des Pactes inactive)."
		return

	var role := ClanManager.recruter_pnj_domaine()
	if role.is_empty():
		_message_retour_extra = "Tous les rôles de domaine sont déjà pourvus."
		return

	_effets["pnj_recrute"] = 1
	_effets["pnj_role"] = role
	_effets["affinite_pnj_gain"] = 12
	_message_retour_extra = "Nouveau PNJ recruté: %s" % role.capitalize()

func _traiter_conquete_bastion() -> void:
	var maison := ClanManager.get_maison(_maison_id)
	if maison.is_empty():
		return
	var bastions: Array = maison.get("bastions", [])
	for b in bastions:
		if not bool(b.get("conquis", false)):
			ClanManager.conquerir_bastion(_maison_id, b.get("id", "") as String)
			break

func _afficher_erreur() -> void:
	$PanneauCentre/TitreAction.text    = "Erreur"
	$PanneauCentre/LabelResultat.text  = "Action inconnue : %s" % _action_id
	$PanneauCentre/ActionBarBottom/BtnContinuer.visible = true
	$PanneauCentre/ActionBarBottom/BtnContinuer.disabled = false

# ─────────────────────────────────────────────────────────────────────
#  NAVIGATION
# ─────────────────────────────────────────────────────────────────────

func _on_continuer() -> void:
	if _already_confirmed or $PanneauCentre/ActionBarBottom/BtnContinuer.disabled:
		return
	_already_confirmed = true
	$PanneauCentre/ActionBarBottom/BtnContinuer.disabled = true
	result_confirmed.emit()
	# Cleanup overlay continue button if present
	var root = get_tree().root
	var overlay = root.get_node_or_null("ResolutionContinueLayer")
	if overlay:
		overlay.queue_free()

	var msg := "%s — %s" % [_action_cfg.get("nom", _action_id), _titre_resultat()]
	if not _message_retour_extra.is_empty():
		msg = "%s | %s" % [msg, _message_retour_extra]
	GameManager.go_to("clan_hub", {"message_retour": msg})
