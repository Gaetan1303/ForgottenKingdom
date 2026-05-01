## autoload/dungeon_generator.gd
## Génère un donjon procédural de 10 étages avec salles, monstres et démons.
extends Node

const FLOORS_TOTAL := 10

var current_run: Dictionary = {}
var _rng := RandomNumberGenerator.new()

var _monstres := ["Goule", "Harpie", "Ogre", "Loup infernal", "Chevalier corrompu"]
var _demons := ["Succube", "Incube", "Démon majeur", "Archidémon", "Seigneur abyssal"]


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
		var demon_chance := clampi(20 + floor_num * 6, 20, 90)
		var pool := _demons if _rng.randi_range(1, 100) <= demon_chance else _monstres
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
	if current_run.is_empty() or bool(current_run.get("completed", false)):
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
		return false
	current_run["current_floor"] = f
	current_run["current_room"] = r
	return true
