## Pactbound — warlock pact: slow rotation oscillation + purple arcane tint.
class_name PactboundCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_rotation(Color(0.75, 0.65, 1.2, 1.0), 2.5, 0.55, 0.7)
