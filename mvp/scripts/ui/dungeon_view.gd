extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const FKHelpers = preload("res://scripts/utils/fk_helpers.gd")

@onready var lbl_floor_room: Label = $VBox/FloorRoom
@onready var lbl_type: Label = $VBox/TypeRoom
@onready var lbl_enemies: RichTextLabel = $VBox/Enemies
@onready var lbl_result: Label = $VBox/Result
@onready var btn_resolve: Button = $VBox/Buttons/BtnResolve
@onready var btn_next: Button = $VBox/Buttons/BtnNext
@onready var btn_exit: Button = $VBox/Buttons/BtnExit


func _ready() -> void:
	FallenUI.apply(self, "dungeon")
	btn_resolve.pressed.connect(_on_resolve)
	btn_next.pressed.connect(_on_next)
	btn_exit.pressed.connect(_on_exit)
	if DungeonGenerator.current_run.is_empty():
		DungeonGenerator.generate_run()
	_refresh_room()


func _refresh_room() -> void:
	var room := DungeonGenerator.get_current_room()
	if room.is_empty():
		lbl_floor_room.text = "Donjon terminé"
		lbl_type.text = ""
		lbl_enemies.text = ""
		btn_resolve.disabled = true
		btn_next.disabled = true
		lbl_result.text = "Vous avez traversé les 10 étages du donjon."
		return

	var run := DungeonGenerator.current_run
	var f := int(run.get("current_floor", 0)) + 1
	var r := int(run.get("current_room", 0)) + 1
	lbl_floor_room.text = "Étage %d — Salle %d" % [f, r]
	lbl_type.text = "Type : %s" % str(room.get("type", "combat"))

	var enemies: Array = room.get("enemies", [])
	if enemies.is_empty():
		lbl_enemies.text = "[i]Aucun ennemi[/i]"
	else:
		lbl_enemies.text = "[b]Ennemis :[/b] " + FKHelpers.join_array(enemies, ", ")

	btn_resolve.disabled = bool(room.get("cleared", false))
	btn_next.disabled = not bool(room.get("cleared", false))
	lbl_result.text = ""


func _on_resolve() -> void:
	var room := DungeonGenerator.get_current_room()
	if room.is_empty():
		return

	var room_type := str(room.get("type", "combat"))
	var power := _estimate_power(room)
	var score := ClanManager.get_stat("force", 5) + ClanManager.get_stat("magie", 5) + randi_range(1, 20)
	var diff := score - power

	if room_type == "treasure":
		ClanManager.gagner({"or": 45, "essence": 2})
		lbl_result.text = "Trésor récupéré : +45 or, +2 essence."
	elif room_type == "rest":
		ClanManager.gagner({"mana": 20, "soldats": 3})
		lbl_result.text = "Repos réussi : +20 mana, +3 soldats."
	elif diff >= 0:
		ClanManager.gagner({"or": 20, "renseignements": 2})
		lbl_result.text = "Victoire dans la salle (%d vs %d)." % [score, power]
	else:
		ClanManager.payer({"soldats": 6, "mana": 8})
		lbl_result.text = "Combat difficile (%d contre %d). Pertes : -6 soldats, -8 mana." % [score, power]

	DungeonGenerator.clear_current_room()
	btn_resolve.disabled = true
	btn_next.disabled = false


func _estimate_power(room: Dictionary) -> int:
	var base := 8
	var room_type := str(room.get("type", "combat"))
	match room_type:
		"combat": base = 10
		"elite": base = 14
		"trap": base = 11
		"boss": base = 22
		"treasure", "rest": base = 2
	var floor_idx := int(DungeonGenerator.current_run.get("current_floor", 0))
	return base + floor_idx * 2


func _on_next() -> void:
	var moved := DungeonGenerator.advance_room()
	if not moved and bool(DungeonGenerator.current_run.get("completed", false)):
		_refresh_room()
		return
	_refresh_room()


func _on_exit() -> void:
	GameManager.go_to("clan_hub")
