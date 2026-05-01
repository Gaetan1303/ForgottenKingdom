## autoload/audio_manager.gd
## Singleton audio — gère la musique de fond et les effets sonores.
extends Node

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR   := "res://assets/audio/sfx/"

# Volumes (0.0 – 1.0)
var music_volume: float = 0.8:
	set(v):
		music_volume = clamp(v, 0.0, 1.0)
		_music_player.volume_db = linear_to_db(music_volume)

var sfx_volume: float = 1.0:
	set(v):
		sfx_volume = clamp(v, 0.0, 1.0)

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music_name: String = ""
var _sfx_preload: Dictionary = {}


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
	_sfx_preload.clear()
	_current_music_name = ""


## Joue une musique de fond (fondu si une autre est en cours).
func play_music(track_name: String, loop: bool = true) -> void:
	# In headless runs (CI/tests), avoid loading audio resources which may not have loaders.
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return

	if _current_music_name == track_name:
		return  # Déjà en lecture

	var base_name := track_name.get_basename()
	var stream: AudioStream = null
	var path: String = ""
	# Try common extensions: mp3, ogg, wav
	var mp3_path := MUSIC_DIR + base_name + '.mp3'
	if FileAccess.file_exists(mp3_path):
		stream = load(mp3_path)
		path = mp3_path
	else:
		var ogg_path := MUSIC_DIR + base_name + '.ogg'
		if FileAccess.file_exists(ogg_path):
			stream = load(ogg_path)
			path = ogg_path
		else:
			var wav_path := MUSIC_DIR + base_name + '.wav'
			if FileAccess.file_exists(wav_path):
				stream = load(wav_path)
				path = wav_path
	if stream == null:
		# Try WAV fallback if OGG loader is not available in this runtime
		var base := path.get_basename()
		var wav_fallback := base + '.wav'
		if FileAccess.file_exists(wav_fallback):
			stream = load(wav_fallback)
			path = wav_fallback
		else:
			push_warning("AudioManager: fichier introuvable '%s'" % path)
			_music_player.stop()
			_current_music_name = ""
			return
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop

	await _fade_out_music(0.5)
	_music_player.stream = stream
	_music_player.play()
	_current_music_name = track_name
	await _fade_in_music(0.5)


## Arrête la musique avec un fondu.
func stop_music(fade_duration: float = 1.0) -> void:
	await _fade_out_music(fade_duration)
	_music_player.stop()
	_current_music_name = ""
	_music_player.volume_db = linear_to_db(music_volume)


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


# --- Fonctions internes ---

func _fade_out_music(duration: float) -> void:
	if not _music_player.playing:
		return
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db",
		linear_to_db(0.001), duration)
	await tween.finished


func _fade_in_music(duration: float) -> void:
	_music_player.volume_db = linear_to_db(0.001)
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db",
		linear_to_db(music_volume), duration)
	await tween.finished


## Retourne vrai si une musique est en cours de lecture.
func is_music_playing() -> bool:
	return _music_player.playing if _music_player else false


## Bascule la musique (stop si joue, play si arrêtée). Utilise `main_theme.ogg` par défaut.
func toggle_music(track_name: String = "main_theme.ogg") -> void:
	if is_music_playing():
		stop_music()
		return
	play_music(track_name)
