## Pactbound — warlock pact: slow rotation oscillation + purple arcane tint.
class_name PactboundCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Lean into the pact
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 2.5, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color(0.75, 0.65, 1.2, 1.0), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Swing through and return
	_card_tween.tween_property(_icon_rect, "rotation_degrees", -2.5, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 0.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(0.7)
