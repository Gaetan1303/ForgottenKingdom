## Void Monk — void energy absorption: deep scale breathe + dark void modulate.
class_name VoidMonkCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(0.55, 0.45, 0.75, 0.9), Vector2(1.07, 1.07), 0.85, 0.65)
