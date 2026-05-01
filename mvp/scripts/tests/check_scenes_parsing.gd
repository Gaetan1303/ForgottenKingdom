extends Node

func _ready() -> void:
    push_warning("SCENE_PARSING_START")
    var gm_path := "res://scripts/autoload/game_manager.gd"
    if not FileAccess.file_exists(gm_path):
        push_error("game_manager.gd not found at %s" % gm_path)
        get_tree().quit(2)
        return

    var f := FileAccess.open(gm_path, FileAccess.READ)
    if f == null:
        push_error("Cannot open %s" % gm_path)
        get_tree().quit(2)
        return

    var content := f.get_as_text()
    f.close()

    # Find all res://scenes/*.tscn occurrences
    var re := RegEx.new()
    var err := re.compile('res://scenes/[^" ]+\\.tscn')
    if err != OK:
        push_error("Failed to compile regex")
        get_tree().quit(2)
        return

    var matches := re.search_all(content)
    var unique_paths := []
    for m in matches:
        var p = m.get_string()
        if not unique_paths.has(p):
            unique_paths.append(p)

    var missing := []
    var failed := []
    for p in unique_paths:
        var res = ResourceLoader.load(p)
        if res == null:
            push_error("MISSING: %s" % p)
            missing.append(p)
            continue
        if res is PackedScene:
            var inst = res.instantiate()
            if inst == null:
                push_error("FAILED_INSTANTIATE: %s" % p)
                failed.append(p)
            else:
                inst.queue_free()
        else:
            push_warning("NOT_SCENE: %s" % p)

    if missing.is_empty() and failed.is_empty():
        print("SCENE_PARSING_OK")
        get_tree().quit(0)
        return

    if not missing.is_empty():
        print("SCENE_PARSING_MISSING: %s" % missing)
    if not failed.is_empty():
        print("SCENE_PARSING_FAILED: %s" % failed)
    get_tree().quit(1)
