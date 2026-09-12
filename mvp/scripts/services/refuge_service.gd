## Règles permanentes du refuge sur état et dépendances injectés.
extends RefCounted

const ContextType = preload("res://scripts/services/clan_service_context.gd")
const Actions = preload("res://scripts/services/clan_action_service.gd")
const Population = preload("res://scripts/services/clan_population_service.gd")
const CharacterService = preload("res://scripts/services/clan_character_service.gd")
const Planner = preload("res://scripts/services/pnj_daily_planner_service.gd")


const PnjDailyPlannerServiceClass = preload("res://scripts/services/pnj_daily_planner_service.gd")

const BUILDINGS := {
	"granary": {"name": "Grenier", "cost": {"bois": 6}, "production": {"nourriture": 4}, "benefit": "+4 nourriture par journée", "requires": ""},
	"walls": {"name": "Palissade", "cost": {"pierre": 6}, "production": {"reputation": 1}, "benefit": "+1 réputation par journée", "requires": ""},
	"workshop": {"name": "Atelier", "cost": {"bois": 8, "fer": 6}, "production": {"fer": 2}, "benefit": "+2 fer par journée ; ouvre la forge", "requires": "salvage"},
	"forge": {"name": "Forge ancestrale", "cost": {"fer": 12, "pierre": 8}, "production": {"fer": 4}, "benefit": "+4 fer par journée", "requires": "workshop"},
}
const COMPANIONS := [
	{"id": "pnj_kael", "nom": "Kael", "role": "garde", "stats": {"force": 14, "magie": 8, "espionnage": 10, "artisanat": 9, "diplomatie": 10, "commandement": 13}},
]

static func initialize(ctx: ContextType) -> void:
	if not ctx.state.campaign.is_empty():
		return
	ctx.state.campaign = {"version": 2, "intro_index": 0, "intro_done": true, "initial_tutorial_done": false, "milestones": [], "buildings": {}, "journal": [], "hints_seen": [], "help_mode": 0, "run": {}, "visibility": 0}
	# Réserves propres à une nouvelle campagne, jamais appliquées à un ancien slot.
	ctx.economy.pay(ctx, {"or": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "or") - 40), "soldats": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "soldats")), "mana": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "mana") - 24), "nourriture": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "nourriture") - 12), "bois": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "bois") - 8), "fer": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "fer") - 2), "pierre": maxi(0, ctx.economy.get_resource(ctx.state.ressources, "pierre") - 8), "essence": ctx.economy.get_resource(ctx.state.ressources, "essence")})
	ctx.state.ressources_par_tour = {"or": 6, "soldats": 0, "mana": 4, "reputation": 0, "renseignements": 0, "bois": 2, "fer": 0, "pierre": 2, "nourriture": 2, "essence": 0}
	ctx.state.pnj_gestion["roster"] = []
	for person in COMPANIONS:
		Population.new(ctx).ajouter_pnj_gere(person.id, person.nom, "scenario", person.role, 2, person.stats)
	log_entry(ctx, "La Brèche-Sèche", "Kael pose deux couvertures près du foyer. Il n’y a personne d’autre. « Avant de relever ces murs, nous devons nous assurer que vous tiendrez debout. »")
	ctx.save_requested.emit()

static func has(ctx: ContextType, milestone: String) -> bool:
	return milestone in ctx.state.campaign.get("milestones", [])

static func mark(ctx: ContextType, milestone: String) -> void:
	var milestones: Array = ctx.state.campaign.get("milestones", [])
	if milestone not in milestones:
		milestones.append(milestone)
	ctx.state.campaign["milestones"] = milestones

static func log_entry(ctx: ContextType, title: String, body: String) -> void:
	ctx.state.campaign["last_feedback"] = body
	var journal: Array = ctx.state.campaign.get("journal", [])
	journal.append({"title": title, "text": body})
	ctx.state.campaign["journal"] = journal

static func building_reason(ctx: ContextType, id: String) -> String:
	if not BUILDINGS.has(id):
		return "Infrastructure inconnue."
	if bool(ctx.state.campaign.get("buildings", {}).get(id, false)):
		return "En service"
	var requirement: String = BUILDINGS[id].requires
	if requirement == "salvage" and not has(ctx, "salvage"):
		return "Retrouver les outils dans les galeries."
	if requirement == "workshop" and not bool(ctx.state.campaign.get("buildings", {}).get("workshop", false)):
		return "Restaurer l’atelier."
	if Actions.action_used(ctx):
		return "La décision de cette demi-journée est déjà prise."
	if not ctx.economy.can_pay(ctx.state.ressources, BUILDINGS[id].cost):
		return "Ressources insuffisantes : " + resources_text(BUILDINGS[id].cost)
	return ""

static func repair(ctx: ContextType, id: String, person_id: String) -> String:
	var reason := building_reason(ctx, id)
	if not reason.is_empty():
		return reason
	var person := find_person(ctx, person_id)
	if person.is_empty() or str(person.get("etat", "")) != "disponible":
		return "Choisissez une personne disponible."
	# Le soutien utilise le calcul canonique des affectations, sans bonus inventé.
	var assigned: Dictionary = Population.new(ctx).assigner_pnj_support_journee(person_id, "fortifier")
	if not bool(assigned.get("ok", false)):
		return "Cette personne est déjà affectée."
	var support: int = Planner.new(ctx).consume_support("fortifier")
	var cost: Dictionary = BUILDINGS[id].cost.duplicate(true)
	# Le soutien économise du matériau de réparation, sans créer de ressources.
	var material: String = "bois" if cost.has("bois") else "pierre"
	if cost.has(material): cost[material] = maxi(1, int(cost[material]) - support)
	ctx.economy.pay(ctx, cost)
	Actions.mark_used(ctx)
	var buildings: Dictionary = ctx.state.campaign.get("buildings", {})
	buildings[id] = true
	ctx.state.campaign["buildings"] = buildings
	ctx.state.campaign["visibility"] = int(ctx.state.campaign.get("visibility", 0)) + 1
	mark(ctx, "govern")
	mark(ctx, "assignment")
	if id == "workshop":
		mark(ctx, "rebuild")
	var message := "%s restaure %s. Soutien à la fortification : +%d (artisanat %d, commandement %d, niveau %d). Coût : %s. %s. La personne reste affectée jusqu’au rapport de journée." % [person.nom, BUILDINGS[id].name, support, int(person.stats.get("artisanat", 8)), int(person.stats.get("commandement", 8)), int(person.get("niveau", 1)), resources_text(cost), BUILDINGS[id].benefit]
	log_entry(ctx, "Des murs qui tiennent", message + "\nKael : « Cette fumée se verra depuis la route. Il faudra en tenir compte. »")
	ctx.save_requested.emit()
	return message

static func prioritize_galleries(ctx: ContextType) -> String:
	if has(ctx, "govern") or Actions.action_used(ctx):
		return "La priorité est déjà fixée."
	Actions.mark_used(ctx)
	mark(ctx, "govern")
	log_entry(ctx, "Les galeries d’abord", "Vous laissez le grenier et les remparts en ruine. Kael : « Nous chercherons de quoi réparer. Mais cette nuit, nous dormirons loin du mur nord. »")
	ctx.save_requested.emit()
	return "Les galeries deviennent la priorité. Préparez une équipe."

static func social_choice(ctx: ContextType, share: bool) -> String:
	if has(ctx, "social"):
		return "Cette décision a déjà été prise."
	if not has(ctx, "govern"):
		return "Écoutez d’abord le rapport de Kael."
	if share and not ctx.economy.can_pay(ctx.state.ressources, {"nourriture": 2}):
		return "Il manque 2 nourriture. Vous pouvez conserver les rations pour demain."
	if share:
		ctx.economy.pay(ctx, {"nourriture": 2})
		Population.new(ctx).modifier_affinite_pnj("intendant", 2)
	else:
		Population.new(ctx).modifier_affinite_pnj("intendant", -1)
	mark(ctx, "social")
	var message := "Vous partagez deux rations avec Kael. Affinité de l’intendance : +2. « Je peux veiller une nuit de plus. Mais promettez-moi de vous reposer. »" if share else "Vous conservez les rations pour demain. Affinité de l’intendance : -1. Kael : « Je comprends. Mais votre corps a déjà payé assez cher. »"
	log_entry(ctx, "Deux personnes près du feu", message)
	ctx.state.campaign["initial_tutorial_done"] = true
	ctx.save_requested.emit()
	return message

static func find_person(ctx: ContextType, id: String) -> Dictionary:
	for person in Population.new(ctx).get_pnj_gestion_state().get("roster", []):
		if str(person.get("id", "")) == id:
			return person
	return {}

static func recover(ctx: ContextType, id: String) -> String:
	var person := find_person(ctx, id)
	if str(person.get("etat", "")) != "blesse":
		return "Cette personne n’a pas besoin de soins."
	var planner := Planner.new(ctx)
	var cost := {"nourriture": 2, "mana": maxi(0, 2 - planner.support_bonus("recuperer"))}
	if not ctx.economy.can_pay(ctx.state.ressources, cost):
		return "Soins : %s nécessaires. Les blessés récupèrent aussi à la prochaine aube." % resources_text(cost)
	planner.consume_support("recuperer")
	ctx.economy.pay(ctx, cost)
	set_person_state(ctx, id, "disponible")
	log_entry(ctx, "Le prix du retour", "%s a reçu des soins et peut repartir. Coût : %s." % [person.nom, resources_text(cost)])
	ctx.save_requested.emit()
	return "Soins terminés."


static func set_person_state(ctx: ContextType, id: String, state: String) -> void:
	for person in ctx.state.pnj_gestion.get("roster", []):
		if str(person.get("id", "")) == id:
			person["etat"] = state

static func dawn(ctx: ContextType) -> void:
	if ctx.state.campaign.is_empty():
		return
	var gains := {}
	for id in BUILDINGS:
		if bool(ctx.state.campaign.get("buildings", {}).get(id, false)):
			for resource in BUILDINGS[id].production:
				gains[resource] = int(gains.get(resource, 0)) + int(BUILDINGS[id].production[resource])
	ctx.economy.gain_state(ctx, gains)
	for person in ctx.state.pnj_gestion.get("roster", []):
		if str(person.get("etat", "")) == "blesse":
			person["etat"] = "disponible"
	# Les conséquences de combat durent jusqu’aux soins ou au repos de la nuit.

static func study_relic(ctx: ContextType, _attune: bool = false) -> String:
	if not has(ctx, "rebuild") or has(ctx, "soul"):
		return "L’atelier doit être restauré et la relique encore intacte."
	mark(ctx, "soul")
	log_entry(ctx, "Une signature impossible", "La relique reconnaît votre sang, puis indique deux présences. Kael enveloppe le métal. « Nous n’y toucherons pas davantage aujourd’hui. »\nArchitecture de l’Âme : instable. L’anomalie empêche toute assimilation.\nSurvivre, comprendre votre passé et reconstruire la Brèche-Sèche.")
	ctx.save_requested.emit()
	return "L’analyse reste incomplète. La relique est conservée dans les archives."

static func resources_text(values: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in values:
		if int(values[key]) == 0: continue
		parts.append("%d %s" % [int(values[key]), str(key)])
	return ", ".join(parts)

static func intro_choice(ctx: ContextType, scene_id: String, choice: Dictionary) -> void:
	var key := "intro_" + scene_id
	if has(ctx, key):
		return
	ctx.economy.gain_state(ctx, choice.get("gains", {}))
	mark(ctx, key)
	log_entry(ctx, str(choice.get("label", "La fuite")), str(choice.get("consequence", "")))
	ctx.save_requested.emit()

static func purify_character(ctx: ContextType, character_id: String) -> Dictionary:
	var run: Dictionary = ctx.state.campaign.get("run", {})
	if not run.is_empty() and not bool(run.get("returned", false)):
		return {"ok": false, "message": "La purification demande de revenir au refuge."}
	var service: RefCounted = ctx.corruption
	if not service.has_character(character_id) or service.get_corruption_level(character_id) <= 0:
		return {"ok": false, "message": "Aucune corruption à purifier."}
	var cost := {"mana": 4, "nourriture": 1}
	if not ctx.economy.can_pay(ctx.state.ressources, cost): return {"ok": false, "message": "Purification : 4 mana et 1 nourriture nécessaires."}
	var result: Dictionary = service.cleanse(character_id, 10.0)
	if not bool(result.get("ok", false)): return result
	ctx.economy.pay(ctx, cost)
	var message := "Purification : %.1f points dissipés. Coût : 4 mana, 1 nourriture." % -float(result.get("delta", 0.0))
	if not ctx.state.campaign.is_empty(): log_entry(ctx, "Retrouver son équilibre", message)
	ctx.save_requested.emit()
	result["message"] = message
	return result
