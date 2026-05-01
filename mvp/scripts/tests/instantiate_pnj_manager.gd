extends SceneTree

func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var sc := load("res://scenes/pnj_manager.tscn") as PackedScene
    if sc == null:
        push_error("Failed to load pnj_manager.tscn")
        quit(1)
        return
    var inst := sc.instantiate()
    if inst == null:
        push_error("Failed to instantiate pnj_manager.tscn")
        quit(1)
        return
    root.add_child(inst)
    print("INSTANTIATE_OK: pnj_manager loaded and instantiated")
    quit(0)
