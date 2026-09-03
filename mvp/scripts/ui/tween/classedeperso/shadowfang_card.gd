## Shadowfang — shadow fade-slide: alpha flicker + lateral drift.
class_name ShadowfangCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_position(Color(0.85, 0.85, 0.9, 1.0), Vector2(-4.0, 0), 0.5, 0.9)
