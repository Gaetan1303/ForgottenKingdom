extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var ClanManager = root.get_node("ClanManager")
    if ClanManager == null:
        print("ERROR: ClanManager not found as autoload")
        quit(1)
        return

    var stats_bonus := {"force": 1, "magie": 2}
    var profil := {
        "genre": "Femme",
        "portrait": {},
        "feats": [],
        "fiche_complete": {"niveau": 1, "points_restants": 0, "stats_brutes": {"force": 12, "magie": 14, "espionnage": 8, "artisanat": 8, "diplomatie": 8, "commandement": 8}}
    }

    ClanManager.nouvelle_partie("Test", "ClanTest", "hellcaster", stats_bonus, profil)

    print("--- After nouvelle_partie ---")
    print("classe:", str(ClanManager.classe))
    print("nom_personnage:", str(ClanManager.nom_personnage))
    print("stats:")
    for k in ClanManager.stats.keys():
        print(" ", k, ":", int(ClanManager.stats[k]))

    # Now save and reload
    ClanManager.sauvegarder()
    var ok: bool = ClanManager.charger_sauvegarde()
    print("charger_sauvegarde returned:", ok)
    print("--- After charger_sauvegarde ---")
    print("classe:", str(ClanManager.classe))
    print("stats:")
    for k in ClanManager.stats.keys():
        print(" ", k, ":", int(ClanManager.stats[k]))

        # Try instantiating the character sheet and calling setup as clan_hub would
        var scene := ResourceLoader.load("res://scenes/character_sheet.tscn") as PackedScene
        if scene:
            var sheet_node = scene.instantiate()
            if sheet_node and sheet_node.has_method("setup"):
                var fiche = ClanManager.get_fiche_complete()
                var raw := (fiche.get("stats_brutes", {}) as Dictionary)
                sheet_node.setup(raw, int(fiche.get("points_restants", 0)), ClanManager.classe)
                print("CharacterSheet.setup called with raw stats:", JSON.stringify(raw))
                sheet_node.free()

        quit(0)
