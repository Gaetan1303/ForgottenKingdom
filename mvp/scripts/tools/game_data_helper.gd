@tool
extends EditorScript

# Petit helper EditorScript pour recharger GameDataLoader depuis l'éditeur
# Exécuter via: Script -> Run -> (sélectionner ce script)
# Note: l'EditorScript s'exécute dans l'éditeur; les singletons autoload actifs
# dans une scène en cours d'exécution ne sont pas accessibles ici. Ce script
# instancie le script `game_data_loader.gd` et appelle `reload()` dessus.

func _run() -> void:
    var script_path: String = "res://scripts/autoload/game_data_loader.gd"
    var s := load(script_path)
    if not s:
        printerr("GameDataHelper: impossible de charger %s" % script_path)
        return
    var inst: Object = s.new()
    if inst == null:
        printerr("GameDataHelper: impossible d'instancier GameDataLoader")
        return
    if inst.has_method("reload"):
        inst.reload()
        print("GameDataHelper: GameDataLoader rechargée (instance temporaire).")
    else:
        printerr("GameDataHelper: l'instance ne possède pas la méthode reload().")
