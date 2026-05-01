extends State
class_name ApresMidiState

func _init() -> void:
    name = "apres_midi"

func enter(data: Dictionary = {}) -> void:
    if machine and machine.debug:
        print("Entering ApresMidiState")
    # Resolve actions
    if data.has("clan_manager"):
        var cm = data["clan_manager"]
        cm.on_apres_midi()
