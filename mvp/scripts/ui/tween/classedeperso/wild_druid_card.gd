## Wild Druid — nature sway: gentle rotation oscillation + warm nature tint.
class_name WildDruidCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_rotation(Color(0.88, 1.1, 0.78, 1.0), 3.0, 1.1, 0.4)
