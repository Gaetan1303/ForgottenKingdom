## Cycle journalier réellement utilisé par le hub, avec reprise sans effets d’entrée.
extends RefCounted
class_name GameLoopStateMachine
const StateMachineClass = preload("res://scripts/state_machine/state_machine.gd")
const Matin = preload("res://scripts/game_loop/matin_state.gd")
const ApresMidi = preload("res://scripts/game_loop/apres_midi_state.gd")
const Soir = preload("res://scripts/game_loop/soir_state.gd")
var machine: RefCounted
var clan_manager: Node

func _init(cm: Node = null, debug: bool = false) -> void:
	clan_manager = cm
	machine = StateMachineClass.new(debug)
	machine.add_state("matin", Matin.new())
	machine.add_state("apres_midi", ApresMidi.new())
	machine.add_state("soir", Soir.new())
	machine.allow("matin", "advance", "apres_midi")
	machine.allow("apres_midi", "advance", "soir")
	machine.allow("soir", "advance", "matin")

func start() -> void:
	machine.restore(str(clan_manager.daily_phase) if clan_manager != null else "matin")

func tick_to_next() -> bool:
	if clan_manager == null: return false
	if machine.current == null: start()
	var run: Dictionary = clan_manager.campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)): return false
	return machine.handle_event("advance", {"clan_manager": clan_manager})
