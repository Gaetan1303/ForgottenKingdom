## Automate du parcours d’expédition ; l’unique état persistant reste run.state.
extends RefCounted
const StateMachineClass = preload("res://scripts/state_machine/state_machine.gd")
const StateClass = preload("res://scripts/state_machine/state.gd")
const STATES := ["arrival", "exploration", "combat", "return", "returned"]

static func make(run: Dictionary) -> RefCounted:
	var machine: RefCounted = StateMachineClass.new()
	for key in STATES: machine.add_state(key, StateClass.new(key))
	machine.allow("arrival", "enter", "exploration")
	machine.allow("exploration", "engage", "combat")
	machine.allow("combat", "victory", "exploration")
	machine.allow("combat", "defeat", "return")
	machine.allow("exploration", "complete", "return")
	for key in ["arrival", "exploration", "combat"]:
		machine.allow(key, "retreat", "return")
	machine.allow("return", "deposit", "returned")
	machine.restore(state_of(run))
	return machine

static func state_of(run: Dictionary) -> String:
	if bool(run.get("returned", false)): return "returned"
	if str(run.get("state", "")) in STATES: return str(run.state)
	if bool(run.get("completed", false)): return "return"
	# Les anciennes sorties reprennent là où elles étaient, sans nouvelle entrée imposée.
	var floors: Array = run.get("floors", [])
	var f := int(run.get("current_floor", 0))
	var r := int(run.get("current_room", 0))
	if f >= 0 and f < floors.size():
		var rooms: Array = floors[f].get("rooms", [])
		if r >= 0 and r < rooms.size():
			var room: Dictionary = rooms[r]
			if not bool(room.get("cleared", false)) and not room.get("battle", {}).is_empty(): return "combat"
	return "exploration"

static func send(run: Dictionary, event: String) -> bool:
	var machine: RefCounted = make(run)
	if not machine.handle_event(event): return false
	run["state"] = machine.current.name
	return true
