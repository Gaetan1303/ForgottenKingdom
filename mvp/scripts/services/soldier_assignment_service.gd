## Gère la réservation de soldats par identifiants sans dépendre du ClanManager.
class_name SoldierAssignmentService
extends RefCounted

const SOLDIER_ACTIONS := {
	"collecter_bois": {"resource": "bois", "rate": 2},
	"collecter_fer": {"resource": "fer", "rate": 1},
	"collecter_pierre": {"resource": "pierre", "rate": 1},
	"collecter_nourriture": {"resource": "nourriture", "rate": 2},
	"espionner": {"resource": "renseignements", "rate": 1},
	"securiser": {"resource": "reputation", "rate": 1},
}

const SOLDIER_PREFIX := "S"
const DEFAULT_MAX_SOLDIERS := 600


func build_pool(count: int, start_id: int = 1, max_soldiers: int = DEFAULT_MAX_SOLDIERS) -> Dictionary:
	var pool: Array = []
	var next_id := maxi(1, start_id)
	var amount := clampi(count, 0, maxi(0, max_soldiers))
	for _index in range(amount):
		pool.append("%s%d" % [SOLDIER_PREFIX, next_id])
		next_id += 1
	return {"pool": pool, "next_id": next_id}


func assign(pool: Array, assignments: Dictionary, mission_id: String, count: int) -> Dictionary:
	var key := mission_id.strip_edges()
	if key.is_empty():
		return _error(pool, assignments, "mission_id_invalide")
	if count <= 0:
		return _error(pool, assignments, "effectif_invalide")
	if assignments.has(key):
		return _error(pool, assignments, "mission_deja_assignee")
	if pool.size() < count:
		return _error(pool, assignments, "soldats_insuffisants")

	var next_pool := pool.duplicate(true)
	var assigned: Array = []
	for _index in range(count):
		assigned.append(next_pool.pop_front())
	var next_assignments := assignments.duplicate(true)
	next_assignments[key] = assigned.duplicate(true)
	return {
		"ok": true,
		"pool": next_pool,
		"assignments": next_assignments,
		"assigned_ids": assigned,
	}


func release(pool: Array, assignments: Dictionary, mission_id: String) -> Dictionary:
	var key := mission_id.strip_edges()
	if not assignments.has(key):
		return _error(pool, assignments, "mission_introuvable")
	var next_pool := pool.duplicate(true)
	var released := (assignments.get(key, []) as Array).duplicate(true)
	for soldier_id in released:
		if not next_pool.has(soldier_id):
			next_pool.append(soldier_id)
	var next_assignments := assignments.duplicate(true)
	next_assignments.erase(key)
	return {
		"ok": true,
		"pool": next_pool,
		"assignments": next_assignments,
		"released_ids": released,
	}


func adjust(pool: Array, assignments: Dictionary, mission_id: String, delta: int) -> Dictionary:
	var key := mission_id.strip_edges()
	if not assignments.has(key):
		return _error(pool, assignments, "mission_introuvable")
	if delta == 0:
		return {"ok": true, "pool": pool.duplicate(true), "assignments": assignments.duplicate(true)}

	var next_pool := pool.duplicate(true)
	var next_assignments := assignments.duplicate(true)
	var assigned := (next_assignments.get(key, []) as Array).duplicate(true)
	if delta > 0:
		if next_pool.size() < delta:
			return _error(pool, assignments, "soldats_insuffisants")
		for _index in range(delta):
			assigned.append(next_pool.pop_front())
	else:
		var release_count := mini(-delta, assigned.size())
		for _index in range(release_count):
			var soldier_id: Variant = assigned.pop_back()
			if not next_pool.has(soldier_id):
				next_pool.append(soldier_id)
	next_assignments[key] = assigned
	return {"ok": true, "pool": next_pool, "assignments": next_assignments, "assigned_ids": assigned.duplicate(true)}


func apply_losses(assignments: Dictionary, mission_id: String, loss_count: int) -> Dictionary:
	var key := mission_id.strip_edges()
	if not assignments.has(key):
		return {"ok": false, "error": "mission_introuvable", "assignments": assignments.duplicate(true), "lost_ids": []}
	var next_assignments := assignments.duplicate(true)
	var assigned := (next_assignments.get(key, []) as Array).duplicate(true)
	var lost: Array = []
	for _index in range(mini(maxi(0, loss_count), assigned.size())):
		lost.append(assigned.pop_back())
	next_assignments[key] = assigned
	return {"ok": true, "assignments": next_assignments, "lost_ids": lost, "survivor_ids": assigned.duplicate(true)}


func add_soldiers(pool: Array, count: int, next_id: int, max_soldiers: int = DEFAULT_MAX_SOLDIERS) -> Dictionary:
	var next_pool := pool.duplicate(true)
	var cursor := maxi(1, next_id)
	var added: Array = []
	for _index in range(maxi(0, count)):
		if next_pool.size() >= max_soldiers:
			break
		var soldier_id := "%s%d" % [SOLDIER_PREFIX, cursor]
		cursor += 1
		if next_pool.has(soldier_id):
			continue
		next_pool.append(soldier_id)
		added.append(soldier_id)
	return {"pool": next_pool, "next_id": cursor, "added_ids": added}


func count_assigned(assignments: Dictionary) -> int:
	var total := 0
	for mission_id in assignments.keys():
		var ids := assignments.get(mission_id, []) as Array
		total += ids.size()
	return total


func _error(pool: Array, assignments: Dictionary, code: String) -> Dictionary:
	return {
		"ok": false,
		"error": code,
		"pool": pool.duplicate(true),
		"assignments": assignments.duplicate(true),
	}


## Alias métier : réserver des soldats pour une mission.
func reserve(pool: Array, assignments: Dictionary, mission_id: String, count: int) -> Dictionary:
	return assign(pool, assignments, mission_id, count)


func cancel(pool: Array, assignments: Dictionary, mission_id: String) -> Dictionary:
	return release(pool, assignments, mission_id)


## Retire les derniers IDs disponibles, comme le débit historique de ClanManager.
func remove_soldiers(pool: Array, count: int) -> Dictionary:
	var next_pool := pool.duplicate(true)
	var removed: Array = []
	for _index in range(mini(maxi(0, count), next_pool.size())):
		removed.append(next_pool.pop_back())
	return {"pool": next_pool, "removed_ids": removed}

## Adaptateurs du format de planning historique. Les allocations restent dans
## pnj_gestion.planning.missions_soldats[].assigned, jamais dans un second registre.
func _missions(state) -> Array:
	return state.pnj_gestion.get("planning", {}).get("missions_soldats", [])

func _sync(state) -> void:
	state.ressources["soldats"] = state._soldats_disponibles.size()

func restore_legacy_pool(state, has_pool: bool) -> void:
	# Avancer au-delà de tous les IDs conservés avant de matérialiser les anciens effectifs.
	var used: Array = state._soldats_disponibles.duplicate()
	for mission in _missions(state): used.append_array(mission.get("assigned", []))
	for id in used:
		if str(id).begins_with("S"):
			state._soldat_next_id = maxi(state._soldat_next_id, int(str(id).substr(1)) + 1)
	if not has_pool:
		var pool := build_pool(int(state.ressources.get("soldats", 0)), state._soldat_next_id)
		state._soldats_disponibles = pool.pool
		state._soldat_next_id = pool.next_id
	for mission in _missions(state): _materialize_legacy(state, mission)
	_sync(state)

func _materialize_legacy(state, mission: Dictionary) -> void:
	if mission.has("assigned"): return
	var pool := build_pool(maxi(0, int(mission.get("effectif", 0))), state._soldat_next_id)
	mission["assigned"] = pool.pool
	mission["effectif"] = pool.pool.size()
	state._soldat_next_id = pool.next_id

func assign_mission(state, action_id: String, count: int) -> Dictionary:
	if not SOLDIER_ACTIONS.has(action_id): return {"ok": false, "error": "action_soldats_invalide"}
	var allocation := assign(state._soldats_disponibles, {}, "mission", count)
	if not allocation.ok: return {"ok": false, "error": allocation.error}
	var missions := _missions(state)
	missions.append({"action_id": action_id, "effectif": count, "assigned": allocation.assigned_ids})
	state.pnj_gestion.planning["missions_soldats"] = missions
	state._soldats_disponibles = allocation.pool
	_sync(state)
	return {"ok": true, "planning": state.pnj_gestion.planning.duplicate(true), "assigned": count}

func release_mission(state, index: int) -> Dictionary:
	var missions := _missions(state)
	if index < 0 or index >= missions.size(): return {"ok": false, "error": "index_invalide"}
	var mission: Dictionary = missions[index]
	_materialize_legacy(state, mission)
	var allocation := release(state._soldats_disponibles, {"mission": mission.assigned}, "mission")
	state._soldats_disponibles = allocation.pool
	missions.remove_at(index)
	_sync(state)
	return {"ok": true, "planning": state.pnj_gestion.planning.duplicate(true)}

func adjust_mission(state, index: int, delta: int) -> Dictionary:
	var missions := _missions(state)
	if index < 0 or index >= missions.size(): return {"ok": false, "error": "index_invalide"}
	if delta == 0: return {"ok": false, "error": "delta_zero"}
	var mission: Dictionary = missions[index]
	_materialize_legacy(state, mission)
	var count := mini(delta, state._soldats_disponibles.size()) if delta > 0 else -mini(-delta, mission.assigned.size())
	if delta < 0 and count == 0: return {"ok": false, "error": "aucun_soldat_a_retirer"}
	var allocation := adjust(state._soldats_disponibles, {"mission": mission.assigned}, "mission", count)
	state._soldats_disponibles = allocation.pool
	mission.assigned = allocation.assignments.mission
	mission.effectif = count_assigned(allocation.assignments)
	if mission.effectif == 0: missions.remove_at(index)
	_sync(state)
	var result := {"ok": true, "planning": state.pnj_gestion.planning.duplicate(true)}
	if delta > 0:
		result["assigned"] = count
		if count < delta: result["warning"] = "insufficient"
	else: result["removed"] = -count
	return result

func release_one(state, index: int, soldier_id: String) -> Dictionary:
	var missions := _missions(state)
	if index < 0 or index >= missions.size(): return {"ok": false, "error": "index_invalide"}
	var mission: Dictionary = missions[index]
	_materialize_legacy(state, mission)
	var ids: Array = mission.assigned
	if ids.is_empty(): return {"ok": false, "error": "aucun_soldat_assign"}
	if soldier_id not in ids: return {"ok": false, "error": "soldat_non_present"}
	# Placer l'ID demandé en fin pour utiliser l'unique opération adjust/release.
	ids.erase(soldier_id)
	ids.append(soldier_id)
	var result := adjust_mission(state, index, -1)
	result.erase("removed")
	return result

func resolve_missions(state, reports: Array) -> void:
	var missions := _missions(state)
	for index in range(missions.size()):
		var mission: Dictionary = missions[index]
		_materialize_legacy(state, mission)
		var losses := int(reports[index].get("soldier_losses", 0)) if index < reports.size() else 0
		var allocation := apply_losses({"mission": mission.assigned}, "mission", losses)
		var returned := release(state._soldats_disponibles, allocation.assignments, "mission")
		state._soldats_disponibles = returned.pool
	missions.clear()
	_sync(state)

func count_planned(planning: Dictionary) -> int:
	var allocations := {}
	for mission in planning.get("missions_soldats", []):
		var ids: Array = mission.get("assigned", []).duplicate()
		if not mission.has("assigned"): ids.resize(maxi(0, int(mission.get("effectif", 0))))
		allocations[str(allocations.size())] = ids
	return count_assigned(allocations)
