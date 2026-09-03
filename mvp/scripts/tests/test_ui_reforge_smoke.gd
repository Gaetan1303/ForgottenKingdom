extends SceneTree

const SCENES: Array[String] = [
	"res://scenes/main_menu.tscn",
	"res://scenes/slot_select.tscn",
	"res://scenes/character_creation/character_creation_screen.tscn",
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn",
	"res://scenes/chapter_select.tscn",
	"res://scenes/chapter_view.tscn",
	"res://scenes/intro_vn.tscn",
	"res://scenes/clan_hub.tscn",
	"res://scenes/pnj_manager.tscn",
	"res://scenes/map_view.tscn",
	"res://scenes/dungeon_view.tscn",
	"res://scenes/resolution_action.tscn",
	"res://scenes/character_sheet.tscn",
]

const REQUIRED_NODES: Dictionary = {
	"res://scenes/main_menu.tscn": [
		"HeaderContainer/Title",
		"ContentVBox/BodyCenterContainer/BodyListHolder/BtnNouvellePartie",
		"ContentVBox/BodyCenterContainer/BodyListHolder/BtnContinuer",
		"ContentVBox/BodyCenterContainer/BodyListHolder/BtnParametres",
		"ContentVBox/BodyCenterContainer/BodyListHolder/BtnEncyclopedie",
		"ContentVBox/BodyCenterContainer/BodyListHolder/BtnQuitter",
	],
	"res://scenes/character_creation/character_creation_screen.tscn": [
		"Main/Title",
		"Main/ErrorLabel",
		"Main/SlideHost",
	],
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn": [
		"Content/MainSplit/ProgressionPanel/ProgressionSummary/ProgressionGrid",
		"Content/MainSplit/ClassesPanel/ClassesScroll/ClassesGrid",
	],
	"res://scenes/chapter_view.tscn": [
		"IllustrationContainer",
		"TextBox/VBox/StoryText",
		"ChapterTitle",
		"NavBar/BtnPrev",
		"NavBar/BtnNext",
	],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var instantiated_count: int = 0
	for scene_path: String in SCENES:
		var resource: Resource = ResourceLoader.load(scene_path)
		if not (resource is PackedScene):
			failures.append("scene non chargeable: %s" % scene_path)
			continue
		var instance: Node = (resource as PackedScene).instantiate()
		if instance == null:
			failures.append("scene non instanciable: %s" % scene_path)
			continue
		instantiated_count += 1
		var required_value: Variant = REQUIRED_NODES.get(scene_path, [])
		var required_nodes: Array = required_value as Array
		for node_path_value: Variant in required_nodes:
			var node_path: String = str(node_path_value)
			if instance.get_node_or_null(node_path) == null:
				failures.append("noeud absent: %s -> %s" % [scene_path, node_path])
		instance.free()

	if failures.is_empty():
		print("UI_REFORGE_SMOKE_OK: %d/%d scenes" % [instantiated_count, SCENES.size()])
		quit(0)
		return
	for failure: String in failures:
		push_error("UI_REFORGE_SMOKE_FAIL: %s" % failure)
	quit(1)
