## Contrat FK_Chibi_Humanoid_v1. Aucun événement métier n'attend une animation.
extends Control
const Placeholder = preload("res://scripts/ui/tutorials/placeholder_animator.gd")
const RIG_CONTRACT := "FK_Chibi_Humanoid_v1"
const POSES := ["idle", "walk", "run", "talk", "attack_light", "attack_heavy", "cast", "hurt", "death", "interact", "angry", "surprised", "bow"]
var _renderer: Placeholder
var current_pose := "idle"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_renderer = Placeholder.new()
	_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_renderer)
	_renderer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play(current_pose)

func play(pose: String) -> bool:
	if pose not in POSES: return false
	current_pose = pose
	if _renderer != null: _renderer.play_pose(pose)
	return true
