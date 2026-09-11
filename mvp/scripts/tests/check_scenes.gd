extends SceneTree

const GameManagerScript = preload("res://scripts/autoload/game_manager.gd")

func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var missing := []
    var failed := []
    push_warning("SCENE_CHECK_START")
    var scenes_map: Dictionary = GameManagerScript.SCENES

    for key in scenes_map.keys():
        var path = scenes_map[key]
        var res = ResourceLoader.load(path)
        if res == null:
            push_error("MISSING: %s -> %s" % [key, path])
            missing.append(path)
            continue
        if res is PackedScene:
            var ok = true
            var inst = res.instantiate()
            if inst == null:
                push_error("FAILED_INSTANTIATE: %s" % path)
                failed.append(path)
                ok = false
            else:
                inst.queue_free()
            if ok:
                push_warning("LOADED: %s -> %s" % [key, path])
        else:
            push_warning("NOT_A_SCENE: %s -> %s" % [key, path])

    if missing.is_empty() and failed.is_empty():
        push_warning("SCENES_OK")
        print("SCENES_OK")
        quit(0)
        return

    if not missing.is_empty():
        print("SCENES_MISSING: %s" % missing)
    if not failed.is_empty():
        print("SCENES_FAILED_INSTANTIATE: %s" % failed)
    quit(1)
