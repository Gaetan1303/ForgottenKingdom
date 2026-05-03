extends Control

const INGRID_MVP_NOTICE_KEY = "ingrid_mvp_notice_seen"
const MAIN_TRACK = "mainmenu.mp3"
const EMBLEM_PATH = "res://assets/icon/jeu.png"
const SOUND_ICON_PATH = "res://assets/ui/stop_icon.svg"


const MENU_ITEMS = [
	{ 
		"node_name": "BtnNouvellePartie",
		"title": "NOUVELLE PARTIE",
		"description": "RPG Gestion – Reconstituez votre Clan Démoniaque",
		"action": "new_game",
	},
	{
		"node_name": "BtnContinuer",
		"title": "CONTINUER",
		"description": "Reprendre votre dernière sauvegarde",
		"action": "continue_game",
	},
	{
		"node_name": "BtnEncyclopedie",
		"title": "ENCYCLOPÉDIE",
		"description": "Le Lore des 9 Maisons Nobles Démoniques",
		"action": "encyclopedia",
	},
	{
		"node_name": "BtnParametres",
		"title": "PARAMÈTRES",
		"description": "Options, Audio, Interface",
		"action": "options",
	},
	{
		"node_name": "BtnQuitter",
		"title": "QUITTER",
		"description": "Version 0.0.1",
		"action": "quit",
	},
]

var _ingrid_notice: AcceptDialog
var _pending_ingrid_target: String = ""
var _options_panel: PanelContainer
var _options_slider: HSlider
var _options_resolution: OptionButton
var _options_fullscreen: CheckBox
var _options_volume_label: Label
var _sound_button: Button
# font variables removed — use engine default font (ABeeZee optional not loaded)
var _menu_top_spacing: int = 48
var _card_vertical_step: int = 100
var _card_height: int = 92
@export var allow_resize_in_editor: bool = true


func _ready() -> void:
	if not OS.has_feature("headless"):
		AudioManager.play_music(MAIN_TRACK)

	# create procedural background shader (linear gradient + soft radial blobs)
	_create_procedural_background()

	_setup_notice_dialog()
	# adjust card separation to follow mockup
	var menu_list: VBoxContainer = $Content/ContentCenter/ContentVBox/MenuListHolder/MenuList
	if menu_list != null:
		menu_list.add_theme_constant_override("separation", 18)

	_build_menu_cards()
	_build_sound_button()
	_apply_saved_display_settings()

	var title_label: Label = $Content/ContentCenter/ContentVBox/Header/Title
	if title_label != null:
		title_label.text = "CHRONIQUES DES 9 NOBLES DU DEMON REALM"
		title_label.custom_minimum_size = Vector2(840, 120)
		title_label.horizontal_alignment = 1

	var subtitle_label: Label = $Content/ContentCenter/ContentVBox/Header/Subtitle
	if subtitle_label != null:
		subtitle_label.text = ""

	# hide any static background texture so procedural background is visible
	if has_node("Background"):
		$Background.visible = false


func _setup_notice_dialog() -> void:
	_ingrid_notice = AcceptDialog.new()
	_ingrid_notice.title = "Mode Ingrid (MVP narratif)"
	_ingrid_notice.dialog_text = "Le contenu Ingrid reste un MVP narratif. Continuer relance le dernier chapitre sauvegardé."
	_ingrid_notice.ok_button_text = "Continuer"
	add_child(_ingrid_notice)
	_ingrid_notice.confirmed.connect(_on_ingrid_notice_confirmed)


func _build_menu_cards() -> void:
	var list: VBoxContainer = $Content/ContentCenter/ContentVBox/MenuListHolder/MenuList
	for child in list.get_children():
		child.queue_free()

	var emblem: Texture2D = load(EMBLEM_PATH) as Texture2D
	for item in MENU_ITEMS:
		list.add_child(_create_menu_card(item, emblem))




func _create_menu_card(item: Dictionary, emblem: Texture2D) -> Button:
	var button := Button.new()
	button.name = str(item.get("node_name", "MenuButton"))
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	# card size matching maquette width and parent layout
	button.custom_minimum_size = Vector2(832, 92)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# create panel style matching CSS: translucent purple overlay, 2px border #8759B4, radius 10-12
	var normal := StyleBoxFlat.new()
	# card base style tuned to match maquette: subtle translucent purple, light magenta border
	normal.bg_color = Color8(46,26,52, int(0.18 * 255))
	normal.border_color = Color8(210,180,240)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color8(0,0,0, int(0.32 * 255))
	normal.shadow_size = 10
	normal.content_margin_left = 36
	normal.content_margin_top = 18
	normal.content_margin_right = 36
	normal.content_margin_bottom = 14
	button.add_theme_stylebox_override("normal", normal)

	var hover2 := normal.duplicate()
	hover2.bg_color = Color8(60,28,88, int(0.30 * 255))
	hover2.border_color = Color8(220,180,240)
	button.add_theme_stylebox_override("hover", hover2)
	button.add_theme_stylebox_override("pressed", hover2)
	button.add_theme_stylebox_override("focus", hover2)

	var layout := HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layout)

	# ensure button text left padding is consistent
	button.add_theme_constant_override("hseparation", 12)

	# icon with red framed panel background matching maquette
	var icon_bg := PanelContainer.new()
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0,0,0,0.0)
	icon_style.border_color = Color(0,0,0,0)
	icon_style.set_border_width_all(0)
	icon_style.set_corner_radius_all(6)
	icon_style.content_margin_left = 4
	icon_style.content_margin_top = 4
	icon_style.content_margin_right = 4
	icon_style.content_margin_bottom = 4
	icon_bg.add_theme_stylebox_override("panel", icon_style)
	# slightly larger framed icon to match maquette
	icon_bg.custom_minimum_size = Vector2(64, 64)
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_rect := TextureRect.new()
	icon_rect.texture = emblem
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.modulate = Color(0.5, 0.5, 0.5, 1.0)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_bg.add_child(icon_rect)
	layout.add_child(icon_bg)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(16, 1)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer)

	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(texts)

	var title := Label.new()
	title.text = str(item.get("title", ""))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# card title (pixel‑perfect)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color8(255, 255, 255))
	texts.add_child(title)

	var description := Label.new()
	description.text = str(item.get("description", ""))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# subtitle / description smaller but readable
	description.add_theme_font_size_override("font_size", 10)
	description.add_theme_color_override("font_color", Color8(200, 180, 200))
	texts.add_child(description)

	button.pressed.connect(_on_menu_action.bind(str(item.get("action", ""))))
	return button


func _create_procedural_background() -> void:
	# create a ColorRect that fills the root and assign the canvas shader
	var bg := ColorRect.new()
	bg.name = "ProceduralBG"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader_res := load("res://scripts/ui/menu_bg_shader.gdshader")
	if shader_res:
		var mat := ShaderMaterial.new()
		mat.shader = shader_res
		bg.material = mat

	add_child(bg)
	# move background to the bottom
	move_child(bg, 0)


func _build_sound_button() -> void:
	_sound_button = $Footer/SoundButton
	_sound_button.flat = true
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.text = ""
	_sound_button.tooltip_text = "Couper / relancer la musique"
	_sound_button.pressed.connect(_on_sound_button_pressed)

	# Position footer at bottom-left like the maquette
	var footer := $Footer
	footer.offset_left = 27
	footer.offset_top = -55
	footer.offset_right = 27
	footer.offset_bottom = -6

	# Make the sound button match maquette (40x40)
	_sound_button.custom_minimum_size = Vector2(40, 40)
	# style the button to match maquette: small rounded warm square with icon
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(38, 14, 24, int(0.72 * 255))
	sb.border_color = Color8(240, 110, 94)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_top = 8
	sb.content_margin_right = 8
	sb.content_margin_bottom = 8
	_sound_button.add_theme_stylebox_override("normal", sb)
	_sound_button.add_theme_stylebox_override("hover", sb.duplicate())
	var icon_tex := ResourceLoader.load(SOUND_ICON_PATH)
	if icon_tex is Texture2D:
		_sound_button.icon = icon_tex
		_sound_button.modulate = Color8(240, 110, 94)


func _apply_saved_display_settings() -> void:
	var persisted := _read_user_settings()
	if persisted.has("resolution") and str(persisted.get("resolution", "")) != "":
		var fullscreen_value: Variant = persisted.get("fullscreen", false)
		var fullscreen_enabled: bool = false
		if typeof(fullscreen_value) == TYPE_BOOL and fullscreen_value == true:
			fullscreen_enabled = true
		elif str(fullscreen_value).to_lower() == "true":
			fullscreen_enabled = true
		_apply_display_settings(str(persisted.get("resolution", "")), fullscreen_enabled)


func _on_menu_action(action: String) -> void:
	match action:
		"new_game":
			GameManager.open_slot_select()
		"continue_game":
			# directly open saved chapter to match desired behaviour
			_open_saved_chapter()
		"encyclopedia":
			_open_encyclopedia()
		"options":
			_open_options_dialog()
		"quit":
			SaveSystem.save()
			get_tree().quit()


func _request_continue_game() -> void:
	var notice_enabled: Variant = SaveSystem.get_value(INGRID_MVP_NOTICE_KEY, false)
	if notice_enabled == true or str(notice_enabled).to_lower() == "true":
		_open_saved_chapter()
		return
	_pending_ingrid_target = "continue_game"
	_ingrid_notice.popup_centered_ratio(0.42)


func _on_ingrid_notice_confirmed() -> void:
	SaveSystem.set_value(INGRID_MVP_NOTICE_KEY, true)
	SaveSystem.save()
	if _pending_ingrid_target == "continue_game":
		_open_saved_chapter()
	_pending_ingrid_target = ""


func _open_saved_chapter() -> void:
	if SaveSystem.slot_has_progress():
		var saved_last_chapter := int(SaveSystem.get_value("last_chapter", 0))
		var saved_last_scene := int(SaveSystem.get_value("last_scene", 0))
		GameManager.open_chapter(saved_last_chapter, saved_last_scene)
		return
	for slot_summary in SaveSystem.list_slot_summaries():
		var has_progress: Variant = slot_summary.get("has_progress", false)
		if has_progress == true or str(has_progress).to_lower() == "true":
			SaveSystem.set_active_slot(str(slot_summary.get("slot_id", "slot_1")))
			GameManager.open_chapter(int(slot_summary.get("last_chapter", 0)), int(slot_summary.get("last_scene", 0)))
			return
	GameManager.open_slot_select()


func _open_encyclopedia() -> void:
	if GameManager.has_method("open_chapter_select"):
		GameManager.open_chapter_select()


func _on_sound_button_pressed() -> void:
	AudioManager.toggle_music(MAIN_TRACK)


func _open_options_dialog() -> void:
	if _options_panel != null:
		return

	_options_panel = PanelContainer.new()
	_options_panel.name = "OptionsDialog"
	_options_panel.custom_minimum_size = Vector2(420, 260)
	_options_panel.position = Vector2(430, 220)

	var style := StyleBoxFlat.new()
	style.bg_color = Color8(36, 16, 48)
	style.border_color = Color8(157, 104, 216)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	_options_panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	_options_panel.add_child(root)

	var title := Label.new()
	title.text = "PARAMÈTRES"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color8(255, 250, 252))
	root.add_child(title)

	var volume_label := Label.new()
	volume_label.text = "Musique"
	volume_label.add_theme_color_override("font_color", Color8(186, 162, 203))
	root.add_child(volume_label)

	_options_slider = HSlider.new()
	_options_slider.min_value = 0
	_options_slider.max_value = 100
	_options_slider.step = 1
	_options_slider.value = int(SaveSystem.get_value("settings/music_volume_pct", 80))
	_options_slider.value_changed.connect(_on_options_volume_changed)
	root.add_child(_options_slider)

	_options_volume_label = Label.new()
	_options_volume_label.text = "%d%%" % int(_options_slider.value)
	_options_volume_label.add_theme_color_override("font_color", Color8(255, 250, 252))
	root.add_child(_options_volume_label)

	var resolution_label := Label.new()
	resolution_label.text = "Résolution"
	resolution_label.add_theme_color_override("font_color", Color8(186, 162, 203))
	root.add_child(resolution_label)

	_options_resolution = OptionButton.new()
	for resolution in ["1280x720", "1600x900", "1920x1080"]:
		_options_resolution.add_item(resolution)
	var saved_res := str(SaveSystem.get_value("settings/resolution", "1920x1080"))
	var index := ["1280x720", "1600x900", "1920x1080"].find(saved_res)
	_options_resolution.select(max(index, 0))
	root.add_child(_options_resolution)

	_options_fullscreen = CheckBox.new()
	_options_fullscreen.text = "Plein écran"
	var fullscreen_setting: Variant = SaveSystem.get_value("settings/fullscreen", false)
	var fullscreen_enabled: bool = false
	if typeof(fullscreen_setting) == TYPE_BOOL and fullscreen_setting:
		fullscreen_enabled = true
	elif str(fullscreen_setting).to_lower() == "true":
		fullscreen_enabled = true
	_options_fullscreen.set_pressed(fullscreen_enabled)
	root.add_child(_options_fullscreen)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(buttons)

	var apply_button := Button.new()
	apply_button.text = "Appliquer"
	apply_button.pressed.connect(_on_options_apply)
	buttons.add_child(apply_button)

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(_on_options_close)
	buttons.add_child(close_button)

	add_child(_options_panel)


func _on_options_volume_changed(value: float) -> void:
	if _options_volume_label != null:
		_options_volume_label.text = "%d%%" % int(value)
	AudioManager.music_volume = float(value) / 100.0


func _on_options_apply() -> void:
	if _options_panel == null:
		return
	SaveSystem.set_value("settings/music_volume_pct", int(_options_slider.value))
	SaveSystem.set_value("settings/resolution", _options_resolution.get_item_text(_options_resolution.selected))
	SaveSystem.set_value("settings/fullscreen", _options_fullscreen.is_pressed())
	SaveSystem.save()

	var settings := {
		"music_volume_pct": int(_options_slider.value),
		"resolution": _options_resolution.get_item_text(_options_resolution.selected),
		"fullscreen": _options_fullscreen.is_pressed(),
	}
	_write_user_settings(settings)
	var selected_resolution: String = str(settings["resolution"])
	var fullscreen_enabled: bool = _options_fullscreen.is_pressed()
	_apply_display_settings(selected_resolution, fullscreen_enabled)
	_on_options_close()


func _on_options_close() -> void:
	if _options_panel != null:
		_options_panel.queue_free()
	_options_panel = null
	_options_slider = null
	_options_resolution = null
	_options_fullscreen = null
	_options_volume_label = null


func _write_user_settings(settings: Dictionary) -> void:
	var path: String = "user://settings.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
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
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _apply_display_settings(resolution: String, fullscreen: bool) -> void:
	var parts := resolution.split("x")
	if parts.size() != 2:
		return
	var width := int(parts[0])
	var height := int(parts[1])
	# Par défaut on évite de modifier la fenêtre de l'éditeur.
	# Pour tester le resize depuis l'éditeur, activez `allow_resize_in_editor`.
	if (Engine.is_editor_hint() or OS.has_feature("editor")) and not allow_resize_in_editor:
		return
	DisplayServer.window_set_size(Vector2i(width, height), 0)
	DisplayServer.window_set_mode(
		(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED),
		0
	)
