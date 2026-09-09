extends SceneTree
const Data = preload("res://scripts/ui/character_creation/creation_data.gd")
const MANAGER_PATH = "res://scripts/ui/character_creation/character_creation_manager.gd"
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var loader := root.get_node("GameDataLoader")
	var screen: Control = load("res://scenes/character_creation/character_creation_screen.tscn").instantiate()
	root.get_node("SaveSystem").set_value("opening", {})
	root.add_child(screen)
	screen._on_slide_changed(1)
	var slide: Control = screen._active_slide
	var data := Data.new()
	slide.enter_slide(data)
	for class_id in loader.get_classes():
		var card := slide.find_child("ClassCard_" + str(class_id), true, false) as Button
		check(card != null and not card.tooltip_text.is_empty() and card.focus_mode == Control.FOCUS_ALL, "carte accessible : " + str(class_id))
		card.pressed.emit()
		check(slide.collect_payload().class_id == class_id, "sélection : " + str(class_id))
		var spin := slide.find_child("Stat_force", true, false) as SpinBox
		var base := spin.value
		spin.value += 1
		check(spin.value == base + 1 and slide._points_remaining() == 9, "+1 coûte 1 : " + str(class_id))
		spin.value -= 1
		check(spin.value == base and slide._points_remaining() == 10, "retrait rend 1 : " + str(class_id))
		spin.value += 3
		slide.find_child("BtnReset", true, false).pressed.emit()
		check(spin.value == base and slide._points_remaining() == 10, "reset conserve bonus : " + str(class_id))
		card.grab_focus()
		await process_frame
		await process_frame
		var panel: Control = card.get_child(0).get_child(0)
		# Chercher la CanvasLayer explicitement : la carte conserve ses enfants animés.
		for child in card.get_children():
			if child is CanvasLayer: panel = child.get_child(0)
		check(panel.visible and not panel.get_global_rect().intersects(card.get_global_rect()), "infobulle séparée : " + str(class_id))
		check(root.get_visible_rect().encloses(panel.get_global_rect()), "infobulle bornée : " + str(class_id))
		card.release_focus()
	screen.queue_free()
	await process_frame
	var powers: Dictionary = loader.get_character_traits().get("pouvoirs", {})
	for class_id in ["hellcaster", "demon_blade"]:
		var manager: Node = load(MANAGER_PATH).new()
		root.add_child(manager)
		var completed := {"payload": {}}
		manager.creation_completed.connect(func(payload: Dictionary): completed.payload = payload)
		manager.update_from_slide(0, {"character_name": "Aren", "clan_name": "Cendres", "racial_power_id": str(powers.keys()[0])})
		check(manager.try_go_next(), "identité : " + class_id)
		manager.update_from_slide(1, {"class_id": class_id, "stats": {"force": 13, "magie": 13}})
		check(manager.try_go_next(), "budget : " + class_id)
		manager.update_from_slide(2, {"selected_feats": ["attaque_puissante"], "selected_abilities": ["second_souffle"]})
		check(manager.try_go_next(), "prérequis : " + class_id)
		manager.update_from_slide(3, {"inventory_items": [], "equipped_items_by_slot": {}})
		check(manager.try_go_next(), "équipement : " + class_id)
		manager.update_from_slide(4, {"confirmation_accepted": true})
		check(manager.try_go_next() and not completed.payload.is_empty(), "fiche finalisée : " + class_id)
		manager.queue_free()
		await process_frame
	if failures.is_empty(): print("CREATION_CLASSES_UI_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
