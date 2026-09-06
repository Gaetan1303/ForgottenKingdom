## Règles permanentes du refuge. État exclusivement détenu et sauvegardé par ClanManager.
extends RefCounted

const BUILDINGS := {
	"granary": {"name": "Grenier", "cost": {"bois": 6}, "production": {"nourriture": 4}, "benefit": "+4 nourriture par journée", "requires": ""},
	"walls": {"name": "Palissade", "cost": {"pierre": 6}, "production": {"reputation": 1}, "benefit": "+1 réputation par journée", "requires": ""},
	"workshop": {"name": "Atelier", "cost": {"bois": 8, "fer": 6}, "production": {"fer": 2}, "benefit": "+2 fer par journée ; ouvre la forge", "requires": "salvage"},
	"forge": {"name": "Forge ancestrale", "cost": {"fer": 12, "pierre": 8}, "production": {"fer": 4}, "benefit": "+4 fer par journée", "requires": "workshop"},
}
const COMPANIONS := [
	{"id": "pnj_kael", "nom": "Kael", "role": "garde", "stats": {"force": 14, "magie": 8, "espionnage": 10, "artisanat": 9, "diplomatie": 10, "commandement": 13}},
]

static func initialize(cm: Node) -> void:
	if not cm.campaign.is_empty():
		return
	cm.campaign = {"version": 2, "intro_index": 0, "intro_done": true, "initial_tutorial_done": false, "milestones": [], "buildings": {}, "journal": [], "hints_seen": [], "help_mode": 0, "run": {}, "visibility": 0}
	# Réserves propres à une nouvelle campagne, jamais appliquées à un ancien slot.
	cm.payer({"or": maxi(0, cm.get_ressource("or") - 40), "soldats": maxi(0, cm.get_ressource("soldats")), "mana": maxi(0, cm.get_ressource("mana") - 24), "nourriture": maxi(0, cm.get_ressource("nourriture") - 12), "bois": maxi(0, cm.get_ressource("bois") - 8), "fer": maxi(0, cm.get_ressource("fer") - 2), "pierre": maxi(0, cm.get_ressource("pierre") - 8), "essence": cm.get_ressource("essence")})
	cm.ressources_par_tour = {"or": 6, "soldats": 0, "mana": 4, "reputation": 0, "renseignements": 0, "bois": 2, "fer": 0, "pierre": 2, "nourriture": 2, "essence": 0}
	cm.pnj_gestion["roster"] = []
	for person in COMPANIONS:
		cm.ajouter_pnj_gere(person.id, person.nom, "scenario", person.role, 2, person.stats)
	log_entry(cm, "La Brèche-Sèche", "Kael pose deux couvertures près du foyer. Il n’y a personne d’autre. « Avant de relever ces murs, nous devons nous assurer que vous tiendrez debout. »")
	cm.sauvegarder()

static func has(cm: Node, milestone: String) -> bool:
	return milestone in cm.campaign.get("milestones", [])

static func mark(cm: Node, milestone: String) -> void:
	var milestones: Array = cm.campaign.get("milestones", [])
	if milestone not in milestones:
		milestones.append(milestone)
	cm.campaign["milestones"] = milestones

static func log_entry(cm: Node, title: String, body: String) -> void:
	cm.campaign["last_feedback"] = body
	var journal: Array = cm.campaign.get("journal", [])
	journal.append({"title": title, "text": body})
	cm.campaign["journal"] = journal

static func building_reason(cm: Node, id: String) -> String:
	if not BUILDINGS.has(id):
		return "Infrastructure inconnue."
	if bool(cm.campaign.get("buildings", {}).get(id, false)):
		return "En service"
	var requirement: String = BUILDINGS[id].requires
	if requirement == "salvage" and not has(cm, "salvage"):
		return "Retrouver les outils dans les galeries."
	if requirement == "workshop" and not bool(cm.campaign.get("buildings", {}).get("workshop", false)):
		return "Restaurer l’atelier."
	if cm.action_deja_utilisee_pour_moment():
		return "La décision de cette demi-journée est déjà prise."
	if not cm.peut_payer(BUILDINGS[id].cost):
		return "Ressources insuffisantes : " + resources_text(BUILDINGS[id].cost)
	return ""

static func repair(cm: Node, id: String, person_id: String) -> String:
	var reason := building_reason(cm, id)
	if not reason.is_empty():
		return reason
	var person := find_person(cm, person_id)
	if person.is_empty() or str(person.get("etat", "")) != "disponible":
		return "Choisissez une personne disponible."
	# Le soutien utilise le calcul canonique des affectations, sans bonus inventé.
	var assigned: Dictionary = cm.assigner_pnj_support_journee(person_id, "fortifier")
	if not bool(assigned.get("ok", false)):
		return "Cette personne est déjà affectée."
	var support := PnjDailyPlannerService.new().compute_support_bonus(person, "fortifier")
	cm.payer(BUILDINGS[id].cost)
	cm.marquer_action_utilisee()
	var buildings: Dictionary = cm.campaign.get("buildings", {})
	buildings[id] = true
	cm.campaign["buildings"] = buildings
	cm.campaign["visibility"] = int(cm.campaign.get("visibility", 0)) + 1
	mark(cm, "govern")
	mark(cm, "assignment")
	if id == "workshop":
		mark(cm, "rebuild")
	var message := "%s restaure %s. Soutien à la fortification : +%d (artisanat %d, commandement %d, niveau %d). Coût : %s. %s. La personne reste affectée jusqu’au rapport de journée." % [person.nom, BUILDINGS[id].name, support, int(person.stats.get("artisanat", 8)), int(person.stats.get("commandement", 8)), int(person.get("niveau", 1)), resources_text(BUILDINGS[id].cost), BUILDINGS[id].benefit]
	log_entry(cm, "Des murs qui tiennent", message + "\nKael : « Cette fumée se verra depuis la route. Il faudra en tenir compte. »")
	cm.sauvegarder()
	return message

static func prioritize_galleries(cm: Node) -> String:
	if has(cm, "govern") or cm.action_deja_utilisee_pour_moment():
		return "La priorité est déjà fixée."
	cm.marquer_action_utilisee()
	mark(cm, "govern")
	log_entry(cm, "Les galeries d’abord", "Vous laissez le grenier et les remparts en ruine. Kael : « Nous chercherons de quoi réparer. Mais cette nuit, nous dormirons loin du mur nord. »")
	cm.sauvegarder()
	return "Les galeries deviennent la priorité. Préparez une équipe."

static func social_choice(cm: Node, share: bool) -> String:
	if has(cm, "social"):
		return "Cette décision a déjà été prise."
	if not has(cm, "govern"):
		return "Écoutez d’abord le rapport de Kael."
	if share and not cm.peut_payer({"nourriture": 2}):
		return "Il manque 2 nourriture. Vous pouvez conserver les rations pour demain."
	if share:
		cm.payer({"nourriture": 2})
		cm.modifier_affinite_pnj("intendant", 2)
	else:
		cm.modifier_affinite_pnj("intendant", -1)
	mark(cm, "social")
	var message := "Vous partagez deux rations avec Kael. Affinité de l’intendance : +2. « Je peux veiller une nuit de plus. Mais promettez-moi de vous reposer. »" if share else "Vous conservez les rations pour demain. Affinité de l’intendance : -1. Kael : « Je comprends. Mais votre corps a déjà payé assez cher. »"
	log_entry(cm, "Deux personnes près du feu", message)
	cm.campaign["initial_tutorial_done"] = true
	cm.sauvegarder()
	return message

static func find_person(cm: Node, id: String) -> Dictionary:
	for person in cm.get_pnj_gestion_state().get("roster", []):
		if str(person.get("id", "")) == id:
			return person
	return {}

static func recover(cm: Node, id: String) -> String:
	var person := find_person(cm, id)
	if str(person.get("etat", "")) != "blesse":
		return "Cette personne n’a pas besoin de soins."
	if not cm.peut_payer({"nourriture": 2, "mana": 2}):
		return "Soins : 2 nourriture et 2 mana nécessaires. Les blessés récupèrent aussi à la prochaine aube."
	cm.payer({"nourriture": 2, "mana": 2})
	set_person_state(cm, id, "disponible")
	log_entry(cm, "Le prix du retour", "%s a reçu des soins et peut repartir. Coût : 2 nourriture, 2 mana." % person.nom)
	cm.sauvegarder()
	return "Soins terminés."

static func set_person_state(cm: Node, id: String, state: String) -> void:
	for person in cm.pnj_gestion.get("roster", []):
		if str(person.get("id", "")) == id:
			person["etat"] = state

static func dawn(cm: Node) -> void:
	if cm.campaign.is_empty():
		return
	var gains := {}
	for id in BUILDINGS:
		if bool(cm.campaign.get("buildings", {}).get(id, false)):
			for resource in BUILDINGS[id].production:
				gains[resource] = int(gains.get(resource, 0)) + int(BUILDINGS[id].production[resource])
	cm.gagner(gains)
	for person in cm.pnj_gestion.get("roster", []):
		if str(person.get("etat", "")) == "blesse":
			person["etat"] = "disponible"
	# Les conséquences de combat durent jusqu’aux soins ou au repos de la nuit.

static func study_relic(cm: Node, _attune: bool = false) -> String:
	if not has(cm, "rebuild") or has(cm, "soul"):
		return "L’atelier doit être restauré et la relique encore intacte."
	mark(cm, "soul")
	log_entry(cm, "Une signature impossible", "La relique reconnaît votre sang, puis indique deux présences. Kael enveloppe le métal. « Nous n’y toucherons pas davantage aujourd’hui. »\nArchitecture de l’Âme : instable. L’anomalie empêche toute assimilation.\nSurvivre, comprendre votre passé et reconstruire la Brèche-Sèche.")
	cm.sauvegarder()
	return "L’analyse reste incomplète. La relique est conservée dans les archives."

static func resources_text(values: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in values:
		if int(values[key]) == 0: continue
		parts.append("%d %s" % [int(values[key]), str(key)])
	return ", ".join(parts)

static func intro_choice(cm: Node, scene_id: String, choice: Dictionary) -> void:
	var key := "intro_" + scene_id
	if has(cm, key):
		return
	cm.gagner(choice.get("gains", {}))
	mark(cm, key)
	log_entry(cm, str(choice.get("label", "La fuite")), str(choice.get("consequence", "")))
	cm.sauvegarder()
