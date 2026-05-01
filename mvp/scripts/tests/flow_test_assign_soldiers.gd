extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    # Init new game to get default resources
    var clan := root.get_node("ClanManager")
    clan.nouvelle_partie("Ingrid", "Clan Test", "mage_du_pacte", {"force":1}, {})
    print("Soldats avant:", int(clan.ressources.get("soldats", 0)))
    var res: Dictionary = clan.planifier_mission_soldats("collecter_bois", 10)
    print("Planifier result:", JSON.stringify(res))
    var report: Dictionary = clan.resoudre_planning_pnj_journee()
    print("Report:", JSON.stringify(report))
    print("Soldats apres:", int(clan.ressources.get("soldats", 0)))
    print("Bois apres:", int(clan.ressources.get("bois", 0)))
    quit(0)
