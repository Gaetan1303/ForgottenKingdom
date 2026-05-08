## Infernal Artificer — gear mechanism: stutter rotation + gentle y bob.
class_name InfernalArtificerCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Gear stutter — step-by-step rotation clicks
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 5.0, 0.12) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 3.0, 0.07) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 8.0, 0.12) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 6.0, 0.07) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 10.0, 0.12) \
		.set_trans(Tween.TRANS_LINEAR)
	# Spring back — spring mechanism
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 0.0, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "position:y", -3.0, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_card_tween.tween_property(_icon_rect, "position:y", 0.0, 0.25) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_card_tween.tween_interval(1.2)
