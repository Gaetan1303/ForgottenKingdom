extends Control
class_name FKScreenChrome

const GOLD := Color("d9b56d")
const VIOLET := Color("7f48a0")
const CRIMSON := Color("ac2b41")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()

func _draw() -> void:
    var s := size
    if s.x < 32.0 or s.y < 32.0:
        return

    var outer := Rect2(Vector2(10, 10), s - Vector2(20, 20))
    var inner := Rect2(Vector2(16, 16), s - Vector2(32, 32))
    draw_rect(outer, Color(GOLD.r, GOLD.g, GOLD.b, 0.28), false, 1.0)
    draw_rect(inner, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.18), false, 1.0)

    var l := 32.0
    var inset := 10.0
    var corners := [
        Vector2(inset, inset),
        Vector2(s.x - inset, inset),
        Vector2(inset, s.y - inset),
        Vector2(s.x - inset, s.y - inset),
    ]
    for i in range(corners.size()):
        var p: Vector2 = corners[i]
        var sx := 1.0 if i % 2 == 0 else -1.0
        var sy := 1.0 if i < 2 else -1.0
        draw_line(p, p + Vector2(l * sx, 0), Color(GOLD.r, GOLD.g, GOLD.b, 0.72), 2.0)
        draw_line(p, p + Vector2(0, l * sy), Color(GOLD.r, GOLD.g, GOLD.b, 0.72), 2.0)
        draw_circle(p + Vector2(8 * sx, 8 * sy), 2.5, Color(CRIMSON.r, CRIMSON.g, CRIMSON.b, 0.7))

    var cx := s.x * 0.5
    var top := 13.0
    var diamond := PackedVector2Array([
        Vector2(cx, top - 4),
        Vector2(cx + 7, top + 3),
        Vector2(cx, top + 10),
        Vector2(cx - 7, top + 3),
    ])
    draw_colored_polygon(diamond, Color(GOLD.r, GOLD.g, GOLD.b, 0.62))
