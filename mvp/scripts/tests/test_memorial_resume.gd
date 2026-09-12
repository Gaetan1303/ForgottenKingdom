extends SceneTree
const Memories = preload("res://scripts/services/memory_tutorial_service.gd")
const Campaign = preload("res://scripts/services/power_campaign_service.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
var failures: Array[String] = []
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func settle() -> void:
	for _i in range(8): await process_frame
func run() -> void:
	var game := root.get_node("GameManager")
	var save := root.get_node("SaveSystem")
	var cm := root.get_node("ClanManager")
	save.set_active_slot("memorial_resume")
	# Les ouvertures antérieures reprennent exactement leurs tableaux historiques.
	save.set_value("opening", {"active": true, "finished": false, "index": 3, "choices": {}, "draft_ready": false})
	game.resume_campaign()
	await settle()
	check(current_scene._scenes.size() == 5 and current_scene._scenes[3].id == "awakening_02", "ancienne ouverture reprise sans déplacer les choix")
	save.set_value("opening", {"active": true, "finished": true, "index": 4, "choices": {}, "draft_ready": false})
	game.resume_campaign()
	await settle()
	check(current_scene.scene_file_path.contains("character_creation_screen"), "ancienne création conservée sans imposer les souvenirs")
	# Reprise pendant le résultat d'une action, puis passage libre de toutes les leçons.
	game.start_new_game()
	await settle()
	current_scene._finish()
	await create_timer(1.4).timeout
	await settle()
	current_scene._actions.get_node("training_attack").pressed.emit()
	var memory_before: Dictionary = save.get_value("opening").memories.duplicate(true)
	game.go_to_menu()
	await settle()
	save.load_save()
	game.resume_campaign()
	await settle()
	check(current_scene._memory.awaiting_ack, "feedback repris avant acquittement")
	check(JSON.parse_string(JSON.stringify(current_scene._memory)) == JSON.parse_string(JSON.stringify(memory_before)), "PV, RNG, coûts et affinités intacts")
	for _i in range(6): current_scene._skip.pressed.emit()
	check(current_scene._memory.finished and current_scene._memory.completed.is_empty(), "passer n’équivaut pas à terminer")
	current_scene._ack.pressed.emit()
	await settle()
	check(current_scene.scene_file_path.contains("character_creation_screen"), "création accessible sans combat ni rituel requis")
	# La première action a été réellement pratiquée ; le passage n'ajoute aucun point.
	var affinities: Dictionary = save.get_value("opening").memories.affinities
	check(affinities.size() == 1 and int(affinities.get("combat_affinity", 0)) == 1, "aucune affinité inventée lors du passage")
	# Récupération d'une coupure entre clan.json et progress.json à la création.
	cm.nouvelle_partie("Aren", "Maison de reprise", "hellcaster", {})
	Refuge.initialize(cm.service_context)
	cm.campaign.version = 3
	cm.campaign.opening_run_id = str(save.get_value("opening").run_id)
	Campaign.ensure(cm.service_context)
	cm.sauvegarder()
	game.resume_campaign()
	await settle()
	check(current_scene.scene_file_path.ends_with("clan_hub.tscn") and not save.get_value("opening").active, "reprise de la finalisation sans recréer le clan")
	# Le pacte du présent utilise et sauvegarde le service canonique.
	var result := Campaign.execute(cm.service_context, "pact")
	check(result.accepted, "pacte bref accepté")
	var pact_id: String = cm.campaign.power_routes.pact_id
	check(cm.get_pact_service().get_active_pacts().size() == 1, "un seul pacte canonique")
	check(cm.get_corruption_service().get_corruption_level("hero") == 3, "prix du pacte dans la corruption canonique")
	Campaign.acknowledge(cm.service_context)
	check(cm.charger_sauvegarde() and cm.get_pact_service().get_active_pacts().size() == 1, "pacte chargé")
	cm.advance_day_phase()
	cm.advance_day_phase()
	check(Campaign.execute(cm.service_context, "bind").accepted, "sceau préparé par le pacte")
	Campaign.acknowledge(cm.service_context)
	check(cm.get_pact_service().export_state().active_pacts[pact_id].status == "fulfilled", "pacte accompli dans son service")
	cm.sauvegarder()
	check(cm.charger_sauvegarde() and cm.get_pact_service().export_state().active_pacts[pact_id].status == "fulfilled", "accomplissement du pacte persistant")
	if failures.is_empty(): print("MEMORIAL_RESUME_OK · PACT_ROUNDTRIP_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
