## scripts/factory/character_factory.gd
## Usine simple pour créer des personnages à partir d'un profil ou d'un template.
class_name CharacterFactory
extends RefCounted

const CLASSES_PATH := "res://data/classes.json"
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")
# rely on StatDefs class_name from data/stat_defs.gd

func create_from_profile(profile: Dictionary) -> Character:
    var CharacterClass = preload("res://scripts/data/character.gd")
    var ch: Character = CharacterClass.new()
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
