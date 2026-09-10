extends "res://scripts/state_machine/state.gd"
class_name MatinState

func _init() -> void:
    name = "matin"

func enter(data: Dictionary = {}) -> void:
    if machine and machine.debug:
        print("Entering MatinState")
    # Morning phase: planning
    if data.has("clan_manager"):
        var cm = data["clan_manager"]
        cm.on_matin()
