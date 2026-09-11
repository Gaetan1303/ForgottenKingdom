## Conseil, occulte, caserne et établi : mêmes contrats que dans les souvenirs.
extends VBoxContainer
signal changed
const Campaign = preload("res://scripts/services/power_campaign_service.gd")
const Loops = preload("res://scripts/services/power_loop_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
var _content: VBoxContainer
var _route := "diplomacy"
var _pending := false
var _modal: EventResultView

func _ready() -> void:
	Campaign.ensure(ClanManager)
	add_theme_constant_override("separation", 10)
	_label(self, "LES GALERIES — CHOISIR VOTRE APPROCHE", 21)
	_label(self, "Des gardiens retiennent les outils de la Maison. Kael peut parlementer, préparer le passage ou vous accompagner. Sécurisez l’accès selon vos méthodes.", 16)
	var tabs := HFlowContainer.new()
	add_child(tabs)
	var destinations := {"combat": "Expédition", "espionage": "Conseil · Renseignements", "diplomacy": "Conseil · Diplomatie", "occult": "Occulte", "command": "Caserne", "craft": "Établi"}
	for route in destinations:
		var button := _button(tabs, str(destinations[route]), _select.bind(str(route)))
		button.name = "route_" + str(route)
		button.custom_minimum_size = Vector2(190, 46)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)
	_render()
	if not ClanManager.campaign.power_routes.get("pending_feedback", {}).is_empty():
		_show_pending.call_deferred()

func _select(route: String) -> void:
	_route = route
	_render()

func _render() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var state: Dictionary = ClanManager.campaign.power_routes
	if Objectives.completed(state):
		var objective: Dictionary = state.objectives[Objectives.GALLERIES]
		_label(_content, "Passage sécurisé · " + str(Loops.ROUTE_LABELS.get(objective.resolution_method, "Expédition antérieure")), 20)
		_label(_content, str(state.get("epilogue", "")), 16)
		_label(_content, "Les outils ouvrent la reconstruction de l’atelier. Votre méthode restera dans les archives de la Maison.", 16)
	_label(_content, str(Loops.ROUTE_LABELS[_route]), 20)
	_label(_content, "Une action occupe une décision de demi-journée. Le matin et le soir permettent d’agir ; le rapport de l’après-midi termine les affectations.", 14)
	var resources: Dictionary = ClanManager.get_ressources()
	var stats: Dictionary = ClanManager.stats.duplicate(true)
	stats.merge(ClanManager.get_fiche_complete().get("secondary_stats", {}), true)
	if _route in ["espionage", "diplomacy"]:
		_label(_content, "Réseau de la Maison · Renseignements : %d · Relation avec les gardiens : %d · Expositions : %d" % [int(resources.get("renseignements", 0)), int(state.warden_relation), int(state.exposure)], 16)
		var facts := {"forces": "Forces : rondes fragiles autour d’une seule porte", "passage": "Vulnérabilité : changement de garde au crépuscule", "secret": "Secret : réserve cachée du lieutenant", "desire": "Motivation : protéger les siens de la famine"}
		for key in facts: _label(_content, str(facts[key]) if key in state.knowledge else "??? — renseignement encore masqué", 15)
	if _route == "command":
		_label(_content, "Soldats disponibles : %d · Commandante : Kael\nFormation : %s · Moral : %d · Fatigue : %d\nLes soldats partagent la réserve militaire de la Maison. Votre personnage reste au poste de commandement." % [int(resources.get("soldats", 0)), "Boucliers à l’avant / soutien à l’arrière" if str(state.formation) == "guard" else "Assaut à l’avant / arrière vide" if str(state.formation) == "charge" else "À décider", int(state.morale), int(state.fatigue)], 16)
	if _route == "craft":
		_label(_content, "Établi portatif · %d automate(s)\nESP — Esprit : %d · TRA — Transfuge : %d · ESE — Essence : %d\nMatière : bois. Composant : fer. Catalyseur : pierre, mana ou Essence. Une Essence n’est jamais indispensable." % [state.artifacts.size(), int(stats.get("ESP", 0)), int(stats.get("TRA", 0)), int(stats.get("ESE", 0))], 16)
	if _route == "occult":
		_label(_content, "Mana : %d · Corruption : %d\nLe cercle réduit le prix du sceau. Le pacte prête sa puissance contre une trace durable. Le sceau peut provoquer une résonance supplémentaire." % [int(resources.get("mana", 0)), int(ClanManager.get_corruption_service().get_corruption_level("hero"))], 16)
	if _route == "combat":
		_label(_content, "Intervenez personnellement avec Kael sur la grille tactique. Les armes, les PV et le mana de l’expédition sont réels ; les blessures persistent au retour. Les outils restent dans les sacs jusqu’au refuge.", 16)
		_button(_content, "Préparer l’expédition avec Kael", _start_expedition)
		return
	var definitions := Loops.definitions()
	for action_id in definitions:
		var action: Dictionary = definitions[action_id]
		if str(action.route) != _route: continue
		if Objectives.completed(state) and action.has("method"): continue
		# Les nouvelles résolutions apparaissent lorsque leurs préparatifs existent.
		if action.has("method") and not Loops.preparation_reason(action, state).is_empty(): continue
		var description := "Coût : " + Loops.resources_text(Loops.cost_for(action, state, stats))
		if action.has("risk"):
			description += " · %s : %d%%" % ["risque d’exposition" if _route == "espionage" else "risque d’altération" if _route == "craft" else "risque de résonance", Loops.risk_for(action, state, stats)]
		if action.has("recipe"): description += " · échec : 5%%, composants perdus"
		if action.has("corruption"): description += " · corruption de base : +%d" % int(action.corruption)
		if str(action_id) == "infiltrate": description += " · gain : deux faits et jusqu’à 2 Renseignements ; exposition : relation −2"
		if str(action_id) == "observe": description += " · gain : deux faits et jusqu’à 2 Renseignements"
		if str(action_id) == "bind": description += " · cercle : −2 corruption ; secret : −1 ; résonance : +4"
		_label(_content, description, 14)
		var button := _button(_content, str(action.label), _execute.bind(str(action_id)))
		button.name = str(action_id)
		var reason := Campaign.reason(ClanManager, str(action_id))
		button.disabled = not reason.is_empty()
		if not reason.is_empty(): _label(_content, reason, 14)

func _execute(action_id: String) -> void:
	if _pending: return
	var result := Campaign.execute(ClanManager, action_id)
	if not result.accepted:
		_label(_content, result.message, 16)
		return
	_show_pending()

func _show_pending() -> void:
	if _pending: return
	_pending = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_modal = preload("res://scenes/ui/event_result_view.tscn").instantiate()
	layer.add_child(_modal)
	_modal.present(ClanManager.campaign.power_routes.pending_feedback)
	_modal.result_confirmed.connect(func():
		Campaign.acknowledge(ClanManager)
		_pending = false
		layer.queue_free()
		changed.emit()
	)

func _start_expedition() -> void:
	var error := DungeonGenerator.start_expedition(["pnj_kael"])
	if error.is_empty(): GameManager.open_dungeon()
	else: _label(_content, error, 16)

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
