## Hellranger — hunter movement: vertical bob + slight horizontal lean.
class_name HellrangerCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_position(Color(0.95, 0.95, 1.0, 1.0), Vector2(0, -5.0), 0.65, 0.8)
