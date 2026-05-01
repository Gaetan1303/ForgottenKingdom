extends Node

func _ready() -> void:
    var missing := []
    var failed := []
    push_warning("SCENE_CHECK_START")
    var scenes_map = {}
    if Engine.has_singleton("GameManager"):
        scenes_map = GameManager.SCENES
    else:
        push_warning("GameManager autoload not present — attempting to load mapping from file")
        # Fallback: try to load the game_manager script and read SCENES via an instance
        var gm_script = load("res://scripts/autoload/game_manager.gd")
        if gm_script == null:
            push_error("Unable to load game_manager.gd for scene mapping")
            get_tree().quit(2)
            return
        var inst = null
        # try to instantiate the script to access SCENES
        if gm_script is Script:
            inst = gm_script.new()
        if inst == null:
            push_error("Cannot instantiate game_manager.gd to read SCENES")
            get_tree().quit(2)
            return
        if inst.has("SCENES"):
            scenes_map = inst.get("SCENES")

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
        get_tree().quit(0)
        return

    if not missing.is_empty():
        print("SCENES_MISSING: %s" % missing)
    if not failed.is_empty():
        print("SCENES_FAILED_INSTANTIATE: %s" % failed)
    get_tree().quit(1)
