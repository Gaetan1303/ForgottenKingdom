## scripts/ui/chapter_select.gd
## Grille de sélection des chapitres déverrouillés.
extends Control

@onready var chapter_grid: GridContainer = $ScrollContainer/ChapterGrid
@onready var btn_menu: Button = $BtnMenu


func _ready() -> void:
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
	btn.custom_minimum_size = Vector2(240, 120)

	if unlocked:
		btn.text = "Récit Ingrid #%d\n%s\n[i]%s[/i]" % [
			index + 1,
			ch.get("titre", "Chapitre %d" % (index + 1)),
			ch.get("periode", "")
		]
		btn.pressed.connect(func(): GameManager.open_chapter(index, 0))
	else:
		btn.text = "🔒\nVerrouillé"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.4, 0.3, 0.5, 0.6))

	return btn


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_menu()
