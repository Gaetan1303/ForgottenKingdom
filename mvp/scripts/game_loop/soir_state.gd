extends "res://scripts/state_machine/state.gd"
class_name SoirState

func _init() -> void:
    name = "soir"

func enter(data: Dictionary = {}) -> void:
    if machine and machine.debug:
        print("Entering SoirState")
    # Evening: cleanup / consequences
    if data.has("clan_manager"):
        var cm = data["clan_manager"]
        cm.on_soir()
