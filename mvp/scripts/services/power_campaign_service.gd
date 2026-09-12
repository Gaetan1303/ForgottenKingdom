## Orchestrateur du présent, sans état mutable propre ni dépendance à une scène.
extends RefCounted

const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Actions = preload("res://scripts/services/clan_action_service.gd")
const Population = preload("res://scripts/services/clan_population_service.gd")
const CharacterService = preload("res://scripts/services/clan_character_service.gd")
const Planner = preload("res://scripts/services/pnj_daily_planner_service.gd")


const Loops = preload("res://scripts/services/power_loop_service.gd")
const Objectives = preload("res://scripts/services/narrative_objective_service.gd")
const Resolution = preload("res://scripts/domain/objective_resolution.gd")
const Result = preload("res://scripts/domain/loop_action_result.gd")
const Refuge = preload("res://scripts/services/refuge_service.gd")
const Enums = preload("res://scripts/core/enums.gd")

static func ensure(ctx: ContextType) -> void:
	if not ctx.state.campaign.has("power_routes"):
		ctx.state.campaign["power_routes"] = Loops.initial_state()
		# Ne pas récompenser une seconde fois les outils des sauvegardes antérieures.
		if Refuge.has(ctx, "salvage"):
			var legacy := Resolution.new()
			legacy.method = "combat" if Refuge.has(ctx, "combat") else "legacy"
			legacy.consequences = "Outils déjà récupérés dans cette sauvegarde ; méthode historique inconnue." if legacy.method == "legacy" else "Outils rapportés d’une expédition antérieure."
			if legacy.method == "legacy": ctx.state.campaign.power_routes.objectives[Objectives.GALLERIES].resolution_methods.append("legacy")
			Objectives.resolve(ctx.state.campaign.power_routes, legacy)
	Loops.normalize(ctx.state.campaign.power_routes)

static func reason(ctx: ContextType, action_id: String) -> String:
	ensure(ctx)
	if not ctx.state.campaign.power_routes.get("pending_feedback", {}).is_empty(): return "Confirmez le dernier résultat avant de décider."
	var run: Dictionary = ctx.state.campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)): return "Revenez au refuge avant de décider."
	if Actions.action_used(ctx): return "Décision déjà prise. Avancez jusqu’à la prochaine demi-journée."
	if action_id == "command_assault" and str(Refuge.find_person(ctx, "pnj_kael").get("etat", "")) != "disponible": return "Kael doit être disponible pour commander."
	return Loops.reason(action_id, ctx.state.campaign.power_routes, ctx.state.ressources.duplicate(true), action_stats(ctx, action_id))

static func execute(ctx: ContextType, action_id: String) -> Result:
	var rejected := Result.new()
	rejected.message = reason(ctx, action_id)
	if not rejected.message.is_empty(): return rejected
	var stats := action_stats(ctx, action_id)
	# Le tirage appartient au domaine ; aucun jet ni conséquence fournis par la vue.
	var result := Loops.evaluate(action_id, ctx.state.campaign.power_routes, ctx.state.ressources.duplicate(true), stats, ctx.rng.randi_range(0, 99))
	if not result.accepted: return result
	Planner.new(ctx).consume_support(support_action(action_id))
	ctx.state.campaign.power_routes = result.next_state
	ctx.economy.pay(ctx, result.cost)
	ctx.economy.gain_state(ctx, result.gains)
	if action_id == "pact":
		var pacts = ctx.pacts
		var offer: Dictionary = pacts.offer_pact("gallery_echo", "hero", Enums.PactType.SERVICE,
			{"ritual_power": 100, "requirements": ["secure_galleries"], "price": "corruption", "source": "memory_teaching"})
		pacts.attempt_pact_ritual("gallery_echo", "hero")
		ctx.state.campaign.power_routes["pact_id"] = str(offer.pact.pact_id)
		var echo: Resource = preload("res://scripts/factory/creature_factory.gd").new().create_from_dict({"id": "gallery_echo", "nom": "Écho des galeries", "species_id": "gallery_echo", "source": "pact"})
		ctx.creatures.acquire_creature(echo, "pacte")
	if result.corruption > 0:
		var corruption = ctx.corruption
		if not corruption.has_character("hero"): corruption.register_character("hero")
		corruption.set_corruption("hero", corruption.get_corruption_level("hero") + result.corruption, "power_" + action_id)
	Actions.mark_used(ctx)
	if result.event == "objective_resolved":
		Refuge.mark(ctx, "salvage")
		Refuge.mark(ctx, "assignment")
		_fulfill_prepared_pact(ctx)
	ctx.state.campaign.power_routes["pending_feedback"] = {"title": str(Loops.definitions()[action_id].label), "description": result.message + "\n\nDépensé : " + Loops.resources_text(result.cost) + "\nObtenu : " + Loops.resources_text(result.gains) + "\nCorruption : +%d" % int(result.corruption)}
	Refuge.log_entry(ctx, str(Loops.definitions()[action_id].label), result.message)
	ctx.save_requested.emit()
	return result

static func acknowledge(ctx: ContextType) -> void:
	if ctx.state.campaign.get("power_routes", {}).get("pending_feedback", {}).is_empty(): return
	ctx.state.campaign.power_routes.erase("pending_feedback")
	ctx.save_requested.emit()

static func record_expedition(ctx: ContextType, run: Dictionary) -> void:
	# Le combat garde son vrai runtime. Cette frontière ne crédite aucun butin.
	ensure(ctx)
	if not bool(run.get("tools_found", false)) or Objectives.completed(ctx.state.campaign.power_routes): return
	var resolution := Resolution.new()
	resolution.method = "combat"
	resolution.consequences = "Vous avez vaincu les gardiens et rapporté les outils. Le refuge s’ouvre ; les survivants raconteront l’assaut."
	var mana := 0
	for floor_data in run.get("floors", []):
		for room in floor_data.get("rooms", []): mana += int(room.get("battle", {}).get("mana_spent", 0))
	resolution.cost = {"mana": mana}
	resolution.relations = {"gallery_wardens": -4}
	resolution.future_events = ["survivors_of_assault"]
	Objectives.resolve(ctx.state.campaign.power_routes, resolution)
	ctx.state.campaign.power_routes.progress["combat"] = int(ctx.state.campaign.power_routes.progress.get("combat", 0)) + 1
	ctx.state.campaign.power_routes.warden_relation = -4
	ctx.state.campaign.power_routes.future_events.append("survivors_of_assault")
	_fulfill_prepared_pact(ctx)

static func _fulfill_prepared_pact(ctx: ContextType) -> void:
	var pact_id := str(ctx.state.campaign.power_routes.get("pact_id", ""))
	if not pact_id.is_empty(): ctx.pacts.fulfill_pact_requirement(pact_id, "secure_galleries")

static func support_action(action_id: String) -> String:
	var route: String = str(Loops.definitions().get(action_id, {}).get("route", ""))
	return str({"espionage": "espionner", "diplomacy": "diplomatie", "command": "attaquer", "craft": "fortifier"}.get(route, ""))

static func action_stats(ctx: ContextType, action_id: String) -> Dictionary:
	var stats := ctx.state.stats.duplicate(true)
	stats.merge(CharacterService.new(ctx).get_fiche_complete().get("secondary_stats", {}), true)
	var action := support_action(action_id)
	var stat: String = str({"espionner": "espionnage", "diplomatie": "diplomatie", "attaquer": "commandement", "fortifier": "artisanat"}.get(action, ""))
	if not stat.is_empty(): stats[stat] = int(stats.get(stat, 8)) + Planner.new(ctx).support_bonus(action)
	return stats
