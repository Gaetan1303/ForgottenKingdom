extends SceneTree

func _init():
    call_deferred("_run")

func _run() -> void:
    var clan_mgr = get_root().get_node_or_null("/root/ClanManager")
    if clan_mgr == null:
        print("ERROR: ClanManager not found")
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
    clan_mgr.nouvelle_partie("E2E", "E2EClan", "mage_du_pacte", {}, profil)
    print("Called nouvelle_partie; now instantiating clan_hub scene to check UI flow")
    var hub_path := "res://scenes/clan_hub.tscn"
    if not ResourceLoader.exists(hub_path):
        print("clan_hub scene missing")
        quit(2)
        return
    var hub_scene = load(hub_path)
    var hub_inst = hub_scene.instantiate()
    get_root().add_child(hub_inst)
    # allow _ready to execute
    await process_frame
    await process_frame
    await process_frame
    # Request profile view to force building the character sheet
    if hub_inst.has_method("_afficher_vue_profil"):
        hub_inst._afficher_vue_profil()
        print("Requested _afficher_vue_profil() on clan_hub instance")
        await process_frame
        await process_frame
        # Iterative DFS to find character_sheet instance and inspect its _character.stats
        var stack = [hub_inst]
        var sheet = null
        while stack.size() > 0 and sheet == null:
            var node = stack.pop_back()
            if node == null:
                continue
            if node.get_script() != null:
                var spath := str(node.get_script().get_path())
                if spath.ends_with("character_sheet.gd"):
                    sheet = node
                    break
            for c in node.get_children():
                stack.append(c)
        if sheet != null:
            print("Found sheet instance:", sheet)
            if sheet.has("_character"):
                var ch = sheet.get("_character")
                if ch != null and ch.has("stats"):
                    print("Sheet._character.stats =", JSON.stringify(ch.stats))
                else:
                    print("Sheet._character present but no stats")
            else:
                print("Sheet found but no _character variable")
        else:
            print("No character_sheet instance found under clan_hub")
    quit(0)
