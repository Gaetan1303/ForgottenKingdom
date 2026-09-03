## scripts/ui/chapter_view.gd
## Contrôleur de la vue chapitre — affiche les scènes narratives une par une.
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")

# Nœuds de l'interface
@onready var illustration: TextureRect = $IllustrationContainer
@onready var story_text: RichTextLabel = $TextBox/VBox/StoryText
@onready var chapter_title: Label = $TextBox/VBox/ChapterTitle
@onready var btn_next: Button = $NavBar/BtnNext
@onready var btn_prev: Button = $NavBar/BtnPrev
@onready var btn_menu: Button = $BtnMenu
@onready var page_indicator: Label = $NavBar/PageIndicator
@onready var flame_effect: ColorRect = $IllustrationContainer/FlameEffect

# État
var _chapter_data: Dictionary = {}
var _current_scene_index: int = 0
var _scenes: Array = []
var _is_animating: bool = false


func _ready() -> void:
	FallenUI.apply(self, "narrative")
	btn_next.pressed.connect(_on_next)
	btn_prev.pressed.connect(_on_prev)
	btn_menu.pressed.connect(_on_menu)

	# init_data est appelé par GameManager après le changement de scène
	if _chapter_data.is_empty():
		_load_chapter(GameManager.current_chapter_id, GameManager.current_scene_index)


## Appelé par GameManager avec les données de navigation.
func init_data(data: Dictionary) -> void:
	_load_chapter(data.get("chapter_id", 0), data.get("scene_index", 0))


func _load_chapter(chapter_id: int, scene_index: int) -> void:
	_chapter_data = ChapterLoader.get_chapter(chapter_id)
	if _chapter_data.is_empty():
		push_error("ChapterView: chapitre %d introuvable" % chapter_id)
		return

	_scenes = _chapter_data.get("scenes", [])
	_current_scene_index = clamp(scene_index, 0, _scenes.size() - 1)

	chapter_title.text = _chapter_data.get("titre", "")
	AudioManager.play_music(_chapter_data.get("musique", ""))

	_display_scene(_current_scene_index)


func _display_scene(index: int) -> void:
	if _scenes.is_empty():
		return

	var scene_data: Dictionary = _scenes[index]

	# Mise à jour de l'illustration
	var illus_name: String = scene_data.get("illustration", "")
	_load_illustration(illus_name)

	# Mise à jour du texte avec animation de typewriter
	story_text.text = ""
	await _typewrite(scene_data.get("texte", ""))

	# Mise à jour de la barre de navigation
	page_indicator.text = "%d / %d" % [index + 1, _scenes.size()]
	btn_prev.disabled = (index == 0 and GameManager.current_chapter_id == 0)
	btn_next.text = "Suivant" if index < _scenes.size() - 1 else "Chapitre suivant"

	# Sauvegarde progression
	SaveSystem.set_value("last_chapter", GameManager.current_chapter_id)
	SaveSystem.set_value("last_scene", index)
	SaveSystem.unlock_chapter(GameManager.current_chapter_id)
	GameManager.current_scene_index = index


func _load_illustration(illustration_name: String) -> void:
	if illustration_name.is_empty():
		illustration.texture = null
		return
	var texture: Texture2D = ResourcePathResolverScript.load_texture(illustration_name, "res://assets/images")
	if texture != null:
		illustration.texture = texture
		VisualAssetCatalog.apply_fit(illustration, VisualAssetCatalog.infer_kind(illustration_name))
		return
	push_warning("ChapterView: illustration introuvable '%s'" % illustration_name)
	illustration.texture = null


func _typewrite(bbcode_text: String) -> void:
	_is_animating = true
	story_text.bbcode_enabled = true
	story_text.text = ""
	story_text.append_text(bbcode_text)

	# Anime le visible ratio de 0 → 1
	story_text.visible_ratio = 0.0
	var tween: Tween = create_tween()
	var duration: float = clamp(float(bbcode_text.length()) * 0.03, 0.5, 4.0)
	tween.tween_property(story_text, "visible_ratio", 1.0, duration)
	await tween.finished
	_is_animating = false


# --- Callbacks navigation ---

func _on_next() -> void:
	if _is_animating:
		# Clic pendant l'animation → affiche le texte complet immédiatement
		story_text.visible_ratio = 1.0
		return

	if _current_scene_index < _scenes.size() - 1:
		_current_scene_index += 1
		_display_scene(_current_scene_index)
	else:
		# Fin du chapitre → chapitre suivant ou retour menu
		var next_ch := GameManager.current_chapter_id + 1
		if next_ch < ChapterLoader.chapter_count():
			GameManager.open_chapter(next_ch, 0)
		else:
			GameManager.go_to_menu()


func _on_prev() -> void:
	if _is_animating:
		story_text.visible_ratio = 1.0
		return

	if _current_scene_index > 0:
		_current_scene_index -= 1
		_display_scene(_current_scene_index)
	elif GameManager.current_chapter_id > 0:
		GameManager.open_chapter(GameManager.current_chapter_id - 1)


func _on_menu() -> void:
	SaveSystem.save()
	GameManager.go_to_menu()


# --- Raccourcis clavier ---

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_next"):
		_on_next()
	elif event.is_action_pressed("ui_previous"):
		_on_prev()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu()
