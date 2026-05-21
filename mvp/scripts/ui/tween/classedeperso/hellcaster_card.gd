## Hellcaster — fire color shimmer: warm orange modulate + scale pulse.
class_name HellcasterCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1.3, 0.75, 0.35, 1.0), Vector2(1.04, 1.04), 0.55, 0.35)
