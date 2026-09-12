## Orchestrateur du présent, sans état mutable propre ni dépendance à une scène.
extends RefCounted

const Loops = preload("res://scripts/services/power_loop_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Resolution = preload("res://scripts/domain/objective_resolution.gd")
const Result = preload("res://scripts/domain/loop_action_result.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
const Enums = preload("res://scripts/core/enums.gd")

static func ensure(cm: Node) -> void:
	if not cm.campaign.has("power_routes"):
		cm.campaign["power_routes"] = Loops.initial_state()
		# Ne pas récompenser une seconde fois les outils des sauvegardes antérieures.
		if Refuge.has(cm, "salvage"):
			var legacy := Resolution.new()
			legacy.method = "combat" if Refuge.has(cm, "combat") else "legacy"
			legacy.consequences = "Outils déjà récupérés dans cette sauvegarde ; méthode historique inconnue." if legacy.method == "legacy" else "Outils rapportés d’une expédition antérieure."
			if legacy.method == "legacy": cm.campaign.power_routes.objectives[Objectives.GALLERIES].resolution_methods.append("legacy")
			Objectives.resolve(cm.campaign.power_routes, legacy)
	Loops.normalize(cm.campaign.power_routes)

static func reason(cm: Node, action_id: String) -> String:
	ensure(cm)
	if not cm.campaign.power_routes.get("pending_feedback", {}).is_empty(): return "Confirmez le dernier résultat avant de décider."
	var run: Dictionary = cm.campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)): return "Revenez au refuge avant de décider."
	if cm.action_deja_utilisee_pour_moment(): return "Décision déjà prise. Avancez jusqu’à la prochaine demi-journée."
	if action_id == "command_assault" and str(Refuge.find_person(cm, "pnj_kael").get("etat", "")) != "disponible": return "Kael doit être disponible pour commander."
	return Loops.reason(action_id, cm.campaign.power_routes, cm.get_ressources(), cm.stats)

static func execute(cm: Node, action_id: String) -> Result:
	var rejected := Result.new()
	rejected.message = reason(cm, action_id)
	if not rejected.message.is_empty(): return rejected
	var stats: Dictionary = cm.stats.duplicate(true)
	stats.merge(cm.get_fiche_complete().get("secondary_stats", {}), true)
	# Le tirage appartient au domaine ; aucun jet ni conséquence fournis par la vue.
	var result := Loops.evaluate(action_id, cm.campaign.power_routes, cm.get_ressources(), stats, randi_range(0, 99))
	if not result.accepted: return result
	cm.campaign.power_routes = result.next_state
	cm.payer(result.cost)
	cm.gagner(result.gains)
	if action_id == "pact":
		var pacts = cm.get_pact_service()
		var offer: Dictionary = pacts.offer_pact("gallery_echo", "hero", Enums.PactType.SERVICE,
			{"ritual_power": 100, "requirements": ["secure_galleries"], "price": "corruption", "source": "memory_teaching"})
		pacts.attempt_pact_ritual("gallery_echo", "hero")
		cm.campaign.power_routes["pact_id"] = str(offer.pact.pact_id)
		var echo: Resource = preload("res://scripts/factory/creature_factory.gd").new().create_from_dict({"id": "gallery_echo", "nom": "Écho des galeries", "species_id": "gallery_echo", "source": "pact"})
		cm.get_creature_roster_service().acquire_creature(echo, "pacte")
	if result.corruption > 0:
		var corruption = cm.get_corruption_service()
		if not corruption.has_character("hero"): corruption.register_character("hero")
		corruption.set_corruption("hero", corruption.get_corruption_level("hero") + result.corruption, "power_" + action_id)
	cm.marquer_action_utilisee()
	if result.event == "objective_resolved":
		Refuge.mark(cm, "salvage")
		Refuge.mark(cm, "assignment")
		_fulfill_prepared_pact(cm)
	cm.campaign.power_routes["pending_feedback"] = {"title": str(Loops.definitions()[action_id].label), "description": result.message + "\n\nDépensé : " + Loops.resources_text(result.cost) + "\nObtenu : " + Loops.resources_text(result.gains) + "\nCorruption : +%d" % int(result.corruption)}
	Refuge.log_entry(cm, str(Loops.definitions()[action_id].label), result.message)
	cm.sauvegarder()
	return result

static func acknowledge(cm: Node) -> void:
	if cm.campaign.get("power_routes", {}).get("pending_feedback", {}).is_empty(): return
	cm.campaign.power_routes.erase("pending_feedback")
	cm.sauvegarder()

static func record_expedition(cm: Node, run: Dictionary) -> void:
	# Le combat garde son vrai runtime. Cette frontière ne crédite aucun butin.
	ensure(cm)
	if not bool(run.get("tools_found", false)) or Objectives.completed(cm.campaign.power_routes): return
	var resolution := Resolution.new()
	resolution.method = "combat"
	resolution.consequences = "Vous avez vaincu les gardiens et rapporté les outils. Le refuge s’ouvre ; les survivants raconteront l’assaut."
	var mana := 0
	for floor_data in run.get("floors", []):
		for room in floor_data.get("rooms", []): mana += int(room.get("battle", {}).get("mana_spent", 0))
	resolution.cost = {"mana": mana}
	resolution.relations = {"gallery_wardens": -4}
	resolution.future_events = ["survivors_of_assault"]
	Objectives.resolve(cm.campaign.power_routes, resolution)
	cm.campaign.power_routes.progress["combat"] = int(cm.campaign.power_routes.progress.get("combat", 0)) + 1
	cm.campaign.power_routes.warden_relation = -4
	cm.campaign.power_routes.future_events.append("survivors_of_assault")
	_fulfill_prepared_pact(cm)

static func _fulfill_prepared_pact(cm: Node) -> void:
	var pact_id := str(cm.campaign.power_routes.get("pact_id", ""))
	if not pact_id.is_empty(): cm.get_pact_service().fulfill_pact_requirement(pact_id, "secure_galleries")
