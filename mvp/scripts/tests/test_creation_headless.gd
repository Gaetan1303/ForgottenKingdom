extends SceneTree

func _init():
	# run deferred to ensure SceneTree is ready
	call_deferred("_run_test")

func _run_test() -> void:
	print("TEST_START: creation_personnage headless")
	var scene_path := "res://scenes/creation_personnage.tscn"
	var scene = null
	if ResourceLoader.exists(scene_path):
		scene = load(scene_path)
	else:
		print("ERROR: scene not found: %s" % scene_path)
		quit(1)
		return
	var inst = scene.instantiate()
	if inst == null:
		print("ERROR: instantiate failed")
		quit(1)
		return
	get_root().add_child(inst)

	# Defer the verification so the child _ready() can run
	call_deferred("_post_ready_check", inst)
	return


func _post_ready_check(inst: Node) -> void:
	var nom_perso = inst.get_node_or_null("PanneauCentre/LigneNoms/ColNomPerso/NomPersonnage")
	var nom_clan = inst.get_node_or_null("PanneauCentre/LigneNoms/ColNomClan/NomClan")
	if nom_perso and nom_clan:
		nom_perso.text = "Ingrid"
		nom_clan.text = "Maison Test"
		print("Inputs set: NomPerso=Ingrid, NomClan=Maison Test")
	else:
		print("Inputs missing: NomPerso/ NomClan not found in scene tree")

	if inst.has_method("_choisir_classe"):
		inst._choisir_classe("chevalier_sombre")

	if inst.has_method("_on_commencer"):
		inst._on_commencer()
		print("_on_commencer invoked")

	# Print autoload state (access via scene root to avoid compile-time global)
	var cm: Node = get_root().get_node_or_null("/root/ClanManager")
	if cm != null:
		print("ClanManager.nom_clan =", str(cm.get("nom_clan")))
		print("ClanManager.nom_personnage =", str(cm.get("nom_personnage")))
	else:
		print("ClanManager autoload not found at /root/ClanManager")

	# Additionally instantiate clan_hub and check displayed label text
	var hub_path := "res://scenes/clan_hub.tscn"
	if ResourceLoader.exists(hub_path):
		var hub_scene = load(hub_path)
		var hub_inst = hub_scene.instantiate()
		get_root().add_child(hub_inst)
		call_deferred("_post_check_clanhub", inst, hub_inst)
		return
	else:
		print("clan_hub scene missing: %s" % hub_path)
		inst.queue_free()
		quit(0)


func _post_check_clanhub(inst: Node, hub_inst: Node) -> void:
	var lbl := hub_inst.get_node_or_null("Header/BgHeader/InfoClan/LabelNomClan")
	if lbl != null:
		print("LabelNomClan.text =", str(lbl.text))
	else:
		print("LabelNomClan node missing in clan_hub instance")
	hub_inst.queue_free()
	inst.queue_free()
	await process_frame
	quit(0)
