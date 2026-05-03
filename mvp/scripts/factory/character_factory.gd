## scripts/factory/character_factory.gd
## Usine simple pour créer des personnages à partir d'un profil ou d'un template.
class_name CharacterFactory
extends RefCounted

const CLASSES_PATH := "res://data/classes.json"
const StatDefs = preload("res://scripts/data/stat_defs.gd")

func create_from_profile(profile: Dictionary) -> Character:
    var CharacterClass = preload("res://scripts/data/character.gd")
    var ch: Character = CharacterClass.new()
    ch.name = str(profile.get("name", ""))
    ch.clan = str(profile.get("clan", ""))
    ch.char_class = str(profile.get("classe", ""))
    ch.level = int(profile.get("niveau", 1))
    ch.points_pool = int(profile.get("points_a_distribuer_base", ch.points_pool))

    # Apply stats if provided
    var s := profile.get("stats_brutes", profile.get("stats", {})) as Dictionary
    if s.size() > 0:
        ch.stats = StatDefs.sanitize_stats(
            s,
            StatDefs.CHARACTER_MIN_STAT,
            StatDefs.CHARACTER_MAX_STAT,
            StatDefs.CHARACTER_MIN_STAT
        )

    # Add starting feats/abilities from centralized GameDataLoader
    var cid: String = ch.char_class
    var cdef := GameDataLoader.get_class_by_id(cid)
    if not cdef.is_empty():
        for f in cdef.get("starting_feats", []):
            ch.add_feat(str(f))
        for a in cdef.get("starting_abilities", []):
            ch.abilities.append(a)
    return ch
