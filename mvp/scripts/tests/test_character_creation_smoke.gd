extends SceneTree

const CREATION_SCENES: Array[String] = [
	"res://scenes/character_creation/character_creation_screen.tscn",
	"res://scenes/character_creation/slides/slide_01_basic_info.tscn",
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn",
	"res://scenes/character_creation/slides/slide_03_feats_abilities.tscn",
	"res://scenes/character_creation/slides/slide_04_items_equipment.tscn",
	"res://scenes/character_creation/slides/slide_06_character_sheet.tscn",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for scene_path: String in CREATION_SCENES:
		var resource := ResourceLoader.load(scene_path)
		if not (resource is PackedScene):
			failures.append("scène non chargeable : %s" % scene_path)
			continue
		var instance := (resource as PackedScene).instantiate()
		if instance == null:
			failures.append("scène non instanciable : %s" % scene_path)
			continue
		instance.free()

	var game_data_loader := get_root().get_node_or_null("GameDataLoader")
	if game_data_loader == null:
		failures.append("autoload GameDataLoader absent")
	else:
		for class_id_value: Variant in game_data_loader.get_classes().keys():
			var class_id := str(class_id_value)
			if game_data_loader.get_class_progression(class_id).size() > 0:
				continue
			failures.append("progression absente : %s" % class_id)

	if failures.is_empty():
		print("CHARACTER_CREATION_SMOKE_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error("CHARACTER_CREATION_SMOKE_FAIL: %s" % failure)
	quit(1)
