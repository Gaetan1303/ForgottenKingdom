## Une vue pour toutes les leçons ; les règles restent dans les services partagés.
extends Control
const Memories = preload("res://scripts/services/memory_tutorial_service.gd")
const Loops = preload("res://scripts/services/power_loop_service.gd")
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")
const Visuals = preload("res://scripts/ui/visual_asset_catalog.gd")
const Animator = preload("res://scripts/ui/tutorials/character_animation_controller.gd")
const Highlight = preload("res://scripts/ui/tutorials/tutorial_highlight.gd")

var _memory: Dictionary
var _replay := false
var _replay_index := -1
var _title: Label
var _mentor: Label
var _prompt: Label
var _state: Label
var _feedback: Label
var _actions: VBoxContainer
var _ack: Button
var _skip: Button
var _exit: Button
var _portrait: TextureRect
var _actor: Animator
var _highlight: Highlight
var _summary: VBoxContainer

func _ready() -> void:
	theme = FallenUI.build_theme()
	var bg := ColorRect.new()
	bg.color = FallenUI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_title = _label(box, "", 26)
	_mentor = _label(box, "", 18)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(row)
	var art := VBoxContainer.new()
	art.custom_minimum_size.x = 220
	row.add_child(art)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(220, 220)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.add_child(_portrait)
	_actor = Animator.new()
	_actor.custom_minimum_size = Vector2(220, 170)
	art.add_child(_actor)
	_label(art, "Un souvenir d’enfance\nLes réserves de cet exercice n’appartiennent pas au présent.", 14)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	_prompt = _label(content, "", 22)
	_state = _label(content, "", 16)
	_state.add_theme_color_override("font_color", FallenUI.MUTED)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	content.add_child(_actions)
	_feedback = _label(content, "", 18)
	_feedback.add_theme_color_override("font_color", FallenUI.GOLD)
	_summary = VBoxContainer.new()
	content.add_child(_summary)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	_ack = _button(footer, "J’ai vu la conséquence — poursuivre", _acknowledge)
	_skip = _button(footer, "Passer cet enseignement", _skip_sequence)
	_exit = _button(footer, "Sauvegarder et revenir au menu", _leave)
	_highlight = Highlight.new()
	add_child(_highlight)
	var opening: Dictionary = SaveSystem.get_value("opening", {})
	_replay = not bool(opening.get("active", false))
	if _replay:
		_memory = Memories.fresh()
	else:
		if not opening.has("memories"): opening["memories"] = Memories.fresh()
		_memory = opening.memories
	_refresh()

func init_data(data: Dictionary) -> void:
	if not data.has("replay"): return
	_replay = true
	_replay_index = clampi(int(data.replay), 0, Memories.sequences().size() - 1)
	_memory = Memories.fresh()
	_memory.sequence = _replay_index
	_refresh()

func _refresh() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	for child in _summary.get_children():
		_summary.remove_child(child)
		child.queue_free()
	if _replay_index >= 0 and int(_memory.sequence) > _replay_index: _memory.finished = true
	var finished := bool(_memory.finished)
	_skip.visible = not finished
	_ack.disabled = not finished and not bool(_memory.awaiting_ack)
	_ack.text = ("Retour aux enseignements" if _replay else "Qui suis-je devenu ?") if finished else "J’ai vu la conséquence — poursuivre"
	_exit.text = "Retour au refuge" if _replay else "Sauvegarder et revenir au menu"
	if finished:
		_title.text = "CE QUE VOUS EMPORTEZ"
		_mentor.text = "Votre sœur — une voix dans le noir"
		_prompt.text = "« Ces souvenirs appartiennent à l’enfant que tu étais. Alors dis-moi… qui es-tu devenu ? »"
		_state.text = Memories.affinity_text(_memory)
		_feedback.text = ""
		_portrait.hide()
		for sequence in Memories.sequences(): _label(_summary, str(sequence.summary), 17)
		_highlight.follow(null)
		_ack.grab_focus()
		_persist()
		return
	var sequence: Dictionary = Memories.sequences()[int(_memory.sequence)]
	var step := Memories.current(_memory)
	_title.text = "%d / 6 · %s" % [int(_memory.sequence) + 1, str(sequence.title).to_upper()]
	_mentor.text = "%s · Étape %d / %d" % [sequence.mentor, int(_memory.step) + 1, sequence.steps.size()]
	_prompt.text = str(step.text)
	var path := Visuals.resolve_family_portrait(str(sequence.portrait_role), "") if not str(sequence.portrait_role).is_empty() else ""
	_portrait.texture = load(path) if not path.is_empty() else null
	_portrait.visible = _portrait.texture != null
	_actor.play(str(step.animation))
	var sim: Dictionary = _memory.simulation
	var shown := {}
	var resource_keys: Array = {"combat": ["soldats"], "occult": ["mana"], "espionage": ["or", "renseignements"], "diplomacy": ["or", "nourriture", "renseignements", "reputation"], "command": ["soldats", "nourriture"], "craft": ["bois", "fer", "pierre", "mana", "essence"]}[str(sequence.id)]
	for key in resource_keys: shown[key] = sim.resources.get(key, 0)
	_state.text = "Réserves : %s · Temps : %s" % [Loops.resources_text(shown), str(sim.phase)]
	if str(sequence.id) in ["occult", "craft"]: _state.text += "\nCorruption : %d" % int(sim.corruption)
	if str(sequence.id) in ["combat", "occult"]:
		for unit in sim.battle.units: _state.text += "\n%s : %d / %d PV" % [unit.name, int(unit.hp), int(unit.max_hp)]
	var intel := {"forces": "Rondes et faiblesse de la porte", "passage": "Plan du passage", "secret": "Réserve cachée du lieutenant", "desire": "Crainte de la famine"}
	if str(sequence.id) in ["espionage", "diplomacy"]:
		for key in intel: _state.text += "\n" + (str(intel[key]) if key in sim.loops.knowledge else "??? — information masquée")
	if str(sequence.id) == "command":
		_state.text += "\nFormation : %s · Moral : %d · Fatigue : %d" % ["Boucliers / soutien" if str(sim.loops.formation) == "guard" else "Assaut / arrière vide" if str(sim.loops.formation) == "charge" else "À placer", int(sim.loops.morale), int(sim.loops.fatigue)]
	if str(sequence.id) == "craft": _state.text += "\nESP — Esprit : 4 · TRA — Transfuge : 4 · ESE — Essence : 4"
	_feedback.text = str(_memory.feedback)
	if bool(_memory.awaiting_ack):
		_feedback.text += "\n\n" + str(step.explanation)
		_highlight.follow(null)
		_ack.grab_focus()
	else:
		var all := Loops.definitions()
		var actions: Array = step.actions.duplicate()
		if str(step.required_event) == "artifact_created": actions.append("materials")
		for action_id in actions:
			var label: String = {"training_attack": "Attaquer la garde du père", "training_defend": "Défendre / fortifier ma garde", "training_night": "Observer le passage au soir", "training_cast": "Lancer le Trait d’Éther · 3 mana"}.get(action_id, str(action_id))
			var reason := ""
			if all.has(action_id):
				var definition: Dictionary = all[action_id]
				reason = Loops.reason(str(action_id), sim.loops, sim.resources, sim.stats)
				label = str(definition.label) + " · " + Loops.resources_text(Loops.cost_for(definition, sim.loops, sim.stats))
				if definition.has("risk"): label += " · risque %d%%" % Loops.risk_for(definition, sim.loops, sim.stats)
				if definition.has("recipe"): label += " · échec 5%%"
				if definition.has("corruption"): label += " · corruption de base +%d" % int(definition.corruption)
				if action_id == "bind": label += " · cercle −2 ; secret −1 ; résonance +4"
			var button := _button(_actions, label, _act.bind(str(action_id)))
			button.name = str(action_id)
			button.disabled = not reason.is_empty()
			button.tooltip_text = reason
		if _actions.get_child_count() > 0:
			_highlight.follow(_actions)
			_actions.get_child(0).grab_focus()
	_persist()

func _act(action_id: String) -> void:
	var result := Memories.act(_memory, action_id)
	if not result.accepted:
		_feedback.text = result.message
		return
	_persist()
	_refresh()

func _acknowledge() -> void:
	if bool(_memory.finished):
		if _replay:
			GameManager.open_clan_hub()
		else:
			var opening: Dictionary = SaveSystem.get_value("opening", {})
			opening.stage = "creation"
			opening.finished = true
			SaveSystem.set_value("opening", opening)
			SaveSystem.save()
			GameManager.go_to("creation_personnage")
		return
	if Memories.acknowledge(_memory): _refresh()

func _skip_sequence() -> void:
	Memories.skip(_memory)
	_refresh()

func _persist() -> void:
	if _replay: return
	var opening: Dictionary = SaveSystem.get_value("opening", {})
	opening["memories"] = _memory
	SaveSystem.set_value("opening", opening)
	SaveSystem.save()

func _leave() -> void:
	_persist()
	if _replay: GameManager.open_clan_hub()
	else: GameManager.go_to_menu()

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
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
