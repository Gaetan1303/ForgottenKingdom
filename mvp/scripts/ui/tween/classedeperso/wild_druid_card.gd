## Wild Druid — nature sway: gentle rotation oscillation + warm nature tint.
class_name WildDruidCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Sway right — breeze from the left
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 3.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color(0.88, 1.1, 0.78, 1.0), 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Sway left — breeze from the right
	_card_tween.tween_property(_icon_rect, "rotation_degrees", -3.0, 2.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Return to neutral
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 0.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(0.4)
