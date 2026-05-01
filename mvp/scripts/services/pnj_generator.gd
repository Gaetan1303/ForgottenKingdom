extends RefCounted
class_name PnjGenerator

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const PnjPlanner = preload("res://scripts/services/pnj_daily_planner_service.gd")

var _rng := RandomNumberGenerator.new()

func _init() -> void:
    _rng.randomize()


func _pick_name(role: String) -> String:
    var first := ["Ravik","Selyra","Borel","Ithra","Vael","Liora","Kade","Marek","Sora","Elen"]
    var last := ["Thorn","Kov","Meris","Vorn","Hald","Ari","Nim","Dare","Yen","Kor"]
    return "%s %s" % [first[_rng.randi_range(0, first.size()-1)], last[_rng.randi_range(0, last.size()-1)]]


func _choose_role(hint: String = "") -> String:
    var roles := ["stratege","eclaireur","mage","diplomate","garde","marchand","villageois","ennemi"]
    if hint != "" and roles.has(hint):
        return hint
    return roles[_rng.randi_range(0, roles.size()-1)]


func _stats_for_role(role: String, niveau: int) -> Dictionary:
    var base := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
    match role:
        "garde":
            base["force"] = 14
            base["commandement"] = 12
            base["espionnage"] = 9
        "marchand":
            base["diplomatie"] = 14
            base["artisanat"] = 12
            base["magie"] = 9
        "ennemi":
            base["force"] = 15
            base["magie"] = 12
            base["commandement"] = 10
        "villageois":
            base = StatDefs.make_default_stats(10)
        "stratege":
            base["commandement"] = 15
            base["espionnage"] = 11
        "eclaireur":
            base["espionnage"] = 15
            base["force"] = 11
        "mage":
            base["magie"] = 16
            base["essai"] = 8
        "diplomate":
            base["diplomatie"] = 15
            base["commandement"] = 10
        _:
            base = StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)

    # small random variation
    for k in StatDefs.STAT_KEYS:
        var v := int(base.get(k, StatDefs.CHARACTER_MIN_STAT))
        v += _rng.randi_range(-1, 2)
        base[k] = clampi(v, StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT)

    # scale slightly with niveau
    if niveau > 1:
        for k in StatDefs.STAT_KEYS:
            base[k] = clampi(int(base[k]) + int(niveau / 2), StatDefs.CHARACTER_MIN_STAT, StatDefs.CHARACTER_MAX_STAT)

    return base


func _equipment_for_role(role: String) -> Array:
    match role:
        "garde": return ["Armure de cuir","Épée courte","Bouclier"]
        "marchand": return ["Bourse","Tunique propre","Balance"]
        "ennemi": return ["Couteau sale","Cape sombre"]
        "villageois": return ["Tablier","Outillage"]
        "stratege": return ["Carte","Anneau d'autorité"]
        "eclaireur": return ["Cape de camouflage","Arc court"]
        "mage": return ["Bâton ritué","Sang-de-feu"]
        "diplomate": return ["Tenue élégante","Sceau de maison"]
    return []


func _behavior_for_role(role: String) -> Dictionary:
    match role:
        "garde": return {"behavior":"patrouille","patrol_radius":8}
        "marchand": return {"behavior":"commerce","hours": [9,17]}
        "ennemi": return {"behavior":"hostile","aggro_range":6}
        "villageois": return {"behavior":"idle","actions":["travail","parler"]}
        "stratege": return {"behavior":"planifier","office":true}
        "eclaireur": return {"behavior":"patrouille","stealth":true}
        "mage": return {"behavior":"etudier","lab":true}
        "diplomate": return {"behavior":"negocier","favor":1}
    return {"behavior":"idle"}


func generate_and_register_pnj(role_hint: String = "", pnj_type: String = "recrute") -> Dictionary:
    # 1. determine role and basic attributes
    var role := _choose_role(role_hint)
    var niveau := _rng.randi_range(1, 4)
    var name := _pick_name(role)
    var pnj_id := "%s_%d" % [name.replace(" ", "_").to_lower(), randi()]

    # 2. generate stats
    var stats := _stats_for_role(role, niveau)

    # 3. build traits and equipment
    var traits: Array = []
    var equipment: Array = _equipment_for_role(role)
    var behavior: Dictionary = _behavior_for_role(role)

    # 4. create profile via planner helper
    var planner: RefCounted = PnjPlanner.new()
    var profile: Dictionary = (planner as Object).make_pnj_profile(pnj_id, name, pnj_type, role, niveau, stats, traits)
    profile["equipment"] = equipment
    profile["behavior"] = behavior

    # 5. register with ClanManager if available (use SceneTree root lookup for reliability)
    var main_loop := Engine.get_main_loop()
    if main_loop != null and typeof(main_loop) == TYPE_OBJECT:
        var tree := main_loop as SceneTree
        if tree != null:
            var root := tree.get_root()
            if root != null:
                var cm_node := root.get_node_or_null("/root/ClanManager")
                if cm_node != null and cm_node.has_method("ajouter_pnj_gere"):
                    var added: Dictionary = cm_node.ajouter_pnj_gere(pnj_id, name, pnj_type, role, niveau, stats, traits)
                    # attach equipment/behavior to stored profile
                    var state: Dictionary = cm_node.get_pnj_gestion_state()
                    var roster := (state.get("roster", []) as Array)
                    var idx := -1
                    for i in range(roster.size()):
                        if str(roster[i].get("id", "")) == pnj_id:
                            idx = i
                            break
                    if idx >= 0:
                        var p := (roster[idx] as Dictionary).duplicate(true)
                        p["equipment"] = equipment
                        p["behavior"] = behavior
                        roster[idx] = p
                        state["roster"] = roster
                        cm_node.pnj_gestion = state
                    return added

    return profile
