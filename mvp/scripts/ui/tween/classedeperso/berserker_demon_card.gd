## Berserker Demon — rage trembling: rapid horizontal shake burst.
class_name BerserkerDemonCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_kill_tween()
	_card_tween = create_tween().set_loops()
	# Rage trembling burst
	var shake_sequence := [3.5, -3.5, 2.8, -2.8, 2.0, -2.0, 1.2, -1.2, 0.0]
	for x in shake_sequence:
		_card_tween.tween_property(_icon_rect, "position:x", x, 0.05) \
			.set_trans(Tween.TRANS_SINE)
	_card_tween.tween_interval(1.8)
