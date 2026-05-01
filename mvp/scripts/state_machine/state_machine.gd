extends RefCounted
class_name StateMachine

signal transitioned(from, to, event)

var states: Dictionary = {}
var initial_state: String = ""
var current: State = null
var debug: bool = true

func _init(_debug: bool = false) -> void:
    debug = _debug

func add_state(name: String, state: State) -> void:
    state.machine = self
    states[name] = state
    if initial_state == "":
        initial_state = name

func set_initial(name: String) -> void:
    initial_state = name

func start(data: Dictionary = {}) -> void:
    if initial_state == "":
        push_error("StateMachine: initial_state not set")
        return
    _goto(initial_state, data)

func _goto(name: String, data: Dictionary = {}) -> void:
    if not states.has(name):
        push_error("StateMachine: target state '%s' unknown" % name)
        return
    var prev = current
    if prev != null:
        prev.exit(data)
    current = states[name]
    current.enter(data)
    if debug:
        print("SM: transitioned %s -> %s" % [prev and prev.name or "<none>", name])
    emit_signal("transitioned", prev and prev.name or null, name, data.get("event", null))

func handle_event(event: String, data: Dictionary = {}) -> void:
    if current and current.handle_event(event, data):
        return
    # By default, allow a state switch if data contains "transition_to"
    if data.has("transition_to"):
        _goto(str(data["transition_to"]), data)

func update(delta: float) -> void:
    if current:
        current.update(delta)
