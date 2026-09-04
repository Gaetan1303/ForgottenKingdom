extends SceneTree

const TEST_IMAGE_PATH := "res://assets/images/hero/defaut.png"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/creation_personnage.tscn") as PackedScene
	if scene == null:
		push_error("TEST_FAIL: creation_personnage.tscn introuvable")
		quit(1)
		return
	var inst := scene.instantiate()
	get_root().add_child(inst)
	await process_frame

	if not inst.has_method("_appliquer_portrait_depuis_chemin"):
		push_error("TEST_FAIL: méthode _appliquer_portrait_depuis_chemin absente")
		inst.queue_free()
		await process_frame
		quit(1)
		return

	inst._appliquer_portrait_depuis_chemin(TEST_IMAGE_PATH)
	var payload := inst.get("_portrait_data") as Dictionary
	if payload.is_empty():
		var err_label := inst.get_node_or_null("PanneauCentre/CreationBody/ColGauche/LabelErreur") as Label
		push_error("TEST_FAIL: portrait_data vide | erreur=%s" % (err_label.text if err_label != null else "(label introuvable)"))
		inst.queue_free()
		await process_frame
		quit(1)
		return

	print("TEST_OK: signature loader portrait fonctionne | file_name=", str(payload.get("file_name", "")))
	inst.queue_free()
	await process_frame
	quit(0)
