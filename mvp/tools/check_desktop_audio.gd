## Sonde desktop à lancer avec --script res://tools/check_desktop_audio.gd.
## --audio-driver Dummy vérifie le mixage sans sortie vers les haut-parleurs.
extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Cette sonde demande un pilote d'affichage desktop.")
		quit(1)
		return
	var audio = root.get_node("AudioManager")
	var results: Array = []
	for track in ["mainmenu.mp3", "main_theme.ogg", "Serment_des_Cendres.mp3"]:
		audio.play_music(track)
		await create_timer(1.6).timeout
		var position: float = audio._music_player.get_playback_position()
		var peak := AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Music"), 0)
		results.append({"track": track, "playing": audio.is_music_playing(), "position": position, "peak_db": peak})
		if not audio.is_music_playing() or position <= 0.0 or peak <= -100.0:
			push_error("Musique non mixée : " + track)
			quit(1)
			return
	var capture := AudioEffectCapture.new()
	var sfx_bus := AudioServer.get_bus_index("SFX")
	AudioServer.add_bus_effect(sfx_bus, capture)
	var failures: Array[String] = []
	for effect in ["click", "whoosh", "swing"]:
		capture.clear_buffer()
		audio.play_sfx(effect)
		await create_timer(0.3).timeout
		var peak := 0.0
		for frame in capture.get_buffer(capture.get_frames_available()):
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		results.append({"effect": effect, "peak": peak})
		if peak <= 0.0:
			failures.append("Effet non mixé : " + effect)
	# Laisser le thread audio libérer ses playbacks avant de quitter la sonde.
	audio.stop_music(0.0)
	audio._sfx_player.stop()
	audio._sfx_player.stream = null
	AudioServer.remove_bus_effect(sfx_bus, 0)
	capture = null
	await create_timer(0.3).timeout
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("DESKTOP_AUDIO_OK ", JSON.stringify(results))
	quit(0 if failures.is_empty() else 1)
