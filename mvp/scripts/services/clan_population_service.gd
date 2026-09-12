## Habitants, domaines et affectations PNJ. Le planning reste exécuté par
## PnjDailyPlannerService ; les profils restent dans ClanState.pnj_gestion.
class_name ClanPopulationService
extends RefCounted
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const CharacterService = preload("res://scripts/services/clan_character_service.gd")
const ROLE_DOMAINES = preload("res://scripts/services/clan_economy_service.gd").DOMAIN_ROLES
var context: ContextType
var _planner: RefCounted
func _init(p_context: ContextType) -> void:
	context = p_context
	_planner = preload("res://scripts/services/pnj_daily_planner_service.gd").new(context)

func modifier_affinite_pnj(role: String, delta: int) -> void:
	if role.is_empty():
		return
	var valeur := clampi(int(context.state.affinites_pnj.get(role, 0)) + delta, -100, 100)
	context.state.affinites_pnj[role] = valeur
	if context.state.fiches_domaine.has(role):
		var fiche := (context.state.fiches_domaine[role] as Dictionary).duplicate(true)
		fiche["affinite"] = valeur
		context.state.fiches_domaine[role] = fiche

func recruter_pnj_domaine() -> String:
	if not bool(context.state.profil_personnage.get("magie_pactes", false)):
		return ""

	for role in ROLE_DOMAINES:
		var fiche := (context.state.fiches_domaine.get(role, {}) as Dictionary).duplicate(true)
		if fiche.is_empty():
			fiche = {
				"nom": role.capitalize(),
				"niveau": 1,
				"specialite": role,
				"actif": false,
				"affinite": int(context.state.affinites_pnj.get(role, 0)),
			}

		if not bool(fiche.get("actif", false)):
			fiche["actif"] = true
			fiche["niveau"] = maxi(1, int(fiche.get("niveau", 1)))
			context.state.fiches_domaine[role] = fiche
			modifier_affinite_pnj(role, 12)
			return role

	return ""

func peut_recruter_pnj_domaine() -> bool:
	for role in ROLE_DOMAINES:
		var fiche := context.state.fiches_domaine.get(role, {}) as Dictionary
		if fiche.is_empty() or not bool(fiche.get("actif", false)):
			return true
	return false

func get_pnj_gestion_state() -> Dictionary:
	_sanitizer_pnj_gestion()
	return context.state.pnj_gestion.duplicate(true)

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
	context.state.pnj_gestion = state
	var corruption: RefCounted = context.corruption
	if not corruption.has_character(pnj_id):
		corruption.register_character(pnj_id, 50.0, traits)
	return fiche.duplicate(true)

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
	context.state.pnj_gestion = state
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
		context.state.pnj_gestion = state
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
		context.state.pnj_gestion = state
	return result

func _sanitizer_pnj_et_domaines() -> void:
	for role in ROLE_DOMAINES:
		context.state.affinites_pnj[role] = clampi(int(context.state.affinites_pnj.get(role, 0)), -100, 100)

	if context.state.fiche_hero.is_empty():
		CharacterService.new(context)._initialiser_fiches_personnage_et_domaine()

	for role in ROLE_DOMAINES:
		if not context.state.fiches_domaine.has(role):
			context.state.fiches_domaine[role] = {
				"nom": role.capitalize(),
				"niveau": 1,
				"specialite": role,
				"actif": false,
				"affinite": int(context.state.affinites_pnj.get(role, 0)),
			}
		else:
			var fiche := (context.state.fiches_domaine[role] as Dictionary).duplicate(true)
			fiche["niveau"] = clampi(int(fiche.get("niveau", 1)), 1, 20)
			fiche["affinite"] = clampi(int(fiche.get("affinite", int(context.state.affinites_pnj.get(role, 0)))), -100, 100)
			context.state.fiches_domaine[role] = fiche

func _sanitizer_pnj_gestion() -> void:
	if context.state.pnj_gestion.is_empty():
		context.state.pnj_gestion = _make_default_pnj_gestion_state()
	if not context.state.pnj_gestion.has("roster") or not (context.state.pnj_gestion.get("roster", []) is Array):
		context.state.pnj_gestion["roster"] = []
	if not context.state.pnj_gestion.has("planning") or not (context.state.pnj_gestion.get("planning", {}) is Dictionary):
		context.state.pnj_gestion["planning"] = _planner.make_daily_plan()
	if not context.state.pnj_gestion.has("last_resolution") or not (context.state.pnj_gestion.get("last_resolution", {}) is Dictionary):
		context.state.pnj_gestion["last_resolution"] = {}

	var sanitized_roster: Array = []
	for pnj_data in context.state.pnj_gestion.get("roster", []):
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
	context.state.pnj_gestion["roster"] = sanitized_roster

	var planning := (context.state.pnj_gestion.get("planning", _planner.make_daily_plan()) as Dictionary).duplicate(true)
	if not planning.has("missions_soldats") or not (planning.get("missions_soldats", []) is Array):
		planning["missions_soldats"] = []
	if not planning.has("missions_pnj") or not (planning.get("missions_pnj", []) is Array):
		planning["missions_pnj"] = []
	context.state.pnj_gestion["planning"] = planning

func _make_default_pnj_gestion_state() -> Dictionary:
	return {
		"roster": [],
		"planning": _planner.make_daily_plan(),
		"last_resolution": {},
	}

func _find_managed_pnj_index(roster: Array, pnj_id: String) -> int:
	for index in range(roster.size()):
		var pnj := roster[index] as Dictionary
		if str(pnj.get("id", "")) == pnj_id:
			return index
	return -1
