extends SceneTree

func _init():
    call_deferred("_run_test")

func _run_test() -> void:
    print("E2E_TEST_START: direct nouvelle_partie -> save verification")
    var clan_mgr = get_root().get_node_or_null("/root/ClanManager")
    if clan_mgr == null:
        print("ERROR: ClanManager autoload not found")
        quit(1)
        return

    var profil = {
        "genre": "Femme",
        "portrait": {},
        "feats": [],
        "fiche_complete": {
            "niveau": 1,
            "points_restants": 0,
            "stats_brutes": {"force": 12, "magie": 14, "espionnage": 8, "artisanat": 8, "diplomatie": 8, "commandement": 8}
        }
    }

    clan_mgr.nouvelle_partie("E2E", "E2EClan", "hellcaster", {}, profil)
    print("Called ClanManager.nouvelle_partie(...)")

    # Force save and reload via ClanManager API to ensure persistence path executed
    clan_mgr.sauvegarder()
    var ok = clan_mgr.charger_sauvegarde()
    print("charger_sauvegarde returned:", ok)

    # Now verify saved JSON contains fiche_complete.stats_brutes
    var save_system = get_root().get_node_or_null("/root/SaveSystem")
    if save_system == null:
        print("ERROR: /root/SaveSystem not found")
        quit(2)
        return

    ## Use class_name JsonPersistenceService in tests.
    var path = save_system.get_clan_save_path()
    print("Save path:", path)
    var saved = JsonPersistenceService.read_json_with_backup(path)
    if saved.is_empty():
        print("FAIL: saved file empty or missing at:", path)
        quit(3)
        return

    profil = saved.get("profil_personnage", {}) as Dictionary
    if profil.is_empty():
        print("FAIL: profil_personnage missing in saved data")
        quit(4)
        return

    var fiche = (profil.get("fiche_complete", {}) as Dictionary)
    if not fiche.has("stats_brutes"):
        print("FAIL: fiche_complete.stats_brutes missing in saved profil")
        print("Saved profil keys:", profil.keys())
        quit(5)
        return

    print("PASS: fiche_complete.stats_brutes saved:", fiche.get("stats_brutes"))
    quit(0)

func _post_ready(inst: Node) -> void:
    # Fill names
    var nom_perso = inst.get_node_or_null("PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage")
    var nom_clan = inst.get_node_or_null("PanneauCentre/LigneNoms/ColNomClan/NomClan")
    if nom_perso:
        nom_perso.text = "E2E"
    if nom_clan:
        nom_clan.text = "E2EClan"

    # Choose a class via exposed helper if available
    if inst.has_method("_choisir_classe"):
        inst._choisir_classe("hellcaster")

    # Instead of triggering full navigation (which may replace scenes and stop this test),
    # build the profile and call ClanManager.nouvelle_partie directly so we can verify save.
    var profil = {}
    if inst.has_method("_construire_profil_personnage"):
        profil = inst._construire_profil_personnage()
        print("Built profil from creation scene")
    else:
        print("Warning: creation scene has no _construire_profil_personnage(), building minimal profil")
        profil = {"fiche_complete": {"stats_brutes": {}}}

    var clan_mgr = get_root().get_node_or_null("/root/ClanManager")
    if clan_mgr == null:
        print("ERROR: ClanManager autoload not found")
        quit(20)
        return
    # Pass empty stats_bonus (actual raw stats are in profil.fiche_complete.stats_brutes)
    clan_mgr.nouvelle_partie("E2E", "E2EClan", "hellcaster", {}, profil)
    print("Called ClanManager.nouvelle_partie(...)")

    # Wait a few frames to let autoloads persist files
    await process_frame
    await process_frame
    await process_frame
    print("E2E: waited frames, checking SaveSystem")

    var save_system = get_root().get_node_or_null("/root/SaveSystem")
    if save_system == null:
        print("ERROR: /root/SaveSystem not found")
        quit(10)
        return

    ## Use class_name JsonPersistenceService in tests.
    var path = save_system.get_clan_save_path()
    print("Save path:", path)
    var saved = JsonPersistenceService.read_json_with_backup(path)
    if saved.is_empty():
        print("FAIL: saved file empty or missing at:", path)
        quit(11)
        return

    profil = saved.get("profil_personnage", {}) as Dictionary
    if profil.is_empty():
        print("FAIL: profil_personnage missing in saved data")
        quit(12)
        return

    var fiche = (profil.get("fiche_complete", {}) as Dictionary)
    if not fiche.has("stats_brutes"):
        print("FAIL: fiche_complete.stats_brutes missing in saved profil")
        print("Saved profil keys:", profil.keys())
        quit(13)
        return

    print("PASS: fiche_complete.stats_brutes saved:", fiche.get("stats_brutes"))
    quit(0)
