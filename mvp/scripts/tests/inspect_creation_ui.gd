extends SceneTree

func _init():
	call_deferred("_run")

func _run() -> void:
	var scene_path := "res://scenes/creation_personnage.tscn"
	if not ResourceLoader.exists(scene_path):
		print("ERROR: scene not found", scene_path)
		quit(1)
		return
	var scene = load(scene_path)
	var inst = scene.instantiate()
	get_root().add_child(inst)
	call_deferred("_inspect", inst)

func _inspect(inst: Node) -> void:
	var paths := [
		"PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage",
		"PanneauCentre/LigneNoms/ColNomPerso/LabelNomPerso",
		"PanneauCentre/LigneNoms/ColNomClan/NomClan",
		"PanneauCentre/LigneNoms/ColNomClan/LabelNomClan",
	]
	for p in paths:
		var n := inst.get_node_or_null(p)
		if n == null:
			print(p, "-> MISSING")
			continue
		print("Node:", p, " class=", n.get_class())
		if n is Control:
			print("  visible=", n.visible, " visible_in_tree=", n.is_visible_in_tree())
			# specific info for LineEdit/Label
			if n is LineEdit:
				print("  placeholder_text=", str(n.placeholder_text))
				print("  text=", str(n.text))
			if n is Label:
				print("  text=", str(n.text))
			# style / modulate
			print("  modulate=", str(n.modulate))
		else:
			print("  (non-Control)")

	inst.queue_free()
	await process_frame
	quit(0)
