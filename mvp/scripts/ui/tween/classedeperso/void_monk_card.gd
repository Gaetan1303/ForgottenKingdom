## Void Monk — void energy absorption: deep scale breathe + dark void modulate.
class_name VoidMonkCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Absorb void energy — expand with dark tint
	_card_tween.tween_property(_icon_rect, "scale", Vector2(1.07, 1.07), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color(0.55, 0.45, 0.75, 0.9), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Release
	_card_tween.tween_property(_icon_rect, "scale", Vector2.ONE, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(0.65)
