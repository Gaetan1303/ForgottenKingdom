## Blood Sorcerer — blood surge: crimson modulate throb + scale pulse.
class_name BloodSorcererCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Blood surge
	_card_tween.tween_property(_icon_rect, "modulate", Color(1.4, 0.4, 0.4, 1.0), 0.38) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_card_tween.parallel().tween_property(_icon_rect, "scale", Vector2(1.06, 1.06), 0.38) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Dissipate
	_card_tween.tween_property(_icon_rect, "modulate", Color.WHITE, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale", Vector2.ONE, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.tween_interval(1.1)
