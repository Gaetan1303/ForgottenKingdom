## Abyss Paladin — heavy presence: slow imposing scale + infernal red-silver aura.
class_name AbyssPaladinCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Rise with authority
	_card_tween.tween_property(_icon_rect, "scale", Vector2(1.05, 1.05), 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color(1.2, 0.65, 0.65, 1.0), 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Stand down
	_card_tween.tween_property(_icon_rect, "scale", Vector2.ONE, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(0.6)
