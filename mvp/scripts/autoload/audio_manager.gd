## autoload/audio_manager.gd
## Singleton audio — musique, SFX et compatibilité Web.
extends Node

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

var music_volume: float = 0.8:
    set(value):
        music_volume = clampf(value, 0.0, 1.0)
        if is_instance_valid(_music_player):
            _music_player.volume_db = _linear_db(music_volume)

var sfx_volume: float = 1.0:
    set(value):
        sfx_volume = clampf(value, 0.0, 1.0)

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music_name := ""
var _sfx_preload: Dictionary = {}

# Les navigateurs bloquent l'audio avant une interaction utilisateur.
var _web_audio_unlocked := true
var _pending_music_name := ""
var _pending_music_loop := true


func _ready() -> void:
    _ensure_audio_buses()

    _music_player = AudioStreamPlayer.new()
    _music_player.name = "MusicPlayer"
    _music_player.bus = MUSIC_BUS
    _music_player.volume_db = _linear_db(music_volume)
    add_child(_music_player)

    _sfx_player = AudioStreamPlayer.new()
    _sfx_player.name = "SfxPlayer"
    _sfx_player.bus = SFX_BUS
    _sfx_player.volume_db = _linear_db(sfx_volume)
    add_child(_sfx_player)

    _preload_common_sfx()

    _web_audio_unlocked = not OS.has_feature("web")
    set_process_input(OS.has_feature("web"))


func _input(event: InputEvent) -> void:
    if _web_audio_unlocked:
        return

    var pressed: bool = false
    if event is InputEventMouseButton:
        pressed = event.pressed
    elif event is InputEventKey:
        pressed = event.pressed and not event.echo
    elif event is InputEventScreenTouch:
        pressed = event.pressed

    if not pressed:
        return

    _web_audio_unlocked = true
    set_process_input(false)

    if not _pending_music_name.is_empty():
        var track: String = _pending_music_name
        var should_loop: bool = _pending_music_loop
        _pending_music_name = ""
        call_deferred("_resume_pending_music", track, should_loop)


func _resume_pending_music(track_name: String, loop: bool) -> void:
    await play_music(track_name, loop)


func _ensure_audio_buses() -> void:
    for bus_name: StringName in [MUSIC_BUS, SFX_BUS]:
        if AudioServer.get_bus_index(bus_name) >= 0:
            continue
        AudioServer.add_bus()
        var index: int = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(index, bus_name)
        AudioServer.set_bus_send(index, &"Master")


func _preload_common_sfx() -> void:
    var common: Array[String] = ["click", "whoosh", "footstep", "swing", "ambience_short"]
    for sfx_name: String in common:
        var stream: AudioStream = _load_audio_from_base(SFX_DIR, sfx_name)
        if stream != null:
            _sfx_preload[sfx_name] = stream


func _exit_tree() -> void:
    if is_instance_valid(_music_player):
        _music_player.stop()
        _music_player.stream = null
    if is_instance_valid(_sfx_player):
        _sfx_player.stop()
        _sfx_player.stream = null
    _sfx_preload.clear()
    _current_music_name = ""
    _pending_music_name = ""


## Joue une musique de fond. Sur Web, la première demande est mise en attente
## jusqu'au premier clic/touche afin de respecter l'autoplay policy du navigateur.
func play_music(track_name: String, loop: bool = true) -> void:
    var clean_name: String = track_name.strip_edges()
    if clean_name.is_empty():
        return

    if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
        return

    if OS.has_feature("web") and not _web_audio_unlocked:
        _pending_music_name = clean_name
        _pending_music_loop = loop
        return

    if _current_music_name == clean_name and _music_player.playing:
        return

    var stream: AudioStream = _load_music(clean_name)
    if stream == null:
        push_warning("AudioManager: musique introuvable ou non chargeable '%s'" % clean_name)
        _current_music_name = ""
        return

    _set_loop(stream, loop)
    await _fade_out_music(0.25)
    _music_player.stream = stream
    _music_player.volume_db = _linear_db(0.001)
    _music_player.play()
    _current_music_name = clean_name
    await _fade_in_music(0.25)


func stop_music(fade_duration: float = 0.5) -> void:
    _pending_music_name = ""
    if not is_instance_valid(_music_player):
        return
    await _fade_out_music(fade_duration)
    _music_player.stop()
    _music_player.stream = null
    _current_music_name = ""
    _music_player.volume_db = _linear_db(music_volume)


func play_sfx(sfx_name: String) -> void:
    if sfx_name.strip_edges().is_empty():
        return
    if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
        return

    # Un SFX est normalement déclenché par une interaction. Si le navigateur
    # n'est pas encore déverrouillé, ne provoque pas d'erreur silencieuse.
    if OS.has_feature("web") and not _web_audio_unlocked:
        return

    var key: String = sfx_name.get_basename()
    var stream: AudioStream = _sfx_preload.get(key) as AudioStream
    if stream == null:
        stream = _load_audio_from_base(SFX_DIR, sfx_name)
    if stream == null:
        push_warning("AudioManager: SFX introuvable ou non chargeable '%s'" % sfx_name)
        return

    _sfx_player.stream = stream
    _sfx_player.volume_db = _linear_db(sfx_volume)
    _sfx_player.play()


func _load_music(track_name: String) -> AudioStream:
    var base_name: String = track_name
    var extension: String = track_name.get_extension().to_lower()
    if extension in ["mp3", "ogg", "wav"]:
        var exact_path: String = MUSIC_DIR + track_name
        if ResourceLoader.exists(exact_path):
            return ResourceLoader.load(exact_path) as AudioStream
        base_name = track_name.get_basename()
    return _load_audio_from_base(MUSIC_DIR, base_name)


func _load_audio_from_base(directory: String, name: String) -> AudioStream:
    var clean: String = name.strip_edges()
    var extension: String = clean.get_extension().to_lower()

    if extension in ["mp3", "ogg", "wav"]:
        var exact: String = directory + clean
        if ResourceLoader.exists(exact):
            return ResourceLoader.load(exact) as AudioStream
        clean = clean.get_basename()

    for ext: String in [".ogg", ".mp3", ".wav"]:
        var path: String = directory + clean + ext
        if ResourceLoader.exists(path):
            var loaded: Resource = ResourceLoader.load(path)
            if loaded is AudioStream:
                return loaded
    return null


func _set_loop(stream: AudioStream, enabled: bool) -> void:
    if stream is AudioStreamOggVorbis:
        stream.loop = enabled
    elif stream is AudioStreamMP3:
        stream.loop = enabled
    elif stream is AudioStreamWAV:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if enabled else AudioStreamWAV.LOOP_DISABLED


func _fade_out_music(duration: float) -> void:
    if not is_instance_valid(_music_player) or not _music_player.playing:
        return
    if duration <= 0.0:
        _music_player.volume_db = _linear_db(0.001)
        return
    var tween: Tween = create_tween()
    tween.tween_property(_music_player, "volume_db", _linear_db(0.001), duration)
    await tween.finished


func _fade_in_music(duration: float) -> void:
    if not is_instance_valid(_music_player):
        return
    var target: float = _linear_db(music_volume)
    if duration <= 0.0:
        _music_player.volume_db = target
        return
    var tween: Tween = create_tween()
    tween.tween_property(_music_player, "volume_db", target, duration)
    await tween.finished


func _linear_db(value: float) -> float:
    return linear_to_db(maxf(value, 0.001))


func is_music_playing() -> bool:
    return is_instance_valid(_music_player) and _music_player.playing


func toggle_music(track_name: String = "main_theme.ogg") -> void:
    if is_music_playing():
        await stop_music()
        return
    await play_music(track_name)
