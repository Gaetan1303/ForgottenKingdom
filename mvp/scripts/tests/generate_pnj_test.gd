extends SceneTree

const AUTOLOAD_WAIT_FRAMES := 180

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var failures: Array[String] = []
    var cm: Node = null
    for i in range(AUTOLOAD_WAIT_FRAMES):
        cm = get_root().get_node_or_null("/root/ClanManager")
        if cm != null:
            break
        await process_frame

    if cm == null:
        failures.append("ClanManager indisponible")
        _finish(failures)
        return

    var gen: RefCounted = load("res://scripts/services/pnj_generator.gd").new()
    var res: Dictionary = (gen as Object).generate_and_register_pnj("garde") as Dictionary
    if res == null or not (res is Dictionary):
        failures.append("Generator returned invalid profile")
    else:
        print("Generated profile:", res)
        var state: Dictionary = cm.get_pnj_gestion_state()
        var roster: Array = state.get("roster", []) as Array
        print("Roster size:", roster.size())
        for p in roster:
            print("Roster entry:", p)
        var found: bool = false
        for p in roster:
            if str(p.get("nom", "")).begins_with(str(res.get("nom", ""))):
                found = true
                break
        if not found:
            failures.append("PNJ non enregistre dans le roster")

    _finish(failures)


func _finish(failures: Array) -> void:
    if failures.size() == 0:
        print("SMOKE_OK: pnj_generator")
        quit(0)
        return
    for f in failures:
        push_error("SMOKE_FAIL: %s" % f)
    quit(1)
