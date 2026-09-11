## Orchestrates slide scenes and delegates data/validation to CharacterCreationManager.
class_name CharacterCreationScreen
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const ManagerType = preload("res://scripts/ui/character_creation/character_creation_manager.gd")
const CharacterCreationFlowType = preload("res://scripts/ui/character_creation/creation_flow_controller.gd")
const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")

const STEP_TITLES: Array[String] = [
	"IDENTITÉ & HÉRITAGE",
	"CLASSE & CARACTÉRISTIQUES",
	"DONS & CAPACITÉS",
	"ARSENAL & ÉQUIPEMENT",
	"SERMENT DE L’HÉRITIER",
]

const STEP_SUBTITLES: Array[String] = [
	"La voix de votre sœur s’éloigne. Reconstruisez votre identité.",
	"Choisissez une classe et répartissez 10 points. Chaque approche reste possible.",
	"Affinez votre style de jeu par les dons et aptitudes qui vous distinguent.",
	"Préparez ce que vous emporterez pour survivre à la reconquête.",
	"Vérifiez ce dont vous êtes capable avant de rejoindre Kael au refuge.",
]

@export var slide_scene_paths: Array[String] = [
	"res://scenes/character_creation/slides/slide_01_basic_info.tscn",
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn",
	"res://scenes/character_creation/slides/slide_03_feats_abilities.tscn",
	"res://scenes/character_creation/slides/slide_04_items_equipment.tscn",
	"res://scenes/character_creation/slides/slide_06_character_sheet.tscn",
]

@onready var _slide_host := get_node_or_null("Main/SlideHost") as Control

var _manager: Node
var _active_slide: Control = null
var _resume_requested: bool = false

func init_data(data: Dictionary) -> void:
	if data.has("resume") and bool(data["resume"]):
		_resume_requested = true
		if _manager != null and not bool(SaveSystem.get_value("opening", {}).get("draft_ready", false)):
			_manager.load_draft(_draft_path())
			_on_slide_changed(_manager.get_current_step())

func _ready() -> void:
	FallenUI.apply(self, "creation")
	_clear_error_label()

	_manager = ManagerType.new()
	add_child(_manager)
	_manager.slide_changed.connect(_on_slide_changed)
	_manager.validation_failed.connect(_on_validation_failed)
	_manager.creation_completed.connect(_on_creation_completed)
	if _resume_requested or bool(SaveSystem.get_value("opening", {}).get("draft_ready", false)):
		_manager.load_draft(_draft_path())
	_on_slide_changed(_manager.get_current_step())


func _on_slide_changed(step_index: int) -> void:
	_update_step_header(step_index)
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



func _update_step_header(step_index: int) -> void:
	var title := get_node_or_null("Main/Title") as Label
	var subtitle := get_node_or_null("Main/Subtitle") as Label
	if title != null and step_index >= 0 and step_index < STEP_TITLES.size():
		title.text = "ÉTAPE %d / %d  —  %s" % [step_index + 1, slide_scene_paths.size(), STEP_TITLES[step_index]]
	if subtitle != null and step_index >= 0 and step_index < STEP_SUBTITLES.size():
		subtitle.text = STEP_SUBTITLES[step_index]
		if step_index == 0:
			subtitle.text += "\n" + preload("res://scripts/services/memory_tutorial_service.gd").affinity_text(SaveSystem.get_value("opening", {}).get("memories", {}))


func _bind_slide_signals(slide: Control) -> void:
	var tips := {"BtnNext": "Valider cette étape. Un message explique les choix manquants.", "BtnPrev": "Revenir à l’étape précédente en conservant les choix.", "PointsPoolLabel": "Budget commun de 10 points. Chaque point investi augmente une caractéristique de 1 ; les bonus de classe sont séparés."}
	for node_name in tips:
		var control := slide.find_child(node_name, true, false) as Control
		if control:
			control.tooltip_text = str(tips[node_name])
			preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(control)
	if slide.has_signal("slide_data_submitted"):
		slide.connect("slide_data_submitted", Callable(self, "_on_slide_data_submitted"))
	if slide.has_signal("slide_next_requested"):
		slide.connect("slide_next_requested", Callable(self, "_on_slide_next_requested"))
	if slide.has_signal("slide_previous_requested"):
		slide.connect("slide_previous_requested", Callable(self, "_on_slide_previous_requested"))


func _on_slide_data_submitted(payload: Dictionary) -> void:
	_manager.update_from_slide(_manager.get_current_step(), payload)
	_clear_error_label()
	_save_draft()


func _on_slide_next_requested() -> void:
	if _manager.try_go_next():
		_save_draft()


func _on_slide_previous_requested() -> void:
	if _manager.get_current_step() <= CharacterCreationFlowType.Step.BASIC_INFO:
		GameManager.go_to("main_menu")
		return
	_manager.go_previous()
	_save_draft()


func _on_validation_failed(_step_index: int, message: String) -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = message
		error_label.show()


func _clear_error_label() -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = ""
		error_label.hide()


func _on_creation_completed(final_payload: Dictionary) -> void:
	var error_label := get_node_or_null("Main/ErrorLabel") as Label
	if error_label:
		error_label.text = ""
		error_label.hide()

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
	var clan_id := str(character.get("clan_id", "")).strip_edges()
	if clan_id.is_empty():
		clan_id = ClanIdentityType.id_from_name(nom_clan)
	var class_id := ""
	if character.has("class_id"):
		class_id = str(character["class_id"]).strip_edges()

	if nom_perso.length() < 2 or nom_clan.length() < 2 or class_id.is_empty():
		if error_label:
			error_label.text = "Création incomplète : nom, clan ou classe invalide."
			error_label.show()
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
	var secondary_stats: Dictionary = {}
	if character.has("secondary_stats"):
		secondary_stats = (character["secondary_stats"] as Dictionary).duplicate(true)

	var feat_labels: Array = []
	for feat_id in feats:
		var feat: Dictionary = GameDataLoader.get_feat(str(feat_id))
		var feat_name = str(feat["name"]) if feat.has("name") else str(feat_id)
		feat_labels.append(feat_name)

	var ability_labels: Array = []
	for ability_id in abilities:
		var ability: Dictionary = GameDataLoader.get_ability_by_id(str(ability_id))
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
		"clan_id": clan_id,
		"clan_name": nom_clan,
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
			"secondary_stats": secondary_stats,
			"points_restants": maxi(0, int(character.get("stats_points_pool", 10)) - _creation_points_spent(raw_stats)),
		},
	}

	var clan_mgr := get_node_or_null("/root/ClanManager")
	var game_mgr := get_node_or_null("/root/GameManager")
	if clan_mgr == null or game_mgr == null:
		if error_label:
			error_label.text = "Services du jeu introuvables (autoload)."
			error_label.show()
		return

	clan_mgr.nouvelle_partie(nom_perso, nom_clan, class_id, final_stats, profil)
	preload("res://scripts/services/refuge_service.gd").initialize(clan_mgr)
	var opening: Dictionary = SaveSystem.get_value("opening", {})
	if int(opening.get("version", 0)) >= 2:
		clan_mgr.campaign["version"] = 3
		clan_mgr.campaign["opening_run_id"] = str(opening.get("run_id", ""))
		clan_mgr.campaign["memories"] = opening.get("memories", {}).duplicate(true)
		# Les exercices terminés quittent la progression d'ouverture : un seul propriétaire.
		clan_mgr.campaign.memories.erase("simulation")
		preload("res://scripts/services/power_campaign_service.gd").ensure(clan_mgr)
		preload("res://scripts/services/refuge_service.gd").log_entry(clan_mgr, "Le présent", "Vous ouvrez les yeux à la Brèche-Sèche. Kael pose deux couvertures près du feu. « Je suis là. Dites-moi seulement ce que vous voulez faire maintenant. »")
	for fragment in opening.get("choices", {}).values():
		preload("res://scripts/services/refuge_service.gd").log_entry(clan_mgr, "Souvenir fragmenté", str(fragment))
	# Le clan est durable avant de fermer l'ouverture dans progress.json.
	clan_mgr.sauvegarder()
	opening.erase("memories")
	opening["active"] = false
	SaveSystem.set_value("opening", opening)
	SaveSystem.save()
	clan_mgr.sauvegarder()
	game_mgr.go_to("clan_hub")


func _creation_points_spent(raw_stats: Dictionary) -> int:
	var spent := 0
	for key in StatDefs.STAT_KEYS:
		spent += maxi(0, int(raw_stats.get(key, StatDefs.CHARACTER_MIN_STAT)) - StatDefs.CHARACTER_MIN_STAT)
	return spent

func _draft_path() -> String:
	return SaveSystem.get_progress_save_path().get_base_dir().path_join("creation_draft.json")

func _save_draft() -> void:
	if _manager.save_draft(_draft_path()):
		var opening: Dictionary = SaveSystem.get_value("opening", {})
		opening["draft_ready"] = true
		SaveSystem.set_value("opening", opening)
		SaveSystem.save()
