extends SceneTree

var _failures: Array[String] = []
var _counts := {"images": 0, "audio": 0, "data": 0, "scenes": 0}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Ce script peut aussi être fourni depuis l'extérieur à --main-pack index.pck.
	_walk("res://assets")
	_walk("res://data")
	_walk("res://story")
	_walk("res://resources/chapters")
	_walk("res://scenes")
	var audio = root.get_node("AudioManager")
	for track in ["mainmenu.mp3", "main_theme.ogg", "Serment_des_Cendres.mp3", "renaissance-des-neuf-couronnes.mp3"]:
		if audio.resolve_music_path(track).is_empty():
			_failures.append("Musique non exportée : %s" % track)
	for bus in ["Master", "Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			_failures.append("Bus absent : %s" % bus)
	# Contrat de l'attente du premier geste, sans demander une sortie audio headless.
	audio._web_audio_unlocked = false
	audio.play_music("mainmenu.mp3")
	audio.play_music("main_theme.ogg")
	if audio._pending_music_name != "main_theme.ogg":
		_failures.append("La dernière musique doit être retenue avant interaction")
	var gesture := InputEventMouseButton.new()
	gesture.button_index = MOUSE_BUTTON_LEFT
	gesture.pressed = true
	audio._input(gesture)
	if not audio._web_audio_unlocked or not audio._pending_music_name.is_empty():
		_failures.append("L'interaction doit débloquer l'audio")
	audio._web_audio_unlocked = false
	audio.play_music("mainmenu.mp3")
	audio.stop_music(0.0)
	if not audio._pending_music_name.is_empty():
		_failures.append("Stop doit annuler une musique en attente")
	if _counts.images < 70 or _counts.audio < 40 or _counts.data < 35 or _counts.scenes < 27:
		_failures.append("Contenu embarqué incomplet : %s" % _counts)
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("EXPORT_RESOURCES_OK ", _counts)
	quit(0 if _failures.is_empty() else 1)


func _walk(directory: String) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		_failures.append("Dossier embarqué absent : %s" % directory)
		return
	for child in dir.get_directories():
		_walk(directory.path_join(child))
	var seen: Dictionary = {}
	for file in dir.get_files():
		# Le PCK conserve les remappages, pas nécessairement les fichiers sources.
		var name: String = file.trim_suffix(".remap").trim_suffix(".import")
		if seen.has(name):
			continue
		seen[name] = true
		var path := directory.path_join(name)
		var extension := name.get_extension().to_lower()
		if extension in ["png", "webp", "jpg", "jpeg", "svg", "mp3", "ogg", "wav", "tscn"]:
			var resource := ResourceLoader.load(path)
			if resource == null:
				_failures.append("Ressource non chargeable : %s" % path)
			elif resource is AudioStream:
				_counts.audio += 1
			elif resource is Texture2D:
				_counts.images += 1
			elif resource is PackedScene:
				_counts.scenes += 1
		elif extension in ["json", "yaml", "csv"]:
			var source := FileAccess.open(path, FileAccess.READ)
			if source == null or source.get_length() == 0:
				_failures.append("Donnée brute absente : %s" % path)
			elif extension == "json" and JSON.parse_string(source.get_as_text()) == null:
				_failures.append("JSON invalide : %s" % path)
			else:
				_counts.data += 1
