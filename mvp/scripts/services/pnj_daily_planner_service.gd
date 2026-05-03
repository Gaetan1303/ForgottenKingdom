extends RefCounted
class_name PnjDailyPlannerService

# rely on StatDefs class_name from data/stat_defs.gd

const ROOM_ORDER := ["combat_faible", "evenement_aleatoire", "repos", "boss"]
const SOLDIER_ACTIONS := {
	"collecter_bois": {"resource": "bois", "rate": 2},
	"collecter_fer": {"resource": "fer", "rate": 1},
	"collecter_pierre": {"resource": "pierre", "rate": 1},
	"collecter_nourriture": {"resource": "nourriture", "rate": 2},
	"espionner": {"resource": "renseignements", "rate": 1},
	"securiser": {"resource": "reputation", "rate": 1},
}
const SUPPORT_STATS := {
	"attaquer": ["commandement", "force"],
	"espionner": ["espionnage", "commandement"],
	"diplomatie": ["diplomatie", "commandement"],
	"fortifier": ["artisanat", "commandement"],
	"recuperer": ["magie", "diplomatie"],
}
const ROLE_BONUS := {
	"stratege": {"attaquer": 2, "fortifier": 1},
	"eclaireur": {"espionner": 2, "attaquer": 1},
	"mage": {"recuperer": 2, "attaquer": 1},
	"diplomate": {"diplomatie": 2},
}


func make_daily_plan() -> Dictionary:
	return {
		"phase": "matin",
		"missions_soldats": [],
		"missions_pnj": [],
	}


func make_pnj_profile(
	pnj_id: String,
	pnj_name: String,
	pnj_type: String,
	role: String,
	niveau: int,
	stats: Dictionary,
	traits: Array = []
) -> Dictionary:
	return {
		"id": pnj_id,
		"nom": pnj_name,
		"type": pnj_type,
		"role": role,
		"niveau": clampi(niveau, 1, 20),
		"stats": StatDefs.sanitize_stats(stats, StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT, StatDefs.CHARACTER_MIN_STAT),
		"traits": traits.duplicate(true),
		"etat": "disponible",
	}


func assign_soldiers(planning: Dictionary, action_id: String, effectif: int, available_soldats: int) -> Dictionary:
	if not SOLDIER_ACTIONS.has(action_id):
		return {"ok": false, "error": "action_soldats_invalide"}
	if effectif <= 0:
		return {"ok": false, "error": "effectif_invalide"}
	if _get_assigned_soldiers(planning) + effectif > available_soldats:
		return {"ok": false, "error": "soldats_insuffisants"}

	var next_plan: Dictionary = planning.duplicate(true)
	var missions: Array = (next_plan.get("missions_soldats", []) as Array).duplicate(true)
	missions.append({
		"action_id": action_id,
		"effectif": effectif,
	})
	next_plan["missions_soldats"] = missions
	return {"ok": true, "planning": next_plan}


func assign_pnj_support(roster: Array, planning: Dictionary, pnj_id: String, hero_action_id: String) -> Dictionary:
	var index := _find_pnj_index(roster, pnj_id)
	if index < 0:
		return {"ok": false, "error": "pnj_introuvable"}
	if _pnj_is_locked(roster[index] as Dictionary, planning, pnj_id):
		return {"ok": false, "error": "pnj_indisponible"}

	var next_roster: Array = roster.duplicate(true)
	var next_plan: Dictionary = planning.duplicate(true)
	var missions: Array = (next_plan.get("missions_pnj", []) as Array).duplicate(true)
	missions.append({
		"pnj_id": pnj_id,
		"mission_type": "support",
		"hero_action_id": hero_action_id,
	})
	next_plan["missions_pnj"] = missions
	var pnj := (next_roster[index] as Dictionary).duplicate(true)
	pnj["etat"] = "assigne"
	next_roster[index] = pnj
	return {"ok": true, "planning": next_plan, "roster": next_roster}


func assign_pnj_expedition(roster: Array, planning: Dictionary, pnj_id: String, seed_value: int = -1) -> Dictionary:
	var index := _find_pnj_index(roster, pnj_id)
	if index < 0:
		return {"ok": false, "error": "pnj_introuvable"}
	if _pnj_is_locked(roster[index] as Dictionary, planning, pnj_id):
		return {"ok": false, "error": "pnj_indisponible"}

	var next_roster: Array = roster.duplicate(true)
	var next_plan: Dictionary = planning.duplicate(true)
	var expedition := build_expedition(next_roster[index] as Dictionary, seed_value)
	var missions: Array = (next_plan.get("missions_pnj", []) as Array).duplicate(true)
	missions.append({
		"pnj_id": pnj_id,
		"mission_type": "expedition",
		"expedition": expedition,
	})
	next_plan["missions_pnj"] = missions
	var pnj := (next_roster[index] as Dictionary).duplicate(true)
	pnj["etat"] = "en_expedition"
	next_roster[index] = pnj
	return {"ok": true, "planning": next_plan, "roster": next_roster}


func build_expedition(pnj: Dictionary, seed_value: int = -1) -> Dictionary:
	var final_seed := seed_value
	if final_seed < 0:
		final_seed = int(Time.get_unix_time_from_system()) + int(pnj.get("niveau", 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = final_seed
	var primary_stat := _get_primary_expedition_stat(pnj)
	var event_kind := "piege" if rng.randi_range(0, 1) == 0 else "bonus"
	return {
		"expedition_id": "%s_%d" % [str(pnj.get("id", "pnj")), final_seed],
		"pnj_id": str(pnj.get("id", "")),
		"seed": final_seed,
		"rooms": [
			{"index": 1, "type": "combat_faible", "primary_stat": primary_stat},
			{"index": 2, "type": "evenement_aleatoire", "event_kind": event_kind},
			{"index": 3, "type": "repos", "recovery": 1},
			{"index": 4, "type": "boss", "primary_stat": primary_stat},
		],
		"index_salle": 0,
		"etat": "en_cours",
		"journal": [],
		"recompenses": {},
		"penalites": {},
	}


func resolve_expedition(pnj: Dictionary, expedition: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(expedition.get("seed", 0))
	var working_pnj: Dictionary = pnj.duplicate(true)
	var rooms: Array = (expedition.get("rooms", []) as Array).duplicate(true)
	var journal: Array[String] = []
	var recompenses := {"or": 0, "essence": 0, "renseignements": 0}
	var penalites := {"blessure": 0}
	var momentum := 0
	var wounds := 0

	for room_data in rooms:
		var room := room_data as Dictionary
		match str(room.get("type", "")):
			"combat_faible":
				var combat_score := _room_roll(rng, working_pnj, str(room.get("primary_stat", "force")), 7)
				if combat_score >= 12:
					journal.append("Combat faible nettoye")
					recompenses["or"] = int(recompenses.get("or", 0)) + 8
					momentum += 1
				else:
					journal.append("Combat faible laborieux")
					wounds += 1
					penalites["blessure"] = wounds
			"evenement_aleatoire":
				if str(room.get("event_kind", "piege")) == "bonus":
					journal.append("Evenement favorable")
					recompenses["renseignements"] = int(recompenses.get("renseignements", 0)) + 1
					momentum += 1
				else:
					var trap_score := _room_roll(rng, working_pnj, "espionnage", 5)
					if trap_score >= 11:
						journal.append("Piege esquive")
					else:
						journal.append("Piege subi")
						wounds += 1
						penalites["blessure"] = wounds
			"repos":
				if wounds > 0:
					wounds -= 1
					penalites["blessure"] = wounds
					journal.append("Repos reparateur")
				else:
					momentum += 1
					journal.append("Repos strategique")
			"boss":
				var boss_score := _room_roll(rng, working_pnj, str(room.get("primary_stat", "force")), 9) + momentum - wounds
				if boss_score >= 15:
					journal.append("Boss vaincu")
					recompenses["or"] = int(recompenses.get("or", 0)) + 20 + int(working_pnj.get("niveau", 1)) * 3
					recompenses["essence"] = int(recompenses.get("essence", 0)) + 1
					working_pnj["etat"] = "disponible"
				elif boss_score >= 11:
					journal.append("Retraite apres le boss")
					recompenses["renseignements"] = int(recompenses.get("renseignements", 0)) + 1
					working_pnj["etat"] = "blesse"
					wounds += 1
					penalites["blessure"] = wounds
				else:
					journal.append("Boss trop puissant")
					working_pnj["etat"] = "blesse"
					wounds += 1
					penalites["blessure"] = wounds

	var outcome := "succes"
	if str(working_pnj.get("etat", "disponible")) == "blesse":
		outcome = "retour_blesse"

	return {
		"pnj_id": str(working_pnj.get("id", "")),
		"seed": int(expedition.get("seed", 0)),
		"outcome": outcome,
		"etat": str(working_pnj.get("etat", "disponible")),
		"journal": journal,
		"recompenses": recompenses,
		"penalites": penalites,
		"pnj": working_pnj,
	}


func resolve_daily_plan(roster: Array, planning: Dictionary) -> Dictionary:
	var next_roster: Array = roster.duplicate(true)
	var hero_support := {}
	var soldier_results: Array = []
	var expeditions: Array = []
	var resource_gains := {
		"or": 0,
		"bois": 0,
		"fer": 0,
		"pierre": 0,
		"nourriture": 0,
		"essence": 0,
		"renseignements": 0,
		"reputation": 0,
	}
	var reports: Array[String] = []
	var generated_events: Array = []
	var total_soldier_losses: int = 0
	var total_pnj_losses: int = 0
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for mission_data in planning.get("missions_soldats", []):
		var mission := mission_data as Dictionary
		var soldier_report := _resolve_soldier_mission(mission)
		soldier_results.append(soldier_report)
		reports.append(str(soldier_report.get("message", "")))
		_accumulate_resources(resource_gains, soldier_report.get("gains", {}) as Dictionary)
		if soldier_report.has("soldier_losses"):
			total_soldier_losses += int(soldier_report.get("soldier_losses", 0))

		# If soldier mission produced a PNJ loss request (e.g., catastrophic failure), apply to roster
		if soldier_report.has("pnj_loss_pct"):
			var pct := int(soldier_report.get("pnj_loss_pct", 0))
			if pct > 0 and next_roster.size() > 0:
				var loss_count := int(floor(float(next_roster.size()) * float(pct) / 100.0))
				loss_count = max(0, loss_count)
				if loss_count > 0:
					var indices := []
					while indices.size() < loss_count and indices.size() < next_roster.size():
						var idx := rng.randi_range(0, next_roster.size() - 1)
						if not indices.has(idx):
							indices.append(idx)
					# mark selected PNJ as blesse
					for idxx in indices:
						var pnj := (next_roster[idxx] as Dictionary).duplicate(true)
						pnj["etat"] = "blesse"
						next_roster[idxx] = pnj
					total_pnj_losses += indices.size()
					reports.append("Échec massif: %d PNJ blessés" % indices.size())

		# collect generated events from soldier missions
		if soldier_report.has("generated_event"):
			var gev := soldier_report.get("generated_event", {}) as Dictionary
			if not gev.is_empty():
				generated_events.append(gev)

	for mission_data in planning.get("missions_pnj", []):
		var mission := mission_data as Dictionary
		var pnj_index := _find_pnj_index(next_roster, str(mission.get("pnj_id", "")))
		if pnj_index < 0:
			continue
		var pnj := (next_roster[pnj_index] as Dictionary).duplicate(true)
		match str(mission.get("mission_type", "")):
			"support":
				var hero_action_id := str(mission.get("hero_action_id", ""))
				var bonus := compute_support_bonus(pnj, hero_action_id)
				hero_support[hero_action_id] = int(hero_support.get(hero_action_id, 0)) + bonus
				reports.append("%s soutient %s (+%d)" % [str(pnj.get("nom", pnj.get("id", "PNJ"))), hero_action_id, bonus])
				pnj["etat"] = "disponible"
				next_roster[pnj_index] = pnj
			"expedition":
				var report: Dictionary = resolve_expedition(pnj, mission.get("expedition", {}) as Dictionary)
				expeditions.append(report)
				reports.append("Expedition %s: %s" % [str(pnj.get("nom", pnj.get("id", "PNJ"))), str(report.get("outcome", ""))])
				_accumulate_resources(resource_gains, report.get("recompenses", {}) as Dictionary)
				next_roster[pnj_index] = (report.get("pnj", pnj) as Dictionary).duplicate(true)

	return {
		"hero_support": hero_support,
		"soldier_results": soldier_results,
		"expeditions": expeditions,
		"resource_gains": resource_gains,
		"soldier_losses": total_soldier_losses,
		"pnj_losses": total_pnj_losses,
		"generated_events": generated_events,
		"roster": next_roster,
		"reports": reports,
	}


func compute_support_bonus(pnj: Dictionary, hero_action_id: String) -> int:
	var weights: Array = SUPPORT_STATS.get(hero_action_id, ["commandement"]) as Array
	var stats: Dictionary = pnj.get("stats", {}) as Dictionary
	var total := 0
	for stat_name in weights:
		total += int(stats.get(str(stat_name), StatDefs.CHARACTER_MIN_STAT))
	var bonus := int(round(total / maxf(1.0, float(weights.size()) * 3.0)))
	bonus += int(pnj.get("niveau", 1)) / 2
	bonus += int((ROLE_BONUS.get(str(pnj.get("role", "")), {}) as Dictionary).get(hero_action_id, 0))
	return clampi(bonus, 1, 6)


func _resolve_soldier_mission(mission: Dictionary) -> Dictionary:
	var action_id := str(mission.get("action_id", ""))
	var effectif := maxi(0, int(mission.get("effectif", 0)))
	var config := SOLDIER_ACTIONS.get(action_id, {}) as Dictionary
	if config.is_empty():
		return {"gains": {}, "message": "Mission soldats invalide"}
	var resource_key := str(config.get("resource", ""))
	var rate := maxi(1, int(config.get("rate", 1)))
	var amount := maxi(1, int(floor(float(effectif * rate) / 4.0)))

	# Resource gathering: small attrition (1% floor)
	if action_id.begins_with("collecter_"):
		var losses: int = int(effectif / 100) # floor 1%
		return {
			"action_id": action_id,
			"gains": {resource_key: amount},
			"soldier_losses": losses,
			"message": "Soldats %s: %+d %s (pertes: %d)" % [action_id, amount, resource_key, losses],
		}

	# Other soldier actions (espionner, securiser): RNG success/failure
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var success_chance := 0.7
	var ok := rng.randf() <= success_chance
	if ok:
		# success: apply gains and moderate attrition (5%)
		var losses_succ: int = int(floor(float(effectif) * 0.05))
		return {
			"action_id": action_id,
			"gains": {resource_key: amount},
			"soldier_losses": losses_succ,
			"message": "Succès soldats %s: %+d %s (pertes: %d)" % [action_id, amount, resource_key, losses_succ],
		}
	else:
		# failure: no gains, trigger PNJ losses (50%) as catastrophic event
		var ev := {
			"id": "catastrophe_%s_%d" % [action_id, randi()],
			"titre": "Échec critique",
			"texte": "Échec critique de la mission %s — conséquences graves." % action_id,
			"probabilite": 1.0,
			"effets": {
				"soldats_perte_pct": 50,
			}
		}
		return {
			"action_id": action_id,
			"gains": {},
			"pnj_loss_pct": 50,
			"generated_event": ev,
			"message": "Échec critique sur %s — événement généré." % action_id,
		}


func _accumulate_resources(target: Dictionary, gains: Dictionary) -> void:
	for key in gains.keys():
		target[key] = int(target.get(key, 0)) + int(gains.get(key, 0))


func _pnj_is_locked(pnj: Dictionary, planning: Dictionary, pnj_id: String) -> bool:
	var state := str(pnj.get("etat", "disponible"))
	if state in ["blesse", "indisponible", "assigne", "en_expedition"]:
		return true
	for mission_data in planning.get("missions_pnj", []):
		var mission := mission_data as Dictionary
		if str(mission.get("pnj_id", "")) == pnj_id:
			return true
	return false


func _find_pnj_index(roster: Array, pnj_id: String) -> int:
	for index in range(roster.size()):
		var pnj := roster[index] as Dictionary
		if str(pnj.get("id", "")) == pnj_id:
			return index
	return -1


func _get_assigned_soldiers(planning: Dictionary) -> int:
	var total := 0
	for mission_data in planning.get("missions_soldats", []):
		var mission := mission_data as Dictionary
		total += maxi(0, int(mission.get("effectif", 0)))
	return total


func _get_primary_expedition_stat(pnj: Dictionary) -> String:
	var stats: Dictionary = pnj.get("stats", {}) as Dictionary
	var candidates := ["commandement", "magie", "force", "espionnage"]
	var best_stat := "force"
	var best_value := -1
	for stat_name in candidates:
		var value := int(stats.get(stat_name, StatDefs.CHARACTER_MIN_STAT))
		if value > best_value:
			best_value = value
			best_stat = stat_name
	return best_stat


func _room_roll(rng: RandomNumberGenerator, pnj: Dictionary, stat_name: String, dice_sides: int) -> int:
	var stats: Dictionary = pnj.get("stats", {}) as Dictionary
	return int(stats.get(stat_name, StatDefs.CHARACTER_MIN_STAT)) + int(pnj.get("niveau", 1)) + rng.randi_range(1, dice_sides)