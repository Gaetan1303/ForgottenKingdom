## Demon Blade — sword energy burst: fast scale punch + red flash.
class_name DemonBladeCard
extends BaseClassCard


func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1.3, 0.55, 0.55, 1.0), Vector2(1.07, 1.07), 0.12, 1.2)
