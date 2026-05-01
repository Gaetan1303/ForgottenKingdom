extends RefCounted
class_name GameLoopStateMachine

const MatinState = preload("res://scripts/game_loop/matin_state.gd")
const ApresMidiState = preload("res://scripts/game_loop/apres_midi_state.gd")
const SoirState = preload("res://scripts/game_loop/soir_state.gd")
const StateMachine = preload("res://scripts/state_machine/state_machine.gd")

var machine: StateMachine = null
var clan_manager = null

func _init(_clan_manager = null, _debug: bool = false) -> void:
    clan_manager = _clan_manager
    machine = StateMachine.new(_debug)
    machine.add_state("matin", MatinState.new())
    machine.add_state("apres_midi", ApresMidiState.new())
    machine.add_state("soir", SoirState.new())
    machine.set_initial("matin")

func start() -> void:
    machine.start({"clan_manager": clan_manager})

func tick_to_next() -> void:
    # advance in loop: matin -> apres_midi -> soir -> matin
    var cur = machine.current
    var next_name = "matin"
    if cur:
        match cur.name:
            "matin": next_name = "apres_midi"
            "apres_midi": next_name = "soir"
            "soir": next_name = "matin"
            _: next_name = "matin"
    machine._goto(next_name, {"clan_manager": clan_manager, "event":"loop_advance"})
