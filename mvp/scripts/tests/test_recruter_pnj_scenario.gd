extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    print("TEST: start recruter_pnj scenario")

    # Ensure ClanManager autoload exists
    var cm = root.get_node_or_null("ClanManager")
    if cm == null:
        push_error("ClanManager not found")
        quit(1)
        return

    # Show roster before
    var state_before = cm.get_pnj_gestion_state()
    var roster_before = state_before.get("roster", []) as Array
    print("Roster before: %d" % roster_before.size())

    # Trigger domain recruitment logic and apply effects that will generate a PNJ
    var role = cm.recruter_pnj_domaine()
    if role == "":
        print("No role available for recruitment")
        quit(0)
        return

    print("Role chosen for recruitment: %s" % role)

    # Apply effects to invoke generator
    cm._appliquer_effets({"pnj_recrute": 1, "pnj_role": role})

    var state_after = cm.get_pnj_gestion_state()
    var roster_after := state_after.get("roster", []) as Array
    print("Roster after: %d" % roster_after.size())
    if roster_after.size() > roster_before.size():
        print("New PNJ registered: %s" % str(roster_after[roster_after.size()-1]))

    # Instantiate PNJ Manager scene and open recruited dialog
    var sc = load("res://scenes/pnj_manager.tscn") as PackedScene
    if sc == null:
        push_error("Failed to load pnj_manager.tscn")
        quit(1)
        return
    var inst = sc.instantiate()
    if inst == null:
        push_error("Failed to instantiate pnj_manager.tscn")
        quit(1)
        return
    root.add_child(inst)
    print("PNJ manager instantiated")

    # Wait a frame for UI to initialize then open recruited list
    call_deferred("_deferred_show", inst)

func _deferred_show(inst):
    # Call show recruited button handler if present
    if inst.has_method("_on_show_recruited"):
        inst._on_show_recruited()
        print("Recruited dialog requested")
    else:
        print("PNJ manager missing _on_show_recruited")

    # Inspect recruited list contents
    var dlg = inst.get_node_or_null("RecruitedDialog")
    if dlg == null:
        print("RecruitedDialog not found on manager instance")
        quit(1)
        return
    var list = dlg.get_node_or_null("RecruitedVBox/RecruitedScroll/RecruitedList")
    if list == null:
        list = dlg.get_node_or_null("RecruitedScroll/RecruitedList")
    if list == null:
        print("RecruitedList not found")
        quit(1)
        return

    print("Recruited list count: %d" % list.get_child_count())
    for i in range(list.get_child_count()):
        var child = list.get_child(i)
        var name = "(no name)"
        if child.has_method("get_profile"):
            # not guaranteed
            name = str(child.get_profile().get("nom", "?"))
        else:
            # try label inside
            var lbl = child.get_node_or_null("HBox/Left/LabelName")
            if lbl:
                name = lbl.text
            else:
                name = child.name
        print(" - item %d : %s" % [i, name])

    quit(0)
