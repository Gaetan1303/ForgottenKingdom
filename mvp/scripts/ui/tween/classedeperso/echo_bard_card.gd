## Echo Bard — sound wave: scale_x ripple simulating a sound propagation.
class_name EchoBardCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Sound wave ripple on X axis
	_card_tween.tween_property(_icon_rect, "scale:x", 1.07, 0.14) \
		.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_property(_icon_rect, "scale:x", 0.94, 0.14) \
		.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_property(_icon_rect, "scale:x", 1.04, 0.12) \
		.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_property(_icon_rect, "scale:x", 0.97, 0.10) \
		.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_property(_icon_rect, "scale:x", 1.0, 0.10) \
		.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_interval(1.5)
