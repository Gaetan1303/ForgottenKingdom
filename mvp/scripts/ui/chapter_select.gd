## scripts/ui/chapter_select.gd
## Grille de sélection des chapitres déverrouillés.
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")

@onready var chapter_grid: GridContainer = $ScrollContainer/ChapterGrid
@onready var btn_menu: Button = $BtnMenu


func _ready() -> void:
	FallenUI.apply(self, "default")
	btn_menu.pressed.connect(func(): GameManager.go_to_menu())
	AudioManager.play_music("menu_ambient.ogg")
	_populate_grid()


func _populate_grid() -> void:
	var unlocked: Array = SaveSystem.get_value("unlocked_chapters", [0]) as Array
	var count := ChapterLoader.chapter_count()

	for i in range(count):
		var ch: Dictionary = ChapterLoader.get_chapter(i)
		var btn := _make_chapter_button(i, ch, i in unlocked)
		chapter_grid.add_child(btn)


func _make_chapter_button(index: int, ch: Dictionary, unlocked: bool) -> Button:
	var btn := Button.new()
	btn.name = "ChapterCard_%d" % index
	btn.text = ""
	btn.custom_minimum_size = Vector2(310, 224)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", FallenUI.card_style(false))
	btn.add_theme_stylebox_override("hover", FallenUI.card_style(unlocked))
	btn.add_theme_stylebox_override("pressed", FallenUI.card_style(true))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 118)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		var scenes_value: Variant = ch.get("scenes", [])
		var scenes: Array = scenes_value as Array
		if not scenes.is_empty() and scenes[0] is Dictionary:
			var first_scene := scenes[0] as Dictionary
			var illustration_name: String = str(first_scene.get("illustration", ""))
			if not illustration_name.is_empty():
				preview.texture = ResourcePathResolver.load_texture(illustration_name, "res://assets/images")
				VisualAssetCatalog.apply_fit(preview, VisualAssetCatalog.infer_kind(illustration_name))
	content.add_child(preview)

	var title := Label.new()
	title.text = str(ch.get("titre", "Chapitre %d" % (index + 1))) if unlocked else "Chronique scellée"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", FallenUI.GOLD if unlocked else FallenUI.DIM)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var period := Label.new()
	period.text = str(ch.get("periode", "")) if unlocked else "Accomplissez les récits précédents"
	period.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	period.add_theme_font_size_override("font_size", 12)
	period.add_theme_color_override("font_color", FallenUI.MUTED if unlocked else FallenUI.DIM)
	period.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(period)

	if unlocked:
		btn.pressed.connect(func(): GameManager.open_chapter(index, 0))
	else:
		btn.disabled = true
		preview.modulate = Color(0.35, 0.30, 0.38, 0.45)

	return btn

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_menu()
