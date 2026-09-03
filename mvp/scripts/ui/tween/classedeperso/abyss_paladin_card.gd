## Abyss Paladin — heavy presence: slow imposing scale + infernal red-silver aura.
class_name AbyssPaladinCard
extends "res://scripts/ui/tween/classedeperso/base_class_card.gd"


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1.2, 0.65, 0.65, 1.0), Vector2(1.05, 1.05), 1.3, 0.6)
