extends CanvasLayer
class_name StopMusicUI

var btn: Button

func _ready() -> void:
    name = "StopMusicUI"
    btn = Button.new()
    btn.name = "BtnStopMusicGlobal"
    # ancre en bas-gauche
    btn.anchor_left = 0.0
    btn.anchor_top = 1.0
    btn.anchor_right = 0.0
    btn.anchor_bottom = 1.0
    btn.offset_left = 12
    btn.offset_top = -48
    btn.offset_right = 12 + 48
    btn.offset_bottom = -12
    btn.custom_minimum_size = Vector2(48, 32)
    btn.flat = true
    btn.focus_mode = Control.FOCUS_NONE
    btn.add_theme_color_override("font_color", Color8(136, 46, 46))

    var tex := ResourceLoader.load("res://assets/ui/stop_icon.svg")
    if tex and tex is Texture2D:
        btn.icon = tex
    else:
        btn.text = "⏯"

    btn.pressed.connect(_toggle_music)
    add_child(btn)

var _muted: bool = false

func _toggle_music() -> void:
    var idx: int = AudioServer.get_bus_index("Music")
    if idx < 0:
        idx = 0
    # simple mute/unmute using volume dB to avoid engine API differences
    if not _muted:
        AudioServer.set_bus_volume_db(idx, -80.0)
        _muted = true
        btn.text = "▶"
    else:
        AudioServer.set_bus_volume_db(idx, 0.0)
        _muted = false
        if not (btn.icon and btn.icon is Texture2D):
            btn.text = "⏹"
