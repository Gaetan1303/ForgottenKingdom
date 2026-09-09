extends SceneTree
const Expedition = preload("res://scripts/game_loop/expedition_state_machine.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
var failures: Array[String] = []
class CountingState extends State:
	var entered := 0
	func enter(_data: Dictionary = {}) -> void:
		entered += 1
		if machine != null: machine.handle_event("next")
func _init() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var machine := StateMachine.new()
	var first := CountingState.new("first")
	var second := CountingState.new("second")
	machine.add_state("first", first)
	machine.add_state("second", second)
	machine.allow("first", "next", "second")
	check(machine.start() and machine.current == first, "entrée non réentrante")
	check(not machine.start() and first.entered == 1, "démarrage unique")
	check(not machine.handle_event("unknown", {"transition_to": "second"}), "événement non autorisé refusé")
	check(machine.handle_event("next") and second.entered == 1, "transition autorisée")
	check(machine.restore("first") and first.entered == 1, "restauration sans effet")
	var weak: WeakRef = weakref(machine)
	machine = null
	check(weak.get_ref() == null, "pas de cycle de références état-machine")
	check(Expedition.state_of({"completed": true}) == "return", "migration sortie terminée")
	check(Expedition.state_of({"floors": []}) == "exploration", "migration ancienne sortie")
	var cm := root.get_node("ClanManager")
	root.get_node("SaveSystem").set_active_slot("campaign_states_test")
	cm.nouvelle_partie("Aren", "Cendres", "hellcaster", {})
	Refuge.initialize(cm)
	check(cm.daily_phase == "matin", "phase initiale")
	check(cm.advance_day_phase().ok and cm.daily_phase == "apres_midi", "résolution journée")
	var snapshot := JSON.stringify(cm.get_ressources())
	check(cm.charger_sauvegarde() and cm.daily_phase == "apres_midi", "reprise phase")
	var loop := GameLoopStateMachine.new(cm)
	loop.start()
	check(JSON.stringify(cm.get_ressources()) == snapshot, "aucun gain au chargement")
	check(cm.advance_day_phase().ok and cm.daily_phase == "soir", "transition nuit")
	var day: int = cm.tour_actuel
	check(cm.advance_day_phase().ok and cm.daily_phase == "matin" and cm.tour_actuel == day + 1, "aube unique")
	var dungeon := root.get_node("DungeonGenerator")
	check(dungeon.start_expedition(["pnj_kael"]).is_empty(), "sortie préparée")
	check(not cm.advance_day_phase().ok and cm.daily_phase == "matin", "journée figée pendant sortie")
	check(dungeon.ensure_battle().is_empty() and not dungeon.advance_room(), "seuil ne déclenche pas combat")
	dungeon.inspect_arrival("passage")
	var journal_size: int = cm.campaign.journal.size()
	dungeon.inspect_arrival("passage")
	check(cm.campaign.journal.size() == journal_size, "inspection idempotente")
	cm.charger_sauvegarde()
	check(dungeon.current_run.state == "arrival" and dungeon.enter_dungeon(), "inspection et arrivée restaurées")
	dungeon.return_to_refuge()
	check(dungeon.current_run.state == "returned", "retour final")
	if failures.is_empty(): print("CAMPAIGN_STATES_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
