## scripts/data/character.gd
## Modèle de personnage réutilisable pour joueurs, PNJ et ennemis.
class_name Character
extends RefCounted

const StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")

var name: String = ""
# `clan` reste disponible pour les anciens profils et sauvegardes.
var clan: String = ""
var clan_id: String = ""
var clan_name: String = ""
var char_class: String = ""
var level: int = 1
var stats: Dictionary = {}
var feats: Array = []
var abilities: Array = []
var points_pool: int = 10

func _init(_name: String = "") -> void:
    name = _name
    _reset_stats()

func _reset_stats() -> void:
    stats = StatDefsClass.make_default_stats(StatDefsClass.CHARACTER_MIN_STAT)

func cost_for_increment(_current_value: int) -> int:
    # Règle canonique : chaque point de caractéristique coûte exactement 1 point.
    return 1

func points_spent() -> int:
    var spent := 0
    for k in StatDefsClass.STAT_KEYS:
        var v: int = int(stats.get(k, StatDefsClass.CHARACTER_MIN_STAT))
        var cur: int = StatDefsClass.CHARACTER_MIN_STAT
        while cur < v:
            spent += cost_for_increment(cur)
            cur += 1
    return spent

func points_remaining() -> int:
    return max(0, points_pool - points_spent())

func can_increase(stat: String) -> bool:
    if not stats.has(stat):
        return false
    var v: int = int(stats[stat])
    if v >= StatDefsClass.CHARACTER_MAX_STAT:
        return false
    var c := cost_for_increment(v)
    return c <= points_remaining()

func increase_stat(stat: String) -> bool:
    if can_increase(stat):
        stats[stat] = int(stats[stat]) + 1
        return true
    return false

func can_decrease(stat: String) -> bool:
    if not stats.has(stat):
        return false
    return int(stats[stat]) > StatDefsClass.CHARACTER_MIN_STAT

func decrease_stat(stat: String) -> bool:
    if can_decrease(stat):
        stats[stat] = int(stats[stat]) - 1
        return true
    return false

func add_feat(feat_id: String) -> void:
    if feat_id in feats:
        return
    feats.append(feat_id)

func remove_feat(feat_id: String) -> void:
    if feat_id in feats:
        feats.erase(feat_id)


func meets_feat_prerequisites(feat_id: String, feats_defs: Dictionary) -> bool:
    # Check whether this character meets the prerequisites declared in feats_defs for feat_id.
    if not feats_defs or not feats_defs.has(feat_id):
        return false
    var info: Dictionary = feats_defs[feat_id] as Dictionary
    var pre: Variant = info.get("prerequisite", null)
    if pre == null:
        return true
    # Check stat prerequisites
    var stats_req := pre.get("stats", {}) as Dictionary
    for stat_key in stats_req.keys():
        var need := int(stats_req[stat_key])
        if int(stats.get(str(stat_key), 0)) < need:
            return false
    # Check feat prerequisites
    var feats_req := pre.get("feats", []) as Array
    for f in feats_req:
        if f not in feats:
            return false
    # Check level prerequisite
    if pre.has("level"):
        if int(level) < int(pre.get("level")):
            return false
    return true


func can_add_feat(feat_id: String, feats_defs: Dictionary) -> bool:
    if feat_id in feats:
        return false
    return meets_feat_prerequisites(feat_id, feats_defs)


func add_feat_checked(feat_id: String, feats_defs: Dictionary) -> bool:
    if can_add_feat(feat_id, feats_defs):
        feats.append(feat_id)
        return true
    return false

func to_dict() -> Dictionary:
    var resolved_clan_name := clan_name if not clan_name.is_empty() else clan
    var resolved_clan_id := clan_id if not clan_id.is_empty() else ClanIdentityType.id_from_name(resolved_clan_name)
    return {
        "name": name,
        "clan": resolved_clan_name,
        "clan_id": resolved_clan_id,
        "clan_name": resolved_clan_name,
        "class": char_class,
        "level": level,
        "stats": stats.duplicate(true),
        "feats": feats.duplicate(true),
        "abilities": abilities.duplicate(true),
        "points_pool": points_pool,
    }

func from_dict(d: Dictionary) -> void:
    name = str(d.get("name", ""))
    clan_name = str(d.get("clan_name", d.get("clan", "")))
    clan = clan_name
    clan_id = str(d.get("clan_id", "")).strip_edges()
    if clan_id.is_empty():
        clan_id = ClanIdentityType.id_from_name(clan_name)
    char_class = str(d.get("class", ""))
    level = int(d.get("level", 1))
    var loaded_stats := (d.get("stats", {}) as Dictionary).duplicate(true)
    stats = StatDefsClass.sanitize_stats(loaded_stats, StatDefsClass.CHARACTER_MIN_STAT, StatDefsClass.CHARACTER_MAX_STAT, StatDefsClass.CHARACTER_MIN_STAT)
    feats = (d.get("feats", []) as Array).duplicate(true)
    abilities = (d.get("abilities", []) as Array).duplicate(true)
    points_pool = int(d.get("points_pool", points_pool))
