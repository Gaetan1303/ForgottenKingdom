## Orchestrates slide scenes and delegates data/validation to CharacterCreationManager.
class_name CharacterCreationScreen
extends Control

const ManagerType = preload("res://scripts/ui/character_creation/character_creation_manager.gd")
const CharacterCreationFlowType = preload("res://scripts/ui/character_creation/creation_flow_controller.gd")

@export var slide_scene_paths: Array[String] = [
	"res://scenes/character_creation/slides/slide_01_basic_info.tscn",
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn",
	"res://scenes/character_creation/slides/slide_03_feats_abilities.tscn",
	"res://scenes/character_creation/slides/slide_04_items_equipment.tscn",
	"res://scenes/character_creation/slides/slide_06_character_sheet.tscn",
]

@onready var _slide_host := get_node_or_null("Main/SlideHost") as Control

var _manager = ManagerType.new()
var _active_slide: Control = null
var _resume_requested: bool = false
var _error_timer: Timer = null

func init_data(data: Dictionary) -> void:
	if data.has("resume") and bool(data["resume"]):
		_resume_requested = true

func _ready() -> void:
	_error_timer = Timer.new()
	_error_timer.one_shot = true
	_error_timer.wait_time = 5.0
	_error_timer.connect("timeout", Callable(self, "_clear_error_label"))
	add_child(_error_timer)

	add_child(_manager)
	_manager.slide_changed.connect(_on_slide_changed)
	_manager.validation_failed.connect(_on_validation_failed)
	_manager.creation_completed.connect(_on_creation_completed)
	if _resume_requested:
		_manager.load_draft()
	_on_slide_changed(_manager.get_current_step())


func _on_slide_changed(step_index: int) -> void:
	if _slide_host == null:
		push_warning("SlideHost node not found in CharacterCreationScreen.")
		return
	if _active_slide != null and is_instance_valid(_active_slide):
		if _active_slide.has_method("exit_slide"):
			_active_slide.exit_slide()
		_active_slide.queue_free()

	if step_index < 0 or step_index >= slide_scene_paths.size():
		push_warning("Invalid step index: %s" % step_index)
		return

	var path := str(slide_scene_paths[step_index])
	if not ResourceLoader.exists(path):
		push_warning("Slide scene not found: %s" % path)
		return

	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Unable to load slide scene: %s" % path)
		return

	_active_slide = packed.instantiate() as Control
	if _active_slide == null:
		return

	_slide_host.add_child(_active_slide)
	_bind_slide_signals(_active_slide)
	if _active_slide.has_method("bind_manager"):
		_active_slide.bind_manager(_manager)
	if _active_slide.has_method("enter_slide"):
		_active_slide.enter_slide(_manager.get_data())


func _bind_slide_signals(slide: Control) -> void:
	if slide.has_signal("slide_data_submitted"):
		slide.connect("slide_data_submitted", Callable(self, "_on_slide_data_submitted"))
	if slide.has_signal("slide_next_requested"):
		slide.connect("slide_next_requested", Callable(self, "_on_slide_next_requested"))
	if slide.has_signal("slide_previous_requested"):
		slide.connect("slide_previous_requested", Callable(self, "_on_slide_previous_requested"))


func _on_slide_data_submitted(payload: Dictionary) -> void:
	_manager.update_from_slide(_manager.get_current_step(), payload)


func _on_slide_next_requested() -> void:
	if _manager.try_go_next():
		_manager.save_draft()


func _on_slide_previous_requested() -> void:
	if _manager.get_current_step() <= CharacterCreationFlowType.Step.BASIC_INFO:
		GameManager.go_to("main_menu")
		return
	_manager.go_previous()


func _on_validation_failed(_step_index: int, message: String) -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = message
		if _error_timer != null:
			_error_timer.stop()
		_error_timer.start()


func _clear_error_label() -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = ""


func _on_creation_completed(final_payload: Dictionary) -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = ""

	var character: Dictionary = {}
	if final_payload.has("character"):
		character = final_payload["character"] as Dictionary
	var final_stats: Dictionary = {}
	if final_payload.has("final_stats"):
		final_stats = final_payload["final_stats"] as Dictionary

	var nom_perso := ""
	if character.has("character_name"):
		nom_perso = str(character["character_name"]).strip_edges()
	var nom_clan := ""
	if character.has("clan_name"):
		nom_clan = str(character["clan_name"]).strip_edges()
	var class_id := ""
	if character.has("class_id"):
		class_id = str(character["class_id"]).strip_edges()

	if nom_perso.length() < 2 or nom_clan.length() < 2 or class_id.is_empty():
		if error_label:
			error_label.text = "Creation incomplete: nom, clan ou classe invalide."
		return

	var feats: Array = []
	if character.has("selected_feats"):
		feats = (character["selected_feats"] as Array).duplicate(true)
	var abilities: Array = []
	if character.has("selected_abilities"):
		abilities = (character["selected_abilities"] as Array).duplicate(true)
	var inventory: Array = []
	if character.has("inventory_items"):
		inventory = (character["inventory_items"] as Array).duplicate(true)
	var equipment: Dictionary = {}
	if character.has("equipped_items_by_slot"):
		equipment = (character["equipped_items_by_slot"] as Dictionary).duplicate(true)
	var raw_stats: Dictionary = {}
	if character.has("stats"):
		raw_stats = (character["stats"] as Dictionary).duplicate(true)

	var feat_labels: Array = []
	for feat_id in feats:
		var feat := GameDataLoader.get_feat(str(feat_id))
		var feat_name = str(feat["name"]) if feat.has("name") else str(feat_id)
		feat_labels.append(feat_name)

	var ability_labels: Array = []
	for ability_id in abilities:
		var ability := GameDataLoader.get_ability_by_id(str(ability_id))
		var ability_name = str(ability["name"]) if ability.has("name") else str(ability_id)
		ability_labels.append(ability_name)

	var full_name := "%s de %s" % [nom_perso, nom_clan]
	var appearance_value := str(character["appearance_id"]) if character.has("appearance_id") else ""
	var portrait_value: Dictionary = {}
	if character.has("portrait_payload"):
		portrait_value = (character["portrait_payload"] as Dictionary).duplicate(true)
	var pouvoir_value := str(character["racial_power_id"]) if character.has("racial_power_id") else ""
	var profil := {
		"nom_complet": full_name,
		"genre": "",
		"apparence": appearance_value,
		"portrait": portrait_value,
		"pouvoir_magique": pouvoir_value,
		"pouvoir_magique_id": pouvoir_value,
		"archetype_pathfinder": "",
		"don": str(feats[0]) if feats.size() > 0 else "",
		"don_id": str(feats[0]) if feats.size() > 0 else "",
		"competence": str(abilities[0]) if abilities.size() > 0 else "",
		"competence_id": str(abilities[0]) if abilities.size() > 0 else "",
		"equipement_depart": str(inventory[0]) if inventory.size() > 0 else "",
		"equipement_depart_id": str(inventory[0]) if inventory.size() > 0 else "",
		"feats": feats,
		"abilities": abilities,
		"equipment_slots": equipment,
		"magie_pactes": true,
		"traits_gameplay": {
			"feats": feat_labels,
			"abilities": ability_labels,
			"equipment": [inventory, equipment.values()],
		},
		"fiche_complete": {
			"stats_brutes": raw_stats,
			"points_restants": 0,
		},
	}

	var clan_mgr := get_node_or_null("/root/ClanManager")
	var game_mgr := get_node_or_null("/root/GameManager")
	if clan_mgr == null or game_mgr == null:
		if error_label:
			error_label.text = "Services du jeu introuvables (autoload)."
		return

	clan_mgr.nouvelle_partie(nom_perso, nom_clan, class_id, final_stats, profil)
	game_mgr.go_to("intro_vn")
