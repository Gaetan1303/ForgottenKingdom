## Blood Sorcerer — blood surge: crimson modulate throb + scale pulse.
class_name BloodSorcererCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1.4, 0.4, 0.4, 1.0), Vector2(1.06, 1.06), 0.38, 1.1)
