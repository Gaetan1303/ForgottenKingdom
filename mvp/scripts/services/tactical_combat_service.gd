## Combat sur grille, indépendant des scènes et du prologue.
## Une action validée mute l'état ; une commande refusée ne dépense rien.
extends RefCounted

const WIDTH := 6
const HEIGHT := 4
const MOVE_RANGE := 3

static func create(party: Array, enemies: Array, floor_index: int = 0) -> Dictionary:
	var units: Array = []
	for i in range(party.size()):
		var member: Dictionary = party[i]
		var stats: Dictionary = member.get("stats", {})
		var modifiers: Dictionary = member.get("corruption_modifiers", {})
		var max_hp := maxi(1, 18 + int(stats.get("commandement", 8)) + int(modifiers.get("max_hp", 0)))
		units.append({"id": str(member.id), "name": str(member.nom), "team": "ally", "x": 0, "y": i, "hp": mini(max_hp, int(member.get("hp", max_hp))), "max_hp": max_hp, "force": int(stats.get("force", 8)), "magie": maxi(0, int(stats.get("magie", 8)) + int(modifiers.get("magie", 0))), "initiative": maxi(0, int(stats.get("espionnage", 8)) + int(modifiers.get("initiative", 0))), "corruption_modifiers": modifiers.duplicate()})
	for i in range(mini(enemies.size(), HEIGHT)):
		units.append({"id": "enemy_%d" % i, "name": str(enemies[i]), "team": "enemy", "x": WIDTH - 1, "y": i, "hp": 10 + floor_index * 3, "max_hp": 10 + floor_index * 3, "force": 6 + floor_index * 2, "magie": 0, "initiative": 6 + floor_index})
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.initiative) > int(b.initiative))
	var battle := {"units": units, "active": 0, "moved": false, "acted": false, "round": 1, "outcome": "", "log": ["Les plus vifs prennent l’initiative."], "mana_spent": 0}
	_check_outcome(battle)
	if not units.is_empty() and int(units[0].hp) <= 0:
		_advance(battle)
	elif not units.is_empty() and str(units[0].team) == "enemy":
		_enemy_turn(battle)
		_advance(battle)
	return battle

static func active(battle: Dictionary) -> Dictionary:
	var units: Array = battle.get("units", [])
	if units.is_empty() or not str(battle.get("outcome", "")).is_empty():
		return {}
	return units[int(battle.get("active", 0))]

static func unit_at(battle: Dictionary, x: int, y: int) -> Dictionary:
	for unit in battle.get("units", []):
		if int(unit.hp) > 0 and int(unit.x) == x and int(unit.y) == y:
			return unit
	return {}

static func distance(a: Dictionary, b: Dictionary) -> int:
	return absi(int(a.x) - int(b.x)) + absi(int(a.y) - int(b.y))

static func can_move(battle: Dictionary, x: int, y: int, allowance: int = MOVE_RANGE) -> bool:
	var actor := active(battle)
	if actor.is_empty() or x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT or not unit_at(battle, x, y).is_empty():
		return false
	var frontier: Array = [{"x": int(actor.x), "y": int(actor.y), "steps": 0}]
	var seen := {}
	while not frontier.is_empty():
		var cell: Dictionary = frontier.pop_front()
		if int(cell.x) == x and int(cell.y) == y:
			return true
		if int(cell.steps) >= allowance:
			continue
		for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nx: int = int(cell.x) + delta.x
			var ny: int = int(cell.y) + delta.y
			var key := "%d:%d" % [nx, ny]
			if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT or seen.has(key) or not unit_at(battle, nx, ny).is_empty():
				continue
			seen[key] = true
			frontier.append({"x": nx, "y": ny, "steps": int(cell.steps) + 1})
	return false

static func command(battle: Dictionary, kind: String, x: int, y: int, mana: int) -> Dictionary:
	var actor := active(battle)
	if actor.is_empty() or str(actor.team) != "ally":
		return {"ok": false, "message": "Le combat est terminé."}
	if kind == "end":
		_advance(battle)
		return {"ok": true, "cost": 0}
	if kind == "move":
		if bool(battle.moved) or not can_move(battle, x, y):
			return {"ok": false, "message": "Déplacement impossible : trois cases libres au maximum, une fois par tour."}
		actor.x = x
		actor.y = y
		battle.moved = true
		return {"ok": true, "cost": 0}
	if kind not in ["attack", "ability"]:
		return {"ok": false, "message": "Action inconnue."}
	var target := unit_at(battle, x, y)
	var reach := 3 if kind == "ability" else 1
	var cost := 3 if kind == "ability" else 0
	if bool(battle.acted) or target.is_empty() or str(target.team) == str(actor.team) or distance(actor, target) > reach:
		return {"ok": false, "message": "Choisissez un adversaire à portée. Une attaque ou capacité par tour."}
	if mana < cost:
		return {"ok": false, "message": "La capacité demande 3 mana du domaine."}
	var base := int(actor.magie) if kind == "ability" else int(actor.force)
	var divisor := 2 if kind == "ability" else 3
	var bonus := 3 if kind == "ability" else 2
	var damage := maxi(1, int(base / divisor) + bonus)
	target.hp = maxi(0, int(target.hp) - damage)
	battle.acted = true
	battle.mana_spent = int(battle.mana_spent) + cost
	_append_log(battle, "%s → %s : base %d ÷ %d + bonus %d − malus 0 = %d dégâts. Coût : %d mana." % [actor.name, target.name, base, divisor, bonus, damage, cost])
	_check_outcome(battle)
	return {"ok": true, "cost": cost}

static func _append_log(battle: Dictionary, message: String) -> void:
	var lines: Array = battle.log
	lines.append(message)
	if lines.size() > 8:
		lines.pop_front()
	battle.log = lines

static func _check_outcome(battle: Dictionary) -> void:
	var allies := 0
	var enemies := 0
	for unit in battle.units:
		if int(unit.hp) <= 0:
			continue
		if str(unit.team) == "ally": allies += 1
		else: enemies += 1
	if enemies == 0: battle.outcome = "victory"
	elif allies == 0: battle.outcome = "defeat"

static func _advance(battle: Dictionary) -> void:
	_check_outcome(battle)
	if not str(battle.outcome).is_empty():
		return
	var units: Array = battle.units
	for _iteration in range(units.size() + 1):
		battle.active = (int(battle.active) + 1) % units.size()
		if int(battle.active) == 0:
			battle.round = int(battle.round) + 1
		battle.moved = false
		battle.acted = false
		var actor: Dictionary = units[int(battle.active)]
		if int(actor.hp) <= 0:
			continue
		if str(actor.team) == "ally":
			return
		_enemy_turn(battle)
		_check_outcome(battle)
		if not str(battle.outcome).is_empty():
			return

static func _enemy_turn(battle: Dictionary) -> void:
	var actor := active(battle)
	if actor.is_empty():
		return
	var target: Dictionary = {}
	for unit in battle.units:
		if str(unit.team) == "ally" and int(unit.hp) > 0 and (target.is_empty() or distance(actor, unit) < distance(actor, target)):
			target = unit
	if target.is_empty():
		return
	for _step in range(2):
		if distance(actor, target) <= 1:
			break
		var best := {"x": int(actor.x), "y": int(actor.y)}
		for delta in [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]:
			var cell := {"x": int(actor.x) + delta.x, "y": int(actor.y) + delta.y}
			if can_move(battle, cell.x, cell.y, 1) and distance(cell, target) < distance(best, target):
				best = cell
		actor.x = best.x
		actor.y = best.y
	if distance(actor, target) <= 1:
		var damage := maxi(1, int(int(actor.force) / 3) + 1)
		target.hp = maxi(0, int(target.hp) - damage)
		_append_log(battle, "%s frappe %s : force %d ÷ 3 + 1 = %d dégâts." % [actor.name, target.name, int(actor.force), damage])
