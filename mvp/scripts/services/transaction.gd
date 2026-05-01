extends RefCounted
class_name Transaction

var target: Dictionary = {}
var changes: Dictionary = {}
var committed: bool = false

func _init(_target: Dictionary) -> void:
    target = _target
    changes = {}
    committed = false

func add_change(key: String, delta: int) -> void:
    if committed:
        push_error("Transaction already committed")
        return
    changes[key] = int(changes.get(key, 0)) + int(delta)

func commit() -> void:
    if committed:
        return
    # apply all changes atomically
    for k in changes.keys():
        target[k] = int(target.get(k, 0)) + int(changes[k])
    committed = true

func rollback() -> void:
    changes.clear()
    committed = false

func get_changes() -> Dictionary:
    return changes.duplicate(true)
