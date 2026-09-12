extends SceneTree
const State = preload("res://scripts/data/clan_state.gd")
const Context = preload("res://scripts/services/clan_service_context.gd")
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var cm = root.get_node("ClanManager")
	var identity = cm.state
	cm.ressources = {"or": 30, "soldats": 0}
	assert(cm.state.ressources.or == 30)
	cm.state.ressources.or = 42
	assert(cm.get_ressource("or") == 42)
	var snapshot: Dictionary = cm.state.export_state()
	assert(snapshot.has("soldats_disponibles") and not snapshot.has("_soldats_disponibles"))
	var other := State.new()
	other.import_state(snapshot)
	other.ressources.or = 99
	assert(cm.ressources.or == 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var ctx := Context.new(other, rng)
	var first := ctx.rng.randi()
	rng.seed = 42
	assert(first == ctx.rng.randi())
	cm.sauvegarder()
	cm.ressources.or = 1
	assert(cm.charger_sauvegarde())
	assert(cm.ressources.or == 42 and cm.state == identity and cm.service_context.state == identity)
	print("CLAN_STATE_OK")
	quit()
