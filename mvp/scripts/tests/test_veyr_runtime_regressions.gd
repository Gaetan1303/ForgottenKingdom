extends SceneTree

const PlannerScript = preload("res://scripts/services/pnj_daily_planner_service.gd")
const INTRO_VN_SCRIPT_PATH := "res://scripts/ui/intro_vn.gd"
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")

const MENU_ICONS: Array[String] = [
    "res://assets/ui/icons/new_game.png",
    "res://assets/ui/icons/continue.png",
    "res://assets/ui/icons/settings.png",
    "res://assets/ui/icons/lore.png",
    "res://assets/ui/icons/quit.png",
]

func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var failures: Array[String] = []

    var planner = PlannerScript.new()
    if planner == null:
        failures.append("PnjDailyPlannerService non instanciable")
    else:
        var plan: Dictionary = planner.make_daily_plan()
        if not plan.has("missions_soldats") or not plan.has("missions_pnj"):
            failures.append("planning PNJ invalide")
        var profile: Dictionary = planner.make_pnj_profile(
            "test_runtime", "Aren Veyr", "recrute", "garde", 1,
            {"force": 10, "magie": 10, "espionnage": 10, "artisanat": 10, "diplomatie": 10, "commandement": 10},
            []
        )
        if int(profile.get("combativite", -1)) < 0:
            failures.append("combativité PNJ absente")

    var intro_script: GDScript = load(INTRO_VN_SCRIPT_PATH) as GDScript
    var intro = intro_script.new() if intro_script != null else null
    if intro == null:
        failures.append("IntroVN non instanciable")
    else:
        intro.free()

    for path: String in MENU_ICONS:
        if not FileAccess.file_exists(path):
            failures.append("icône absente: %s" % path)
            continue
        var texture: Texture2D = ResourcePathResolver.load_texture(path, "res://assets/ui/icons")
        if texture == null:
            failures.append("icône non chargeable: %s" % path)

    if not failures.is_empty():
        for failure: String in failures:
            push_error("VEYR_RUNTIME_REGRESSION: %s" % failure)
        print("VEYR_RUNTIME_REGRESSIONS_FAIL: %d erreur(s)" % failures.size())
        quit(1)
        return

    print("VEYR_RUNTIME_REGRESSIONS_OK")
    quit(0)
