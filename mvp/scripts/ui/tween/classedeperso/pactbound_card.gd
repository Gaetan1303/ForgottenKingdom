## Pactbound — warlock pact: slow rotation oscillation + purple arcane tint.
class_name PactboundCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_rotation(Color(0.75, 0.65, 1.2, 1.0), 2.5, 0.55, 0.7)
