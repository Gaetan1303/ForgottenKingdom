## Mise en évidence générique sans capturer les clics ni imposer un timer.
extends Control
var target: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func follow(control: Control) -> void:
	target = control
	visible = is_instance_valid(target)
	queue_redraw()

func _process(_delta: float) -> void:
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		hide()
		return
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(target): return
	var rect := target.get_global_rect()
	rect.position -= global_position
	var dim := Color(0, 0, 0, 0.15)
	draw_rect(Rect2(0, 0, size.x, maxf(0, rect.position.y)), dim)
	draw_rect(Rect2(0, rect.end.y, size.x, maxf(0, size.y - rect.end.y)), dim)
	draw_rect(Rect2(0, rect.position.y, maxf(0, rect.position.x), rect.size.y), dim)
	draw_rect(Rect2(rect.end.x, rect.position.y, maxf(0, size.x - rect.end.x), rect.size.y), dim)
	draw_rect(rect.grow(3), Color("d7b56d"), false, 2)
