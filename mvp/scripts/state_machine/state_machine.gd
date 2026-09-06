extends RefCounted
class_name StateMachine

signal transitioned(from: String, to: String, event: String)
var states: Dictionary = {}
var transitions: Dictionary = {}
var initial_state: String = ""
var current: State = null
var debug: bool = false
var _transitioning := false

func _init(_debug: bool = false) -> void:
	debug = _debug

func add_state(state_name: String, state: State) -> void:
	state.name = state_name
	state.machine = self
	states[state_name] = state
	if initial_state.is_empty(): initial_state = state_name

func allow(from: String, event: String, to: String) -> void:
	if not transitions.has(from): transitions[from] = {}
	transitions[from][event] = to

func set_initial(state_name: String) -> void:
	initial_state = state_name

func start(data: Dictionary = {}) -> bool:
	if current != null: return false
	return _goto(initial_state, data)

## Restaurer ne rejoue jamais enter() : production, combat et récompenses ne se répètent pas.
func restore(state_name: String) -> bool:
	if _transitioning or not states.has(state_name): return false
	current = states[state_name]
	return true

func _goto(state_name: String, data: Dictionary = {}) -> bool:
	if _transitioning or not states.has(state_name) or (current != null and current.name == state_name):
		return false
	_transitioning = true
	var previous := current.name if current != null else ""
	if current != null: current.exit(data)
	current = states[state_name]
	current.enter(data)
	transitioned.emit(previous, state_name, str(data.get("event", "")))
	_transitioning = false
	return true

func handle_event(event: String, data: Dictionary = {}) -> bool:
	if current == null or _transitioning: return false
	var target := str(transitions.get(current.name, {}).get(event, ""))
	if target.is_empty(): return current.handle_event(event, data)
	var context := data.duplicate()
	context["event"] = event
	return _goto(target, context)

func update(delta: float) -> void:
	if current != null: current.update(delta)
