## scripts/ui/main_menu.gd
## Contrôleur du menu principal.
extends Control

const INGRID_MVP_NOTICE_KEY := "ingrid_mvp_notice_seen"

var _ingrid_notice: AcceptDialog
var _pending_ingrid_target: String = ""
var _options_panel: Panel = null
var _options_slider: HSlider = null
var _options_option: OptionButton = null
var _options_resolution: OptionButton = null
var _options_subtitles: CheckBox = null
var _options_sensitivity: HSlider = null
var _options_fullscreen: CheckBox = null
var _options_volume_label: Label = null


func _ready() -> void:
	# Autoplay main theme when not running headless (editor or normal play)
	if not OS.has_feature("headless"):
		AudioManager.play_music("mainmenu.mp3")

	_setup_ingrid_notice_dialog()
	_add_audio_button()
	# Ensure menu buttons are in the desired order before connecting signals
	_order_menu()
	_connect_buttons()
	_restore_continue_button()

	# Apply persisted display settings if present
	var persisted: Dictionary = _read_user_settings()
	if persisted and persisted.has("resolution") and persisted["resolution"] != "":
		_apply_display_settings(str(persisted["resolution"]), bool(persisted.get("fullscreen", false)))

	# Instantiate character card at runtime to avoid editor instancing warnings
	call_deferred("_create_character_card")


func _setup_ingrid_notice_dialog() -> void:
	_ingrid_notice = AcceptDialog.new()
	_ingrid_notice.title = "Mode Ingrid (MVP narratif)"
	_ingrid_notice.dialog_text = "Le contenu Ingrid est un MVP narratif pour présenter l'univers et donner un aperçu du jeu complet (Visual Novel + Gestion RPG)."
	_ingrid_notice.ok_button_text = "Continuer"
	add_child(_ingrid_notice)
	_ingrid_notice.confirmed.connect(_on_ingrid_notice_confirmed)


func _add_audio_button() -> void:
	# Replace audio toggle with an Options button (opens settings dialog)
	if not $VBox.has_node("BtnOptions"):
		var btn_options: Button = Button.new()
		btn_options.name = "BtnOptions"
		btn_options.text = "Options"
		$VBox.add_child(btn_options)
		btn_options.pressed.connect(_on_btn_options)


func _on_btn_audio_toggle() -> void:
	AudioManager.toggle_music("mainmenu.mp3")
	var btn: Button = $VBox.get_node_or_null("BtnAudioToggle") as Button
	if btn:
		if AudioManager.is_music_playing():
			btn.text = "Stop Music"
		else:
			btn.text = "Play Music"

func _on_btn_options() -> void:
	# Create an options panel programmatically (avoids PackedScene issues in headless)
	var panel: Panel = Panel.new()
	panel.name = "OptionsDialog"
	panel.custom_minimum_size = Vector2(420, 240)

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_vol: Label = Label.new()
	lbl_vol.text = "Musique"
	vbox.add_child(lbl_vol)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = int(SaveSystem.get_value("settings/music_volume_pct", 100))
	vbox.add_child(slider)

	# Volume feedback label (shows percentage and updates in real time)
	var lbl_vol_val: Label = Label.new()
	lbl_vol_val.text = "%d%%" % int(slider.value)
	vbox.add_child(lbl_vol_val)


	var lbl_diff: Label = Label.new()
	lbl_diff.text = "Difficulté"
	vbox.add_child(lbl_diff)

	var opt: OptionButton = OptionButton.new()
	opt.add_item("Facile")
	opt.add_item("Normal")
	opt.add_item("Difficile")
	var saved_diff: String = str(SaveSystem.get_value("settings/difficulty", "Normal"))
	match saved_diff:
		"Facile": opt.select(0)
		"Normal": opt.select(1)
		"Difficile": opt.select(2)
		_: opt.select(1)
	vbox.add_child(opt)

	# Resolution selector
	var lbl_res: Label = Label.new()
	lbl_res.text = "Résolution"
	vbox.add_child(lbl_res)
	var res: OptionButton = OptionButton.new()
	var resolutions: Array = ["1280x720", "1600x900", "1920x1080"]
	for r in resolutions:
		res.add_item(r)
	var saved_res: String = str(SaveSystem.get_value("settings/resolution", "1920x1080"))
	var sel_idx: int = resolutions.find(saved_res)
	if sel_idx < 0:
		sel_idx = resolutions.find("1920x1080")
	res.select(sel_idx)
	vbox.add_child(res)

	# Fullscreen checkbox
	var cb_full: CheckBox = CheckBox.new()
	cb_full.text = "Plein écran"
	cb_full.set_pressed(str(SaveSystem.get_value("settings/fullscreen", false)).to_lower() == "true")
	vbox.add_child(cb_full)

	# Subtitles checkbox
	var cb_sub: CheckBox = CheckBox.new()
	cb_sub.text = "Afficher sous-titres"
	cb_sub.set_pressed(str(SaveSystem.get_value("settings/subtitles", true)).to_lower() == "true")
	vbox.add_child(cb_sub)

	# Sensitivity slider
	var lbl_sens: Label = Label.new()
	lbl_sens.text = "Sensibilité souris"
	vbox.add_child(lbl_sens)
	var sens: HSlider = HSlider.new()
	sens.min_value = 1
	sens.max_value = 20
	sens.step = 1
	sens.value = int(SaveSystem.get_value("settings/sensitivity", 10))
	vbox.add_child(sens)

	var hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(hbox)

	var btn_apply: Button = Button.new()
	btn_apply.text = "Appliquer"
	hbox.add_child(btn_apply)

	var btn_close: Button = Button.new()
	btn_close.text = "Fermer"
	hbox.add_child(btn_close)

	# store refs and connect to instance methods to avoid inline closure type inferrence
	_options_panel = panel
	_options_slider = slider
	_options_option = opt
	_options_resolution = res
	_options_fullscreen = cb_full
	_options_subtitles = cb_sub
	_options_sensitivity = sens
	_options_volume_label = lbl_vol_val
	# connect slider value change to update label and apply volume immediately
	slider.connect("value_changed", Callable(self, "_on_options_volume_changed"))
	btn_apply.pressed.connect(_on_options_apply)
	btn_close.pressed.connect(_on_options_close)

	get_tree().root.call_deferred("add_child", panel)
	call_deferred("_deferred_show_options", panel)

func _deferred_show_options(inst: Node) -> void:
	if not inst:
		return
	if inst.has_method("show_centered"):
		inst.call("show_centered")
	else:
		inst.visible = true

func _on_options_apply() -> void:
	if not _options_panel:
		return
	var vol_pct: int = int(_options_slider.value)
	SaveSystem.set_value("settings/music_volume_pct", vol_pct)
	# Apply volume via AudioManager to update the active player correctly
	AudioManager.music_volume = float(vol_pct) / 100.0
	var diff: String = _options_option.get_item_text(_options_option.selected)
	SaveSystem.set_value("settings/difficulty", diff)

	# Resolution / Fullscreen / Subtitles / Sensitivity
	if _options_resolution:
		var res_str: String = _options_resolution.get_item_text(_options_resolution.selected)
		SaveSystem.set_value("settings/resolution", res_str)
	if _options_fullscreen:
		SaveSystem.set_value("settings/fullscreen", _options_fullscreen.is_pressed())
	if _options_subtitles:
		SaveSystem.set_value("settings/subtitles", _options_subtitles.pressed)
	if _options_sensitivity:
		SaveSystem.set_value("settings/sensitivity", int(_options_sensitivity.value))
	SaveSystem.save()

	# Also persist global UI/settings to user://settings.json for robust persistence
	var settings: Dictionary = {
		"music_volume_pct": vol_pct,
		"difficulty": diff,
		"resolution": ("%s" % [_options_resolution.get_item_text(_options_resolution.selected)]) if _options_resolution else "",
		"fullscreen": (_options_fullscreen.is_pressed() if _options_fullscreen else false),
		"subtitles": (_options_subtitles.is_pressed() if _options_subtitles else true),
		"sensitivity": (int(_options_sensitivity.value) if _options_sensitivity else 10),
	}
	_write_user_settings(settings)

	# Apply display settings immediately
	if settings.has("resolution") and settings["resolution"] != "":
		_apply_display_settings(settings["resolution"], settings["fullscreen"])
	_options_panel.queue_free()
	_options_panel = null
	_options_slider = null
	_options_option = null
	_options_resolution = null
	_options_fullscreen = null
	_options_subtitles = null
	_options_sensitivity = null
	_options_volume_label = null

func _on_options_close() -> void:
	if _options_panel:
		_options_panel.queue_free()
	_options_panel = null
	_options_slider = null
	_options_option = null
	_options_volume_label = null


func _write_user_settings(settings: Dictionary) -> void:
	var path: String = "user://settings.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open %s for writing" % path)
		return
	file.store_string(JSON.stringify(settings))
	file.close()


func _read_user_settings() -> Dictionary:
	var path: String = "user://settings.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _apply_display_settings(resolution: String, fullscreen: bool) -> void:
	# resolution: "WIDTHxHEIGHT"
	if resolution == null or resolution == "":
		return
	var parts: Array = resolution.split("x")
	if parts.size() != 2:
		return
	var w: int = int(parts[0])
	var h: int = int(parts[1])
	# apply size and fullscreen mode
	# Use deferred helper to avoid changing window during setup
	call_deferred("_deferred_apply_display", w, h, fullscreen)


func _deferred_apply_display(w: int, h: int, fullscreen: bool) -> void:
	# Use default window id 0; DisplayServer expects (Vector2i size, int window) signature
	var win_id: int = 0
	if DisplayServer.has_method("window_set_size"):
		DisplayServer.window_set_size(Vector2i(w, h), win_id)

	if DisplayServer.has_method("window_set_mode"):
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN, win_id)
		else:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED, win_id)


func _on_options_volume_changed(value: float) -> void:
	# update label and apply volume immediately for direct feedback
	if _options_volume_label:
		_options_volume_label.text = "%d%%" % int(value)
	AudioManager.music_volume = float(value) / 100.0


func _connect_buttons() -> void:
	$VBox/BtnNouvellePartie.pressed.connect(_on_btn_nouvelle_partie)
	$VBox/BtnHistoire.pressed.connect(_on_btn_histoire)
	$VBox/BtnCarte.pressed.connect(_on_btn_carte)
	$VBox/BtnChapitre.pressed.connect(_on_btn_chapitre)
	$VBox/BtnQuitter.pressed.connect(_on_btn_quitter)


func _restore_continue_button() -> void:
	var last: int = SaveSystem.get_value("last_chapter", 0)
	if last > 0:
		$VBox/BtnHistoire.text = "Reprendre récit Ingrid (ch. %d)" % last
	else:
		$VBox/BtnHistoire.text = "Récit Ingrid (linéaire)"

	$VBox/BtnChapitre.text = "Chapitres Ingrid (optionnel)"
	$VBox/BtnNouvellePartie.text = "Campagne: choisir un slot (%s)" % SaveSystem.get_active_slot()


# --- Callbacks ---

func _on_btn_nouvelle_partie() -> void:
	GameManager.open_slot_select()


func _on_btn_histoire() -> void:
	_request_ingrid_entry("histoire")


func _request_ingrid_entry(target: String) -> void:
	if bool(SaveSystem.get_value(INGRID_MVP_NOTICE_KEY, false)):
		_open_ingrid_target(target)
		return

	_pending_ingrid_target = target
	if _ingrid_notice != null:
		_ingrid_notice.popup_centered_ratio(0.48)


func _on_ingrid_notice_confirmed() -> void:
	SaveSystem.set_value(INGRID_MVP_NOTICE_KEY, true)
	SaveSystem.save()
	_open_ingrid_target(_pending_ingrid_target)
	_pending_ingrid_target = ""


func _open_ingrid_target(target: String) -> void:
	if target == "histoire":
		_open_saved_chapter()
		return

	if target == "chapitres":
		GameManager.open_chapter_select()
		return

	# Fallback sécurité
	_open_saved_chapter()


func _open_saved_chapter() -> void:
	var saved_last_chapter: int = (SaveSystem.get_value("last_chapter", 0) as int)
	var saved_last_scene: int = (SaveSystem.get_value("last_scene", 0) as int)
	GameManager.open_chapter(saved_last_chapter, saved_last_scene)


func _on_btn_carte() -> void:
	GameManager.open_map()


func _on_btn_chapitre() -> void:
	_request_ingrid_entry("chapitres")


func _on_btn_quitter() -> void:
	SaveSystem.save()
	get_tree().quit()


func _order_menu() -> void:
	# Desired order of menu buttons (top -> bottom)
	var desired: Array = ["BtnNouvellePartie", "BtnHistoire", "BtnChapitre", "BtnCarte", "BtnOptions", "BtnQuitter"]
	var vbox: Node = $VBox
	for i in range(desired.size()):
		var name: String = desired[i]
		var node: Node = vbox.get_node_or_null(name)
		if node:
			# move_child will clamp the index internally; safe to call
			vbox.move_child(node, i)


func _create_character_card() -> void:
	# Invisible placement container anchored bottom-right
	var card: Control = Control.new()
	card.name = "CharacterCard"
	card.anchor_left = 1.0
	card.anchor_top = 1.0
	card.anchor_right = 1.0
	card.anchor_bottom = 1.0
	card.size = Vector2(260, 220)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# offset from bottom-right handled in deferred placement
	add_child(card)

	# Create a CanvasLayer to host the Node2D animation so it renders above UI
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CharacterCanvas"
	layer.layer = 50
	add_child(layer)

	# Load and instantiate the character animation scene into the CanvasLayer
	var packed: PackedScene = load("res://scenes/character_animation.tscn") as PackedScene
	if packed:
		var inst: Node = packed.instantiate()
		layer.add_child(inst)
		# Place the instance centered inside the card (deferred to ensure viewport sizes available)
		call_deferred("_deferred_place_character", inst, card)


func _deferred_place_character(inst: Node, card: Control) -> void:
	if inst == null or card == null:
		return
	await get_tree().process_frame
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var card_size := Vector2(340, 320)
	var margin_right := 36.0
	var margin_bottom := 56.0
	card.size = card_size
	card.position = Vector2(view_size.x - margin_right - card_size.x, view_size.y - margin_bottom - card_size.y)

	if not (inst is Node2D):
		return

	var visual := _find_first_character_sprite(inst)
	if visual == null or visual.texture == null:
		(inst as Node2D).position = card.position + card_size * 0.5
		return

	var tex_size: Vector2 = visual.texture.get_size()
	var target_size: Vector2 = Vector2(card_size.x * 0.92, card_size.y * 0.92)
	var scale_x: float = target_size.x / maxf(1.0, tex_size.x)
	var scale_y: float = target_size.y / maxf(1.0, tex_size.y)
	var scale: float = minf(scale_x, scale_y)
	scale = min(scale, 1.0)
	inst.scale = Vector2(scale, scale)

	var scaled_size: Vector2 = tex_size * scale
	(inst as Node2D).position = Vector2(
		card.position.x + card_size.x * 0.5,
		card.position.y + card_size.y - scaled_size.y * 0.5 - 2.0
	)


func _find_first_character_sprite(root: Node) -> Sprite2D:
	if root == null:
		return null
	if root is Sprite2D:
		return root as Sprite2D
	for child in root.get_children():
		var sprite := _find_first_character_sprite(child)
		if sprite != null:
			return sprite
	return null
