extends Panel

var _difficulty_option: OptionButton = null
var _volume_slider: HSlider = null

func _ready() -> void:
    # Initialize controls from SaveSystem
    var vol_pct: int = int(SaveSystem.get_value("settings/music_volume_pct", 100))
    var diff: String = str(SaveSystem.get_value("settings/difficulty", "Normal"))
    _volume_slider = $HSliderVolume as HSlider
    _difficulty_option = $OptionDifficulty as OptionButton
    _volume_slider.value = vol_pct
    # select option index matching saved difficulty
    var idx: int = 1
    match diff:
        "Facile": idx = 0
        "Normal": idx = 1
        "Difficile": idx = 2
        _: idx = 1
    if _difficulty_option:
        _difficulty_option.select(idx)

    $BtnApply.pressed.connect(_on_apply)
    $BtnClose.pressed.connect(_on_close)
    visible = false

func show_centered() -> void:
    # add to tree root then center in viewport
    visible = true
    var vp: Vector2 = get_viewport_rect().size
    # use Control API: position and size
    position = (vp - size) * 0.5

func _on_apply() -> void:
    var vol_pct: int = int(_volume_slider.value) if _volume_slider != null else int($HSliderVolume.value)
    SaveSystem.set_value("settings/music_volume_pct", vol_pct)
    # convert percent to dB (-80..0)
    var db: float = lerp(-80.0, 0.0, float(vol_pct) / 100.0)
    var idx: int = AudioServer.get_bus_index("Music")
    if idx < 0:
        idx = 0
    AudioServer.set_bus_volume_db(idx, db)

    var diff_text: String = _difficulty_option.get_item_text(_difficulty_option.selected) if _difficulty_option != null else $OptionDifficulty.get_item_text($OptionDifficulty.selected)
    SaveSystem.set_value("settings/difficulty", diff_text)

    SaveSystem.save()
    hide()

func _on_close() -> void:
    hide()
