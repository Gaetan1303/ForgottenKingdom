extends SceneTree
const Refuge = preload("res://scripts/services/refuge_service.gd")
const Combat = preload("res://scripts/services/tactical_combat_service.gd")
const Tutorial = preload("res://scripts/autoload/tutorial_director.gd")
var failures: Array[String] = []
var cm: Node
var dungeon: Node
var saves: Node

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	_test_combat_edges()
	cm = root.get_node("ClanManager")
	dungeon = root.get_node("DungeonGenerator")
	saves = root.get_node("SaveSystem")
	saves.set_active_slot("prologue_contract_test")
	cm.nouvelle_partie("Aren", "Maison des Cendres", "hellcaster", {})
	Refuge.initialize(cm)
	check(cm.get_ressource("nourriture") == 12, "réserves de départ")
	check(cm.get_pnj_gestion_state().roster.size() == 1, "compagnons canoniques")
	Refuge.initialize(cm)
	check(cm.get_pnj_gestion_state().roster.size() == 1 and cm.get_ressource("nourriture") == 12, "initialisation idempotente")
	var intro: Control = load("res://scenes/intro_vn.tscn").instantiate()
	root.add_child(intro)
	await process_frame
	intro._show_scene(1)
	await process_frame
	await process_frame
	await process_frame
	for button in intro._choices.get_children():
		check(button.get_global_rect().end.y <= intro.get_viewport_rect().end.y, "choix de l’intro visible dans le viewport")
	check(int(cm.campaign.intro_index) == 1, "position de l’introduction sauvegardée")
	var choice: Dictionary = intro._scenes[1].choices[0]
	var mana_before: int = cm.get_ressource("mana")
	Refuge.intro_choice(cm, "chute_03", choice)
	Refuge.intro_choice(cm, "chute_03", choice)
	check(cm.get_ressource("mana") == mana_before, "choix intro sans double gain")
	intro.queue_free()
	await process_frame
	check(cm.charger_sauvegarde(), "chargement en introduction")
	check(int(cm.campaign.intro_index) == 1, "reprise intro conservée")
	cm.campaign.intro_done = true
	var wood: int = cm.get_ressource("bois")
	Refuge.repair(cm, "granary", "pnj_kael")
	check(cm.get_ressource("bois") == wood - 6, "coût réel réparation")
	check(Refuge.find_person(cm, "pnj_kael").etat == "assigne", "vraie affectation")
	check(not Refuge.building_reason(cm, "walls").is_empty(), "deux décisions interdites dans la même phase")
	Refuge.repair(cm, "granary", "pnj_kael")
	check(cm.get_ressource("bois") == wood - 6, "réparation non répétable")
	Refuge.social_choice(cm, true)
	check(cm.get_ressource("nourriture") == 10, "conséquence humaine réelle")
	check(not dungeon.start_expedition(["pnj_kael"]).is_empty(), "compagnon affecté interdit")
	check(not dungeon.start_expedition(["pnj_kael", "pnj_kael"]).is_empty(), "pas de doublon équipe")
	cm.advance_day_phase()
	check(dungeon.start_expedition(["pnj_kael"]).is_empty(), "départ équipe")
	check(not dungeon.enter_dungeon(), "entrée sans inspection refusée")
	dungeon.inspect_arrival("passage")
	check(dungeon.enter_dungeon(), "entrée inspectée")
	check(not dungeon.enter_dungeon(), "entrée non répétable")
	check(not dungeon.advance_room(), "salle non résolue ne peut pas être sautée")
	dungeon.resolve_quiet_room()
	check(dungeon.advance_room(), "observation puis exploration")
	var battle: Dictionary = dungeon.ensure_battle()
	var snapshot := JSON.stringify(battle)
	var rejected := Combat.command(battle, "attack", 5, 0, 0)
	check(not bool(rejected.ok) and JSON.stringify(battle) == snapshot, "attaque hors portée sans mutation")
	cm.sauvegarder()
	check(cm.charger_sauvegarde(), "sauvegarde milieu combat")
	check(JSON.parse_string(JSON.stringify(dungeon.ensure_battle())) == JSON.parse_string(snapshot), "combat restauré exactement")
	var dungeon_ui: Control = load("res://scenes/dungeon_view.tscn").instantiate()
	root.add_child(dungeon_ui)
	await process_frame
	check(dungeon_ui._grid.get_child_count() == 24, "grille jouable")
	dungeon_ui.queue_free()
	await process_frame
	var iterations := 0
	while not bool(dungeon.get_current_room().get("cleared", false)) and iterations < 100:
		battle = dungeon.ensure_battle()
		if not str(battle.get("outcome", "")).is_empty(): break
		_play_turn(battle)
		iterations += 1
	check(iterations < 100 and bool(dungeon.get_current_room().get("cleared", false)), "combat gagnable sans modifier les PV")
	check(Refuge.has(cm, "combat"), "combat accompli")
	dungeon.advance_room()
	dungeon.resolve_quiet_room()
	var fer_before: int = cm.get_ressource("fer")
	check(fer_before == 2, "butin non crédité avant retour")
	# Une blessure déjà produite dans l’état de combat doit atteindre le registre canonique.
	for person in dungeon.current_run.party:
		if str(person.id) == "pnj_kael":
			person.hp = 1
			person.max_hp = 30
	var xp_before: int = cm.get_personnage_experience()
	dungeon.return_to_refuge()
	check(cm.get_personnage_experience() == xp_before + 20, "expérience canonique au retour")
	check(cm.campaign.power_routes.objectives.secure_galleries.status == "completed" and cm.campaign.power_routes.objectives.secure_galleries.resolution_method == "combat", "combat réel résout l’objectif commun")
	check(cm.get_ressource("fer") == fer_before + 6, "butin déposé")
	dungeon.return_to_refuge()
	check(cm.get_ressource("fer") == fer_before + 6, "retour idempotent")
	check(cm.get_personnage_experience() == xp_before + 20, "expérience non répétée")
	check(Refuge.find_person(cm, "pnj_kael").etat == "blesse", "blessure persistante")
	cm.sauvegarder()
	cm.charger_sauvegarde()
	check(Refuge.find_person(cm, "pnj_kael").etat == "blesse", "blessure chargée")
	check(not dungeon.start_expedition(["pnj_kael"]).is_empty(), "blessure empêche départ")
	Refuge.recover(cm, "pnj_kael")
	check(Refuge.find_person(cm, "pnj_kael").etat == "disponible", "soins rendent disponible")
	cm.resoudre_planning_pnj_journee()
	cm.advance_day_phase()
	cm.reset_actions_pour_nuit()
	Refuge.repair(cm, "workshop", "pnj_kael")
	check(Refuge.has(cm, "rebuild"), "atelier réel restauré")
	check(cm.get_ressource("fer") == 2, "coût atelier")
	var food: int = cm.get_ressource("nourriture")
	Refuge.dawn(cm)
	check(cm.get_ressource("nourriture") == food + 4, "production bâtiment")
	for mode in range(3):
		cm.campaign.help_mode = mode
		check(Tutorial.current(cm.campaign).id == "soul", "aide indépendante histoire")
	Refuge.study_relic(cm, false)
	check(Tutorial.current(cm.campaign).id == "open_world", "ouverture naturelle")
	var intel: int = cm.get_ressource("renseignements")
	Refuge.study_relic(cm, false)
	check(cm.get_ressource("renseignements") == intel, "relique non répétable")
	var hub: Control = load("res://scenes/clan_hub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	await process_frame
	check(hub._vue_gauche == "domaine", "domaine affiché par défaut")
	for label in hub.find_children("*", "Label", true, false):
		if label.has_meta("keyboard_tooltip"):
			label.grab_focus()
			await process_frame
			await process_frame
			var panel: Control = label.get_child(0).get_child(0)
			check(panel.visible and panel.get_global_rect().end.y <= root.get_visible_rect().end.y, "infobulle clavier bornée au viewport")
			check(not panel.get_child(0).text.is_empty(), "contenu infobulle clavier")
			label.release_focus()
			check(not panel.visible, "infobulle fermée au départ du focus")
			break
	hub.queue_free()
	await process_frame
	# Isolation d’une nouvelle partie ; les anciennes sauvegardes restent sans prologue forcé.
	cm.nouvelle_partie("Autre", "Maison Autre", "hellcaster", {})
	check(cm.campaign.is_empty(), "nouvelle partie réinitialise campagne")
	check(cm.charger_sauvegarde() and cm.campaign.is_empty(), "ancienne structure compatible")
	Refuge.initialize(cm)
	Refuge.prioritize_galleries(cm)
	check(Refuge.has(cm, "govern") and not Refuge.has(cm, "assignment"), "priorité alternative sans réparation imposée")
	cm.campaign.help_mode = 2
	Refuge.social_choice(cm, false)
	check(Refuge.has(cm, "social"), "choix social avec aides désactivées")
	Refuge.mark(cm, "rebuild")
	cm.gagner({"essence": 1})
	var soul_before: int = cm.barre_ame
	var mana_attune: int = cm.get_ressource("mana")
	Refuge.study_relic(cm, true)
	check(cm.barre_ame == soul_before and cm.get_ressource("mana") == mana_attune, "Architecture verrouillée sans consommation")
	if failures.is_empty():
		print("PLAYABLE_PROLOGUE_OK")
		quit(0)
	else:
		for failure in failures: push_error("PROLOGUE_FAIL: " + failure)
		quit(1)

func _play_turn(battle: Dictionary) -> void:
	var actor := Combat.active(battle)
	var target: Dictionary = {}
	for unit in battle.units:
		if str(unit.team) == "enemy" and int(unit.hp) > 0 and (target.is_empty() or Combat.distance(actor, unit) < Combat.distance(actor, target)):
			target = unit
	if target.is_empty(): return
	if Combat.distance(actor, target) > 1 and not bool(battle.moved):
		var best := {"x": int(actor.x), "y": int(actor.y)}
		for y in range(Combat.HEIGHT):
			for x in range(Combat.WIDTH):
				var cell := {"x": x, "y": y}
				if Combat.can_move(battle, x, y) and Combat.distance(cell, target) < Combat.distance(best, target): best = cell
		if int(best.x) != int(actor.x) or int(best.y) != int(actor.y): dungeon.combat_command("move", best.x, best.y)
	if Combat.distance(actor, target) <= 1:
		dungeon.combat_command("attack", int(target.x), int(target.y))
	elif Combat.distance(actor, target) <= 3 and cm.get_ressource("mana") >= 3:
		dungeon.combat_command("ability", int(target.x), int(target.y))
	if not bool(dungeon.get_current_room().get("cleared", false)):
		dungeon.combat_command("end")

func _test_combat_edges() -> void:
	var party := [{"id": "test", "nom": "Test", "stats": {"force": 12, "magie": 12, "espionnage": 18}}]
	var battle := Combat.create(party, ["Garde"])
	var actor := Combat.active(battle)
	actor.x = 2
	var snapshot := JSON.stringify(battle)
	var rejected := Combat.command(battle, "ability", 5, 0, 2)
	check(not bool(rejected.ok) and JSON.stringify(battle) == snapshot, "mana insuffisant sans mutation")
	var accepted := Combat.command(battle, "ability", 5, 0, 3)
	check(bool(accepted.ok) and int(accepted.cost) == 3, "capacité avec coût exact")
	snapshot = JSON.stringify(battle)
	rejected = Combat.command(battle, "ability", 5, 0, 3)
	check(not bool(rejected.ok) and JSON.stringify(battle) == snapshot, "une seule action par tour")
	var fallen_party := party.duplicate(true)
	fallen_party[0].hp = 0
	fallen_party.append({"id": "survivor", "nom": "Survivant", "hp": 20, "stats": {"espionnage": 10}})
	var next_battle := Combat.create(fallen_party, ["Garde"])
	check(str(Combat.active(next_battle).id) != "test", "unité hors combat ignorée à la salle suivante")
	var state := {"help_mode": 0, "hints_seen": []}
	check(not Tutorial.hint(state, "test", "Conseil").is_empty(), "premier conseil")
	check(Tutorial.hint(state, "test", "Conseil").is_empty(), "conseil non répété")
	state = JSON.parse_string(JSON.stringify(state))
	check(Tutorial.hint(state, "test", "Conseil").is_empty(), "conseil non répété après chargement")
