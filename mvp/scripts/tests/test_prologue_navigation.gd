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
	check(current_scene.scene_file_path.ends_with("intro_vn.tscn"), "nouvelle partie ouvre le prologue")
	check(current_scene._scenes.size() == 3, "exactement trois tableaux")
	check(current_scene._scenes.map(func(s: Dictionary): return s.id) == ["duel", "stolen_essence", "presumed_death"], "duel, Essence, mort dans cet ordre")
	current_scene._btn_continue.pressed.emit()
	await create_timer(0.15).timeout
	check(current_scene._story_text.visible_ratio == 1.0 and current_scene._idx == 0, "révélation du texte stable, sans saut de scène")
	current_scene._show_scene(1)
	await settle()
	var saved_index: int = save.get_value("opening", {}).index
	game.open_slot_select()
	await settle()
	current_scene._selected_slot_id = "navigation_test"
	current_scene._on_load_pressed()
	await settle()
	check(current_scene.scene_file_path.ends_with("intro_vn.tscn") and current_scene._idx == saved_index, "rechargement reprend le bon choix")
	current_scene._on_continue() # Révéler le tableau rechargé.
	current_scene._on_continue() # Passer à la mort supposée.
	check(current_scene._idx == 2, "dernier tableau après le vol")
	current_scene._finish()
	await create_timer(1.4).timeout
	await settle()
	check(current_scene.scene_file_path.ends_with("memory_tutorial.tscn"), "mort ouvre les souvenirs")
	var actions := ["training_attack", "training_defend", "training_night", "training_cast", "ward", "bind", "infiltrate", "audience", "use_secret", "formation_guard", "command_assault", "materials", "craft_grounded"]
	for action in actions:
		var before_step: int = current_scene._memory.step
		current_scene._ack.pressed.emit()
		check(current_scene._memory.step == before_step, "bouton continuer ne valide pas une action absente")
		current_scene._actions.get_node(action).pressed.emit()
		await settle()
		var retries := 0
		while not current_scene._memory.awaiting_ack and retries < 8:
			current_scene._actions.get_node("materials").pressed.emit()
			current_scene._actions.get_node(action).pressed.emit()
			retries += 1
		check(current_scene._memory.awaiting_ack, "action UI validée : " + action)
		check(current_scene._ack.get_global_rect().end.y <= 720, "confirmation visible")
		current_scene._ack.pressed.emit()
		await settle()
	check(current_scene._memory.completed.size() == 6, "six leçons jouées")
	check(current_scene.scene_file_path.ends_with("memory_tutorial.tscn"), "résumé attend confirmation")
	game.go_to_menu()
	await settle()
	game.resume_campaign()
	await settle()
	check(current_scene._memory.finished, "résumé repris après fermeture")
	current_scene._ack.pressed.emit()
	await settle()
	check(current_scene.scene_file_path.contains("character_creation_screen"), "souvenirs ouvrent reconstruction")
	var manager = current_scene._manager
	var powers: Dictionary = root.get_node("GameDataLoader").get_character_traits().get("pouvoirs", {})
	manager.update_from_slide(0, {"character_name": "Aren", "clan_name": "Les Cendres", "racial_power_id": str(powers.keys()[0])})
	check(manager.try_go_next(), "identité validée")
	manager.update_from_slide(1, {"class_id": "hellcaster", "stats": {"force": 10, "magie": 12, "espionnage": 10, "artisanat": 8, "diplomatie": 8, "commandement": 10}})
	check(manager.try_go_next(), "classe et 10 points validés")
	manager.update_from_slide(2, {"selected_feats": [], "selected_abilities": ["recuperation_arcanique"]})
	check(manager.try_go_next(), "capacités validées")
	manager.update_from_slide(3, {"inventory_items": [], "equipped_items_by_slot": {}})
	check(manager.try_go_next(), "équipement validé")
	manager.update_from_slide(4, {"confirmation_accepted": true})
	check(manager.try_go_next(), "confirmation finale validée")
	await settle()
	check(current_scene.scene_file_path.ends_with("clan_hub.tscn"), "évaluation ouvre le refuge")
	check(not bool(save.get_value("opening", {}).active), "ouverture terminée")
	check(bool(cm.campaign.intro_done), "fin intro sauvegardée")
	check(cm.campaign.memories.completed.size() == 6 and not save.get_value("opening", {}).has("memories"), "transfert des souvenirs vers un seul propriétaire")
	var world_before := JSON.stringify(cm.campaign)
	var reserves_before := JSON.stringify(cm.get_ressources())
	for lesson_index in range(6):
		current_scene.find_child("MemoryArchiveToggle", true, false).pressed.emit()
		current_scene.find_child("ReplayLesson%d" % lesson_index, true, false).pressed.emit()
		await settle()
		check(current_scene.scene_file_path.ends_with("memory_tutorial.tscn") and current_scene._replay and int(current_scene._memory.sequence) == lesson_index, "relecture choisie depuis les archives")
		current_scene._actions.get_child(0).pressed.emit()
		current_scene._exit.pressed.emit()
		await settle()
	check(JSON.stringify(cm.campaign) == world_before and JSON.stringify(cm.get_ressources()) == reserves_before, "six relectures sans gains ni affinités supplémentaires")
	var dungeon := root.get_node("DungeonGenerator")
	dungeon.start_expedition(["pnj_kael"])
	game.open_slot_select()
	await settle()
	current_scene._selected_slot_id = "navigation_test"
	current_scene._on_load_pressed()
	await settle()
	check(current_scene.scene_file_path.ends_with("dungeon_view.tscn") and current_scene._arrival != null, "reprise au seuil")
	var enter: Button
	var inspect: Button
	var passage: Button
	for button in current_scene._arrival.find_children("*", "Button", true, false):
		if button.text == "Descendre avec Kael": enter = button
		if button.text == "Examiner l’inscription": inspect = button
		if button.text == "Vérifier le passage avec Kael": passage = button
	inspect.pressed.emit()
	check(enter.disabled, "observer le sceau ne valide pas le passage")
	passage.pressed.emit()
	check(not enter.disabled, "inspection déverrouille le bouton")
	enter.pressed.emit()
	await settle()
	check(dungeon.current_run.state == "exploration", "bouton franchit le seuil")
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
