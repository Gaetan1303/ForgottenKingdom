extends VBoxContainer
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const ACTION_LABELS := {
    "collecter_bois": "Collecter le bois",
    "collecter_fer": "Collecter le fer",
    "collecter_pierre": "Collecter la pierre",
    "collecter_nourriture": "Collecter la nourriture",
    "espionner": "Envoyer en espionnage",
    "securiser": "Securiser la zone",
}

const ACTION_DESCRIPTIONS := {
    "collecter_bois": "Ramene du bois (construction)",
    "collecter_fer": "Ramene du fer (artisanat)",
    "collecter_pierre": "Ramene de la pierre (fortification)",
    "collecter_nourriture": "Collecte de nourriture pour le clan",
    "espionner": "Renseignements (risque faible)",
    "securiser": "Ameliore la reputation locale",
}

var _title: Label = null
var _status: Label = null
var _roster: VBoxContainer = null
var _plan_list: VBoxContainer = null
var _task_selector: OptionButton = null
var _btn_assign_soldiers: Button = null
var _btn_resolve: Button = null
var _btn_back: Button = null
var _confirm_dialog: ConfirmationDialog = null
var _soldier_count: SpinBox = null
var _apply_now: CheckBox = null
var _btn_show_recruited: Button = null
var _recruited_dialog: PanelContainer = null
var _recruited_list: VBoxContainer = null

var _pending_action: Dictionary = {}


func _ready() -> void:
    FallenUI.apply(self, "clan")
    call_deferred("_init_ui")


func _init_ui() -> void:
    _ensure_ui_nodes()

    _title.text = "Gestion des PNJ — Planification"
    _confirm_dialog.ok_button_text = "Confirmer"
    var _confirm_cb := Callable(self, "_on_confirmed")
    if not _confirm_dialog.is_connected("confirmed", _confirm_cb):
        _confirm_dialog.connect("confirmed", _confirm_cb)

    _btn_assign_soldiers.text = "Assigner tous les soldats"
    _btn_resolve.text = "Résoudre"
    _btn_back.text = "Retour"

    var _assign_cb := Callable(self, "_on_assign_all_soldiers")
    var _resolve_cb := Callable(self, "_on_resolve")
    var _back_cb := Callable(self, "_on_back")
    if not _btn_assign_soldiers.is_connected("pressed", _assign_cb):
        _btn_assign_soldiers.connect("pressed", _assign_cb)
    if not _btn_resolve.is_connected("pressed", _resolve_cb):
        _btn_resolve.connect("pressed", _resolve_cb)
    if not _btn_back.is_connected("pressed", _back_cb):
        _btn_back.connect("pressed", _back_cb)

    _populate_task_selector()
    _refresh_roster()
    _refresh_recruited()
    _refresh_planning_summary()
    _update_soldier_ui()

    # Connect spinbox changes to update button text dynamically
    if _soldier_count:
        var _soldier_cb := Callable(self, "_on_soldier_count_changed")
        if not _soldier_count.is_connected("value_changed", _soldier_cb):
            _soldier_count.connect("value_changed", _soldier_cb)


func _ensure_ui_nodes() -> void:
    var header := get_node_or_null("Header")
    if not header:
        header = PanelContainer.new()
        header.name = "Header"
        add_child(header)

    _title = header.get_node_or_null("Title")
    if not _title:
        _title = Label.new()
        _title.name = "Title"
        header.add_child(_title)

    var body := get_node_or_null("Body")
    if not body:
        body = VBoxContainer.new()
        body.name = "Body"
        add_child(body)

    var roster_scroll := body.get_node_or_null("RosterScroll")
    if not roster_scroll:
        roster_scroll = ScrollContainer.new()
        roster_scroll.name = "RosterScroll"
        roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        body.add_child(roster_scroll)

    _roster = roster_scroll.get_node_or_null("RosterList")
    if not _roster:
        _roster = VBoxContainer.new()
        _roster.name = "RosterList"
        _roster.custom_minimum_size = Vector2(0, 260)
        roster_scroll.add_child(_roster)

    var planning_summary := body.get_node_or_null("PlanningSummary")
    if not planning_summary:
        planning_summary = PanelContainer.new()
        planning_summary.name = "PlanningSummary"
        planning_summary.custom_minimum_size = Vector2(0, 160)
        body.add_child(planning_summary)

    var planning_box := planning_summary.get_node_or_null("PlanVBox")
    if not planning_box:
        planning_box = VBoxContainer.new()
        planning_box.name = "PlanVBox"
        planning_summary.add_child(planning_box)

    var plan_header := planning_box.get_node_or_null("PlanHeader")
    if not plan_header:
        plan_header = Label.new()
        plan_header.name = "PlanHeader"
        plan_header.text = "Planification"
        planning_box.add_child(plan_header)

    _plan_list = planning_box.get_node_or_null("PlanList")
    if not _plan_list:
        _plan_list = VBoxContainer.new()
        _plan_list.name = "PlanList"
        planning_box.add_child(_plan_list)

    # Recruited PNJ button in header area (shows modal with PNJ cards)
    _btn_show_recruited = get_node_or_null("BtnShowRecruited")
    if not _btn_show_recruited:
        _btn_show_recruited = Button.new()
        _btn_show_recruited.name = "BtnShowRecruited"
        _btn_show_recruited.text = "PNJ recruté"
        # will be parented into Footer/BtnsRight later when created

    _recruited_dialog = get_node_or_null("RecruitedDialog")
    if not _recruited_dialog:
        _recruited_dialog = PanelContainer.new()
        _recruited_dialog.name = "RecruitedDialog"
        _recruited_dialog.custom_minimum_size = Vector2(400, 320)
        _recruited_dialog.visible = false
        add_child(_recruited_dialog)

        var dlg_vbox := VBoxContainer.new()
        dlg_vbox.name = "RecruitedVBox"
        _recruited_dialog.add_child(dlg_vbox)

        var title := Label.new()
        title.text = "PNJ recrutés"
        dlg_vbox.add_child(title)

        var recruited_scroll := ScrollContainer.new()
        recruited_scroll.name = "RecruitedScroll"
        recruited_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        recruited_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        dlg_vbox.add_child(recruited_scroll)

        _recruited_list = VBoxContainer.new()
        _recruited_list.name = "RecruitedList"
        _recruited_list.custom_minimum_size = Vector2(0, 300)
        recruited_scroll.add_child(_recruited_list)
    else:
        _recruited_list = _recruited_dialog.get_node_or_null("RecruitedScroll/RecruitedList")

    var footer := get_node_or_null("Footer")
    if not footer:
        footer = VBoxContainer.new()
        footer.name = "Footer"
        footer.custom_minimum_size = Vector2(0, 96)
        add_child(footer)

    _status = footer.get_node_or_null("Status")
    if not _status:
        _status = Label.new()
        _status.name = "Status"
        _status.text = "Prêt"
        footer.add_child(_status)

    var controls := footer.get_node_or_null("FooterControls")
    if not controls:
        controls = HFlowContainer.new()
        controls.name = "FooterControls"
        controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        footer.add_child(controls)

    _task_selector = controls.get_node_or_null("TaskSelector")
    if not _task_selector:
        _task_selector = OptionButton.new()
        _task_selector.name = "TaskSelector"
        controls.add_child(_task_selector)

    _soldier_count = controls.get_node_or_null("SoldierCount")
    if not _soldier_count:
        _soldier_count = SpinBox.new()
        _soldier_count.name = "SoldierCount"
        _soldier_count.min_value = 0
        _soldier_count.max_value = 999
        _soldier_count.step = 1
        _soldier_count.value = 0
        controls.add_child(_soldier_count)

    _apply_now = controls.get_node_or_null("ApplyNow")
    if not _apply_now:
        _apply_now = CheckBox.new()
        _apply_now.name = "ApplyNow"
        _apply_now.text = "Appliquer maintenant"
        controls.add_child(_apply_now)

    var right_buttons := controls.get_node_or_null("BtnsRight")
    if not right_buttons:
        right_buttons = HFlowContainer.new()
        right_buttons.name = "BtnsRight"
        right_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        controls.add_child(right_buttons)

    # Place the 'PNJ recruté' button into the responsive action area.
    if _btn_show_recruited and not _btn_show_recruited.get_parent():
        right_buttons.add_child(_btn_show_recruited)

    _btn_assign_soldiers = right_buttons.get_node_or_null("BtnAssignSoldiers")
    if not _btn_assign_soldiers:
        _btn_assign_soldiers = Button.new()
        _btn_assign_soldiers.name = "BtnAssignSoldiers"
        right_buttons.add_child(_btn_assign_soldiers)

    _btn_resolve = right_buttons.get_node_or_null("BtnResolve")
    if not _btn_resolve:
        _btn_resolve = Button.new()
        _btn_resolve.name = "BtnResolve"
        right_buttons.add_child(_btn_resolve)

    _btn_back = right_buttons.get_node_or_null("BtnBack")
    if not _btn_back:
        _btn_back = Button.new()
        _btn_back.name = "BtnBack"
        right_buttons.add_child(_btn_back)

    _confirm_dialog = get_node_or_null("ConfirmDialog")
    if not _confirm_dialog:
        _confirm_dialog = ConfirmationDialog.new()
        _confirm_dialog.name = "ConfirmDialog"
        add_child(_confirm_dialog)

    # Connect recruited button
    if _btn_show_recruited:
        var _show_cb := Callable(self, "_on_show_recruited")
        if not _btn_show_recruited.is_connected("pressed", _show_cb):
            _btn_show_recruited.connect("pressed", _show_cb)


func _update_soldier_ui() -> void:
    # Sync the SoldierCount max to available soldiers and disable assign if none
    var avail := ClanManager.get_ressource("soldats", 0)
    if _soldier_count:
        _soldier_count.max_value = max(0, avail)
        if int(_soldier_count.value) > int(_soldier_count.max_value):
            _soldier_count.value = _soldier_count.max_value
    if _btn_assign_soldiers:
        _btn_assign_soldiers.disabled = avail <= 0
        # Update button text according to selected count
        if _soldier_count and int(_soldier_count.value) > 0:
            _btn_assign_soldiers.text = "Assigner %d" % int(_soldier_count.value)
        else:
            _btn_assign_soldiers.text = "Assigner"



func _populate_task_selector() -> void:
    _task_selector.clear()
    for action_id in ACTION_LABELS.keys():
        _task_selector.add_item(str(ACTION_LABELS[action_id]))
        var idx := _task_selector.get_item_count() - 1
        _task_selector.set_item_metadata(idx, action_id)
        var desc := str(ACTION_DESCRIPTIONS.get(action_id, ""))
        if not desc.is_empty():
            _task_selector.set_item_tooltip(idx, desc)


func _selected_action_id() -> String:
    var selected: int = _task_selector.get_selected()
    if selected < 0:
        return "collecter_bois"
    var meta: Variant = _task_selector.get_item_metadata(selected)
    if meta == null:
        return "collecter_bois"
    return str(meta)


func _refresh_roster() -> void:
    for child in _roster.get_children():
        _roster.remove_child(child)
        child.queue_free()

    var state := ClanManager.get_pnj_gestion_state()
    var roster := state.get("roster", []) as Array

    if roster.is_empty():
        var empty := Label.new()
        empty.text = "Aucun PNJ géré"
        _roster.add_child(empty)
        return

    for pnj_data in roster:
        _roster.add_child(_make_pnj_row(pnj_data as Dictionary))

    # Keep the recruited list up to date as well
    _refresh_recruited()

    # Update soldier UI after roster refresh
    _update_soldier_ui()


func _make_pnj_row(pnj: Dictionary) -> Control:
    # Build inline PNJ row (legacy) to avoid scene instantiation warnings
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(0, 56)

    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var portrait_tex := TextureRect.new()
    VisualAssetCatalog.apply_fit(portrait_tex, "portrait")
    var target_size := Vector2(72, 88)
    portrait_tex.custom_minimum_size = target_size
    portrait_tex.size_flags_horizontal = 0
    portrait_tex.size_flags_vertical = 0
    # Try PNJ-id based images first (e.g. pnj id 'pnj_kael' -> 'kael')
    var pnj_id_raw := str(pnj.get("id", "")).to_lower()
    var pnj_basename := ""
    if pnj_id_raw != "":
        pnj_basename = pnj_id_raw.replace("pnj_", "")
        pnj_basename = pnj_basename.replace(".pnj", "")
    var pnj_class = str(pnj.get("classe", pnj.get("role", ""))).to_lower()
    var exts = [".png", ".jpg", ".webp", ".svg"]
    var loaded_tex: Texture2D = null
    # 0) Portrait explicite défini dans la donnée PNJ.
    var explicit_portrait := str(pnj.get("portrait", pnj.get("portrait_path", ""))).strip_edges()
    if not explicit_portrait.is_empty():
        loaded_tex = ResourcePathResolver.load_texture(explicit_portrait, "res://assets/images/PNJ")
    # 1) Try id-based exact paths: res://assets/images/PNJ/<basename>/<basename>.<ext>
    if loaded_tex == null and pnj_basename != "":
        for e in exts:
            var p_id = "res://assets/images/PNJ/%s/%s" % [pnj_basename, pnj_basename] + e
            if ResourceLoader.exists(p_id):
                loaded_tex = load(p_id)
                break
        # 2) Try id-based directly under PNJ folder: res://assets/images/PNJ/<basename>.<ext>
        if not loaded_tex:
            for e in exts:
                var p_id2 = "res://assets/images/PNJ/%s" % pnj_basename + e
                if ResourceLoader.exists(p_id2):
                    loaded_tex = load(p_id2)
                    break
    # 3) Try mvp/ui assets with basename
    if not loaded_tex and pnj_basename != "":
        var ui_try = "res://assets/ui/%s.png" % pnj_basename
        if ResourceLoader.exists(ui_try):
            loaded_tex = load(ui_try)

    # 3b) Search all subfolders of assets/images/PNJ for a file matching basename (case-insensitive)
    if not loaded_tex and pnj_basename != "":
        var root = DirAccess.open("res://assets/images/PNJ")
        if root != null:
            root.list_dir_begin()
            var entry = root.get_next()
            while entry != "":
                if root.current_is_dir():
                    var sub = DirAccess.open("res://assets/images/PNJ/%s" % entry)
                    if sub != null:
                        sub.list_dir_begin()
                        var fname2 = sub.get_next()
                        while fname2 != "":
                            if not sub.current_is_dir():
                                var lower_fname = fname2.to_lower()
                                for e in exts:
                                    if lower_fname.ends_with(e) and lower_fname.substr(0, lower_fname.length() - e.length()) == pnj_basename:
                                        var p2 = "res://assets/images/PNJ/%s/%s" % [entry, fname2]
                                        if ResourceLoader.exists(p2):
                                            loaded_tex = load(p2)
                                            break
                                if loaded_tex:
                                    break
                            fname2 = sub.get_next()
                        sub.list_dir_end()
                        if loaded_tex:
                            break
                entry = root.get_next()
            root.list_dir_end()

    # 4) Class-based lookup (existing logic)
    if not loaded_tex and pnj_class != "":
        var base = "res://assets/images/PNJ/%s/%s" % [pnj_class, pnj_class]
        for e in exts:
            var p = base + e
            if ResourceLoader.exists(p):
                loaded_tex = load(p)
                break
        if not loaded_tex:
            var dir = DirAccess.open("res://assets/images/PNJ/%s" % pnj_class)
            if dir != null:
                dir.list_dir_begin()
                var fname = dir.get_next()
                while fname != "":
                    if not dir.current_is_dir():
                        for e2 in exts:
                            if fname.to_lower().ends_with(e2):
                                var p2 = "res://assets/images/PNJ/%s/%s" % [pnj_class, fname]
                                if ResourceLoader.exists(p2):
                                    loaded_tex = load(p2)
                                    break
                        if loaded_tex:
                            break
                    fname = dir.get_next()
                dir.list_dir_end()
    # Determine selected texture. Unknown gender stays intentionally blank rather than
    # displaying the wrong person.
    var selected_tex: Texture2D = loaded_tex
    if selected_tex == null:
        var gender_val := str(pnj.get("sexe", pnj.get("gender", pnj.get("genre", "")))).to_lower()
        var fallback_path := ""
        if gender_val.contains("femme") or gender_val.contains("female"):
            fallback_path = VisualAssetCatalog.person_path("generic_female")
        elif gender_val.contains("homme") or gender_val.contains("male"):
            fallback_path = VisualAssetCatalog.person_path("generic_male")
        if not fallback_path.is_empty():
            selected_tex = ResourcePathResolver.load_texture(fallback_path, "res://assets/images/PNJ")

    if selected_tex != null:
        portrait_tex.texture = selected_tex
    else:
        push_warning("PNJ portrait non défini pour %s; aucune image arbitraire utilisée." % str(pnj.get("nom", "?")))

    var left := VBoxContainer.new()
    var name_label := Label.new()
    name_label.text = "%s\n%s (niv.%d)" % [
        str(pnj.get("nom", "PNJ")),
        str(pnj.get("role", "?")),
        int(pnj.get("niveau", 1))
    ]
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.add_child(name_label)
    # add portrait to the left of the text
    row.add_child(portrait_tex)
    row.add_child(left)

    var stretch := Control.new()
    stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(stretch)

    var available := str(pnj.get("etat", "disponible")) == "disponible"
    var pnj_id := str(pnj.get("id", ""))
    var pnj_name := str(pnj.get("nom", pnj_id))

    var support_button := Button.new()
    support_button.text = "Support"
    support_button.disabled = not available
    support_button.connect("pressed", _request_action.bind({
        "type": "support",
        "pnj_id": pnj_id,
        "label": pnj_name,
    }))
    row.add_child(support_button)

    var expedition_button := Button.new()
    expedition_button.text = "Expédition"
    expedition_button.disabled = not available
    expedition_button.connect("pressed", _request_action.bind({
        "type": "expedition",
        "pnj_id": pnj_id,
        "label": pnj_name,
    }))
    row.add_child(expedition_button)

    panel.add_child(row)
    panel.custom_minimum_size = Vector2(0, 100)
    return panel


func _refresh_planning_summary() -> void:
    for child in _plan_list.get_children():
        child.queue_free()

    var state := ClanManager.get_pnj_gestion_state()
    var planning := state.get("planning", {}) as Dictionary
    var soldier_missions := planning.get("missions_soldats", []) as Array
    var pnj_missions := planning.get("missions_pnj", []) as Array

    _add_section_label("Soldats")
    for i in range(soldier_missions.size()):
        var mission := soldier_missions[i] as Dictionary
        _add_soldier_mission_row(i, mission)

    _add_section_label("PNJ")
    for j in range(pnj_missions.size()):
        var mission_pnj := pnj_missions[j] as Dictionary
        _add_cancellable_row(
            "%s : %s" % [str(mission_pnj.get("mission_type", "?")), str(mission_pnj.get("pnj_id", "?"))],
            _on_cancel_pnj.bind(j)
        )

    if soldier_missions.is_empty() and pnj_missions.is_empty():
        var empty := Label.new()
        empty.text = "Aucune mission planifiée"
        _plan_list.add_child(empty)


func _add_section_label(text_value: String) -> void:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", 12)
    _plan_list.add_child(label)


func _add_cancellable_row(text_value: String, callback: Callable) -> void:
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = text_value
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)

    var cancel_button := Button.new()
    cancel_button.text = "Annuler"
    cancel_button.connect("pressed", callback)
    row.add_child(cancel_button)

    _plan_list.add_child(row)


func _add_soldier_mission_row(index: int, mission: Dictionary) -> void:
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var label := Label.new()
    var effectif := int(mission.get("effectif", 0))
    var action := str(mission.get("action_id", "?"))
    label.text = "%d x %s" % [effectif, action]
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)

    # Quick adjust controls: -5, -1, +1, +5
    var controls := HBoxContainer.new()
    var btn_minus5 := Button.new()
    btn_minus5.text = "-5"
    btn_minus5.tooltip_text = "Retirer 5 soldats"
    btn_minus5.connect("pressed", _on_adjust_soldier_count.bind(index, -5))
    controls.add_child(btn_minus5)

    var btn_minus1 := Button.new()
    btn_minus1.text = "-1"
    btn_minus1.tooltip_text = "Retirer 1 soldat"
    btn_minus1.connect("pressed", _on_adjust_soldier_count.bind(index, -1))
    controls.add_child(btn_minus1)

    var btn_plus1 := Button.new()
    btn_plus1.text = "+1"
    btn_plus1.tooltip_text = "Ajouter 1 soldat"
    btn_plus1.connect("pressed", _on_adjust_soldier_count.bind(index, 1))
    controls.add_child(btn_plus1)

    var btn_plus5 := Button.new()
    btn_plus5.text = "+5"
    btn_plus5.tooltip_text = "Ajouter 5 soldats"
    btn_plus5.connect("pressed", _on_adjust_soldier_count.bind(index, 5))
    controls.add_child(btn_plus5)

    row.add_child(controls)

    var cancel_button := Button.new()
    cancel_button.text = "Annuler"
    cancel_button.connect("pressed", _on_cancel_soldier.bind(index))
    row.add_child(cancel_button)

    _plan_list.add_child(row)


func _request_action(ctx: Dictionary) -> void:
    _pending_action = ctx.duplicate(true)
    _confirm_dialog.dialog_text = "Confirmer : %s pour %s ?" % [
        str(ctx.get("type", "")),
        str(ctx.get("label", "PNJ"))
    ]
    _confirm_dialog.popup_centered()


func _on_confirmed() -> void:
    if _pending_action.is_empty():
        return

    var action_type := str(_pending_action.get("type", ""))
    var pnj_id := str(_pending_action.get("pnj_id", ""))
    var result: Dictionary

    if action_type == "support":
        result = ClanManager.assigner_pnj_support_journee(pnj_id, "attaquer")
    elif action_type == "expedition":
        result = ClanManager.assigner_pnj_expedition_journee(pnj_id, -1)
    else:
        result = {"ok": false, "error": "type_inconnu"}

    _handle_result(result, "%s assigne : %s" % [action_type, pnj_id])
    _pending_action.clear()
    _refresh_roster()
    _refresh_planning_summary()


func _on_show_recruited() -> void:
    _refresh_recruited()
    if _recruited_dialog:
        _recruited_dialog.visible = true


func _refresh_recruited() -> void:
    if not _recruited_list:
        return

    for child in _recruited_list.get_children():
        _recruited_list.remove_child(child)
        child.queue_free()

    var state := ClanManager.get_pnj_gestion_state()
    var roster := state.get("roster", []) as Array
    if roster.is_empty():
        var empty := Label.new()
        empty.text = "Aucun PNJ recruté"
        _recruited_list.add_child(empty)
        return

    for pnj_data in roster:
        # Use the inline builder to avoid instantiation issues
        var item = _make_pnj_row(pnj_data as Dictionary)
        if item:
            # in recruited dialog we want the card to be non-interactive and show details
            _recruited_list.add_child(item)


func _on_assign_all_soldiers() -> void:
    var action_id := _selected_action_id()

    # Determine number of soldiers to assign from UI (SoldierCount) or fallback to all available
    var soldiers_to_assign: int = 0
    if _soldier_count:
        soldiers_to_assign = int(_soldier_count.value)
    else:
        soldiers_to_assign = ClanManager.get_ressource("soldats", 0)

    var avail_total := ClanManager.get_ressource("soldats", 0)
    if soldiers_to_assign <= 0:
        _set_status("Aucun soldat sélectionné")
        return
    if soldiers_to_assign > avail_total:
        # Cap request to available to avoid crash
        soldiers_to_assign = avail_total
        _set_status("Nombre réduit au stock disponible (%d)" % soldiers_to_assign)

    var result := ClanManager.planifier_mission_soldats(action_id, soldiers_to_assign)
    _handle_result(result, "%d soldats -> %s" % [soldiers_to_assign, action_id])
    _refresh_planning_summary()
    _update_soldier_ui()

    # Confirmation visuelle plus explicite quand réservation OK
    if bool(result.get("ok", false)):
        var assigned := int(result.get("assigned", soldiers_to_assign))
        if str(result.get("warning", "")) == "insufficient":
            _set_status("Seuls %d soldats réservés (stock insuffisant)" % assigned)
        else:
            _set_status("%d soldats réservés" % assigned)

    # Si "Appliquer maintenant" est coché, résoudre immédiatement
    if _apply_now and _apply_now.is_pressed() and bool(result.get("ok", false)):
        _on_resolve()


func _on_soldier_count_changed(value: float) -> void:
    # Value comes as float from SpinBox signal
    _update_soldier_ui()


func _on_resolve() -> void:
    var state := ClanManager.get_pnj_gestion_state()
    var planning := state.get("planning", {}) as Dictionary
    var missions_soldats := planning.get("missions_soldats", []) as Array
    var missions_pnj := planning.get("missions_pnj", []) as Array

    if missions_soldats.is_empty() and missions_pnj.is_empty():
        _set_status("Aucune mission à résoudre")
        return

    var report := ClanManager.resoudre_planning_pnj_journee()
    ClanManager.sauvegarder()
    var gains := report.get("resource_gains", {}) as Dictionary
    _set_status("Résolu — bois +%d | or +%d" % [int(gains.get("bois", 0)), int(gains.get("or", 0))])
    _refresh_roster()
    _refresh_planning_summary()


func _on_back() -> void:
    GameManager.go_to("clan_hub")


func _on_cancel_soldier(index: int) -> void:
    var result := ClanManager.annuler_mission_soldats(index)
    _handle_result(result, "Mission des soldats annulée")
    _refresh_planning_summary()


func _on_adjust_soldier_count(mission_index: int, delta: int) -> void:
    var result := ClanManager.adjust_mission_soldier_count(mission_index, delta)
    if bool(result.get("ok", false)):
        if result.has("warning") and str(result.get("warning", "")) == "insufficient":
            _set_status("Impossible d’en assigner autant : stock insuffisant")
        else:
            _set_status("Ajustement effectué")
        ClanManager.sauvegarder()
    else:
        _set_status("Erreur : %s" % str(result.get("error", "inconnue")))
    _refresh_planning_summary()
    _update_soldier_ui()


func _on_cancel_pnj(index: int) -> void:
    var result := ClanManager.annuler_mission_pnj(index)
    _handle_result(result, "Mission du PNJ annulée")
    _refresh_roster()
    _refresh_planning_summary()


func _set_status(text_value: String) -> void:
    if _status:
        _status.text = text_value


func _handle_result(result: Dictionary, success_message: String) -> void:
    if bool(result.get("ok", false)):
        _set_status(success_message)
        ClanManager.sauvegarder()
    else:
        _set_status("Erreur : %s" % str(result.get("error", "inconnue")))
