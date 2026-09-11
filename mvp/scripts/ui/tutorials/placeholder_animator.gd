## Silhouette vectorielle légère, remplaçable par un renderer de rig.
extends Control
var pose: String = "idle"
var tint := Color("d7b56d")
var _tween: Tween

func play_pose(value: String) -> void:
	pose = value
	if _tween != null: _tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.6 if value in ["hurt", "death"] else 0.82, 0.25)
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var lean := 16.0 if pose in ["attack_light", "attack_heavy", "run", "bow"] else 0.0
	if pose == "death":
		draw_line(center + Vector2(-50, 32), center + Vector2(38, 32), tint, 9, true)
		draw_circle(center + Vector2(-64, 32), 14, tint)
		return
	draw_circle(center + Vector2(lean, -44), 16, tint)
	draw_line(center + Vector2(lean, -25), center + Vector2(0, 24), tint, 8, true)
	for direction in [-1, 1]:
		draw_line(center + Vector2(0, 24), center + Vector2(24 * direction, 60), tint, 6, true)
		var raised := -34.0 if pose in ["cast", "surprised", "angry"] else 8.0
		draw_line(center + Vector2(lean, -12), center + Vector2(42 * direction, raised), tint, 6, true)
	if pose == "cast": draw_arc(center + Vector2(0, -14), 66, 0, TAU, 32, Color("9a52b3"), 3, true)
