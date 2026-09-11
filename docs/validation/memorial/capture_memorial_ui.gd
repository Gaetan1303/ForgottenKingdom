extends SceneTree
const Memories = preload("res://scripts/services/memory_tutorial_service.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
func _init() -> void:
	call_deferred("run")
func settle() -> void:
	for _i in range(8): await process_frame
func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var err := picture.save_png("/tmp/fk-memorial-validation/" + name + ".png")
	print("CAPTURE ", name, " ", err, " ", picture.get_size())
func run() -> void:
	root.size = Vector2i(1280, 720)
	var save := root.get_node("SaveSystem")
	var game := root.get_node("GameManager")
	save.set_active_slot("visual_memorial")
	game.start_new_game()
	await settle()
	for i in range(3):
		current_scene._show_scene(i)
		current_scene._on_continue()
		await capture("prologue_" + str(i))
	current_scene._finish()
	await create_timer(1.4).timeout
	await settle()
	var index := -1
	var attempts := 0
	while not current_scene._memory.finished and attempts < 40:
		var m: Dictionary = current_scene._memory
		if int(m.sequence) != index:
			index = int(m.sequence)
			await capture("memory_" + str(index))
		var step := Memories.current(m)
		current_scene._actions.get_node(str(step.actions[0])).pressed.emit()
		await settle()
		if m.awaiting_ack:
			await capture("feedback_" + str(index))
			current_scene._ack.pressed.emit()
		elif str(step.required_event) == "artifact_created":
			current_scene._actions.get_node("materials").pressed.emit()
		attempts += 1
	await capture("memory_summary")
	current_scene._ack.pressed.emit()
	await capture("creation_identity")
	var cm := root.get_node("ClanManager")
	cm.nouvelle_partie("Aren", "Maison des Cendres", "hellcaster", {})
	Refuge.initialize(cm)
	cm.campaign.version = 3
	Refuge.prioritize_galleries(cm)
	Refuge.social_choice(cm, true)
	cm.advance_day_phase()
	cm.advance_day_phase()
	game.open_clan_hub()
	await capture("present_hub")
	var routes: Control
	for node in current_scene.find_children("*", "VBoxContainer", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with("power_routes_panel.gd"):
			routes = node
	if routes != null:
		current_scene.get_node("ContenuPrincipal/PanneauMaisons").scroll_vertical = int(routes.position.y)
		await capture("present_routes")
		for route in ["espionage", "occult", "command", "craft"]:
			routes._select(route)
			await capture("present_" + route)
	print("MEMORIAL_RENDER_OK")
	quit(0)
