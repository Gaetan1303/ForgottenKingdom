extends RefCounted
class_name State

var name: String = "State"
var machine: StateMachine = null

func _init(_name: String="State") -> void:
    name = _name

func enter(data: Dictionary = {}) -> void:
    # override in subclass
    pass

func exit(data: Dictionary = {}) -> void:
    # override in subclass
    pass

func handle_event(event: String, data: Dictionary = {}) -> bool:
    # override: return true if handled
    return false

func update(delta: float) -> void:
    # override for per-frame or per-tick logic
    pass
