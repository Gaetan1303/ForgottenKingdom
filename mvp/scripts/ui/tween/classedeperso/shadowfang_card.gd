## Shadowfang — shadow fade-slide: alpha flicker + lateral drift.
class_name ShadowfangCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Fade into shadow and drift left
	_card_tween.tween_property(_icon_rect, "modulate:a", 0.38, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_card_tween.parallel().tween_property(_icon_rect, "position:x", -4.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Reappear and return
	_card_tween.tween_property(_icon_rect, "modulate:a", 1.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "position:x", 0.0, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.tween_interval(0.9)
