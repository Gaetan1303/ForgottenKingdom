## État canonique du clan. Aucun service, autoload ou règle de résolution.
class_name ClanState
extends RefCounted

var nom_clan:       String     = ""
var clan_id:        String     = ""
var nom_personnage: String     = ""
var classe:         String     = ""
var profil_personnage: Dictionary = {
	"genre": "Homme",
	"apparence": "Vétéran balafré",
	"portrait": {},
	"pouvoir_magique": "Pyromancie",
	"archetype_pathfinder": "Lame jurée (inspiration Guerrier)",
	"don": "Volonté de fer",
	"competence": "Maîtrise martiale",
	"equipement_depart": "Arme lourde + bouclier",
	"magie_pactes": true,
	"competences_depart": ["Magie des Pactes"],
}

var stats: Dictionary = {
	"force": 5,
	"magie": 5,
	"espionnage": 5,
	"artisanat": 5,
	"diplomatie": 5,
	"commandement": 5,
}

var caracteristiques_hero: Dictionary = {
	"vigueur": 10,
	"esprit": 10,
	"presence": 10,
	"discipline": 10,
}

var stats_clan: Dictionary = {
	"stabilite": 5,
	"influence": 5,
	"logistique": 5,
	"autorite": 5,
}

var ressources: Dictionary = {
	"or": 500,
	"soldats": 50,
	"mana": 100,
	"reputation": 10,
	"renseignements": 0,
	"bois": 60,
	"fer": 40,
	"pierre": 30,
	"nourriture": 120,
	"essence": 10,
}

var ressources_par_tour: Dictionary = {
	"or": 120,
	"soldats": 0,
	"mana": 20,
	"reputation": 0,
	"renseignements": 0,
	"bois": 10,
	"fer": 6,
	"pierre": 5,
	"nourriture": 12,
	"essence": 2,
}

var affinites_pnj: Dictionary = {
	"forgeron": 0,
	"alchimiste": 0,
	"intendant": 0,
	"arcaniste": 0,
}

var fiche_hero: Dictionary = {}
var fiches_domaine: Dictionary = {}
# Pool de soldats (micro-gestion): liste d'IDs disponibles et compteur
var _soldat_next_id: int = 1
var _soldats_disponibles: Array = []

var barre_ame: int          = 100
var forme_dragon_utilisee:  int = 0
var tour_actuel: int        = 1
var moment_journee: String  = "jour"
var action_jour_effectuee: bool = false
var action_nuit_effectuee: bool = false
var maisons_nobles: Array   = []
var evenements_declenches: Array = []
var historique_tours: Array = []
var pnj_gestion: Dictionary = {}
## Progression du refuge et expédition : même transaction que ressources et habitants.
var campaign: Dictionary = {}

var daily_phase: String = "matin"
var day_report: String = ""

const SAVE_FIELDS := {
	"nom_clan": "nom_clan",
	"clan_id": "clan_id",
	"nom_personnage": "nom_personnage",
	"classe": "classe",
	"profil_personnage": "profil_personnage",
	"stats": "stats",
	"caracteristiques_hero": "caracteristiques_hero",
	"stats_clan": "stats_clan",
	"ressources": "ressources",
	"ressources_par_tour": "ressources_par_tour",
	"affinites_pnj": "affinites_pnj",
	"fiche_hero": "fiche_hero",
	"fiches_domaine": "fiches_domaine",
	"_soldat_next_id": "soldat_next_id",
	"_soldats_disponibles": "soldats_disponibles",
	"barre_ame": "barre_ame",
	"forme_dragon_utilisee": "forme_dragon_utilisee",
	"tour_actuel": "tour_actuel",
	"moment_journee": "moment_journee",
	"action_jour_effectuee": "action_jour_effectuee",
	"action_nuit_effectuee": "action_nuit_effectuee",
	"maisons_nobles": "maisons_nobles",
	"evenements_declenches": "evenements_declenches",
	"historique_tours": "historique_tours",
	"pnj_gestion": "pnj_gestion",
	"campaign": "campaign",
	"daily_phase": "daily_phase",
	"day_report": "day_report",
}

func export_state() -> Dictionary:
	var data := {}
	for field in SAVE_FIELDS:
		var value: Variant = get(field)
		data[SAVE_FIELDS[field]] = value.duplicate(true) if value is Dictionary or value is Array else value
	return data

func import_state(data: Dictionary) -> void:
	for field in SAVE_FIELDS:
		var key: String = SAVE_FIELDS[field]
		if not data.has(key): continue
		var value: Variant = data[key]
		set(field, value.duplicate(true) if value is Dictionary or value is Array else value)
