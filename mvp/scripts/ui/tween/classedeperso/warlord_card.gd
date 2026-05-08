## Warlord — commanding presence: slow imposing scale + gold authority modulate.
class_name WarlordCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1.25, 1.05, 0.45, 1.0), Vector2(1.06, 1.06), 1.6, 0.5)
