## Demon Blade — sword energy burst: fast scale punch + red flash.
class_name DemonBladeCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Scale burst like a sword strike
	_card_tween.tween_property(_icon_rect, "scale", Vector2(1.07, 1.07), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color(1.3, 0.55, 0.55, 1.0), 0.12) \
		.set_trans(Tween.TRANS_LINEAR)
	# Elastic return
	_card_tween.tween_property(_icon_rect, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, 0.45) \
		.set_trans(Tween.TRANS_LINEAR)
	_card_tween.tween_interval(1.2)
