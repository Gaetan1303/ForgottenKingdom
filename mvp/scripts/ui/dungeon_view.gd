extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
const Combat = preload("res://scripts/services/tactical_combat_service.gd")
const Tutorial = preload("res://scripts/autoload/tutorial_director.gd")

@onready var lbl_floor_room: Label = $VBox/FloorRoom
@onready var lbl_type: Label = $VBox/TypeRoom
@onready var lbl_enemies: RichTextLabel = $VBox/Enemies
@onready var lbl_result: Label = $VBox/Result
@onready var btn_resolve: Button = $VBox/Buttons/BtnResolve
@onready var btn_next: Button = $VBox/Buttons/BtnNext
@onready var btn_exit: Button = $VBox/Buttons/BtnExit
var _grid: GridContainer
var _commands: HBoxContainer
var _hint: Label
var _mode := "move"

func _ready() -> void:
	FallenUI.apply(self, "dungeon")
	btn_resolve.pressed.connect(_on_resolve)
	btn_next.pressed.connect(_on_next)
	btn_exit.pressed.connect(_on_exit)
	# Compatibilité des anciennes campagnes : leur donjon reste résolu par le parcours historique.
	if ClanManager.campaign.is_empty():
		if DungeonGenerator.current_run.is_empty(): DungeonGenerator.generate_run()
	else:
		if DungeonGenerator.current_run.is_empty() or bool(DungeonGenerator.current_run.get("returned", false)):
			GameManager.go_to.call_deferred("clan_hub")
			return
		_build_tactical_ui()
	_refresh_room()

func _build_tactical_ui() -> void:
	$VBox/Title.text = "SOUS LA BRÈCHE-SÈCHE"
	lbl_enemies.size_flags_vertical = Control.SIZE_FILL
	lbl_enemies.fit_content = false
	lbl_enemies.custom_minimum_size.y = 66
	_grid = GridContainer.new()
	_grid.columns = Combat.WIDTH
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$VBox.add_child(_grid)
	$VBox.move_child(_grid, lbl_enemies.get_index() + 1)
	for y in range(Combat.HEIGHT):
		for x in range(Combat.WIDTH):
			var cell := Button.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.custom_minimum_size = Vector2(80, 52)
			cell.add_theme_font_size_override("font_size", 14)
			cell.pressed.connect(_on_cell.bind(x, y))
			_grid.add_child(cell)
			preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(cell)
	_commands = HBoxContainer.new()
	$VBox.add_child(_commands)
	$VBox.move_child(_commands, lbl_result.get_index())
	for definition in [["move", "Déplacement · 3 cases"], ["attack", "Attaque · portée 1"], ["ability", "Trait d’Éther · portée 3 · 3 mana"], ["end", "Fin du tour"]]:
		var button := Button.new()
		button.text = definition[1]
		button.pressed.connect(_select_command.bind(str(definition[0])))
		_commands.add_child(button)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$VBox.add_child(_hint)
	$VBox.move_child(_hint, _commands.get_index())
	btn_exit.text = "Revenir au refuge avec les sacs"
	btn_exit.tooltip_text = "Quitter termine cette sortie. Les objets récupérés sont déposés et les blessures conservées."

func _refresh_room() -> void:
	var room := DungeonGenerator.get_current_room()
	var run: Dictionary = DungeonGenerator.current_run
	if room.is_empty():
		lbl_floor_room.text = "Repli de l’équipe" if bool(run.get("defeat", false)) else "La voie est dégagée"
		lbl_type.text = "Rentrez déposer les ressources et prendre soin de vos compagnons."
		btn_resolve.disabled = true
		btn_next.disabled = true
		if _grid != null: _grid.visible = false
		if _commands != null: _commands.visible = false
		return
	lbl_floor_room.text = "Étage %d — Salle %d" % [int(run.get("current_floor", 0)) + 1, int(run.get("current_room", 0)) + 1]
	var names := {"combat": "Affrontement", "elite": "Garde d’élite", "trap": "Embuscade", "boss": "Gardien", "treasure": "Cache oubliée", "rest": "Halte"}
	lbl_type.text = str(names.get(str(room.get("type", "combat")), "Galerie"))
	btn_resolve.disabled = bool(room.get("cleared", false))
	btn_next.disabled = not bool(room.get("cleared", false))
	if _grid == null:
		lbl_enemies.text = ", ".join(PackedStringArray(room.get("enemies", [])))
		return
	var battle: Dictionary = room.get("battle", {})
	if not bool(room.get("cleared", false)):
		battle = DungeonGenerator.ensure_battle()
	_grid.visible = not battle.is_empty()
	_commands.visible = not battle.is_empty() and str(battle.get("outcome", "")).is_empty()
	btn_resolve.visible = battle.is_empty()
	btn_resolve.text = "Examiner et fouiller"
	if battle.is_empty():
		lbl_enemies.text = "Les outils abandonnés pourraient encore servir à l’atelier." if str(room.get("type", "")) == "treasure" else "Des empreintes traversent la poussière. Observez avant d’avancer."
		_hint.text = ""
		return
	var actor := Combat.active(battle)
	var order: PackedStringArray = []
	for unit in battle.units:
		if int(unit.hp) > 0: order.append("%s (%d)" % [unit.name, int(unit.initiative)])
	lbl_enemies.text = "Ordre d’initiative : " + " → ".join(order) + "\nMana du domaine : %d" % ClanManager.get_ressource("mana")
	if not actor.is_empty():
		lbl_type.text = "Tour %d · %s · %s · %s" % [int(battle.round), actor.name, "déplacement utilisé" if bool(battle.moved) else "déplacement disponible", "attaque utilisée" if bool(battle.acted) else "attaque disponible"]
	for y in range(Combat.HEIGHT):
		for x in range(Combat.WIDTH):
			var cell := _grid.get_child(y * Combat.WIDTH + x) as Button
			var unit := Combat.unit_at(battle, x, y)
			cell.text = "%d,%d" % [x + 1, y + 1]
			cell.tooltip_text = "Case libre"
			cell.modulate = Color.WHITE
			if not unit.is_empty():
				cell.text = ("▶ " if not actor.is_empty() and str(actor.id) == str(unit.id) else "") + str(unit.name) + "\n%d/%d PV" % [int(unit.hp), int(unit.max_hp)]
				cell.tooltip_text = "%s · %s · Force %d · Magie %d · Initiative %d" % [unit.name, "Allié" if str(unit.team) == "ally" else "Adversaire", int(unit.force), int(unit.magie), int(unit.initiative)]
				cell.tooltip_text += "\nAttaque : force ÷ 3 + 2 ; Trait d’Éther : magie ÷ 2 + 3. Malus actif : 0." if str(unit.team) == "ally" else "\nAttaque : force ÷ 3 + 1. Malus actif : 0."
				cell.modulate = Color(0.75, 0.9, 1) if str(unit.team) == "ally" else Color(1, 0.8, 0.75)
			elif not actor.is_empty() and _mode == "move" and not bool(battle.moved) and Combat.can_move(battle, x, y):
				cell.text = "· Accessible ·"
			cell.disabled = actor.is_empty()
	var lines: Array = battle.get("log", [])
	lbl_result.text = "\n".join(PackedStringArray(lines.slice(maxi(0, lines.size() - 3))))
	if str(battle.get("outcome", "")) == "victory":
		lbl_type.text = "Victoire — les sacs attendent le retour au domaine."
	var hint := Tutorial.hint(ClanManager.campaign, "combat_start", "Kael : « Les plus vifs ouvrent la marche. Déplacez-vous, puis choisissez votre cible. Vous pouvez garder votre position et terminer le tour. »")
	if not hint.is_empty(): _hint.text = hint
	ClanManager.sauvegarder()

func _select_command(kind: String) -> void:
	if kind == "end":
		DungeonGenerator.combat_command("end")
	else:
		_mode = kind
		var text := "Choisissez une case libre accessible." if kind == "move" else "Choisissez un adversaire adjacent." if kind == "attack" else "Choisissez un adversaire à trois cases au maximum. Coût : 3 mana."
		_hint.text = text
	_refresh_room()

func _on_cell(x: int, y: int) -> void:
	var result: Dictionary = DungeonGenerator.combat_command(_mode, x, y)
	_refresh_room()
	if bool(result.get("ok", false)):
		var tips := {"attack": "Une attaque utilise l’action du personnage. Le journal détaille ses dégâts ; terminez le tour pour laisser agir le suivant.", "ability": "Le Trait d’Éther puise 3 mana dans les réserves du domaine. Ce qui est dépensé ici manquera au retour."}
		if tips.has(_mode):
			var text := Tutorial.hint(ClanManager.campaign, "first_" + _mode, str(tips[_mode]))
			if not text.is_empty(): _hint.text = text
			ClanManager.sauvegarder()
	else:
		lbl_result.text = str(result.get("message", "Action impossible."))

func _on_resolve() -> void:
	if _grid != null:
		var message := DungeonGenerator.resolve_quiet_room()
		_refresh_room()
		lbl_result.text = message
		return
	_resolve_legacy_room()

func _resolve_legacy_room() -> void:
	var room := DungeonGenerator.get_current_room()
	if room.is_empty() or bool(room.get("cleared", false)): return
	var room_type := str(room.get("type", "combat"))
	var power := _estimate_power(room)
	var score := ClanManager.get_stat("force", 5) + ClanManager.get_stat("magie", 5) + randi_range(1, 20)
	if room_type == "treasure":
		ClanManager.gagner({"or": 45, "essence": 2})
		lbl_result.text = "Trésor : +45 or, +2 essence."
	elif room_type == "rest":
		ClanManager.gagner({"mana": 20, "soldats": 3})
		lbl_result.text = "Repos : +20 mana, +3 soldats."
	elif score >= power:
		ClanManager.gagner({"or": 20, "renseignements": 2})
		lbl_result.text = "Victoire (%d contre %d)." % [score, power]
	else:
		ClanManager.payer({"soldats": 6, "mana": 8})
		lbl_result.text = "Combat difficile (%d contre %d). Pertes : 6 soldats, 8 mana." % [score, power]
	DungeonGenerator.clear_current_room()
	ClanManager.sauvegarder()
	btn_resolve.disabled = true
	btn_next.disabled = false

func _estimate_power(room: Dictionary) -> int:
	var bases := {"combat": 10, "elite": 14, "trap": 11, "boss": 22, "treasure": 2, "rest": 2}
	return int(bases.get(str(room.get("type", "combat")), 8)) + int(DungeonGenerator.current_run.get("current_floor", 0)) * 2

func _on_next() -> void:
	DungeonGenerator.advance_room()
	ClanManager.sauvegarder()
	lbl_result.text = ""
	if _hint != null: _hint.text = ""
	_refresh_room()

func _on_exit() -> void:
	if _grid != null: DungeonGenerator.return_to_refuge()
	GameManager.go_to("clan_hub")
