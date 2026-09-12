## autoload/dungeon_generator.gd
## Génère un donjon procédural de 10 étages avec salles et entités des ruines.
extends Node
const Expedition = preload("res://scripts/game_loop/expedition_state_machine.gd")

const FLOORS_TOTAL := 10

const Combat = preload("res://scripts/services/tactical_combat_service.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")


func _clan_manager() -> Node:
	var node: Node = get_node_or_null("/root/ClanManager")
	assert(node != null, "DungeonGenerator: autoload ClanManager introuvable")
	return node


func _save_system() -> Node:
	var node: Node = get_node_or_null("/root/SaveSystem")
	assert(node != null, "DungeonGenerator: autoload SaveSystem introuvable")
	return node


var _legacy_run: Dictionary = {}
var _legacy_slot := ""
var current_run: Dictionary:
	get:
		if _legacy_slot != _save_system().get_active_slot():
			_legacy_run = {}
			_legacy_slot = _save_system().get_active_slot()
		return _clan_manager().campaign.get("run", {}) if not _clan_manager().campaign.is_empty() else _legacy_run
	set(value):
		if _clan_manager().campaign.is_empty():
			_legacy_slot = _save_system().get_active_slot()
			_legacy_run = value
		else:
			_clan_manager().campaign["run"] = value
var _rng := RandomNumberGenerator.new()

var _monstres := ["Goule", "Harpie", "Ogre", "Loup infernal", "Chevalier corrompu"]
var _entities := ["Dévoreur de Cendre", "Veuve de Faille", "Héraut brisé", "Colosse d’Éther", "Seigneur de Ruine"]


func generate_run(seed_value: int = -1) -> Dictionary:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system())
	_rng.seed = seed_value

	var floors: Array = []
	for floor_idx in range(FLOORS_TOTAL):
		floors.append(_generate_floor(floor_idx + 1))

	current_run = {
		"seed": seed_value,
		"floors": floors,
		"current_floor": 0,
		"current_room": 0,
		"completed": false,
	}
	return current_run


func _generate_floor(num: int) -> Dictionary:
	var rooms_count := _rng.randi_range(6, 10)
	if num == FLOORS_TOTAL:
		rooms_count = 10

	var rooms: Array = []
	for i in range(rooms_count):
		var is_boss := (num == FLOORS_TOTAL and i == rooms_count - 1)
		rooms.append(_generate_room(num, i + 1, is_boss))

	return {
		"floor": num,
		"rooms": rooms,
	}


func _generate_room(floor_num: int, room_num: int, is_boss: bool) -> Dictionary:
	var room_type := "combat"
	if is_boss:
		room_type = "boss"
	else:
		var roll := _rng.randi_range(1, 100)
		if roll <= 60:
			room_type = "combat"
		elif roll <= 78:
			room_type = "elite"
		elif roll <= 88:
			room_type = "treasure"
		elif roll <= 95:
			room_type = "trap"
		else:
			room_type = "rest"

	return {
		"id": "F%d-R%d" % [floor_num, room_num],
		"type": room_type,
		"enemies": _pick_enemies(floor_num, room_type),
		"cleared": false,
	}


func _pick_enemies(floor_num: int, room_type: String) -> Array:
	if room_type in ["treasure", "rest"]:
		return []
	var enemies: Array = []
	var count := 1
	match room_type:
		"combat": count = _rng.randi_range(1, 3)
		"elite": count = _rng.randi_range(2, 4)
		"trap": count = 1
		"boss": count = 1

	for _i in range(count):
		var entity_chance := clampi(20 + floor_num * 6, 20, 90)
		var pool := _entities if _rng.randi_range(1, 100) <= entity_chance else _monstres
		enemies.append(pool[_rng.randi_range(0, pool.size() - 1)])
	return enemies


func get_current_room() -> Dictionary:
	if current_run.is_empty() or bool(current_run.get("completed", false)):
		return {}
	var f := int(current_run.get("current_floor", 0))
	var r := int(current_run.get("current_room", 0))
	var floors: Array = current_run.get("floors", [])
	if f < 0 or f >= floors.size():
		return {}
	var rooms: Array = (floors[f] as Dictionary).get("rooms", [])
	if r < 0 or r >= rooms.size():
		return {}
	return rooms[r]


func clear_current_room() -> void:
	if current_run.is_empty():
		return
	var f := int(current_run.get("current_floor", 0))
	var r := int(current_run.get("current_room", 0))
	var floors: Array = current_run.get("floors", [])
	if f < 0 or f >= floors.size():
		return
	var floor_d := floors[f] as Dictionary
	var rooms: Array = floor_d.get("rooms", [])
	if r < 0 or r >= rooms.size():
		return
	var room := rooms[r] as Dictionary
	room["cleared"] = true
	rooms[r] = room
	floor_d["rooms"] = rooms
	floors[f] = floor_d
	current_run["floors"] = floors


func advance_room() -> bool:
	if not _clan_manager().campaign.is_empty() and Expedition.state_of(current_run) != "exploration": return false
	if current_run.is_empty() or bool(current_run.get("completed", false)) or not bool(get_current_room().get("cleared", false)):
		return false
	var f := int(current_run.get("current_floor", 0))
	var r := int(current_run.get("current_room", 0))
	var floors: Array = current_run.get("floors", [])
	var rooms: Array = (floors[f] as Dictionary).get("rooms", [])
	r += 1
	if r >= rooms.size():
		f += 1
		r = 0
	if f >= floors.size():
		current_run["completed"] = true
		Expedition.send(current_run, "complete")
		_clan_manager().sauvegarder()
		return false
	current_run["current_floor"] = f
	current_run["current_room"] = r
	if f > 0 and r == 0: apply_run_exposure("floor_%d" % f, 8.0 + f * 2.0)
	return true


## Préparation commune aux galeries et aux futures sorties du domaine.
func start_expedition(ids: Array) -> String:
	if not current_run.is_empty() and not bool(current_run.get("returned", false)):
		return "Une sortie est déjà en cours."
	if ids.is_empty() or ids.size() > 2 or ids.size() != _unique_count(ids):
		return "Choisissez un ou deux compagnons différents."
	var party: Array = [{"id": "hero", "nom": _clan_manager().nom_personnage, "stats": _clan_manager().get_stats()}]
	for id in ids:
		var person := Refuge.find_person(_clan_manager().service_context, str(id))
		if person.is_empty() or str(person.get("etat", "")) != "disponible":
			return "Un compagnon est blessé ou déjà affecté."
		party.append(person.duplicate(true))
	var short_run := not Refuge.has(_clan_manager().service_context, "salvage")
	preload("res://scripts/services/power_campaign_service.gd").ensure(_clan_manager().service_context)
	if short_run:
		current_run = {"floors": [{"floor": 1, "rooms": [
			{"id": "gallery_threshold", "type": "rest", "enemies": [], "cleared": false},
			{"id": "gallery_guards", "type": "combat", "enemies": ["Goule affamée", "Goule des pierres"], "cleared": false},
			{"id": "gallery_cache", "type": "treasure", "enemies": [], "cleared": false}
		]}], "current_floor": 0, "current_room": 0, "completed": false, "short": true}
		if int(_clan_manager().campaign.get("version", 2)) >= 3:
			current_run.floors[0].rooms[1].enemies = ["Garde du passage", "Garde des réserves"]
	else:
		generate_run()
	current_run["state"] = "arrival"
	current_run["inspected"] = {}
	current_run["exposures"] = {}
	current_run["party"] = party
	current_run["loot"] = {}
	for id in ids:
		Refuge.set_person_state(_clan_manager().service_context, str(id), "en_expedition")
	Refuge.mark(_clan_manager().service_context, "assignment")
	Refuge.log_entry(_clan_manager().service_context, "Sous la Brèche-Sèche", "L’équipe emporte ses armes. Les compagnons seront indisponibles au domaine jusqu’au retour.")
	_clan_manager().sauvegarder()
	return ""

func _unique_count(ids: Array) -> int:
	var found := {}
	for id in ids: found[id] = true
	return found.size()

func ensure_battle() -> Dictionary:
	if Expedition.state_of(current_run) not in ["exploration", "combat"]: return {}
	var room := get_current_room()
	if room.is_empty() or bool(room.get("cleared", false)) or (room.get("enemies", []) as Array).is_empty():
		return {}
	if not room.has("battle"):
		if not Expedition.send(current_run, "engage"): return {}
		var party: Array = current_run.get("party", []).duplicate(true)
		for person in party:
			person["corruption_modifiers"] = _clan_manager().get_corruption_service().expedition_modifiers(str(person.id))
		party = preload("res://scripts/services/pnj_daily_planner_service.gd").new(_clan_manager().service_context).supported_combat_party(party)
		room["battle"] = Combat.create(party, room.get("enemies", []), int(current_run.get("current_floor", 0)))
		_clan_manager().sauvegarder()
	return room.battle

func combat_command(kind: String, x: int = 0, y: int = 0) -> Dictionary:
	var battle := ensure_battle()
	if battle.is_empty():
		return {"ok": false, "message": "Aucun combat en cours."}
	var result := Combat.command(battle, kind, x, y, _clan_manager().get_ressource("mana"))
	if not bool(result.get("ok", false)):
		return result
	_clan_manager().payer({"mana": int(result.get("cost", 0))})
	for unit in battle.units:
		if str(unit.team) == "ally":
			for person in current_run.party:
				if str(person.id) == str(unit.id):
					person["hp"] = int(unit.hp)
					person["max_hp"] = int(unit.max_hp)
	if str(battle.outcome) == "victory":
		Expedition.send(current_run, "victory")
		clear_current_room()
		_add_loot({"or": 12, "nourriture": 4})
		current_run["experience"] = int(current_run.get("experience", 0)) + 20
		Refuge.mark(_clan_manager().service_context, "combat")
	elif str(battle.outcome) == "defeat":
		Expedition.send(current_run, "defeat")
		current_run["completed"] = true
		current_run["defeat"] = true
		apply_run_exposure("defeat", 10.0)
	_clan_manager().sauvegarder()
	return result

func resolve_quiet_room() -> String:
	if Expedition.state_of(current_run) != "exploration": return "Inspectez le passage avant de franchir le seuil."
	var room := get_current_room()
	if room.is_empty() or bool(room.get("cleared", false)) or not (room.get("enemies", []) as Array).is_empty():
		return "Cette salle ne peut pas être fouillée maintenant."
	var message := ""
	if str(room.get("type", "")) == "treasure":
		_add_loot({"bois": 8, "fer": 6, "essence": 1})
		current_run["tools_found"] = true
		message = "Outils, 8 bois, 6 fer et 1 essence placés dans les sacs. Sous le coffre, un sceau a été gratté. La Cicatrice de Sang brûle un instant."
	else:
		if not bool(current_run.get("short", false)):
			for person in current_run.get("party", []):
				if int(person.get("hp", 0)) > 0:
					person["hp"] = mini(int(person.get("max_hp", 30)), int(person.hp) + 8)
		message = "Vous retrouvez les empreintes décrites par Kael. Au départ, Kael vous a prévenu : « Deux silhouettes au fond. Approchez ensemble, puis choisissez votre angle. »"
	if str(room.get("type", "")) == "rest" and not bool(current_run.get("short", false)):
		message = "Halte : les compagnons encore debout récupèrent jusqu’à 8 PV."
	clear_current_room()
	_clan_manager().sauvegarder()
	return message

func _add_loot(gains: Dictionary) -> void:
	var loot: Dictionary = current_run.get("loot", {})
	for key in gains:
		loot[key] = int(loot.get(key, 0)) + int(gains[key])
	current_run["loot"] = loot

func return_to_refuge() -> String:
	if current_run.is_empty() or bool(current_run.get("returned", false)):
		return "L’équipe est déjà rentrée."
	if Expedition.state_of(current_run) != "return":
		if not Expedition.send(current_run, "retreat"): return "Repli impossible."
	if not Expedition.send(current_run, "deposit"): return "L’équipe est déjà rentrée."
	var wounds: PackedStringArray = []
	for person in current_run.get("party", []):
		if str(person.id) == "hero":
			continue
		var wounded := int(person.get("hp", 30)) <= int(person.get("max_hp", 30)) / 2
		Refuge.set_person_state(_clan_manager().service_context, str(person.id), "blesse" if wounded else "disponible")
		if wounded: wounds.append(str(person.nom))
	var loot: Dictionary = current_run.get("loot", {})
	_clan_manager().gagner(loot)
	if bool(current_run.get("tools_found", false)):
		preload("res://scripts/services/power_campaign_service.gd").record_expedition(_clan_manager().service_context, current_run)
		Refuge.mark(_clan_manager().service_context, "salvage")
	Refuge.mark(_clan_manager().service_context, "return")
	current_run["returned"] = true
	current_run["completed"] = true
	var message := "Retour à la Brèche-Sèche. Ressources déposées : " + (Refuge.resources_text(loot) if not loot.is_empty() else "aucune") + "."
	if not wounds.is_empty():
		message += " Blessures : " + ", ".join(wounds) + ". Soins ou repos jusqu’à l’aube nécessaires."
	message += " Expérience de l’héritier : +%d." % int(current_run.get("experience", 0))
	Refuge.log_entry(_clan_manager().service_context, "Le retour", message)
	_clan_manager().donner_experience(int(current_run.get("experience", 0)))
	_clan_manager().sauvegarder()
	return message

func inspect_arrival(target: String) -> String:
	if Expedition.state_of(current_run) != "arrival": return "Le seuil a déjà été franchi."
	var descriptions := {
		"inscription": "Une date gravée contredit votre souvenir de la chute. Sous vos doigts, une seconde vibration répond, puis disparaît. Kael ne reconnaît pas ce signe.",
		"passage": "Kael vérifie les marches et désigne des traces fraîches. Le passage tient. Deux silhouettes bougent plus loin ; restez ensemble."
	}
	if not descriptions.has(target): return "Rien à examiner ici."
	var inspected: Dictionary = current_run.get("inspected", {})
	if not inspected.has(target):
		inspected[target] = true
		current_run["inspected"] = inspected
		Refuge.log_entry(_clan_manager().service_context, "Au seuil du donjon", descriptions[target])
		_clan_manager().sauvegarder()
	return descriptions[target]

func enter_dungeon() -> bool:
	if not bool(current_run.get("inspected", {}).get("passage", false)): return false
	if not Expedition.send(current_run, "enter"): return false
	apply_run_exposure("entrance", 8.0)
	_clan_manager().sauvegarder()
	return true

func touch_inscription() -> String:
	if Expedition.state_of(current_run) != "arrival": return "L’inscription est derrière vous."
	if not apply_run_exposure("inscription", 16.0, ["hero"]): return "Vous avez déjà éprouvé cette résonance."
	return "La pierre répond à votre sang, puis le froid remonte votre bras. Kael vous écarte du sceau. L’analyse reste incomplète ; la corruption a augmenté."

func apply_run_exposure(key: String, amount: float, targets: Array = []) -> bool:
	if current_run.is_empty() or bool(current_run.get("returned", false)): return false
	var exposures: Dictionary = current_run.get("exposures", {})
	if exposures.has(key): return false
	exposures[key] = true
	current_run["exposures"] = exposures
	var lines: PackedStringArray = []
	for person in current_run.get("party", []):
		if not targets.is_empty() and str(person.id) not in targets: continue
		var result: Dictionary = _clan_manager().apply_corruption(str(person.id), amount, "dungeon:" + key, false)
		if bool(result.get("ok", false)): lines.append("%s : +%.1f" % [person.nom, float(result.get("delta", 0.0))])
	Refuge.log_entry(_clan_manager().service_context, "Exposition à l’Éther", "Corruption — " + ", ".join(lines) + ". La purification est disponible au refuge.")
	_clan_manager().sauvegarder()
	return true
