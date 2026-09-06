## autoload/clan_manager.gd
## Singleton de gestion du clan — état complet de la partie en cours.
## Chargé depuis game/clan/etat_clan_defaut.json + sauvegarde utilisateur.
extends Node

## rely on the script's class_name (StatDefs) instead of preloading it here
## Use the service classes registered by class_name (PnjDailyPlannerService, PnjGenerator, JsonPersistenceService)
const FKHelpers = preload("res://scripts/utils/fk_helpers.gd")
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")

# ── Chemins ────────────────────────────────────────────────────────────
const DEFAULT_STATE_PATH := "res://data/clan/etat_clan_defaut.json"
const STAT_KEYS := StatDefs.STAT_KEYS
const RESSOURCE_KEYS := [
	"or", "soldats", "mana", "reputation", "renseignements",
	"bois", "fer", "pierre", "nourriture", "essence"
]
const ROLE_DOMAINES := ["forgeron", "alchimiste", "intendant", "arcaniste"]

# ── État du clan ────────────────────────────────────────────────────────
var nom_clan:       String     = ""
var clan_id:        String     = ""
var nom_personnage: String     = ""
var classe:         String     = ""
var profil_personnage: Dictionary = {
	"genre": "Homme",
	"apparence": "Vétéran balafré",
	"portrait": {},
	"pouvoir_magique": "Pyromancie",
	"archetype_pathfinder": "Lame jurée (inspiration Guerrier)",
	"don": "Volonté de fer",
	"competence": "Maîtrise martiale",
	"equipement_depart": "Arme lourde + bouclier",
	"magie_pactes": true,
	"competences_depart": ["Magie des Pactes"],
}

var stats: Dictionary = {
	"force": 5,
	"magie": 5,
	"espionnage": 5,
	"artisanat": 5,
	"diplomatie": 5,
	"commandement": 5,
}

var caracteristiques_hero: Dictionary = {
	"vigueur": 10,
	"esprit": 10,
	"presence": 10,
	"discipline": 10,
}

var stats_clan: Dictionary = {
	"stabilite": 5,
	"influence": 5,
	"logistique": 5,
	"autorite": 5,
}

var ressources: Dictionary = {
	"or": 500,
	"soldats": 50,
	"mana": 100,
	"reputation": 10,
	"renseignements": 0,
	"bois": 60,
	"fer": 40,
	"pierre": 30,
	"nourriture": 120,
	"essence": 10,
}

var ressources_par_tour: Dictionary = {
	"or": 120,
	"soldats": 0,
	"mana": 20,
	"reputation": 0,
	"renseignements": 0,
	"bois": 10,
	"fer": 6,
	"pierre": 5,
	"nourriture": 12,
	"essence": 2,
}

var affinites_pnj: Dictionary = {
	"forgeron": 0,
	"alchimiste": 0,
	"intendant": 0,
	"arcaniste": 0,
}

var fiche_hero: Dictionary = {}
var fiches_domaine: Dictionary = {}
# Pool de soldats (micro-gestion): liste d'IDs disponibles et compteur
var _soldat_next_id: int = 1
var _soldats_disponibles: Array = []

var barre_ame: int          = 100
var forme_dragon_utilisee:  int = 0
var tour_actuel: int        = 1
var moment_journee: String  = "jour"
var action_jour_effectuee: bool = false
var action_nuit_effectuee: bool = false
var maisons_nobles: Array   = []
var evenements_declenches: Array = []
var historique_tours: Array = []
var pnj_gestion: Dictionary = {}
## Progression du refuge et expédition : même transaction que ressources et habitants.
var campaign: Dictionary = {}
var _corruption_service: CorruptionService = CorruptionService.new()
var daily_phase := "matin"
var day_report := ""
var _day_transition_pending := false

# ── Services (instanciation unique — DRY / SRP) ────────────────────────
var _planner: PnjDailyPlannerService = null

# Bonus de classe chargés depuis les données
var _bonus_par_action: Dictionary = {}

# Signal émis quand le tour avance
signal tour_suivant(numero_tour: int)
signal ressources_mises_a_jour

const MIN_STAT := StatDefs.CLAN_MIN_STAT
const MAX_STAT := StatDefs.CLAN_MAX_STAT
const SOLDATS_MAX := 600


func _ready() -> void:
	_planner = PnjDailyPlannerService.new()
	_charger_etat_defaut()


# ─────────────────────────────────────────────────────────────────────
#  INITIALISATION D'UNE NOUVELLE PARTIE
# ─────────────────────────────────────────────────────────────────────

## Initialise un nouveau jeu avec les données de création de personnage.
func nouvelle_partie(
	p_nom_personnage: String,
	p_nom_clan: String,
	p_classe: String,
	stats_bonus: Dictionary,
	p_profil_personnage: Dictionary = {}
) -> void:
	_charger_etat_defaut()
	campaign = {}
	_corruption_service = CorruptionService.new()
	daily_phase = "matin"
	day_report = ""
	nom_personnage = p_nom_personnage
	nom_clan       = p_nom_clan
	clan_id        = str(p_profil_personnage.get("clan_id", "")).strip_edges()
	if clan_id.is_empty():
		clan_id = ClanIdentityType.id_from_name(nom_clan)
	classe         = p_classe
	if not p_profil_personnage.is_empty():
		profil_personnage = p_profil_personnage.duplicate(true)
	profil_personnage["clan_id"] = clan_id
	profil_personnage["clan_name"] = nom_clan
	_forcer_magie_pactes()

	# If the creation profile already contains raw character scores (stats_brutes),
	# apply and persist them now so the character is saved at game start.
	var fiche_in_profile := (profil_personnage.get("fiche_complete", {}) as Dictionary)
	if fiche_in_profile.has("stats_brutes"):
		var raw := (fiche_in_profile.get("stats_brutes", {}) as Dictionary)
		var pts := int(fiche_in_profile.get("points_restants", 0))
		var feats := (profil_personnage.get("feats", []) as Array)
		# apply_profile_sheet_update will compute final stats and call sauvegarder()
		apply_profile_sheet_update(raw, pts, feats)
		# Ensure fiche_hero and related structures reflect the new stats
		_initialiser_fiches_personnage_et_domaine()
	else:
		# No raw stats provided: fall back to previous flow (apply stats_bonus)
		_initialiser_fiches_personnage_et_domaine()
		# Applique les bonus de classe aux stats de base
		for stat in stats_bonus:
			if stats.has(stat):
				stats[stat] = maxi(1, stats[stat] + int(stats_bonus[stat]))

		_sanitizer_stats()

		# Appliquer les effets non-stat provenant des dons/feats (pv_bonus, mana_bonus, etc.)
		_compute_and_apply_profil_effects(profil_personnage, false)

	tour_actuel = 1
	moment_journee = "jour"
	action_jour_effectuee = false
	action_nuit_effectuee = false
	barre_ame   = 100
	forme_dragon_utilisee = 0
	evenements_declenches = []
	historique_tours = []
	pnj_gestion = _make_default_pnj_gestion_state()

	# Initialiser la pool de soldats (IDs) à partir de la ressource initiale
	_soldat_next_id = 1
	_soldats_disponibles.clear()
	var initial_soldats := int(ressources.get("soldats", 0))
	for i in range(initial_soldats):
		_soldats_disponibles.append("S%d" % _soldat_next_id)
		_soldat_next_id += 1
	# conserver ressources comme le nombre de soldats disponibles
	ressources["soldats"] = _soldats_disponibles.size()

	sauvegarder()
	emit_signal("ressources_mises_a_jour")


## Charge l'état par défaut depuis le JSON de référence.
func _charger_etat_defaut() -> void:
	var data := _lire_json(DEFAULT_STATE_PATH)
	if data.is_empty():
		push_warning("ClanManager: impossible de charger l'état par défaut.")
		return

	var clan := data.get("clan", {}) as Dictionary
	var perso := clan.get("personnage", {}) as Dictionary

	stats              = StatDefs.sanitize_stats(
		(perso.get("stats", stats) as Dictionary),
		MIN_STAT,
		MAX_STAT,
		5
	)
	caracteristiques_hero = (perso.get("caracteristiques", caracteristiques_hero) as Dictionary).duplicate(true)
	stats_clan         = (clan.get("stats_clan", stats_clan) as Dictionary).duplicate(true)
	profil_personnage  = {
		"genre": str(perso.get("genre", profil_personnage.get("genre", "Homme"))),
		"apparence": str(perso.get("apparence", profil_personnage.get("apparence", "Vétéran balafré"))),
		"portrait": (perso.get("portrait", profil_personnage.get("portrait", {})) as Dictionary).duplicate(true),
		"pouvoir_magique": str(perso.get("pouvoir_magique", profil_personnage.get("pouvoir_magique", "Pyromancie"))),
		"archetype_pathfinder": str(perso.get("archetype_pathfinder", profil_personnage.get("archetype_pathfinder", "Lame jurée (inspiration Guerrier)"))),
		"don": str(perso.get("don", profil_personnage.get("don", "Volonté de fer"))),
		"competence": str(perso.get("competence", profil_personnage.get("competence", "Maîtrise martiale"))),
		"equipement_depart": str(perso.get("equipement_depart", profil_personnage.get("equipement_depart", "Arme lourde + bouclier"))),
		"magie_pactes": true,
		"competences_depart": (perso.get("competences_depart", ["Magie des Pactes"]) as Array).duplicate(true),
	}
	_forcer_magie_pactes()
	ressources         = clan.get("ressources", ressources).duplicate()
	ressources_par_tour = clan.get("ressources_par_tour", ressources_par_tour).duplicate()
	affinites_pnj      = (clan.get("affinites_pnj", affinites_pnj) as Dictionary).duplicate(true)
	fiche_hero         = (clan.get("fiche_hero", {}) as Dictionary).duplicate(true)
	fiches_domaine     = (clan.get("fiches_domaine", {}) as Dictionary).duplicate(true)
	pnj_gestion        = (clan.get("pnj_gestion", _make_default_pnj_gestion_state()) as Dictionary).duplicate(true)
	barre_ame          = int(perso.get("barre_ame", 100))
	forme_dragon_utilisee = int(perso.get("forme_dragon_utilisations", 0))
	tour_actuel        = int(clan.get("tour_actuel", 1))
	moment_journee     = str(clan.get("moment_journee", "jour"))
	action_jour_effectuee = false
	action_nuit_effectuee = false
	maisons_nobles     = (data.get("maisons_nobles", []) as Array).duplicate(true)
	evenements_declenches = []
	historique_tours   = []
	_sanitizer_stats()
	_sanitizer_ressources()
	# Après avoir chargé et sanitizé l'état par défaut, appliquer les effets de feats
	# si nécessaire (compatibilité avec anciennes sauvegardes)
	_compute_and_apply_profil_effects(profil_personnage, true)
	_sanitizer_pnj_et_domaines()
	_sanitizer_pnj_gestion()

	# Restore soldats pool if present in saved data, otherwise build from ressources
	if _soldats_disponibles == null or _soldats_disponibles.is_empty():
		_soldats_disponibles = []
		var count: int = int(ressources.get("soldats", 0))
		for i in range(count):
			_soldats_disponibles.append("S%d" % _soldat_next_id)
			_soldat_next_id += 1
	# Ensure ressources matches available count
	ressources["soldats"] = _soldats_disponibles.size()
	if moment_journee not in ["jour", "nuit"]:
		moment_journee = "jour"


# ─────────────────────────────────────────────────────────────────────
#  GESTION DES RESSOURCES
# ─────────────────────────────────────────────────────────────────────

## Vérifie si le clan peut payer un coût donné.
func peut_payer(cout: Dictionary) -> bool:
	for res in cout:
		if ressources.get(res, 0) < int(cout[res]):
			return false
	return true


## Débite les ressources (sans vérification — utiliser peut_payer avant).
func payer(cout: Dictionary) -> void:
	for res in cout:
		if str(res) == "soldats":
			# remove soldier IDs from pool when paying soldiers
			var to_remove := maxi(0, int(cout[res]))
			_remove_soldiers(to_remove)
		else:
			ressources[res] = maxi(0, int(ressources.get(res, 0)) - int(cout[res]))
	emit_signal("ressources_mises_a_jour")


## Ajoute des ressources.
func gagner(gains: Dictionary) -> void:
	for res in gains:
		if ressources.has(res):
			var inc := int(gains[res])
			if str(res) == "soldats":
				# add soldier IDs to pool when gaining soldiers
				_add_soldiers(inc)
			else:
				var nv := int(ressources[res]) + inc
				ressources[res] = nv
	emit_signal("ressources_mises_a_jour")


func get_ressources() -> Dictionary:
	return ressources.duplicate(true)


func get_ressource(key: String, default_value: int = 0) -> int:
	return int(ressources.get(key, default_value))


func get_stats() -> Dictionary:
	return stats.duplicate(true)


func get_stat(key: String, default_value: int = 5) -> int:
	return int(stats.get(key, default_value))


## Pool helpers: ensure pool and ressources stay in sync when soldiers are added/removed.
func _remove_soldiers(count: int) -> int:
	var removed := 0
	for i in range(maxi(0, count)):
		if _soldats_disponibles.size() > 0:
			_soldats_disponibles.pop_back()
			removed += 1
		else:
			break
	ressources["soldats"] = _soldats_disponibles.size()
	emit_signal("ressources_mises_a_jour")
	return removed


func _add_soldiers(count: int) -> int:
	var added := 0
	for i in range(maxi(0, count)):
		if _soldats_disponibles.size() >= SOLDATS_MAX:
			break
		_soldats_disponibles.append("S%d" % _soldat_next_id)
		_soldat_next_id += 1
		added += 1
	ressources["soldats"] = _soldats_disponibles.size()
	emit_signal("ressources_mises_a_jour")
	return added


func action_deja_utilisee_pour_moment() -> bool:
	if daily_phase == "apres_midi": return true
	return action_jour_effectuee if moment_journee == "jour" else action_nuit_effectuee


func marquer_action_utilisee() -> void:
	if moment_journee == "jour":
		action_jour_effectuee = true
	else:
		action_nuit_effectuee = true


func reset_actions_pour_nuit() -> void:
	action_nuit_effectuee = false


func reset_actions_nouveau_tour() -> void:
	action_jour_effectuee = false
	action_nuit_effectuee = false


func magie_pactes_active() -> bool:
	return bool(profil_personnage.get("magie_pactes", false))


func modifier_affinite_pnj(role: String, delta: int) -> void:
	if role.is_empty():
		return
	var valeur := clampi(int(affinites_pnj.get(role, 0)) + delta, -100, 100)
	affinites_pnj[role] = valeur
	if fiches_domaine.has(role):
		var fiche := (fiches_domaine[role] as Dictionary).duplicate(true)
		fiche["affinite"] = valeur
		fiches_domaine[role] = fiche


func recruter_pnj_domaine() -> String:
	if not magie_pactes_active():
		return ""

	for role in ROLE_DOMAINES:
		var fiche := (fiches_domaine.get(role, {}) as Dictionary).duplicate(true)
		if fiche.is_empty():
			fiche = {
				"nom": role.capitalize(),
				"niveau": 1,
				"specialite": role,
				"actif": false,
				"affinite": int(affinites_pnj.get(role, 0)),
			}

		if not bool(fiche.get("actif", false)):
			fiche["actif"] = true
			fiche["niveau"] = maxi(1, int(fiche.get("niveau", 1)))
			fiches_domaine[role] = fiche
			modifier_affinite_pnj(role, 12)
			return role

	return ""


func peut_recruter_pnj_domaine() -> bool:
	for role in ROLE_DOMAINES:
		var fiche := fiches_domaine.get(role, {}) as Dictionary
		if fiche.is_empty() or not bool(fiche.get("actif", false)):
			return true
	return false


func get_production_totale(base_production: Dictionary) -> Dictionary:
	var total := ressources_par_tour.duplicate(true) if not campaign.is_empty() else base_production.duplicate(true)
	for cle in RESSOURCE_KEYS:
		if not total.has(cle):
			total[cle] = 0

	var bonus := _calculer_bonus_production_domaines()
	for cle_bonus in bonus:
		total[cle_bonus] = int(total.get(cle_bonus, 0)) + int(bonus[cle_bonus])

	return total


func get_traits_gameplay() -> Dictionary:
	return (profil_personnage.get("traits_gameplay", {}) as Dictionary).duplicate(true)


func get_action_cout_modifie(action_id: String, cout_base: Dictionary) -> Dictionary:
	var cout := cout_base.duplicate(true)
	var traits := get_traits_gameplay()
	var caps := _get_traits_caps()

	var mana_reduc_pct := clampi(int(traits.get("mana_cost_reduction_pct", 0)), 0, int(caps.get("mana_cost_reduction_pct", 35)))
	if mana_reduc_pct > 0 and cout.has("mana"):
		if action_id in ["recruter", "recruter_pnj", "recuperer"]:
			cout["mana"] = maxi(0, int(round(int(cout["mana"]) * (100 - mana_reduc_pct) / 100.0)))

	var soldats_reduc_atk := clampi(int(traits.get("soldats_cost_reduction_attaquer_pct", 0)), 0, int(caps.get("soldats_cost_reduction_attaquer_pct", 20)))
	if soldats_reduc_atk > 0 and action_id == "attaquer" and cout.has("soldats"):
		cout["soldats"] = maxi(0, int(round(int(cout["soldats"]) * (100 - soldats_reduc_atk) / 100.0)))

	return cout


func get_bonus_score_action(action_id: String) -> int:
	var traits := get_traits_gameplay()
	var caps := _get_traits_caps()
	var map_bonus := traits.get("bonus_score_actions", {}) as Dictionary
	var cap := int(caps.get("bonus_per_action_max", 3))
	return clampi(int(map_bonus.get(action_id, 0)), -cap, cap)


func appliquer_passifs_nuit() -> String:
	var traits := get_traits_gameplay()
	var caps := _get_traits_caps()
	var details: Array[String] = []

	var regen_ame := clampi(int(traits.get("night_soul_regen", 0)), 0, int(caps.get("night_soul_regen", 4)))
	if regen_ame > 0:
		barre_ame = clampi(barre_ame + regen_ame, 0, 100)
		details.append("Ame +%d" % regen_ame)

	var rep_gain := clampi(int(traits.get("night_reputation_gain", 0)), 0, int(caps.get("night_reputation_gain", 2)))
	if rep_gain > 0:
		gagner({"reputation": rep_gain})
		details.append("Reputation +%d" % rep_gain)

	if details.is_empty():
		return ""
	return "Passifs de nuit: %s" % FKHelpers.join_array(details, ", ")


func get_resume_traits_actifs() -> String:
	var traits := get_traits_gameplay()
	if traits.is_empty():
		return "Traits actifs: aucun"

	var parts: Array[String] = []
	var mana_reduc := int(traits.get("mana_cost_reduction_pct", 0))
	if mana_reduc > 0:
		parts.append("Rituels -%d%% mana" % mana_reduc)

	var sold_reduc := int(traits.get("soldats_cost_reduction_attaquer_pct", 0))
	if sold_reduc > 0:
		parts.append("Attaquer -%d%% soldats" % sold_reduc)

	var regen_ame := int(traits.get("night_soul_regen", 0))
	if regen_ame > 0:
		parts.append("Nuit: Ame +%d" % regen_ame)

	var rep_nuit := int(traits.get("night_reputation_gain", 0))
	if rep_nuit > 0:
		parts.append("Nuit: Reputation +%d" % rep_nuit)

	var map_bonus := traits.get("bonus_score_actions", {}) as Dictionary
	for action_id in map_bonus.keys():
		var val := int(map_bonus[action_id])
		if val != 0:
			parts.append("%s %+d" % [str(action_id), val])

	if parts.is_empty():
		return "Traits actifs: aucun effet chiffré"
	return "Traits actifs: %s" % FKHelpers.join_array(parts, " | ")


func _get_traits_caps() -> Dictionary:
	var traits_cfg: Dictionary = GameDataLoader.get_character_traits()
	return (traits_cfg.get("caps", {}) as Dictionary).duplicate(true)


func _calculer_bonus_production_domaines() -> Dictionary:
	var bonus := {
		"or": 0,
		"mana": 0,
		"fer": 0,
		"essence": 0,
		"bois": 0,
		"pierre": 0,
		"nourriture": 0,
	}

	for role in ROLE_DOMAINES:
		if not fiches_domaine.has(role):
			continue
		var fiche := fiches_domaine[role] as Dictionary
		if not bool(fiche.get("actif", false)):
			continue

		var niveau := clampi(int(fiche.get("niveau", 1)), 1, 20)
		var affinite := clampi(int(fiche.get("affinite", int(affinites_pnj.get(role, 0)))), -100, 100)
		var bonus_aff := maxi(0, affinite) / 25

		match role:
			"forgeron":
				bonus["fer"] += niveau + bonus_aff
				bonus["pierre"] += maxi(1, niveau / 3)
			"alchimiste":
				bonus["essence"] += maxi(1, niveau / 2) + bonus_aff
				bonus["mana"] += maxi(1, niveau / 2)
			"intendant":
				bonus["or"] += 5 * niveau + (2 * bonus_aff)
				bonus["nourriture"] += maxi(1, niveau / 2)
			"arcaniste":
				bonus["mana"] += 2 * niveau + bonus_aff
				if niveau >= 5:
					bonus["essence"] += 1

	return bonus


func get_pnj_gestion_state() -> Dictionary:
	_sanitizer_pnj_gestion()
	return pnj_gestion.duplicate(true)


func ajouter_pnj_gere(
	pnj_id: String,
	pnj_name: String,
	pnj_type: String,
	role: String,
	niveau: int,
	pnj_stats: Dictionary,
	traits: Array = []
) -> Dictionary:
	var fiche := _planner.make_pnj_profile(pnj_id, pnj_name, pnj_type, role, niveau, pnj_stats, traits)
	var state := get_pnj_gestion_state()
	var roster: Array = (state.get("roster", []) as Array).duplicate(true)
	var index := _find_managed_pnj_index(roster, pnj_id)
	if index >= 0:
		roster[index] = fiche
	else:
		roster.append(fiche)
	state["roster"] = roster
	pnj_gestion = state
	return fiche.duplicate(true)


func planifier_mission_soldats(action_id: String, effectif: int) -> Dictionary:
	var state: Dictionary = get_pnj_gestion_state()
	var result: Dictionary = _planner.assign_soldiers(
		state.get("planning", {}) as Dictionary,
		action_id,
		effectif,
		int(ressources.get("soldats", 0))
	)
	if bool(result.get("ok", false)):
		state["planning"] = (result.get("planning", state.get("planning", {})) as Dictionary).duplicate(true)
		# Reserve soldiers at planning time by assigning concrete IDs from pool.
		var requested: int = int(effectif)
		var available_pool: int = _soldats_disponibles.size()
		var to_assign: int = min(requested, available_pool)
		var assigned_ids: Array = []
		for i in range(to_assign):
			var sid: String = str(_soldats_disponibles[0])
			assigned_ids.append(sid)
			_soldats_disponibles.remove_at(0)
		# If requested > available, return a warning so UI can inform user
		if to_assign < requested:
			result["warning"] = "insufficient"
			result["assigned"] = to_assign
		else:
			result["assigned"] = to_assign

		# Attach assigned ids to the last mission entry
		var planning: Dictionary = (state.get("planning", {}) as Dictionary)
		var missions: Array = (planning.get("missions_soldats", []) as Array)
		if missions.size() > 0:
			var last_idx := missions.size() - 1
			var m: Dictionary = (missions[last_idx] as Dictionary).duplicate(true)
			m["assigned"] = assigned_ids
			missions[last_idx] = m
			planning["missions_soldats"] = missions
			state["planning"] = planning

		# Keep ressources count in sync with available pool
		ressources["soldats"] = _soldats_disponibles.size()
		emit_signal("ressources_mises_a_jour")
		pnj_gestion = state
	return result


func annuler_mission_soldats(index: int) -> Dictionary:
	var state: Dictionary = get_pnj_gestion_state()
	var planning: Dictionary = (state.get("planning", {}) as Dictionary).duplicate(true)
	var missions: Array = (planning.get("missions_soldats", []) as Array).duplicate(true)
	if index < 0 or index >= missions.size():
		return {"ok": false, "error": "index_invalide"}
	var mission := missions[index] as Dictionary
	# refund reserved soldiers when a mission is cancelled
	var assigned_ids: Array = (mission.get("assigned", []) as Array).duplicate(true)
	var effectif := int(mission.get("effectif", 0))
	# If explicit assigned ids are present, return them to pool, otherwise refund by effectif
	if assigned_ids.size() > 0:
		for sid in assigned_ids:
			_soldats_disponibles.append(str(sid))
	else:
		# generate placeholder IDs to return to pool
		for i in range(effectif):
			_soldats_disponibles.append("S%d" % _soldat_next_id)
			_soldat_next_id += 1

	missions.remove_at(index)
	planning["missions_soldats"] = missions
	state["planning"] = planning
	pnj_gestion = state

	# Update ressources count to reflect available pool
	ressources["soldats"] = _soldats_disponibles.size()
	emit_signal("ressources_mises_a_jour")
	return {"ok": true, "planning": planning}


func unassign_soldier_from_mission(index: int, soldier_id: String) -> Dictionary:
	var state: Dictionary = get_pnj_gestion_state()
	var planning: Dictionary = (state.get("planning", {}) as Dictionary).duplicate(true)
	var missions: Array = (planning.get("missions_soldats", []) as Array).duplicate(true)
	if index < 0 or index >= missions.size():
		return {"ok": false, "error": "index_invalide"}

	var mission := (missions[index] as Dictionary).duplicate(true)
	var assigned: Array = (mission.get("assigned", []) as Array).duplicate(true)
	if assigned.is_empty():
		return {"ok": false, "error": "aucun_soldat_assign"}

	var sid_str: String = str(soldier_id)
	var found: bool = false
	for i in range(assigned.size()):
		if str(assigned[i]) == sid_str:
			assigned.remove_at(i)
			found = true
			break

	if not found:
		return {"ok": false, "error": "soldat_non_present"}

	# Return the ID to the pool
	_soldats_disponibles.append(sid_str)

	# Decrement effectif and update/remove mission
	var new_effectif: int = max(0, int(mission.get("effectif", 0)) - 1)
	if new_effectif <= 0:
		missions.remove_at(index)
	else:
		mission["effectif"] = new_effectif
		mission["assigned"] = assigned
		missions[index] = mission

	planning["missions_soldats"] = missions
	state["planning"] = planning
	pnj_gestion = state

	# Sync resources count with pool and persist
	ressources["soldats"] = _soldats_disponibles.size()
	emit_signal("ressources_mises_a_jour")
	return {"ok": true, "planning": planning}


func adjust_mission_soldier_count(index: int, delta: int) -> Dictionary:
	# Adjusts a soldier mission's effectif by delta (positive = assign, negative = unassign)
	var state: Dictionary = get_pnj_gestion_state()
	var planning: Dictionary = (state.get("planning", {}) as Dictionary).duplicate(true)
	var missions: Array = (planning.get("missions_soldats", []) as Array).duplicate(true)
	if index < 0 or index >= missions.size():
		return {"ok": false, "error": "index_invalide"}

	var mission: Dictionary = (missions[index] as Dictionary).duplicate(true)
	var assigned: Array = (mission.get("assigned", []) as Array).duplicate(true)
	var effectif: int = int(mission.get("effectif", 0))

	if delta > 0:
		# Try to assign up to delta soldiers from pool
		var available: int = _soldats_disponibles.size()
		var to_assign: int = min(delta, available)
		var assigned_ids: Array = []
		for i in range(to_assign):
			var sid: String = str(_soldats_disponibles[0])
			assigned_ids.append(sid)
			_soldats_disponibles.remove_at(0)

		# merge into assigned
		for sid in assigned_ids:
			assigned.append(sid)
		effectif += to_assign

		mission["assigned"] = assigned
		mission["effectif"] = effectif
		missions[index] = mission
		planning["missions_soldats"] = missions
		state["planning"] = planning
		pnj_gestion = state

		ressources["soldats"] = _soldats_disponibles.size()
		emit_signal("ressources_mises_a_jour")

		if to_assign < delta:
			return {"ok": true, "planning": planning, "assigned": to_assign, "warning": "insufficient"}
		return {"ok": true, "planning": planning, "assigned": to_assign}

	elif delta < 0:
		var remove_n: int = min(abs(delta), assigned.size())
		if remove_n <= 0:
			return {"ok": false, "error": "aucun_soldat_a_retirer"}
		# remove last remove_n ids and return them to pool
		for i in range(remove_n):
			var sid: String = str(assigned.pop_back())
			_soldats_disponibles.append(sid)

		effectif = max(0, effectif - remove_n)
		if effectif <= 0:
			missions.remove_at(index)
		else:
			mission["effectif"] = effectif
			mission["assigned"] = assigned
			missions[index] = mission

		planning["missions_soldats"] = missions
		state["planning"] = planning
		pnj_gestion = state

		ressources["soldats"] = _soldats_disponibles.size()
		emit_signal("ressources_mises_a_jour")
		return {"ok": true, "planning": planning, "removed": remove_n}

	return {"ok": false, "error": "delta_zero"}


func annuler_mission_pnj(index: int) -> Dictionary:
	var state := get_pnj_gestion_state()
	var planning := (state.get("planning", {}) as Dictionary).duplicate(true)
	var missions := (planning.get("missions_pnj", []) as Array).duplicate(true)
	if index < 0 or index >= missions.size():
		return {"ok": false, "error": "index_invalide"}
	var mission := missions[index] as Dictionary
	var pnj_id := str(mission.get("pnj_id", ""))
	missions.remove_at(index)
	planning["missions_pnj"] = missions
	# restore pnj state to disponible if present in roster
	var roster := (state.get("roster", []) as Array).duplicate(true)
	var i := _find_managed_pnj_index(roster, pnj_id)
	if i >= 0:
		var pnj := (roster[i] as Dictionary).duplicate(true)
		pnj["etat"] = "disponible"
		roster[i] = pnj
		state["roster"] = roster

	state["planning"] = planning
	pnj_gestion = state
	return {"ok": true, "planning": planning, "roster": roster}


func assigner_pnj_support_journee(pnj_id: String, hero_action_id: String) -> Dictionary:
	var state := get_pnj_gestion_state()
	var result: Dictionary = _planner.assign_pnj_support(
		state.get("roster", []) as Array,
		state.get("planning", {}) as Dictionary,
		pnj_id,
		hero_action_id
	)
	if bool(result.get("ok", false)):
		state["roster"] = (result.get("roster", state.get("roster", [])) as Array).duplicate(true)
		state["planning"] = (result.get("planning", state.get("planning", {})) as Dictionary).duplicate(true)
		pnj_gestion = state
	return result


func assigner_pnj_expedition_journee(pnj_id: String, seed_value: int = -1) -> Dictionary:
	var state := get_pnj_gestion_state()
	var result: Dictionary = _planner.assign_pnj_expedition(
		state.get("roster", []) as Array,
		state.get("planning", {}) as Dictionary,
		pnj_id,
		seed_value
	)
	if bool(result.get("ok", false)):
		state["roster"] = (result.get("roster", state.get("roster", [])) as Array).duplicate(true)
		state["planning"] = (result.get("planning", state.get("planning", {})) as Dictionary).duplicate(true)
		pnj_gestion = state
	return result


func resoudre_planning_pnj_journee() -> Dictionary:
	var state := get_pnj_gestion_state()
	var result: Dictionary = _planner.resolve_daily_plan(
		state.get("roster", []) as Array,
		state.get("planning", {}) as Dictionary
	)
	var gains := (result.get("resource_gains", {}) as Dictionary).duplicate(true)
	# Apply hero support effects (PNJ support can generate ressources like renseignements/reputation)
	var hero_support := (result.get("hero_support", {}) as Dictionary).duplicate(true)
	var HERO_ACTION_RESOURCE := {
		"espionner": "renseignements",
		"securiser": "reputation",
	}
	for action_key in hero_support.keys():
		var amount := int(hero_support.get(action_key, 0))
		if amount <= 0:
			continue
		if HERO_ACTION_RESOURCE.has(action_key):
			var rkey: String = str(HERO_ACTION_RESOURCE.get(action_key, ""))
			gains[rkey] = int(gains.get(rkey, 0)) + amount

	if not gains.is_empty():
		gagner(gains)

	# Special handling for espionnage soldier missions: reveal an unrevealed house if present
	var soldier_results := (result.get("soldier_results", []) as Array)
	for s in soldier_results:
		if not (s is Dictionary):
			continue
		var aid := str(s.get("action_id", ""))
		if aid == "espionner":
			var r_gains := (s.get("gains", {}) as Dictionary)
			var renseignements_gain := int(r_gains.get("renseignements", 0))
			if renseignements_gain <= 0:
				continue
			# find first unrevealed house
			var found_idx := -1
			for i in range(maisons_nobles.size()):
				if not bool(maisons_nobles[i].get("revelee", false)):
					found_idx = i
					break
			if found_idx >= 0:
				maisons_nobles[found_idx]["revelee"] = true
				maisons_nobles[found_idx]["espionnee"] = true
				var _set_status_msg = "Maison révélée: %s" % str(maisons_nobles[found_idx].get("nom", "Inconnu"))
				print(_set_status_msg)
			else:
				# No unrevealed houses: treat as external espionnage, keep gain
				print("Espionnage externe: +%d renseignements" % renseignements_gain)

	# If planner generated events (from failures), apply them now
	var gen_events := (result.get("generated_events", []) as Array).duplicate(true)
	if not gen_events.is_empty():
		for ev in gen_events:
			if ev is Dictionary:
				# Use tirer_et_appliquer_evenement to apply the event effects (probability handled inside)
				var applied_msg := tirer_et_appliquer_evenement([ev])
				if not applied_msg.is_empty():
					print("Event applied: %s" % applied_msg)

	# Apply soldier losses returned by the planner (remove IDs from pool)
	var soldier_losses := int(result.get("soldier_losses", 0))
	if soldier_losses > 0:
		var removed := 0
		for i in range(soldier_losses):
			if _soldats_disponibles.size() > 0:
				_soldats_disponibles.pop_back()
				removed += 1
			else:
				break
		# sync ressources count
		ressources["soldats"] = _soldats_disponibles.size()
		emit_signal("ressources_mises_a_jour")

	# PNJ losses: planner may have already marked PNJ as 'blesse' in returned roster
	var pnj_losses := int(result.get("pnj_losses", 0))
	if pnj_losses > 0:
		# optionally log or record in last_resolution; roster already updated below
		print("PNJ pertes appliquees: %d" % pnj_losses)
	state["roster"] = (result.get("roster", state.get("roster", [])) as Array).duplicate(true)
	state["planning"] = _planner.make_daily_plan()
	state["last_resolution"] = result.duplicate(true)
	pnj_gestion = state
	return result


func advance_day_phase() -> Dictionary:
	if _day_transition_pending:
		return {"ok": false, "message": "Le changement de phase est déjà en cours."}
	_day_transition_pending = true
	var loop := GameLoopStateMachine.new(self)
	loop.start()
	var changed := loop.tick_to_next()
	_day_transition_pending = false
	if not changed:
		return {"ok": false, "message": "Revenez de l’expédition avant de faire avancer la journée."}
	sauvegarder()
	return {"ok": true, "message": day_report, "phase": daily_phase}

func on_matin() -> void:
	daily_phase = "matin"
	var loader := get_node("/root/GameDataLoader")
	var production := get_production_totale(loader.get_production_par_tour())
	gagner(production)
	# Le premier tête-à-tête ne tire pas des événements destinés à une communauté constituée.
	var message := ""
	if campaign.is_empty() or int(campaign.get("version", 1)) < 2 or bool(campaign.get("initial_tutorial_done", false)):
		message = tirer_et_appliquer_evenement(loader.get_evenements_aleatoires())
	preload("res://scripts/services/refuge_service.gd").dawn(self)
	tour_actuel += 1
	moment_journee = "jour"
	reset_actions_nouveau_tour()
	day_report = "Une nouvelle aube. Production : %s. %s" % [preload("res://scripts/services/refuge_service.gd").resources_text(production), message]
	tour_suivant.emit(tour_actuel)

func on_apres_midi() -> void:
	daily_phase = "apres_midi"
	var report := resoudre_planning_pnj_journee()
	day_report = "Le travail de la journée est terminé. " + preload("res://scripts/services/refuge_service.gd").resources_text(report.get("resource_gains", {}))

func on_soir() -> void:
	daily_phase = "soir"
	moment_journee = "nuit"
	reset_actions_pour_nuit()
	day_report = "La nuit tombe sur la Brèche-Sèche. " + appliquer_passifs_nuit()


# ─────────────────────────────────────────────────────────────────────
#  BARRE D'ÂME
# ─────────────────────────────────────────────────────────────────────

## Utilise la Forme Dragon (dépense de l'âme).
func utiliser_forme_dragon(cout_ame: int = 25) -> bool:
	if barre_ame <= 0:
		return false
	barre_ame = maxi(0, barre_ame - cout_ame)
	forme_dragon_utilisee += 1
	emit_signal("ressources_mises_a_jour")
	if barre_ame <= 0:
		# Déclenchement du Bad End
		GameManager.declencher_bad_end_dragon()
	return true


# ─────────────────────────────────────────────────────────────────────
#  GESTION DES MAISONS NOBLES
# ─────────────────────────────────────────────────────────────────────

## Retourne les données d'une maison noble par son ID.
func get_maison(id: int) -> Dictionary:
	for maison in maisons_nobles:
		if int(maison.get("id", -1)) == id:
			return maison
	return {}


## Marque une maison comme espionnée et révèle ses infos.
func espionner_maison(id: int, succes_critique: bool = false) -> void:
	for i in range(maisons_nobles.size()):
		if int(maisons_nobles[i].get("id", -1)) == id:
			maisons_nobles[i]["revelee"]   = true
			maisons_nobles[i]["espionnee"] = true
			if str(maisons_nobles[i].get("statut", "inconnue")) == "inconnue":
				maisons_nobles[i]["statut"] = "revelee"
			if succes_critique:
				maisons_nobles[i]["ressources_revelees"] = true


## Conquiert un bastion d'une maison noble.
func conquerir_bastion(maison_id: int, bastion_id: String) -> void:
	for i in range(maisons_nobles.size()):
		if int(maisons_nobles[i].get("id", -1)) == maison_id:
			var bastions: Array = maisons_nobles[i].get("bastions", [])
			for j in range(bastions.size()):
				if bastions[j].get("id", "") == bastion_id:
					bastions[j]["conquis"] = true
					maisons_nobles[i]["revelee"] = true
			# Vérifie si toute la maison est soumise
			_verifier_maison_soumise(i)
			return


func _verifier_maison_soumise(index: int) -> void:
	var bastions: Array = maisons_nobles[index].get("bastions", [])
	var tous_conquis := bastions.all(func(b): return bool(b.get("conquis", false)))
	if tous_conquis:
		maisons_nobles[index]["statut"] = "soumise"


## Nombre de maisons soumises (pour vérifier la victoire).
func maisons_soumises() -> int:
	var count := 0
	for m in maisons_nobles:
		if m.get("statut", "") == "soumise":
			count += 1
	return count


## Modification de la relation avec une maison noble.
func modifier_relation(maison_id: int, nouvelle_relation: String) -> void:
	for i in range(maisons_nobles.size()):
		if int(maisons_nobles[i].get("id", -1)) == maison_id:
			var relation := nouvelle_relation
			var statut_courant := str(maisons_nobles[i].get("statut", "inconnue"))

			if relation == "neutre_positive":
				relation = "neutre"

			maisons_nobles[i]["relation"] = relation

			# Le hub utilise la clé "statut" pour filtrer les actions et colorer l'UI.
			# On la synchronise avec la relation, sauf si la maison est déjà soumise.
			if statut_courant != "soumise":
				if relation in ["alliee", "hostile", "neutre", "revelee", "inconnue"]:
					maisons_nobles[i]["statut"] = relation
				else:
					maisons_nobles[i]["statut"] = "neutre"
			return


# ─────────────────────────────────────────────────────────────────────
#  FIN DE TOUR
# ─────────────────────────────────────────────────────────────────────

## Avance d'un tour : collecte les ressources, applique les effets.
func fin_de_tour(action_choisie: String, effets_action: Dictionary) -> void:
	# 1. Applique les effets de l'action
	_appliquer_effets(effets_action)

	# 2. Production automatique
	for res in ressources_par_tour:
		if ressources.has(res):
			ressources[res] = int(ressources[res]) + int(ressources_par_tour[res])

	# 3. Journal du tour
	historique_tours.append({
		"tour": tour_actuel,
		"action": action_choisie,
		"effets": effets_action.duplicate(),
		"ressources_apres": ressources.duplicate(),
	})

	tour_actuel += 1
	emit_signal("ressources_mises_a_jour")
	emit_signal("tour_suivant", tour_actuel)
	sauvegarder()


func _appliquer_effets(effets: Dictionary) -> void:
	# Gains directs
	if effets.has("or_recupere"):       gagner({"or": int(effets["or_recupere"])})
	if effets.has("or_penalite"):       payer({"or": absi(int(effets["or_penalite"]))})
	if effets.has("mana_gain"):         gagner({"mana": int(effets["mana_gain"])})
	if effets.has("soldats_gain"):      gagner({"soldats": int(effets["soldats_gain"])})
	if effets.has("reputation_gain"):   gagner({"reputation": int(effets["reputation_gain"])})
	if effets.has("renseignements_gain"): gagner({"renseignements": int(effets["renseignements_gain"])})

	# Pertes en pourcentage
	if effets.has("pertes_soldats_pct"):
		var pct := int(effets["pertes_soldats_pct"])
		var pertes := int(ressources.get("soldats", 0)) * pct / 100
		payer({"soldats": maxi(1, pertes)})

	if effets.has("soldats_perte_pct"):
		var pct := int(effets["soldats_perte_pct"])
		var pertes := int(ressources.get("soldats", 0)) * pct / 100
		payer({"soldats": maxi(1, pertes)})

	# Pertes de réputation
	if effets.has("reputation_perte"):  payer({"reputation": int(effets["reputation_perte"])})
	if effets.has("relation_perte"):
		pass  # Géré par les scènes directement via modifier_relation

	# Handle PNJ recruitment effect: generate and register PNJ(s)
	if effets.has("pnj_recrute"):
		var count := int(effets.get("pnj_recrute", 1))
		var role_hint := str(effets.get("pnj_role", ""))
		print("[DEBUG] _appliquer_effets: pnj_recrute=%d role_hint=%s moment=%s magie=%s" % [count, role_hint, str(moment_journee), str(magie_pactes_active())])
		for i in range(count):
			var gen := PnjGenerator.new()
			var added := gen.generate_and_register_pnj(role_hint, "recrute")
			if added == null:
				print("[DEBUG] generate_and_register_pnj returned null for hint=%s" % role_hint)
			else:
				print("[DEBUG] New PNJ registered: %s" % str(added))
			# ensure effects reflect actual recruitment for UI
			if added != null:
				effets["pnj_recrute"] = int(effets.get("pnj_recrute", 0))

	# Gains de renforcement (fortification)
	if effets.has("soldats_bonus"): gagner({"soldats": int(effets["soldats_bonus"])})
	if effets.has("production_or_bonus"):
		ressources_par_tour["or"] = int(ressources_par_tour.get("or", 120)) + int(effets["production_or_bonus"])
		emit_signal("ressources_mises_a_jour")


## Tire au plus un événement aléatoire pour le tour et applique ses effets.
## Retourne un message à afficher dans le log, ou une chaîne vide.
func tirer_et_appliquer_evenement(evenements: Array) -> String:
	if evenements.is_empty():
		return ""

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for ev in evenements:
		var d := ev as Dictionary
		if d.is_empty():
			continue

		var condition := str(d.get("condition", ""))
		if not _condition_evenement_valide(condition):
			continue

		var probabilite := float(d.get("probabilite", 0.0))
		if probabilite <= 0.0:
			continue

		if rng.randf() <= probabilite:
			_appliquer_effets((d.get("effets", {}) as Dictionary).duplicate(true))
			var id_evt := str(d.get("id", ""))
			if not id_evt.is_empty() and not evenements_declenches.has(id_evt):
				evenements_declenches.append(id_evt)
			var titre := str(d.get("titre", "Événement"))
			var texte := str(d.get("texte", ""))
			if texte.is_empty():
				return "Événement: %s." % titre
			return "Événement: %s — %s" % [titre, texte]

	return ""


## Évalue l'état de la partie (en cours / victoire / défaite).
func evaluer_etat_partie() -> Dictionary:
	if barre_ame <= 0:
		return {
			"terminee": true,
			"etat": "defaite",
			"message": "Barre d’âme épuisée. L’héritier est consumé par l’Éther de Cendre.",
		}

	if maisons_soumises() >= 9:
		return {
			"terminee": true,
			"etat": "victoire",
			"message": "Les Neuf Maisons sont soumises. Victoire totale.",
		}

	var soldats := int(ressources.get("soldats", 0))
	var or_total := int(ressources.get("or", 0))
	if soldats <= 0 and or_total < 50 and not _a_alliance_active():
		return {
			"terminee": true,
			"etat": "defaite",
			"message": "Votre clan s'effondre: plus de soldats, presque plus d'or et aucune alliance active.",
		}

	return {
		"terminee": false,
		"etat": "en_cours",
		"message": "",
	}


func _a_alliance_active() -> bool:
	for maison in maisons_nobles:
		var relation := str(maison.get("relation", ""))
		var statut := str(maison.get("statut", ""))
		if relation == "alliee" or statut == "alliee":
			return true
	return false


func _condition_evenement_valide(condition: String) -> bool:
	var cond := condition.strip_edges()
	if cond.is_empty() or cond == "null":
		return true

	var clauses := cond.split("AND")
	for clause_raw in clauses:
		var clause := clause_raw.strip_edges()
		if clause.is_empty():
			continue
		if not _evaluer_clause_condition(clause):
			return false
	return true


func _evaluer_clause_condition(clause: String) -> bool:
	for op_any in [">=", "<=", "==", "!=", ">", "<", "="]:
		var op: String = str(op_any)
		var idx: int = clause.find(op)
		if idx == -1:
			continue

		var gauche: String = clause.substr(0, idx).strip_edges().to_lower()
		var droite: String = clause.substr(idx + op.length()).strip_edges()
		if op == "=":
			op = "=="

		var left_value: Variant = _valeur_condition(gauche)
		var right_value: Variant = _convertir_condition_value(droite)
		if left_value == null or right_value == null:
			return false
		return _comparer_condition(left_value, right_value, op)

	return false


func _valeur_condition(key: String) -> Variant:
	match key:
		"tour":
			return tour_actuel
		"moment_journee":
			return moment_journee
		_:
			if ressources.has(key):
				return int(ressources.get(key, 0))
	return null


func _convertir_condition_value(value: String) -> Variant:
	var v := value.strip_edges()
	if v.is_empty():
		return null

	if v.begins_with("\"") and v.ends_with("\"") and v.length() >= 2:
		return v.substr(1, v.length() - 2)

	if v.is_valid_int():
		return int(v)
	if v.is_valid_float():
		return float(v)

	return v.to_lower()


func _comparer_condition(a: Variant, b: Variant, op: String) -> bool:
	match op:
		">":
			return a > b
		"<":
			return a < b
		">=":
			return a >= b
		"<=":
			return a <= b
		"==":
			return a == b
		"!=":
			return a != b
	return false


# ─────────────────────────────────────────────────────────────────────
#  SAUVEGARDE / CHARGEMENT
# ─────────────────────────────────────────────────────────────────────

func sauvegarder() -> void:
	var data := {
		"clan_id": clan_id,
		"nom_clan": nom_clan,
		"nom_personnage": nom_personnage,
		"classe": classe,
		"profil_personnage": profil_personnage.duplicate(true),
		"caracteristiques_hero": caracteristiques_hero.duplicate(true),
		"stats_clan": stats_clan.duplicate(true),
		"affinites_pnj": affinites_pnj.duplicate(true),
		"fiche_hero": fiche_hero.duplicate(true),
		"fiches_domaine": fiches_domaine.duplicate(true),
		"pnj_gestion": pnj_gestion.duplicate(true),
		"campaign": campaign.duplicate(true),
		"daily_phase": daily_phase,
		"corruption_state": get_corruption_service().export_state(),
		"day_report": day_report,
		"stats": stats.duplicate(),
		"ressources": ressources.duplicate(),
		"ressources_par_tour": ressources_par_tour.duplicate(),
		"barre_ame": barre_ame,
		"forme_dragon_utilisee": forme_dragon_utilisee,
		"tour_actuel": tour_actuel,
		"moment_journee": moment_journee,
		"action_jour_effectuee": action_jour_effectuee,
		"action_nuit_effectuee": action_nuit_effectuee,
		"maisons_nobles": maisons_nobles.duplicate(true),
		"evenements_declenches": evenements_declenches.duplicate(),
		"historique_tours": historique_tours.duplicate(true),
		"soldats_disponibles": _soldats_disponibles.duplicate(true),
		"soldat_next_id": _soldat_next_id,
	}
	var save_path := _get_clan_save_path()
	if not JsonPersistenceService.write_json_atomic(save_path, data):
		push_error("ClanManager: impossible d'écrire la sauvegarde du clan pour le slot actif.")
		return


func charger_sauvegarde() -> bool:
	var save_path := _get_clan_save_path()
	if not FileAccess.file_exists(save_path):
		return false
	var data := _lire_json(save_path)
	if data.is_empty():
		return false

	nom_clan             = str(data.get("nom_clan", data.get("clan_name", "")))
	clan_id              = str(data.get("clan_id", "")).strip_edges()
	if clan_id.is_empty():
		clan_id = ClanIdentityType.id_from_name(nom_clan)
	nom_personnage       = data.get("nom_personnage", "")
	classe               = data.get("classe", "")
	profil_personnage    = (data.get("profil_personnage", profil_personnage) as Dictionary).duplicate(true)
	profil_personnage["clan_id"] = clan_id
	profil_personnage["clan_name"] = nom_clan
	_forcer_magie_pactes()
	caracteristiques_hero = (data.get("caracteristiques_hero", caracteristiques_hero) as Dictionary).duplicate(true)
	stats_clan           = (data.get("stats_clan", stats_clan) as Dictionary).duplicate(true)
	affinites_pnj        = (data.get("affinites_pnj", affinites_pnj) as Dictionary).duplicate(true)
	fiche_hero           = (data.get("fiche_hero", fiche_hero) as Dictionary).duplicate(true)
	fiches_domaine       = (data.get("fiches_domaine", fiches_domaine) as Dictionary).duplicate(true)
	pnj_gestion          = (data.get("pnj_gestion", _make_default_pnj_gestion_state()) as Dictionary).duplicate(true)
	campaign             = (data.get("campaign", {}) as Dictionary).duplicate(true)
	_corruption_service = CorruptionService.new()
	_corruption_service.import_state(data.get("corruption_state", data.get("corruption", {})))
	_corruption_service.setup(self)
	stats                = (data.get("stats", {}) as Dictionary).duplicate()
	ressources           = (data.get("ressources", {}) as Dictionary).duplicate()
	ressources_par_tour  = (data.get("ressources_par_tour", {}) as Dictionary).duplicate()
	barre_ame            = int(data.get("barre_ame", 100))
	forme_dragon_utilisee = int(data.get("forme_dragon_utilisee", 0))
	tour_actuel          = int(data.get("tour_actuel", 1))
	moment_journee       = str(data.get("moment_journee", "jour"))
	daily_phase = str(data.get("daily_phase", "soir" if moment_journee == "nuit" else "matin"))
	if daily_phase not in ["matin", "apres_midi", "soir"]: daily_phase = "matin"
	day_report = str(data.get("day_report", ""))
	action_jour_effectuee = bool(data.get("action_jour_effectuee", false))
	action_nuit_effectuee = bool(data.get("action_nuit_effectuee", false))
	maisons_nobles       = (data.get("maisons_nobles", []) as Array).duplicate(true)
	evenements_declenches = (data.get("evenements_declenches", []) as Array).duplicate()
	historique_tours     = (data.get("historique_tours", []) as Array).duplicate(true)
	_sanitizer_stats()
	_sanitizer_ressources()
	# restore soldier pool
	_soldats_disponibles = (data.get("soldats_disponibles", []) as Array).duplicate(true)
	_soldat_next_id = int(data.get("soldat_next_id", _soldat_next_id))
	_sanitizer_pnj_et_domaines()
	_sanitizer_pnj_gestion()
	if moment_journee not in ["jour", "nuit"]:
		moment_journee = "jour"

	emit_signal("ressources_mises_a_jour")
	return true


func get_profil_personnage() -> Dictionary:
	return profil_personnage.duplicate(true)


func get_fiche_complete() -> Dictionary:
	_ensure_fiche_complete()
	return (profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)


func get_personnage_niveau() -> int:
	_ensure_fiche_complete()
	var fiche := profil_personnage.get("fiche_complete", {}) as Dictionary
	return maxi(1, int(fiche.get("niveau", 1)))


func get_personnage_points_restants() -> int:
	_ensure_fiche_complete()
	var fiche := profil_personnage.get("fiche_complete", {}) as Dictionary
	return maxi(0, int(fiche.get("points_restants", 0)))


func get_personnage_feats() -> Array:
	return (profil_personnage.get("feats", []) as Array).duplicate(true)


func get_personnage_portrait_path() -> String:
	var portrait := profil_personnage.get("portrait", {}) as Dictionary
	return str(portrait.get("path", ""))


func set_personnage_portrait(payload: Dictionary, do_save: bool = false) -> void:
	if payload == null:
		return
	profil_personnage["portrait"] = (payload as Dictionary).duplicate(true)
	if do_save:
		sauvegarder()


func get_personnage_experience() -> int:
	if fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	return int(fiche_hero.get("experience", 0))


func get_personnage_xp_for_next_level() -> int:
	if fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	var lvl := int(fiche_hero.get("niveau", 1))
	return 100 * lvl


func is_personnage_xp_full() -> bool:
	return get_personnage_experience() >= get_personnage_xp_for_next_level()


func apply_profile_sheet_update(stats_update: Dictionary, points_remaining: int, feats: Array = []) -> void:
	print("ClanManager.apply_profile_sheet_update: called; stats_update=", JSON.stringify(stats_update), " points_remaining=", points_remaining, " feats=", JSON.stringify(feats))
	# Store raw character stats (sanitized to character bounds)
	var raw_stats = StatDefs.sanitize_stats(
		stats_update,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)

	_ensure_fiche_complete()
	var fiche := (profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	fiche["points_restants"] = maxi(0, int(points_remaining))
	fiche["stats_brutes"] = raw_stats.duplicate(true)
	profil_personnage["fiche_complete"] = fiche
	print("ClanManager.apply_profile_sheet_update: stored fiche_complete=", JSON.stringify(fiche))

	if not feats.is_empty():
		profil_personnage["feats"] = feats.duplicate(true)

	# Recompute clan-level stats (final values) from class, raw stats and feats
	var class_stats_bonus: Dictionary = {}
	if classe != "":
		# Get class data from centralized GameDataLoader
		var class_entry: Dictionary = GameDataLoader.get_class_by_id(classe)
		if class_entry and not class_entry.is_empty():
			class_stats_bonus = class_entry.get("stats_bonus", {}) as Dictionary

	# Aggregate flat stat bonuses from feats through the canonical loader API.
	# feats.json is namespaced under "dons"/"capacites", so direct root lookup is invalid.
	var feats_bonus_stats: Dictionary = {}
	var current_feats: Array = profil_personnage.get("feats", []) as Array
	for f in current_feats:
		var fdef: Dictionary = GameDataLoader.get_feat(str(f))
		var eff := (fdef.get("effects", {}) as Dictionary)
		var stats_eff := (eff.get("stats", {}) as Dictionary)
		for sk in stats_eff.keys():
			feats_bonus_stats[sk] = int(feats_bonus_stats.get(sk, 0)) + int(stats_eff[sk])

	# Compute final stats using CharacterBuildService
	var final_stats: Dictionary = CharacterBuildService.compute_final_stats(
		class_stats_bonus,
		raw_stats,
		{},
		{},
		feats_bonus_stats
	)

	# Persist final stats into clan-level `stats` used by other systems
	for key in StatDefs.STAT_KEYS:
		stats[key] = int(final_stats.get(key, 0))

	_sanitizer_stats()

	# Re-calculer et appliquer les effets dérivés des feats pour persistance et cohérence
	_compute_and_apply_profil_effects(profil_personnage, true)

	sauvegarder()


func level_up_personnage(points_awarded: int = 10) -> Dictionary:
	_ensure_fiche_complete()
	var fiche := (profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	var current_lvl := maxi(1, int(fiche.get("niveau", 1)))
	fiche["niveau"] = current_lvl + 1
	fiche["points_restants"] = maxi(0, int(fiche.get("points_restants", 0))) + maxi(0, points_awarded)
	profil_personnage["fiche_complete"] = fiche
	sauvegarder()
	return {
		"ok": true,
		"niveau": int(fiche.get("niveau", 1)),
		"points_restants": int(fiche.get("points_restants", 0)),
	}


## Lance un dé à N faces.
func lancer_de(faces: int = 20) -> int:
	return randi_range(1, faces)


## Calcule le score d'une action (stat principale + stat secondaire + dé).
func calculer_score_action(stat_principale: String, stat_secondaire: String = "") -> int:
	var score := int(stats.get(stat_principale, 5))
	if stat_secondaire != "":
		score += int(stats.get(stat_secondaire, 5))
	score += lancer_de(20)
	return score


# ─────────────────────────────────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────────────────────────────────

func partie_en_cours() -> bool:
	return (nom_clan != "" and tour_actuel > 0) or FileAccess.file_exists(_get_clan_save_path())


func _get_clan_save_path() -> String:
	if SaveSystem == null:
		return "user://slots/slot_1/clan.json"
	return SaveSystem.get_clan_save_path()


func _lire_json(path: String) -> Dictionary:
	return JsonPersistenceService.read_json_with_backup(path)


func _sanitizer_stats() -> void:
	# Protège la boucle de gameplay contre une sauvegarde corrompue.
	stats = StatDefs.sanitize_stats(stats, MIN_STAT, MAX_STAT, 5)

	for cle in ["vigueur", "esprit", "presence", "discipline"]:
		var v := int(caracteristiques_hero.get(cle, 10))
		caracteristiques_hero[cle] = clampi(v, 1, 30)

	for cle in ["stabilite", "influence", "logistique", "autorite"]:
		var s := int(stats_clan.get(cle, 5))
		stats_clan[cle] = clampi(s, 1, 20)


func _sanitizer_ressources() -> void:
	for cle in RESSOURCE_KEYS:
		if not ressources.has(cle):
			ressources[cle] = 0
		if not ressources_par_tour.has(cle):
			ressources_par_tour[cle] = 0
		ressources[cle] = maxi(0, int(ressources.get(cle, 0)))
		ressources_par_tour[cle] = maxi(0, int(ressources_par_tour.get(cle, 0)))

	ressources["soldats"] = clampi(int(ressources.get("soldats", 0)), 0, SOLDATS_MAX)


func _sanitizer_pnj_et_domaines() -> void:
	for role in ROLE_DOMAINES:
		affinites_pnj[role] = clampi(int(affinites_pnj.get(role, 0)), -100, 100)

	if fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()

	for role in ROLE_DOMAINES:
		if not fiches_domaine.has(role):
			fiches_domaine[role] = {
				"nom": role.capitalize(),
				"niveau": 1,
				"specialite": role,
				"actif": false,
				"affinite": int(affinites_pnj.get(role, 0)),
			}
		else:
			var fiche := (fiches_domaine[role] as Dictionary).duplicate(true)
			fiche["niveau"] = clampi(int(fiche.get("niveau", 1)), 1, 20)
			fiche["affinite"] = clampi(int(fiche.get("affinite", int(affinites_pnj.get(role, 0)))), -100, 100)
			fiches_domaine[role] = fiche


func _sanitizer_pnj_gestion() -> void:
	if pnj_gestion.is_empty():
		pnj_gestion = _make_default_pnj_gestion_state()
	if not pnj_gestion.has("roster") or not (pnj_gestion.get("roster", []) is Array):
		pnj_gestion["roster"] = []
	if not pnj_gestion.has("planning") or not (pnj_gestion.get("planning", {}) is Dictionary):
		pnj_gestion["planning"] = _planner.make_daily_plan()
	if not pnj_gestion.has("last_resolution") or not (pnj_gestion.get("last_resolution", {}) is Dictionary):
		pnj_gestion["last_resolution"] = {}

	var sanitized_roster: Array = []
	for pnj_data in pnj_gestion.get("roster", []):
		var pnj := pnj_data as Dictionary
		if pnj.is_empty():
			continue
		sanitized_roster.append(
			_planner.make_pnj_profile(
				str(pnj.get("id", "pnj_%d" % sanitized_roster.size())),
				str(pnj.get("nom", "PNJ")),
				str(pnj.get("type", "recrute")),
				str(pnj.get("role", "auxiliaire")),
				int(pnj.get("niveau", 1)),
				pnj.get("stats", {}) as Dictionary,
				pnj.get("traits", []) as Array
			)
		)
		sanitized_roster[-1]["etat"] = str(pnj.get("etat", "disponible"))
	pnj_gestion["roster"] = sanitized_roster

	var planning := (pnj_gestion.get("planning", _planner.make_daily_plan()) as Dictionary).duplicate(true)
	if not planning.has("missions_soldats") or not (planning.get("missions_soldats", []) is Array):
		planning["missions_soldats"] = []
	if not planning.has("missions_pnj") or not (planning.get("missions_pnj", []) is Array):
		planning["missions_pnj"] = []
	pnj_gestion["planning"] = planning


func _make_default_pnj_gestion_state() -> Dictionary:
	return {
		"roster": [],
		"planning": _planner.make_daily_plan(),
		"last_resolution": {},
	}


# Calculer et appliquer les effets issus du profil (feats)
func _compute_and_apply_profil_effects(profil: Dictionary, do_save: bool = false) -> void:
	if profil == null:
		return
	# Eviter double-application
	if bool(profil.get("computed_effects_applied", false)):
		return
	var total_pv_bonus := 0
	var total_mana_bonus := 0
	if profil.has("feats") and (profil.get("feats") is Array):
		for f in (profil.get("feats") as Array):
			var fid := str(f)
			var fdef: Dictionary = GameDataLoader.get_feat(fid)
			var eff := fdef.get("effects", {}) as Dictionary
			if eff.has("pv_bonus"):
				total_pv_bonus += int(eff.get("pv_bonus", 0))
			if eff.has("mana_bonus"):
				total_mana_bonus += int(eff.get("mana_bonus", 0))

	# Appliquer PV bonus à la caractéristique 'vigueur' et à la fiche_hero si initialisée
	if total_pv_bonus != 0:
		caracteristiques_hero["vigueur"] = int(caracteristiques_hero.get("vigueur", 10)) + total_pv_bonus
		if fiche_hero.has("caracteristiques"):
			var fic := fiche_hero.duplicate(true)
			var car := (fic.get("caracteristiques", caracteristiques_hero) as Dictionary).duplicate(true)
			car["vigueur"] = int(car.get("vigueur", int(caracteristiques_hero.get("vigueur", 10))))
			fic["caracteristiques"] = car
			fiche_hero = fic

	# Appliquer mana bonus aux ressources initiales
	if total_mana_bonus != 0:
		ressources["mana"] = int(ressources.get("mana", 0)) + total_mana_bonus

	# Persister un résumé des effets pour traçabilité
	profil["computed_effects"] = {"pv_bonus": total_pv_bonus, "mana_bonus": total_mana_bonus}
	profil["computed_effects_applied"] = true
	# Écriture optionnelle : si do_save, sauvegarder le nouveau flag et résumé
	if do_save:
		sauvegarder()


# Gestion d'expérience simple pour le héros
signal niveau_montee(nouveau_niveau: int)

func donner_experience(amount: int) -> void:
	if amount <= 0:
		return
	if fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	var current_xp := int(fiche_hero.get("experience", 0))
	var current_lvl := int(fiche_hero.get("niveau", 1))
	current_xp += int(amount)
	fiche_hero["experience"] = current_xp
	_check_level_up()
	# Notify listeners that experience changed
	emit_signal("ressources_mises_a_jour")


func _check_level_up() -> void:
	var lvl := int(fiche_hero.get("niveau", 1))
	var xp := int(fiche_hero.get("experience", 0))
	var required := 100 * lvl
	var leveled := false
	while xp >= required:
		xp -= required
		lvl += 1
		leveled = true
		required = 100 * lvl
	fiche_hero["niveau"] = lvl
	fiche_hero["experience"] = xp
	if leveled:
		emit_signal("niveau_montee", lvl)
		sauvegarder()


func _find_managed_pnj_index(roster: Array, pnj_id: String) -> int:
	for index in range(roster.size()):
		var pnj := roster[index] as Dictionary
		if str(pnj.get("id", "")) == pnj_id:
			return index
	return -1


func _forcer_magie_pactes() -> void:
	profil_personnage["magie_pactes"] = true
	var competences: Array = (profil_personnage.get("competences_depart", []) as Array).duplicate(true)
	if not competences.has("Magie des Pactes"):
		competences.append("Magie des Pactes")
	profil_personnage["competences_depart"] = competences


func _initialiser_fiches_personnage_et_domaine() -> void:
	fiche_hero = {
		"nom": nom_personnage,
		"classe": classe,
		"profil": profil_personnage.duplicate(true),
		"caracteristiques": caracteristiques_hero.duplicate(true),
		"stats_hero": stats.duplicate(true),
		"niveau": 1,
		"experience": 0,
		"stats_clan": stats_clan.duplicate(true),
	}

	fiches_domaine = {
		"forgeron": {
			"nom": "Forgeron",
			"niveau": 1,
			"specialite": "Armes et armures",
			"actif": false,
			"affinite": int(affinites_pnj.get("forgeron", 0)),
		},
		"alchimiste": {
			"nom": "Alchimiste",
			"niveau": 1,
			"specialite": "Potions et explosifs",
			"actif": false,
			"affinite": int(affinites_pnj.get("alchimiste", 0)),
		},
		"intendant": {
			"nom": "Intendant",
			"niveau": 1,
			"specialite": "Logistique et taxes",
			"actif": false,
			"affinite": int(affinites_pnj.get("intendant", 0)),
		},
		"arcaniste": {
			"nom": "Arcaniste",
			"niveau": 1,
			"specialite": "Rituels et pactes",
			"actif": false,
			"affinite": int(affinites_pnj.get("arcaniste", 0)),
		},
	}


func _ensure_fiche_complete() -> void:
	var fiche := (profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	if fiche.is_empty():
		fiche = {
			"niveau": 1,
			"points_restants": 0,
		}
	if not fiche.has("niveau"):
		fiche["niveau"] = 1
	if not fiche.has("points_restants"):
		fiche["points_restants"] = 0
	fiche["niveau"] = maxi(1, int(fiche.get("niveau", 1)))
	fiche["points_restants"] = maxi(0, int(fiche.get("points_restants", 0)))
	profil_personnage["fiche_complete"] = fiche

## Façade : la corruption reste dans son service et dans le même instantané de sauvegarde.
func get_corruption_service() -> CorruptionService:
	_corruption_service.setup(self)
	if not _corruption_service.has_character("hero"):
		var secondary: Dictionary = get_fiche_complete().get("secondary_stats", {})
		_corruption_service.register_character("hero", clampf(50.0 + float(secondary.get("ESE", 0)) * 2.0, 0.0, 90.0))
	return _corruption_service

func get_corruption_profile(character_id: String) -> Dictionary:
	return get_corruption_service().get_profile(character_id)

func apply_corruption(character_id: String, amount: float, source: String = "", persist: bool = true) -> Dictionary:
	var result := get_corruption_service().apply_corruption(character_id, amount, source)
	if bool(result.get("ok", false)) and persist: sauvegarder()
	return result

func purify_character(character_id: String) -> Dictionary:
	var run: Dictionary = campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)):
		return {"ok": false, "message": "La purification demande de revenir au refuge."}
	var service := get_corruption_service()
	if not service.has_character(character_id) or service.get_corruption_level(character_id) <= 0:
		return {"ok": false, "message": "Aucune corruption à purifier."}
	var cost := {"mana": 4, "nourriture": 1}
	if not peut_payer(cost): return {"ok": false, "message": "Purification : 4 mana et 1 nourriture nécessaires."}
	var result := service.cleanse(character_id, 10.0)
	if not bool(result.get("ok", false)): return result
	payer(cost)
	var message := "Purification : %.1f points dissipés. Coût : 4 mana, 1 nourriture." % -float(result.get("delta", 0.0))
	if not campaign.is_empty(): preload("res://scripts/services/refuge_service.gd").log_entry(self, "Retrouver son équilibre", message)
	sauvegarder()
	result["message"] = message
	return result
