## Infernal Artificer — gear mechanism: stutter rotation + gentle y bob.
class_name InfernalArtificerCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_rotation(Color(1.1, 0.95, 0.78, 1.0), 10.0, 0.45, 1.2)
