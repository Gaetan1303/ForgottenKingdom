extends RefCounted
class_name PnjGenerator

const NameGeneratorServiceScript = preload("res://scripts/services/name_generator_service.gd")
const StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const PnjDailyPlannerServiceClass = preload("res://scripts/services/pnj_daily_planner_service.gd")

var context: RefCounted
var _rng: RandomNumberGenerator
var _names: RefCounted

func _init(p_context: RefCounted = null) -> void:
    context = p_context
    if context != null: _rng = context.rng
    else:
        _rng = RandomNumberGenerator.new()
        _rng.randomize()
    _names = NameGeneratorServiceScript.new(-1, _rng)


func _pick_name(role: String) -> String:
    var identity: Dictionary = _names.generate_pnj_identity(role, "marches")
    return str(identity.get("nom", "Aren Veyr"))


func _choose_role(hint: String = "") -> String:
    var roles := ["stratege","eclaireur","mage","diplomate","garde","marchand","villageois","ennemi"]
    if hint != "" and roles.has(hint):
        return hint
    return roles[_rng.randi_range(0, roles.size()-1)]


func _stats_for_role(role: String, niveau: int) -> Dictionary:
    var base: Dictionary = StatDefsClass.make_default_stats(StatDefsClass.CHARACTER_MIN_STAT)
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
            base = StatDefsClass.make_default_stats(10)
        "stratege":
            base["commandement"] = 15
            base["espionnage"] = 11
        "eclaireur":
            base["espionnage"] = 15
            base["force"] = 11
        "mage":
            base["magie"] = 16
            base["artisanat"] = 10
        "diplomate":
            base["diplomatie"] = 15
            base["commandement"] = 10
        _:
            base = StatDefsClass.make_default_stats(StatDefsClass.CHARACTER_MIN_STAT)

    # small random variation
    for k in StatDefsClass.STAT_KEYS:
        var v: int = int(base.get(k, StatDefsClass.CHARACTER_MIN_STAT))
        v += _rng.randi_range(-1, 2)
        base[k] = clampi(v, StatDefsClass.CHARACTER_MIN_STAT, StatDefsClass.CHARACTER_MAX_STAT)

    # scale slightly with niveau
    if niveau > 1:
        for k in StatDefsClass.STAT_KEYS:
            base[k] = clampi(int(base[k]) + int(niveau / 2), StatDefsClass.CHARACTER_MIN_STAT, StatDefsClass.CHARACTER_MAX_STAT)

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
    var identity: Dictionary = _names.generate_pnj_identity(role, "marches")
    var name := str(identity.get("nom", _pick_name(role)))
    var pnj_id := "%s_%d" % [name.replace(" ", "_").to_lower(), _rng.randi()]

    # 2. generate stats
    var stats := _stats_for_role(role, niveau)

    # 3. build traits and equipment
    var traits: Array = []
    var equipment: Array = _equipment_for_role(role)
    var behavior: Dictionary = _behavior_for_role(role)

    # 4. create profile via planner helper
    var planner: RefCounted = PnjDailyPlannerServiceClass.new()
    var profile: Dictionary = (planner as Object).make_pnj_profile(pnj_id, name, pnj_type, role, niveau, stats, traits)
    profile["equipment"] = equipment
    profile["behavior"] = behavior
    profile["combativite"] = int(identity.get("combativite", profile.get("combativite", 45)))
    profile["temperament"] = str(identity.get("temperament", profile.get("temperament", "résolu")))

    if context != null:
        var population = preload("res://scripts/services/clan_population_service.gd").new(context)
        population.ajouter_pnj_gere(pnj_id, name, pnj_type, role, niveau, stats, traits)
        var roster: Array = context.state.pnj_gestion.get("roster", [])
        for entry in roster:
            if str(entry.get("id", "")) == pnj_id:
                entry.merge(profile, true)
                break
    return profile
