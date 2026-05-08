## Hellcaster — fire color shimmer: warm orange modulate + scale pulse.
class_name HellcasterCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Ignition: warm orange glow + slight scale
	_card_tween.tween_property(_icon_rect, "modulate", Color(1.3, 0.75, 0.35, 1.0), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale", Vector2(1.04, 1.04), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Cool down
	_card_tween.tween_property(_icon_rect, "modulate", Color.WHITE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(0.35)
