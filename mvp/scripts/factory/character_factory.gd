## scripts/factory/character_factory.gd
## Usine simple pour créer des personnages à partir d'un profil ou d'un template.
class_name CharacterFactory
extends RefCounted

const CLASSES_PATH := "res://data/classes.json"
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")
const StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const CharacterClass = preload("res://scripts/data/character.gd")

func create_from_profile(profile: Dictionary) -> RefCounted:
    var ch: RefCounted = CharacterClass.new()
    ch.name = str(profile.get("name", ""))
    ch.clan_name = str(profile.get("clan_name", profile.get("clan", "")))
    ch.clan = ch.clan_name
    ch.clan_id = str(profile.get("clan_id", "")).strip_edges()
    if ch.clan_id.is_empty():
        ch.clan_id = ClanIdentityType.id_from_name(ch.clan_name)
    ch.char_class = str(profile.get("classe", ""))
    ch.level = int(profile.get("niveau", 1))
    ch.points_pool = int(profile.get("points_a_distribuer_base", ch.points_pool))

    # Apply stats if provided
    var s := profile.get("stats_brutes", profile.get("stats", {})) as Dictionary
    if s.size() > 0:
        ch.stats = StatDefsClass.sanitize_stats(
            s,
            StatDefsClass.CHARACTER_MIN_STAT,
            StatDefsClass.CHARACTER_MAX_STAT,
            StatDefsClass.CHARACTER_MIN_STAT
        )

    # Add starting feats/abilities from centralized GameDataLoader
    var cid: String = ch.char_class
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    var loader: Node = tree.root.get_node_or_null("GameDataLoader") if tree != null else null
    var cdef: Dictionary = loader.get_class_by_id(cid) if loader != null else {}
    if not cdef.is_empty():
        for f in cdef.get("starting_feats", []):
            ch.add_feat(str(f))
        for a in cdef.get("starting_abilities", []):
            ch.abilities.append(a)
    return ch
