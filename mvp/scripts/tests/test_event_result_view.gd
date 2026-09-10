extends SceneTree

const EventResultViewScene = preload("res://scenes/ui/event_result_view.tscn")
const Presenter = preload("res://scripts/ui/event_result_presenter.gd")
const RESOLUTION_ACTION_PATH := "res://scenes/resolution_action.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	get_root().size = Vector2i(1280, 720)
	var view := EventResultViewScene.instantiate() as Control
	get_root().add_child(view)
	await process_frame

	var source_effects := {"or_recupere": 150, "soldats_perte_pct": 12, "mana_gain": 5}
	var source_copy := source_effects.duplicate(true)
	view.present({
		"title": "Résultat",
		"description": "Conséquences du test",
		"illustration_path": "res://assets/images/asset_inconnu.png",
		"effects": source_effects,
		"effects_applied": true,
	})
	await process_frame

	var continue_button := view.get_continue_button() as Button
	_check(continue_button != null and continue_button.visible and not continue_button.disabled, "action de validation absente", failures)
	_check(view.is_ancestor_of(continue_button), "bouton Continuer hors de la popup", failures)
	var button_rect := continue_button.get_global_rect()
	_check(button_rect.position.y >= 0.0 and button_rect.end.y <= 720.0, "bouton Continuer hors du viewport 1280x720", failures)
	_check(view.get_illustration_rect().stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "illustration/portrait zoomé au lieu d'être centré", failures)
	_check(view.get_illustration_rect().texture == null, "asset inconnu remplacé par un fallback incorrect", failures)
	_check(source_effects == source_copy, "la vue a modifié ou réappliqué les effets métier", failures)

	for resource_id in ["or", "mana", "essence", "soldats", "reputation", "pierre", "nourriture", "bois", "fer"]:
		var icon_path := Presenter.icon_for_resource(resource_id)
		_check(not icon_path.is_empty() and FileAccess.file_exists(icon_path), "icône connue non résolue: %s" % resource_id, failures)
	_check(Presenter.icon_for_resource("influence").is_empty(), "fallback incorrect pour une ressource sans icône", failures)
	_validate_configured_results(failures)

	var confirmation_count := [0]
	view.result_confirmed.connect(func(): confirmation_count[0] += 1)
	view.confirm_result()
	view.confirm_result()
	_check(confirmation_count[0] == 1, "double clic: confirmation émise plusieurs fois", failures)
	_check(not view.visible, "popup encore visible après confirmation", failures)

	var resolution_scene := ResourceLoader.load(RESOLUTION_ACTION_PATH) as PackedScene
	_check(resolution_scene != null, "scène de résolution non chargeable", failures)
	var resolution := resolution_scene.instantiate() as Control
	get_root().add_child(resolution)
	await process_frame
	var resolution_button := resolution.get_node_or_null("PanneauCentre/ActionBarBottom/BtnContinuer") as Button
	var player_portrait := resolution.get_node_or_null("PanneauCentre/PanneauStats/ContenuStats/ColJoueur/IconeClanJoueur") as TextureRect
	_check(resolution.get_script() != null, "script de résolution non compilé", failures)
	_check(resolution_button != null, "résolution d'action sans bouton Continuer", failures)
	_check(player_portrait != null and player_portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "portrait de résolution trop zoomé", failures)

	resolution.free()
	view.free()
	if failures.is_empty():
		print("EVENT_RESULT_VIEW_OK")
		quit(0)
		return
	for failure in failures:
		push_error("EVENT_RESULT_VIEW_FAIL: %s" % failure)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _validate_configured_results(failures: Array[String]) -> void:
	var file := FileAccess.open("res://data/phases/config_tour.json", FileAccess.READ)
	if file == null:
		failures.append("config_tour.json illisible")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		failures.append("config_tour.json invalide")
		return
	var result_count := 0
	for action_value in (parsed as Dictionary).get("actions", []) as Array:
		var action := action_value as Dictionary
		for result_id in (action.get("resultats", {}) as Dictionary):
			var configured := (action.get("resultats", {}) as Dictionary).get(result_id, {}) as Dictionary
			var normalized := Presenter.normalize({"title": str(result_id), "description": configured.get("texte", ""), "effects": configured.get("effets", {})})
			if str(normalized.get("title", "")).is_empty():
				failures.append("résultat d'action non normalisable: %s" % str(result_id))
			result_count += 1
	for event_value in (parsed as Dictionary).get("evenements_aleatoires", []) as Array:
		var event := event_value as Dictionary
		var normalized := Presenter.normalize(event)
		if str(normalized.get("title", "")).is_empty():
			failures.append("événement non normalisable: %s" % str(event.get("id", "")))
		result_count += 1
	if result_count != 19:
		failures.append("couverture config_tour incomplète: %d/19" % result_count)
