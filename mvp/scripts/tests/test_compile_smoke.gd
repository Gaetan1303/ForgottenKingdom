extends SceneTree

# Les scripts métier sont préchargés pour provoquer une erreur de compilation immédiatement.
# Les autoloads ne sont PAS préchargés ici : Godot les instancie depuis project.godot et
# certains d'entre eux se référencent mutuellement par leur nom de singleton.
const StatDefsScript = preload("res://scripts/data/stat_defs.gd")
const PnjDailyPlannerScript = preload("res://scripts/services/pnj_daily_planner_service.gd")
const PnjGeneratorScript = preload("res://scripts/services/pnj_generator.gd")
const JsonPersistenceScript = preload("res://scripts/services/json_persistence_service.gd")
const CharacterBuildScript = preload("res://scripts/data/character_build_service.gd")
const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")
const CorruptionServiceScript = preload("res://scripts/services/corruption_service.gd")
const EnumsScript = preload("res://scripts/core/enums.gd")
const TrainingSystemScript = preload("res://scripts/services/training_system.gd")
const PactServiceScript = preload("res://scripts/services/pact_service.gd")
const WorldStateScript = preload("res://scripts/data/world_state.gd")
const WorldStateAdapterScript = preload("res://scripts/adapters/world_state_adapter.gd")
const EventResultPresenterScript = preload("res://scripts/ui/event_result_presenter.gd")
const EventResultViewScript = preload("res://scripts/ui/event_result_view.gd")
const CreatureProfileScript = preload("res://scripts/data/creature_profile.gd")
const CreatureProfileLegacyPathScript = preload("res://scripts/domain/creature_profile.gd")
const CreatureFactoryScript = preload("res://scripts/factory/creature_factory.gd")
const CreatureRosterServiceScript = preload("res://scripts/services/creature_roster_service.gd")
const SoldierAssignmentServiceScript = preload("res://scripts/services/soldier_assignment_service.gd")
const ClanHouseServiceScript = preload("res://scripts/services/clan_house_service.gd")
const ClanEconomyServiceScript = preload("res://scripts/services/clan_economy_service.gd")

const AUTOLOAD_NAMES: Array[String] = [
	"GameManager",
	"SaveSystem",
	"AudioManager",
	"ChapterLoader",
	"ClanManager",
	"GameDataLoader",
	"DungeonGenerator",
]
const SLIDE_02_SCENE := "res://scenes/character_creation/slides/slide_02_class_stats.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var scripts: Array[Script] = [
		StatDefsScript,
		PnjDailyPlannerScript,
		PnjGeneratorScript,
		JsonPersistenceScript,
		CharacterBuildScript,
		ResourcePathResolverScript,
		CorruptionServiceScript,
		EnumsScript,
		TrainingSystemScript,
		PactServiceScript,
		WorldStateScript,
		WorldStateAdapterScript,
		EventResultPresenterScript,
		EventResultViewScript,
		CreatureProfileScript,
		CreatureProfileLegacyPathScript,
		CreatureFactoryScript,
		CreatureRosterServiceScript,
		SoldierAssignmentServiceScript,
		ClanHouseServiceScript,
		ClanEconomyServiceScript,
	]
	for script: Script in scripts:
		if script == null or not script.can_instantiate():
			failures.append("script métier non instanciable")

	var root: Window = get_root()
	for singleton_name: String in AUTOLOAD_NAMES:
		if root.get_node_or_null(singleton_name) == null:
			failures.append("autoload absent: %s" % singleton_name)

	var slide_resource: Resource = ResourceLoader.load(SLIDE_02_SCENE)
	if not (slide_resource is PackedScene):
		failures.append("slide 2 non chargeable")

	if failures.is_empty():
		print("COMPILE_SMOKE_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error("COMPILE_SMOKE_FAIL: %s" % failure)
	quit(1)
