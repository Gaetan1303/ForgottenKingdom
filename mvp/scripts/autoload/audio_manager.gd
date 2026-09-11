## autoload/audio_manager.gd
## Singleton audio — gère la musique de fond et les effets sonores.
extends Node

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR   := "res://assets/audio/sfx/"

# Volumes (0.0 – 1.0)
var music_volume: float = 0.8:
	set(v):
		music_volume = clamp(v, 0.0, 1.0)
		if _music_player:
			_music_player.volume_db = linear_to_db(music_volume)

var sfx_volume: float = 1.0:
	set(v):
		sfx_volume = clamp(v, 0.0, 1.0)

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music_name: String = ""
var _sfx_preload: Dictionary = {}
var _web_audio_unlocked := not OS.has_feature("web")
var _pending_music_name := ""
var _pending_music_loop := true
var _music_transition: Tween


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	# Preload common SFX (if present in res://assets/audio/sfx/)
	var common: Array[String] = ["click", "whoosh", "footstep", "swing", "ambience_short"]
	for name: String in common:
		var p: String = SFX_DIR + name + ".ogg"
		if ResourceLoader.exists(p):
			_sfx_preload[name] = load(p)


func _exit_tree() -> void:
	# Explicit cleanup helps keep headless startup/quit tests free of resource leak warnings.
	if _music_player:
		_music_player.stop()
		_music_player.stream = null
	if _sfx_player:
		_sfx_player.stop()
		_sfx_player.stream = null
	if _music_transition:
		_music_transition.kill()
	_music_transition = null
	_pending_music_name = ""
	_sfx_preload.clear()
	_current_music_name = ""


## Le moteur reprend son contexte Web Audio sur cette même interaction native.
func _input(event: InputEvent) -> void:
	if _web_audio_unlocked or not event.is_pressed():
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey:
		_web_audio_unlocked = true
		var pending := _pending_music_name
		_pending_music_name = ""
		if not pending.is_empty():
			play_music(pending, _pending_music_loop)


## Les ressources importées sont remappées dans le PCK : FileAccess ne suffit pas.
func resolve_music_path(track_name: String) -> String:
	var base_name := track_name.get_basename()
	# Préserver l'ordre de sélection historique MP3, OGG, WAV.
	for extension in ["mp3", "ogg", "wav"]:
		var path: String = MUSIC_DIR + base_name + "." + extension
		if ResourceLoader.exists(path):
			return path
	return ""


## Joue une musique de fond ; la dernière demande remplace un fondu en cours.
func play_music(track_name: String, loop: bool = true) -> void:
	if track_name.strip_edges().is_empty():
		return
	if not _web_audio_unlocked:
		_pending_music_name = track_name
		_pending_music_loop = loop
		return
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	if _current_music_name == track_name:
		return
	var path := resolve_music_path(track_name)
	var stream: AudioStream = load(path) as AudioStream if not path.is_empty() else null
	if stream == null:
		push_warning("AudioManager: musique introuvable '%s'" % track_name)
		stop_music(0.0)
		return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	if _music_transition:
		_music_transition.kill()
	_current_music_name = track_name
	_music_transition = create_tween()
	_music_transition.finished.connect(_on_music_transition_finished)
	if _music_player.playing:
		_music_transition.tween_property(_music_player, "volume_db", linear_to_db(0.001), 0.5)
	_music_transition.tween_callback(func():
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(0.001)
		_music_player.play()
	)
	_music_transition.tween_property(_music_player, "volume_db", linear_to_db(music_volume), 0.5)


## Arrête aussi une demande encore en attente du premier geste Web.
func stop_music(fade_duration: float = 1.0) -> void:
	_pending_music_name = ""
	_current_music_name = ""
	if _music_transition:
		_music_transition.kill()
	if not _music_player:
		return
	_music_transition = create_tween()
	_music_transition.finished.connect(_on_music_transition_finished)
	if _music_player.playing and fade_duration > 0.0:
		_music_transition.tween_property(_music_player, "volume_db", linear_to_db(0.001), fade_duration)
	_music_transition.tween_callback(func():
		_music_player.stop()
		_music_player.volume_db = linear_to_db(music_volume)
	)


func _on_music_transition_finished() -> void:
	# Libérer les callbacks de fondu qui retiennent la ressource audio précédente.
	_music_transition = null


## Joue un effet sonore ponctuel.
func play_sfx(sfx_name: String) -> void:
	# Accept names either without extension (preloaded) or full filename
	var key := sfx_name
	if key.ends_with('.ogg'):
		# strip extension for lookup
		key = key.get_basename()
	if key in _sfx_preload:
		_sfx_player.stream = _sfx_preload[key]
		_sfx_player.volume_db = linear_to_db(sfx_volume)
		_sfx_player.play()
		return
	# Fallback: try load by filename (with or without extension)
	var path := SFX_DIR + sfx_name
	if not ResourceLoader.exists(path):
		# try with .ogg appended
		path = SFX_DIR + sfx_name + '.ogg'
		if not ResourceLoader.exists(path):
			push_warning("AudioManager: SFX introuvable '%s'" % path)
			return
	_sfx_player.stream = load(path)
	_sfx_player.volume_db = linear_to_db(sfx_volume)
	_sfx_player.play()


## Retourne vrai si une musique est en cours de lecture.
func is_music_playing() -> bool:
	return _music_player.playing if _music_player else false


## Bascule la musique (stop si joue, play si arrêtée). Utilise `main_theme.ogg` par défaut.
func toggle_music(track_name: String = "main_theme.ogg") -> void:
	if is_music_playing() or not _pending_music_name.is_empty() or not _current_music_name.is_empty():
		stop_music()
		return
	play_music(track_name)
