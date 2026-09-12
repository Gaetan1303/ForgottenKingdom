## autoload/clan_manager.gd
## Singleton de gestion du clan — état complet de la partie en cours.
## Façade compatible : données res://data/clan/ et sauvegarde user://.
extends Node

const ClanEconomyServiceClass = preload("res://scripts/services/clan_economy_service.gd")
const SoldierAssignmentServiceClass = preload("res://scripts/services/soldier_assignment_service.gd")

const FKHelpers = preload("res://scripts/utils/fk_helpers.gd")
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")
const StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const CorruptionServiceClass = preload("res://scripts/services/corruption_service.gd")
const CreatureRosterServiceClass = preload("res://scripts/services/creature_roster_service.gd")
const PactServiceClass = preload("res://scripts/services/pact_service.gd")
const PnjDailyPlannerServiceClass = preload("res://scripts/services/pnj_daily_planner_service.gd")
const CharacterBuildServiceClass = preload("res://scripts/data/character_build_service.gd")
const PnjGeneratorClass = preload("res://scripts/services/pnj_generator.gd")
const GameLoopStateMachineClass = preload("res://scripts/game_loop/game_loop_state_machine.gd")
const JsonPersistenceServiceClass = preload("res://scripts/services/json_persistence_service.gd")

# ── Chemins ────────────────────────────────────────────────────────────
const DEFAULT_STATE_PATH := "res://data/clan/etat_clan_defaut.json"
const RESSOURCE_KEYS = ClanEconomyServiceClass.RESOURCE_KEYS
const ROLE_DOMAINES = ClanEconomyServiceClass.DOMAIN_ROLES

# ── État du clan ────────────────────────────────────────────────────────
var state = preload("res://scripts/data/clan_state.gd").new()
var service_context = preload("res://scripts/services/clan_service_context.gd").new(state)
var diplomacyService = preload("res://scripts/services/diplomacy_service.gd").new(service_context)
var espionageService = preload("res://scripts/services/espionage_service.gd").new(service_context)
var clanEventService = preload("res://scripts/services/clan_event_service.gd").new(service_context)
var conquestService = preload("res://scripts/services/conquest_service.gd").new(service_context)
var victoryService = preload("res://scripts/services/victory_service.gd").new(service_context)
var character_service = preload("res://scripts/services/clan_character_service.gd").new(service_context)

var nom_clan: String:
	get: return state.nom_clan
	set(value): state.nom_clan = value
var clan_id: String:
	get: return state.clan_id
	set(value): state.clan_id = value
var nom_personnage: String:
	get: return state.nom_personnage
	set(value): state.nom_personnage = value
var classe: String:
	get: return state.classe
	set(value): state.classe = value
var profil_personnage: Dictionary:
	get: return state.profil_personnage
	set(value): state.profil_personnage = value
var stats: Dictionary:
	get: return state.stats
	set(value): state.stats = value
var caracteristiques_hero: Dictionary:
	get: return state.caracteristiques_hero
	set(value): state.caracteristiques_hero = value
var stats_clan: Dictionary:
	get: return state.stats_clan
	set(value): state.stats_clan = value
var ressources: Dictionary:
	get: return state.ressources
	set(value): state.ressources = value
var ressources_par_tour: Dictionary:
	get: return state.ressources_par_tour
	set(value): state.ressources_par_tour = value
var affinites_pnj: Dictionary:
	get: return state.affinites_pnj
	set(value): state.affinites_pnj = value
var fiche_hero: Dictionary:
	get: return state.fiche_hero
	set(value): state.fiche_hero = value
var fiches_domaine: Dictionary:
	get: return state.fiches_domaine
	set(value): state.fiches_domaine = value
var _soldat_next_id: int:
	get: return state._soldat_next_id
	set(value): state._soldat_next_id = value
var _soldats_disponibles: Array:
	get: return state._soldats_disponibles
	set(value): state._soldats_disponibles = value
var barre_ame: int:
	get: return state.barre_ame
	set(value): state.barre_ame = value
var forme_dragon_utilisee: int:
	get: return state.forme_dragon_utilisee
	set(value): state.forme_dragon_utilisee = value
var tour_actuel: int:
	get: return state.tour_actuel
	set(value): state.tour_actuel = value
var moment_journee: String:
	get: return state.moment_journee
	set(value): state.moment_journee = value
var action_jour_effectuee: bool:
	get: return state.action_jour_effectuee
	set(value): state.action_jour_effectuee = value
var action_nuit_effectuee: bool:
	get: return state.action_nuit_effectuee
	set(value): state.action_nuit_effectuee = value
var maisons_nobles: Array:
	get: return state.maisons_nobles
	set(value): state.maisons_nobles = value
var evenements_declenches: Array:
	get: return state.evenements_declenches
	set(value): state.evenements_declenches = value
var historique_tours: Array:
	get: return state.historique_tours
	set(value): state.historique_tours = value
var pnj_gestion: Dictionary:
	get: return state.pnj_gestion
	set(value): state.pnj_gestion = value
var campaign: Dictionary:
	get: return state.campaign
	set(value): state.campaign = value
var daily_phase: String:
	get: return state.daily_phase
	set(value): state.daily_phase = value
var day_report: String:
	get: return state.day_report
	set(value): state.day_report = value
var _bonus_par_action: Dictionary:
	get: return state._bonus_par_action
	set(value): state._bonus_par_action = value
var _corruption_service: RefCounted = CorruptionServiceClass.new()
var _creature_roster_service: RefCounted = CreatureRosterServiceClass.new()
var _pact_service: RefCounted = PactServiceClass.new()
var _day_transition_pending := false

# ── Services (instanciation unique — DRY / SRP) ────────────────────────
var _planner: RefCounted = null
var _economy = service_context.economy
var _soldier_assignment = service_context.soldiers

# Bonus de classe chargés depuis les données

# Signal émis quand le tour avance
signal tour_suivant(numero_tour: int)
signal ressources_mises_a_jour

const SOLDATS_MAX = SoldierAssignmentServiceClass.DEFAULT_MAX_SOLDIERS


func _ready() -> void:
	service_context.save_requested.connect(sauvegarder)
	service_context.level_changed.connect(func(level: int): niveau_montee.emit(level))
	service_context.soul_depleted.connect(_on_soul_depleted)
	service_context.resources_changed.connect(func(): ressources_mises_a_jour.emit())
	service_context.recruitment_requested.connect(_on_recruitment_requested)
	service_context.data_loader = get_node_or_null("/root/GameDataLoader")
	_planner = PnjDailyPlannerServiceClass.new(service_context)
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
	_corruption_service = CorruptionServiceClass.new()
	_creature_roster_service = CreatureRosterServiceClass.new()
	_pact_service = PactServiceClass.new()
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
	_normalize_loaded_character_sheet()

	# La création transmet des scores finaux déjà calculés. Ils sont la vérité à
	# persister : les recalculer ici appliquerait les bonus de classe deux fois.
	var fiche_in_profile: Dictionary = profil_personnage.get("fiche_complete", {}) as Dictionary
	if fiche_in_profile.has("stats_brutes") or fiche_in_profile.has("character_scores"):
		var final_scores: Dictionary = fiche_in_profile.get("character_scores", fiche_in_profile.get("stats_brutes", {})) as Dictionary
		stats = StatDefsClass.sanitize_stats(final_scores, 1, 30, StatDefsClass.CHARACTER_MIN_STAT)
		fiche_in_profile["stats_brutes"] = stats.duplicate(true)
		fiche_in_profile["character_scores"] = stats.duplicate(true)
		fiche_in_profile["modifiers"] = CharacterBuildServiceClass.build_modifiers(stats)
		fiche_in_profile["derived_stats"] = CharacterBuildServiceClass.build_derived_stats(fiche_in_profile["modifiers"] as Dictionary)
		profil_personnage["fiche_complete"] = fiche_in_profile
		_initialiser_fiches_personnage_et_domaine()
		_compute_and_apply_profil_effects(profil_personnage, false)
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
	var pool: Dictionary = _soldier_assignment.build_pool(initial_soldats)
	_soldats_disponibles = pool.pool
	_soldat_next_id = pool.next_id
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

	stats              = StatDefsClass.sanitize_stats(
		(perso.get("stats", stats) as Dictionary),
		StatDefsClass.CLAN_MIN_STAT,
		StatDefsClass.CLAN_MAX_STAT,
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
		var pool: Dictionary = _soldier_assignment.build_pool(count, _soldat_next_id)
		_soldats_disponibles = pool.pool
		_soldat_next_id = pool.next_id
	# Ensure ressources matches available count
	ressources["soldats"] = _soldats_disponibles.size()
	if moment_journee not in ["jour", "nuit"]:
		moment_journee = "jour"


# ─────────────────────────────────────────────────────────────────────
#  GESTION DES RESSOURCES
# ─────────────────────────────────────────────────────────────────────

## Vérifie si le clan peut payer un coût donné.
func peut_payer(cout: Dictionary) -> bool:
	return _economy.can_pay(ressources, cout)


## Débite les ressources (sans vérification — utiliser peut_payer avant).
func payer(cout: Dictionary) -> void:
	_economy.pay(service_context, cout)


## Ajoute des ressources.
func gagner(gains: Dictionary) -> void:
	_economy.gain_state(service_context, gains)


func get_ressources() -> Dictionary:
	return ressources.duplicate(true)


func get_ressource(key: String, default_value: int = 0) -> int:
	return _economy.get_resource(ressources, key, default_value)


func get_stats() -> Dictionary:
	return stats.duplicate(true)


func get_stat(key: String, default_value: int = 5) -> int:
	return int(stats.get(key, default_value))


## Pool helpers: ensure pool and ressources stay in sync when soldiers are added/removed.
func _remove_soldiers(count: int) -> int:
	return _economy.remove_available(service_context, count)


func _add_soldiers(count: int) -> int:
	return _economy.add_available(service_context, count)


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
	return character_service.magie_pactes_active()


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
	var base := ressources_par_tour if not campaign.is_empty() else base_production
	return _economy.total_production(base, fiches_domaine, affinites_pnj)


func get_traits_gameplay() -> Dictionary:
	return character_service.get_traits_gameplay()


func get_action_cout_modifie(action_id: String, cout_base: Dictionary) -> Dictionary:
	return _economy.action_cost(action_id, cout_base, get_traits_gameplay(), _get_traits_caps())


func get_bonus_score_action(action_id: String) -> int:
	return character_service.get_bonus_score_action(action_id)


func appliquer_passifs_nuit() -> String:
	return character_service.appliquer_passifs_nuit()


func get_resume_traits_actifs() -> String:
	return character_service.get_resume_traits_actifs()


func _get_traits_caps() -> Dictionary:
	return character_service._get_traits_caps()


func _calculer_bonus_production_domaines() -> Dictionary:
	return _economy.domain_production(fiches_domaine, affinites_pnj)


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
	var fiche: Dictionary = _planner.make_pnj_profile(pnj_id, pnj_name, pnj_type, role, niveau, pnj_stats, traits)
	var state := get_pnj_gestion_state()
	var roster: Array = (state.get("roster", []) as Array).duplicate(true)
	var index := _find_managed_pnj_index(roster, pnj_id)
	if index >= 0:
		roster[index] = fiche
	else:
		roster.append(fiche)
	state["roster"] = roster
	pnj_gestion = state
	var corruption: RefCounted = get_corruption_service()
	if not corruption.has_character(pnj_id):
		corruption.register_character(pnj_id, 50.0, traits)
	return fiche.duplicate(true)


func planifier_mission_soldats(action_id: String, effectif: int) -> Dictionary:
	_sanitizer_pnj_gestion()
	var result: Dictionary = _soldier_assignment.assign_mission(state, action_id, effectif)
	if bool(result.get("ok", false)): ressources_mises_a_jour.emit()
	return result


func annuler_mission_soldats(index: int) -> Dictionary:
	_sanitizer_pnj_gestion()
	var result: Dictionary = _soldier_assignment.release_mission(state, index)
	if bool(result.get("ok", false)): ressources_mises_a_jour.emit()
	return result


func unassign_soldier_from_mission(index: int, soldier_id: String) -> Dictionary:
	_sanitizer_pnj_gestion()
	var result: Dictionary = _soldier_assignment.release_one(state, index, soldier_id)
	if bool(result.get("ok", false)): ressources_mises_a_jour.emit()
	return result


func adjust_mission_soldier_count(index: int, delta: int) -> Dictionary:
	_sanitizer_pnj_gestion()
	var result: Dictionary = _soldier_assignment.adjust_mission(state, index, delta)
	if bool(result.get("ok", false)): ressources_mises_a_jour.emit()
	return result


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
	_planner.store_resolved_support(result.get("hero_support", {}))

	if not gains.is_empty():
		gagner(gains)

	var soldier_results: Array = result.get("soldier_results", [])
	espionageService.apply_soldier_intelligence(soldier_results)

	# If planner generated events (from failures), apply them now
	var gen_events := (result.get("generated_events", []) as Array).duplicate(true)
	if not gen_events.is_empty():
		for ev in gen_events:
			if ev is Dictionary:
				# Use tirer_et_appliquer_evenement to apply the event effects (probability handled inside)
				var applied_msg := tirer_et_appliquer_evenement([ev])
				if not applied_msg.is_empty():
					print("Event applied: %s" % applied_msg)

	# Les pertes touchent les réservations ; les survivants regagnent le pool.
	_soldier_assignment.resolve_missions(self.state, soldier_results)
	ressources_mises_a_jour.emit()

	# PNJ losses: planner may have already marked PNJ as 'blesse' in returned roster
	var pnj_losses := int(result.get("pnj_losses", 0))
	if pnj_losses > 0:
		# optionally log or record in last_resolution; roster already updated below
		print("PNJ pertes appliquees: %d" % pnj_losses)
	state["roster"] = (result.get("roster", state.get("roster", [])) as Array).duplicate(true)
	state["planning"] = _planner.make_daily_plan()
	state["last_resolution"] = result.duplicate(true)
	state["support"] = pnj_gestion.get("support", {}).duplicate(true)
	pnj_gestion = state
	return result


func advance_day_phase() -> Dictionary:
	if _day_transition_pending:
		return {"ok": false, "message": "Le changement de phase est déjà en cours."}
	_day_transition_pending = true
	var loop: RefCounted = GameLoopStateMachineClass.new(self)
	loop.start()
	var changed: bool = loop.tick_to_next()
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
	return character_service.utiliser_forme_dragon(cout_ame)


# ─────────────────────────────────────────────────────────────────────
#  GESTION DES MAISONS NOBLES
# ─────────────────────────────────────────────────────────────────────

## Retourne les données d'une maison noble par son ID.
func get_maison(id: int) -> Dictionary:
	return conquestService.get_house(id)


## Marque une maison comme espionnée et révèle ses infos.
func espionner_maison(id: int, succes_critique: bool = false) -> void:
	espionageService.reveal_information(id, succes_critique)


## Conquiert un bastion d'une maison noble.
func conquerir_bastion(maison_id: int, bastion_id: String) -> void:
	conquestService.conquer_bastion(maison_id, bastion_id)


func _verifier_maison_soumise(index: int) -> void:
	conquestService.check_submission(index)


## Nombre de maisons soumises (pour vérifier la victoire).
func maisons_soumises() -> int:
	return conquestService.submitted_count()


## Modification de la relation avec une maison noble.
func modifier_relation(maison_id: int, nouvelle_relation: String) -> void:
	diplomacyService.modify_relation(maison_id, nouvelle_relation)


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
	clanEventService.apply_effects(effets)


## Tire au plus un événement aléatoire pour le tour et applique ses effets.
## Retourne un message à afficher dans le log, ou une chaîne vide.
func tirer_et_appliquer_evenement(evenements: Array) -> String:
	return clanEventService.draw_and_apply(evenements)


## Évalue l'état de la partie (en cours / victoire / défaite).
func evaluer_etat_partie() -> Dictionary:
	return victoryService.evaluate()


func _a_alliance_active() -> bool:
	return diplomacyService.has_active_alliance()


func _condition_evenement_valide(condition: String) -> bool:
	return clanEventService.evaluate_conditions(condition)


func _evaluer_clause_condition(clause: String) -> bool:
	return clanEventService._evaluer_clause_condition(clause)


func _valeur_condition(key: String) -> Variant:
	return clanEventService._valeur_condition(key)


func _convertir_condition_value(value: String) -> Variant:
	return clanEventService._convertir_condition_value(value)


func _comparer_condition(a: Variant, b: Variant, op: String) -> bool:
	return clanEventService._comparer_condition(a, b, op)


# ─────────────────────────────────────────────────────────────────────
#  SAUVEGARDE / CHARGEMENT
# ─────────────────────────────────────────────────────────────────────

func sauvegarder() -> void:
	var data: Dictionary = state.export_state()
	data["corruption_state"] = get_corruption_service().export_state()
	data["creature_roster_state"] = _creature_roster_service.export_state()
	data["pact_state"] = _pact_service.export_state()
	var save_path := _get_clan_save_path()
	if not JsonPersistenceServiceClass.write_json_atomic(save_path, data):
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
	_normalize_loaded_character_sheet()
	caracteristiques_hero = (data.get("caracteristiques_hero", caracteristiques_hero) as Dictionary).duplicate(true)
	stats_clan           = (data.get("stats_clan", stats_clan) as Dictionary).duplicate(true)
	affinites_pnj        = (data.get("affinites_pnj", affinites_pnj) as Dictionary).duplicate(true)
	fiche_hero           = (data.get("fiche_hero", fiche_hero) as Dictionary).duplicate(true)
	fiches_domaine       = (data.get("fiches_domaine", fiches_domaine) as Dictionary).duplicate(true)
	pnj_gestion          = (data.get("pnj_gestion", _make_default_pnj_gestion_state()) as Dictionary).duplicate(true)
	campaign             = (data.get("campaign", {}) as Dictionary).duplicate(true)
	_corruption_service = CorruptionServiceClass.new()
	_corruption_service.import_state(data.get("corruption_state", data.get("corruption", {})))
	_corruption_service.setup(self)
	_creature_roster_service = CreatureRosterServiceClass.new()
	_creature_roster_service.import_state(data.get("creature_roster_state", {}) as Dictionary)
	_pact_service = PactServiceClass.new()
	_pact_service.import_state(data.get("pact_state", {}) as Dictionary)
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
	_soldier_assignment.restore_legacy_pool(state, data.has("soldats_disponibles"))
	_sanitizer_pnj_et_domaines()
	_sanitizer_pnj_gestion()
	if moment_journee not in ["jour", "nuit"]:
		moment_journee = "jour"

	emit_signal("ressources_mises_a_jour")
	return true


func get_profil_personnage() -> Dictionary:
	return character_service.get_profil_personnage()


func get_fiche_complete() -> Dictionary:
	return character_service.get_fiche_complete()


func get_personnage_niveau() -> int:
	return character_service.get_personnage_niveau()


func get_personnage_points_restants() -> int:
	return character_service.get_personnage_points_restants()


func get_personnage_feats() -> Array:
	return character_service.get_personnage_feats()


func get_personnage_portrait_path() -> String:
	return character_service.get_personnage_portrait_path()


func set_personnage_portrait(payload: Dictionary, do_save: bool = false) -> void:
	character_service.set_personnage_portrait(payload, do_save)


func get_personnage_experience() -> int:
	return character_service.get_personnage_experience()


func get_personnage_xp_for_next_level() -> int:
	return character_service.get_personnage_xp_for_next_level()


func is_personnage_xp_full() -> bool:
	return character_service.is_personnage_xp_full()


func apply_profile_sheet_update(stats_update: Dictionary, points_remaining: int, feats: Array = []) -> void:
	character_service.apply_profile_sheet_update(stats_update, points_remaining, feats)


func level_up_personnage(points_awarded: int = 10) -> Dictionary:
	return character_service.level_up_personnage(points_awarded)


## Lance un dé à N faces.
func lancer_de(faces: int = 20) -> int:
	return character_service.lancer_de(faces)


## Calcule le score d'une action (stat principale + stat secondaire + dé).
func calculer_score_action(stat_principale: String, stat_secondaire: String = "") -> int:
	return character_service.calculer_score_action(stat_principale, stat_secondaire)


# ─────────────────────────────────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────────────────────────────────

func partie_en_cours() -> bool:
	return (nom_clan != "" and tour_actuel > 0) or FileAccess.file_exists(_get_clan_save_path())


func _get_clan_save_path() -> String:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return "user://slots/slot_1/clan.json"
	return save_system.get_clan_save_path()


func _lire_json(path: String) -> Dictionary:
	return JsonPersistenceServiceClass.read_json_with_backup(path)


func _sanitizer_stats() -> void:
	character_service._sanitizer_stats()


func _sanitizer_ressources() -> void:
	ressources = _economy.sanitize(ressources, true)
	ressources_par_tour = _economy.sanitize(ressources_par_tour, true, false)


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
	character_service._compute_and_apply_profil_effects(profil, do_save)


# Gestion d'expérience simple pour le héros
signal niveau_montee(nouveau_niveau: int)

func donner_experience(amount: int) -> void:
	character_service.donner_experience(amount)


func _check_level_up() -> void:
	character_service._check_level_up()


func _find_managed_pnj_index(roster: Array, pnj_id: String) -> int:
	for index in range(roster.size()):
		var pnj := roster[index] as Dictionary
		if str(pnj.get("id", "")) == pnj_id:
			return index
	return -1


func _forcer_magie_pactes() -> void:
	character_service._forcer_magie_pactes()


func _initialiser_fiches_personnage_et_domaine() -> void:
	character_service._initialiser_fiches_personnage_et_domaine()


func _ensure_fiche_complete() -> void:
	character_service._ensure_fiche_complete()


func _normalize_loaded_character_sheet() -> void:
	character_service._normalize_loaded_character_sheet()

## Façade : la corruption reste dans son service et dans le même instantané de sauvegarde.
func get_corruption_service() -> RefCounted:
	_corruption_service.setup(self)
	if not _corruption_service.has_character("hero"):
		var secondary: Dictionary = get_fiche_complete().get("secondary_stats", {})
		_corruption_service.register_character("hero", clampf(50.0 + float(secondary.get("ESE", 0)) * 2.0, 0.0, 90.0))
	return _corruption_service


func get_creature_roster_service() -> RefCounted:
	return _creature_roster_service


func get_pact_service() -> RefCounted:
	return _pact_service


func assign_creature_to_pnj(creature_id: String, pnj_id: String, assignment_type: int) -> Dictionary:
	var creature: Resource = _creature_roster_service.get_profile_by_id(creature_id)
	if creature == null:
		return {"ok": false, "error": "creature_introuvable"}
	var corruption: RefCounted = get_corruption_service()
	corruption.register_creature(creature)
	return corruption.assign_creature_to_target(creature_id, pnj_id, assignment_type)


func start_pnj_training(pnj_id: String, training_type: int) -> Dictionary:
	return get_corruption_service().start_training(pnj_id, training_type)


func process_corruption_tick(delta: float) -> void:
	get_corruption_service().process_tick(delta)

func get_corruption_profile(character_id: String) -> Dictionary:
	return get_corruption_service().get_profile(character_id)

func apply_corruption(character_id: String, amount: float, source: String = "", persist: bool = true) -> Dictionary:
	var result: Dictionary = get_corruption_service().apply_corruption(character_id, amount, source)
	if bool(result.get("ok", false)) and persist: sauvegarder()
	return result

func purify_character(character_id: String) -> Dictionary:
	var run: Dictionary = campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)):
		return {"ok": false, "message": "La purification demande de revenir au refuge."}
	var service: RefCounted = get_corruption_service()
	if not service.has_character(character_id) or service.get_corruption_level(character_id) <= 0:
		return {"ok": false, "message": "Aucune corruption à purifier."}
	var cost := {"mana": 4, "nourriture": 1}
	if not peut_payer(cost): return {"ok": false, "message": "Purification : 4 mana et 1 nourriture nécessaires."}
	var result: Dictionary = service.cleanse(character_id, 10.0)
	if not bool(result.get("ok", false)): return result
	payer(cost)
	var message := "Purification : %.1f points dissipés. Coût : 4 mana, 1 nourriture." % -float(result.get("delta", 0.0))
	if not campaign.is_empty(): preload("res://scripts/services/refuge_service.gd").log_entry(self, "Retrouver son équilibre", message)
	sauvegarder()
	result["message"] = message
	return result


func _require_autoload(autoload_name: String) -> Node:
	var node: Node = get_node_or_null("/root/%s" % autoload_name)
	if node == null:
		push_error("ClanManager: autoload requis introuvable : %s" % autoload_name)
	return node

func _on_recruitment_requested(role: String) -> void:
	PnjGeneratorClass.new().generate_and_register_pnj(role, "recrute")

func get_pnj_support_bonus(action_id: String) -> int:
	return _planner.support_bonus(action_id)

func consume_pnj_support(action_id: String) -> int:
	return _planner.consume_support(action_id)

func _on_soul_depleted() -> void:
	var manager := _require_autoload("GameManager")
	if manager != null: manager.declencher_bad_end_dragon()
