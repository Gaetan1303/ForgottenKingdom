extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_autoloads()
	_test_game_data_loader_contracts()
	_finish()

func _test_autoloads() -> void:
	for autoload_name in ["GameManager", "SaveSystem", "ChapterLoader", "ClanManager", "GameDataLoader"]:
		var node: Node = root.get_node_or_null(autoload_name)
		if node == null:
			_failures.append("Autoload absent ou non compilé: %s" % autoload_name)

func _test_game_data_loader_contracts() -> void:
	var loader: Node = root.get_node_or_null("GameDataLoader")
	if loader == null:
		return
	var traits_cfg: Dictionary = loader.call("get_character_traits") as Dictionary
	var classes: Dictionary = loader.call("get_classes") as Dictionary
	var feats: Dictionary = loader.call("get_feats") as Dictionary
	var abilities: Dictionary = loader.call("get_abilities") as Dictionary
	if traits_cfg.is_empty():
		_failures.append("Character traits non chargés")
	if classes.size() != 14:
		_failures.append("14 classes attendues, trouvé: %d" % classes.size())
	if not feats.has("robustesse") or feats.has("dons"):
		_failures.append("get_feats doit exposer directement les dons par ID")
	if abilities.is_empty():
		_failures.append("Capacités non chargées")

func _finish() -> void:
	if _failures.is_empty():
		print("VEYR_BOOT_CONTRACTS_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	push_error("VEYR_BOOT_CONTRACTS_FAIL: %d erreur(s)" % _failures.size())
	quit(1)
