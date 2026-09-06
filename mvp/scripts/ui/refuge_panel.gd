## Vue du refuge dans le hub canonique : aucune règle de coût ou de résolution ici.
extends VBoxContainer

signal changed
const Refuge = preload("res://scripts/services/refuge_service.gd")
const Tutorial = preload("res://scripts/autoload/tutorial_director.gd")
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
var _worker: OptionButton
var _team: Array = []
var _status: Label

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_label(self, "LA BRÈCHE-SÈCHE", 26)
	_label(self, "Refuge · %s · Jour %d" % [ClanManager.nom_clan, ClanManager.tour_actuel], 16)
	var state: Dictionary = ClanManager.campaign
	if state.is_empty():
		_label(self, "Votre campagne continue. Les Maisons, l’intendance et les expéditions restent accessibles.")
		return
	var objective := Tutorial.current(state)
	var priority := _card("À décider")
	_label(priority, str(objective.objective), 20)
	if int(state.get("help_mode", 0)) == 0:
		_label(priority, str(objective.hint))
	_status = _label(priority, str(state.get("last_feedback", "")))
	_status.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	if not Refuge.has(ClanManager, "govern"):
		_label(priority, "12 rations au départ, un grenier ouvert au vent et une palissade fendue. Une réparation occupe la décision de la demi-journée ; les galeries attendent en contrebas.")
		_button(priority, "Donner la priorité aux galeries", func(): _result(Refuge.prioritize_galleries(ClanManager)))
	if Refuge.has(ClanManager, "govern") and not Refuge.has(ClanManager, "social"):
		_label(priority, "Vaelen a surpris un survivant près des réserves. Il voulait nourrir une personne malade. Kael attend votre décision.")
		_button(priority, "Partager deux rations · −2 nourriture, +2 affinité d’intendance", func(): _result(Refuge.social_choice(ClanManager, true)))
		_button(priority, "Faire garder les réserves · −1 affinité d’intendance", func(): _result(Refuge.social_choice(ClanManager, false)))
	var shortcuts := HFlowContainer.new()
	add_child(shortcuts)
	for target in ["Les personnes qui vous restent", "Reconstruire", "Préparer une sortie", "Archives du refuge"]:
		var shortcut := _button(shortcuts, target, func():
			var scroll := get_parent().get_parent() as ScrollContainer
			if scroll != null:
				for child in get_children():
					if child.get_meta("section_title", "") == target:
						scroll.scroll_vertical = int(child.position.y + position.y)
		)
		shortcut.custom_minimum_size.x = 190
	_build_roster()
	_build_buildings()
	_build_expedition()
	if Refuge.has(ClanManager, "rebuild") and not Refuge.has(ClanManager, "soul"):
		var relic := _card("Le métal se souvient")
		_label(relic, "Sylas pose la relique sur l’établi. La Cicatrice de Sang répond. Kael : « Nous avons survécu sans elle jusqu’ici. Prenez le temps de choisir. »")
		for key in StatDefs.SECONDARY_STAT_KEYS:
			var stats: Dictionary = ClanManager.get_fiche_complete().get("secondary_stats", {})
			var stat_button := _button(relic, "%s — %s : %d" % [key, StatDefs.SECONDARY_STAT_LABELS[key], int(stats.get(key, 0))], func(): pass)
			stat_button.tooltip_text = StatDefs.description(key) + "\nCette première résonance a un coût fixe et ne demande pas de jet."
			stat_button.focus_entered.connect(func(): _status.text = stat_button.tooltip_text)
		_button(relic, "Laisser résonner · −1 essence, −5 âme, +10 mana", func(): _result(Refuge.study_relic(ClanManager, true)))
		_button(relic, "Sceller pour étudier · +2 renseignements", func(): _result(Refuge.study_relic(ClanManager, false)))
	var archives := _card("Archives du refuge")
	var help_row := HBoxContainer.new()
	archives.add_child(help_row)
	_label(help_row, "Aide contextuelle")
	var help := OptionButton.new()
	for text in ["Complète", "Réduite", "Désactivée"]:
		help.add_item(text)
	help.select(clampi(int(state.get("help_mode", 0)), 0, 2))
	help.item_selected.connect(func(index: int):
		ClanManager.campaign["help_mode"] = index
		ClanManager.sauvegarder()
		changed.emit()
	)
	help_row.add_child(help)
	var content := VBoxContainer.new()
	content.visible = false
	var toggle := _button(archives, "Consulter le journal et les aides connues", func(): content.visible = not content.visible)
	toggle.toggle_mode = true
	archives.add_child(content)
	for entry in state.get("journal", []):
		_label(content, str(entry.title), 18)
		_label(content, str(entry.text))
	for step in Tutorial.STEPS:
		if Refuge.has(ClanManager, str(step.id)) or str(objective.id) == str(step.id):
			_label(content, str(step.objective), 18)
			_label(content, str(step.hint))
	if Refuge.has(ClanManager, "combat"):
		_label(content, "Combat : initiative = espionnage. Déplacement : 3 cases libres. Attaque : portée 1, force ÷ 3 + 2 dégâts. Trait d’Éther : portée 3, magie ÷ 2 + 3 dégâts, 3 mana. Une attaque et un déplacement par tour. Une unité à 0 PV ne joue plus. Les blessures persistent au retour jusqu’aux soins ou à l’aube.")

func _build_roster() -> void:
	var box := _card("Les personnes qui vous restent")
	_label(box, "Choisissez un responsable pour les réparations. Les compagnons affectés ne peuvent pas partir en même temps.")
	_worker = OptionButton.new()
	box.add_child(_worker)
	var roster: Array = ClanManager.get_pnj_gestion_state().get("roster", [])
	var available_index := -1
	for person in roster:
		var index := _worker.item_count
		_worker.add_item(str(person.nom))
		_worker.set_item_metadata(index, str(person.id))
		var available := str(person.get("etat", "")) == "disponible"
		_worker.set_item_disabled(index, not available)
		if available and available_index < 0: available_index = index
		var states := {"disponible": "Disponible", "assigne": "Affectation en cours", "en_expedition": "En expédition", "blesse": "Blessure — soins ou repos nécessaires"}
		var info := "%s · %s\nForce %d · Magie %d · Espionnage %d · Artisanat %d · Diplomatie %d · Commandement %d" % [person.nom, states.get(str(person.get("etat", "")), "Indisponible"), int(person.stats.force), int(person.stats.magie), int(person.stats.espionnage), int(person.stats.artisanat), int(person.stats.diplomatie), int(person.stats.commandement)]
		var person_label := _label(box, info)
		var details: PackedStringArray = []
		for key in StatDefs.STAT_KEYS:
			details.append(StatDefs.description(str(key)) + "\nBase : %d · Bonus actif : 0 · Malus actif : 0 · Total : %d" % [int(person.stats.get(key, 8)), int(person.stats.get(key, 8))])
		person_label.tooltip_text = "\n\n".join(details)
		person_label.mouse_filter = Control.MOUSE_FILTER_STOP
		preload("res://scripts/ui/components/keyboard_tooltip.gd").bind(person_label)
		if str(person.get("etat", "")) == "blesse":
			_button(box, "Soigner %s · 2 nourriture, 2 mana" % person.nom, func(): _result(Refuge.recover(ClanManager, str(person.id))))
	if available_index >= 0: _worker.select(available_index)
	else: _worker.disabled = true
	var detail := _label(box, "")
	_worker.item_selected.connect(func(_index: int): _worker_details(detail))
	_worker_details(detail)

func _worker_details(detail: Label) -> void:
	var person := Refuge.find_person(ClanManager, _worker_id())
	if person.is_empty():
		detail.text = "Personne de disponible. Terminez la journée pour résoudre les affectations."
		return
	var bonus := PnjDailyPlannerService.new().compute_support_bonus(person, "fortifier")
	detail.text = "%s : soutien +%d à Fortifier. Calcul : moyenne artisanat/commandement ÷ 3, arrondie, + niveau ÷ 2, + rôle éventuel ; total borné entre 1 et 6. La réparation réussit avec les matériaux requis ; le soutien rejoint le rapport de journée." % [person.nom, bonus]

func _worker_id() -> String:
	if _worker == null or _worker.disabled or _worker.selected < 0:
		return ""
	return str(_worker.get_item_metadata(_worker.selected))

func _build_buildings() -> void:
	var box := _card("Reconstruire")
	_label(box, "Récupération quotidienne du refuge : " + Refuge.resources_text(ClanManager.ressources_par_tour) + ". Les infrastructures ajoutent leur production à chaque aube.")
	for id in Refuge.BUILDINGS:
		var definition: Dictionary = Refuge.BUILDINGS[id]
		var repaired := bool(ClanManager.campaign.get("buildings", {}).get(id, false))
		_label(box, ("◆ " if repaired else "◇ ") + str(definition.name) + (" — En service" if repaired else " — En ruine"), 18)
		_label(box, str(definition.benefit))
		if repaired: continue
		var reason := Refuge.building_reason(ClanManager, id)
		_label(box, "Coût : %s · Temps : une décision de demi-journée.%s" % [Refuge.resources_text(definition.cost), "\n" + reason if not reason.is_empty() else ""])
		var repair := _button(box, "Restaurer " + str(definition.name), func(): _result(Refuge.repair(ClanManager, id, _worker_id())))
		repair.disabled = not reason.is_empty() or _worker_id().is_empty()
	_label(box, "Traces de reconstruction : %d. La fumée de vos foyers se voit depuis la route." % int(ClanManager.campaign.get("visibility", 0)))

func _build_expedition() -> void:
	var box := _card("Préparer une sortie")
	if not DungeonGenerator.current_run.is_empty() and not bool(DungeonGenerator.current_run.get("returned", false)):
		_button(box, "Reprendre la sortie en cours", func(): GameManager.open_dungeon())
		return
	_label(box, "Les galeries sous le refuge" if not Refuge.has(ClanManager, "salvage") else "Les profondeurs — dix étages ; retour possible après chaque salle", 18)
	_label(box, "L’héritier accompagne un ou deux compagnons. Le mana est partagé avec le domaine ; les matériaux sont déposés au retour. Vous pouvez vous retirer à tout moment.")
	for person in ClanManager.get_pnj_gestion_state().get("roster", []):
		var check := CheckButton.new()
		check.text = "%s · Force %d / Magie %d / Initiative %d" % [person.nom, int(person.stats.force), int(person.stats.magie), int(person.stats.espionnage)]
		check.disabled = str(person.get("etat", "")) != "disponible"
		check.toggled.connect(func(pressed: bool):
			if pressed: _team.append(str(person.id))
			else: _team.erase(str(person.id))
		)
		box.add_child(check)
	_button(box, "Descendre avec l’équipe", func():
		var error := DungeonGenerator.start_expedition(_team)
		if error.is_empty(): GameManager.open_dungeon()
		else: _status.text = error
	)

func _result(message: String) -> void:
	_status.text = message
	ClanManager.campaign["last_feedback"] = message
	changed.emit()

func _card(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_meta("section_title", title)
	panel.add_theme_stylebox_override("panel", FallenUI.card_style(false))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_label(box, title, 20)
	return box

func _label(parent: Node, text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 40
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
