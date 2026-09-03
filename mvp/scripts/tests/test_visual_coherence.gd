extends SceneTree

const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")

const REQUIRED_VISUALS: Array[String] = [
	"res://assets/images/PNJ/defaut/female.png",
	"res://assets/images/PNJ/defaut/male.png",
	"res://assets/images/PNJ/defaut/Kael.png",
	"res://assets/images/clan/defaut.png",
	"res://assets/images/clan/nine_nobles.png",
	"res://assets/images/nine_nobles_1024.png",
	"res://assets/images/demon_realm_map_1024.png",
	"res://assets/images/yomihara_1024.png",
	"res://assets/images/ingrid_39_1024.png",
	"res://assets/images/lore/hell_knight_1024.webp",
]

const RESOURCE_VISUALS: Array[String] = [
	"res://assets/icon/gold.png",
	"res://assets/icon/soldat.png",
	"res://assets/icon/mana.png",
	"res://assets/icon/food.png",
	"res://assets/icon/wood.png",
	"res://assets/icon/iron.png",
	"res://assets/icon/essence.png",
]

const SCENES_TO_COMPILE: Array[String] = [
	"res://scenes/main_menu.tscn",
	"res://scenes/slot_select.tscn",
	"res://scenes/pnj_manager.tscn",
	"res://scenes/pnj_card.tscn",
	"res://scenes/clan_hub.tscn",
	"res://scenes/chapter_view.tscn",
	"res://scenes/chapter_select.tscn",
	"res://scenes/resolution_action.tscn",
	"res://scenes/character_creation/slides/slide_01_basic_info.tscn",
	"res://scenes/character_creation/slides/slide_02_class_stats.tscn",
	"res://scenes/character_creation/slides/slide_06_character_sheet.tscn",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	for path: String in REQUIRED_VISUALS + RESOURCE_VISUALS:
		var texture: Texture2D = ResourcePathResolver.load_texture(path, "res://assets/images")
		if texture == null:
			failures.append("texture non chargeable: %s" % path)

	for scene_path: String in SCENES_TO_COMPILE:
		var packed: PackedScene = load(scene_path) as PackedScene
		if packed == null:
			failures.append("scene non chargeable: %s" % scene_path)
			continue
		var instance: Node = packed.instantiate()
		if instance == null:
			failures.append("scene non instanciable: %s" % scene_path)
			continue
		_validate_scene_layout(scene_path, instance, failures)
		instance.free()

	var portrait_probe := TextureRect.new()
	VisualAssetCatalog.apply_fit(portrait_probe, "portrait")
	if portrait_probe.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		failures.append("les portraits ne sont pas en KEEP_ASPECT_CENTERED")
	portrait_probe.free()

	if failures.is_empty():
		print("VISUAL_COHERENCE_OK: %d assets, %d scenes" % [REQUIRED_VISUALS.size() + RESOURCE_VISUALS.size(), SCENES_TO_COMPILE.size()])
		quit(0)
		return

	for failure: String in failures:
		push_error("VISUAL_COHERENCE_FAIL: %s" % failure)
	quit(1)


func _validate_scene_layout(scene_path: String, instance: Node, failures: Array[String]) -> void:
	match scene_path:
		"res://scenes/pnj_manager.tscn":
			if not (instance.get_node_or_null("Footer/FooterControls") is HFlowContainer):
				failures.append("PNJ Manager: FooterControls doit etre un HFlowContainer")
			if not (instance.get_node_or_null("Footer/FooterControls/BtnsRight") is HFlowContainer):
				failures.append("PNJ Manager: BtnsRight doit etre un HFlowContainer")
		"res://scenes/pnj_card.tscn":
			if not (instance.get_node_or_null("Content/HBox/Right") is HFlowContainer):
				failures.append("PNJ Card: actions non responsives")
			var portrait := instance.get_node_or_null("Content/HBox/Left/Portrait") as TextureRect
			if portrait == null or portrait.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				failures.append("PNJ Card: portrait mal cadre")
		"res://scenes/slot_select.tscn":
			if not (instance.get_node_or_null("Root/Actions") is HFlowContainer):
				failures.append("Slots: barre d'actions non responsive")
		"res://scenes/clan_hub.tscn":
			if not (instance.get_node_or_null("Header/BgHeader/InfoClan/RessourcesHeader") is HFlowContainer):
				failures.append("Clan Hub: ressources header non responsive")
		"res://scenes/character_creation/slides/slide_01_basic_info.tscn":
			var preview := instance.find_child("PreviewBox", true, false) as TextureRect
			if preview == null or preview.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				failures.append("Slide 1: portrait preview recadre/zoome")
