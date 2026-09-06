extends SceneTree
var failures: Array[String] = []
func _init() -> void:
	call_deferred("_run")
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func settle() -> void:
	for _i in range(6): await process_frame
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := root.get_node("GameManager")
	var cm := root.get_node("ClanManager")
	var save := root.get_node("SaveSystem")
	save.set_active_slot("navigation_test")
	game.start_new_game()
	await settle()
	check(current_scene.scene_file_path.contains("character_creation_screen"), "nouvelle partie ouvre la création")
	var raw := {"force": 10, "magie": 12, "espionnage": 10, "artisanat": 8, "diplomatie": 8, "commandement": 10}
	current_scene._on_creation_completed({"character": {"character_name": "Aren", "clan_name": "Les Cendres", "class_id": "hellcaster", "stats": raw, "secondary_stats": {"ESP": 0, "TRA": 0, "ESE": 0}}, "final_stats": raw})
	await settle()
	check(current_scene.scene_file_path.ends_with("intro_vn.tscn"), "validation mène au prologue")
	check(cm.nom_clan == "Les Cendres" and not cm.campaign.is_empty(), "identité et progression initialisées")
	current_scene._show_scene(1)
	await settle()
	var saved_index: int = cm.campaign.intro_index
	game.open_slot_select()
	await settle()
	current_scene._selected_slot_id = "navigation_test"
	current_scene._on_load_pressed()
	await settle()
	check(current_scene.scene_file_path.ends_with("intro_vn.tscn") and current_scene._idx == saved_index, "rechargement reprend le bon choix")
	# Les boutons, et non les seules règles métier, font avancer les choix.
	current_scene._choices.get_child(0).pressed.emit()
	await settle()
	check(current_scene._idx == 2, "bouton narratif avance une seule fois")
	current_scene._show_scene(3)
	await settle()
	current_scene._choices.get_child(1).pressed.emit()
	await settle()
	check(current_scene._idx == 4, "second choix narratif jouable")
	current_scene._show_scene(5)
	current_scene._finish()
	await create_timer(1.4).timeout
	await settle()
	check(current_scene.scene_file_path.ends_with("clan_hub.tscn"), "fin narrative ouvre le domaine")
	check(bool(cm.campaign.intro_done), "fin intro sauvegardée")
	var dungeon := root.get_node("DungeonGenerator")
	dungeon.start_expedition(["pnj_kael"])
	dungeon.resolve_quiet_room()
	dungeon.advance_room()
	dungeon.ensure_battle()
	game.open_slot_select()
	await settle()
	current_scene._selected_slot_id = "navigation_test"
	current_scene._on_load_pressed()
	await settle()
	check(current_scene.scene_file_path.ends_with("dungeon_view.tscn"), "chargement rejoint la sortie active")
	current_scene._on_exit()
	await settle()
	check(current_scene.scene_file_path.ends_with("clan_hub.tscn"), "retour du combat au domaine")
	if failures.is_empty():
		print("PROLOGUE_NAVIGATION_OK")
		quit(0)
	else:
		for failure in failures: push_error("NAVIGATION_FAIL: " + failure)
		quit(1)
