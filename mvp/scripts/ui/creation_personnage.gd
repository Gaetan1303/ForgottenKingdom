## Compatibility wrapper: old creation screen now delegates to modular flow.
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const MODULAR_CREATION_SCENE := "res://scenes/character_creation/character_creation_screen.tscn"
var _portrait_data: Dictionary = {}


func _ready() -> void:
	FallenUI.apply(self, "creation")
	if not ResourceLoader.exists(MODULAR_CREATION_SCENE):
		push_error("Modular creation scene introuvable: %s" % MODULAR_CREATION_SCENE)
		return
	var packed := load(MODULAR_CREATION_SCENE) as PackedScene
	if packed == null:
		push_error("Impossible de charger la scene modulaire de creation.")
		return
	var instance := packed.instantiate() as Control
	if instance == null:
		push_error("Impossible d'instancier la scene modulaire de creation.")
		return
	instance.name = "CharacterCreationModular"
	add_child(instance)


func _appliquer_portrait_depuis_chemin(path: String) -> void:
	var image: Image
	if path.begins_with("res://"):
		var texture: Texture2D = ResourceLoader.load(path) as Texture2D if ResourceLoader.exists(path) else null
		if texture != null:
			image = texture.get_image()
	elif FileAccess.file_exists(path):
		# Image choisie par le joueur ; son contenu est ensuite embarqué en base64.
		image = Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("Portrait illisible : %s" % path)
		return
	_portrait_data = {
		"file_name": path.get_file(),
		"image_path": path,
		"image_base64": Marshalls.raw_to_base64(image.save_png_to_buffer()),
	}
