extends SceneTree
const Memories = preload("res://scripts/services/memory_tutorial_service.gd")
const Campaign = preload("res://scripts/services/power_campaign_service.gd")
var failures: Array[String] = []
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var memory := Memories.fresh()
	var actions := ["training_attack", "training_defend", "training_night", "training_cast", "ward", "bind", "infiltrate", "audience", "use_secret", "formation_guard", "command_assault", "materials", "craft_grounded"]
	var save := root.get_node("SaveSystem")
	save.set_active_slot("memory_sequence_test")
	for action in actions:
		var snapshot := JSON.stringify(memory)
		check(not Memories.acknowledge(memory) and JSON.stringify(memory) == snapshot, "aucune progression prématurée")
		check(not Memories.act(memory, "wrong_action").accepted and JSON.stringify(memory) == snapshot, "action incorrecte sans progression")
		var result := Memories.act(memory, action)
		check(result.accepted, action + ": action acceptée")
		var attempts := 0
		while not result.succeeded and attempts < 8:
			Memories.act(memory, "materials")
			result = Memories.act(memory, action)
			attempts += 1
		check(bool(memory.awaiting_ack), action + ": conséquence avant progression")
		snapshot = JSON.stringify(memory)
		check(not Memories.act(memory, action).accepted and JSON.stringify(memory) == snapshot, "double clic sans effet")
		save.set_value("opening", {"active": true, "stage": "memories", "memories": memory})
		save.save()
		save.load_save()
		memory = save.get_value("opening").memories
		check(JSON.parse_string(JSON.stringify(memory)) == JSON.parse_string(snapshot), "save/load de chaque étape et feedback")
		check(Memories.acknowledge(memory), "acquittement valide")
	check(memory.finished and memory.completed.size() == 6, "six séquences achevées")
	check(memory.affinities.size() == 6, "six affinités indicatives")
	var skipped := Memories.fresh()
	for _i in range(6): Memories.skip(skipped)
	check(skipped.finished and skipped.completed.is_empty() and skipped.affinities.is_empty(), "passage libre sans faux accomplissement")
	check(memory.simulation.loops.knowledge.has("secret"), "espionnage vers diplomatie")
	if failures.is_empty(): print("MEMORY_SEQUENCES_OK")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
