## Soulwarden — soul pulse: slow scale breathe + soft ethereal glow.
class_name SoulwardenCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(0.85, 0.9, 1.15, 1.0), Vector2(1.05, 1.05), 1.4, 0.5)
