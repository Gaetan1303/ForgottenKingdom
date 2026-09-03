## Compatibility wrapper: old creation screen now delegates to modular flow.
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const MODULAR_CREATION_SCENE := "res://scenes/character_creation/character_creation_screen.tscn"


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
