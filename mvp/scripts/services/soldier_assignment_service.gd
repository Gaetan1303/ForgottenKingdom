## Gère la réservation de soldats par identifiants sans dépendre du ClanManager.
class_name SoldierAssignmentService
extends RefCounted

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
