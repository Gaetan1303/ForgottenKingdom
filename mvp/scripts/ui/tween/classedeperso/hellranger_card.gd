## Hellranger — hunter movement: vertical bob + slight horizontal lean.
class_name HellrangerCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Spring forward — tracking stance
	_card_tween.tween_property(_icon_rect, "position:y", -5.0, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale:x", 0.96, 0.65) \
		.set_trans(Tween.TRANS_LINEAR)
	# Land
	_card_tween.tween_property(_icon_rect, "position:y", 0.0, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_card_tween.parallel().tween_property(_icon_rect, "scale:x", 1.0, 0.65) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_interval(0.8)
