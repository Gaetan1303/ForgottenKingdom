## DTO metier pour transporter les choix de creation de personnage.
class_name CharacterCreationContext
extends RefCounted

var nom_personnage: String = ""
var nom_clan: String = ""
var classe_id: String = ""

var genre: String = ""
var apparence: String = ""
var portrait: Dictionary = {}

var pouvoir_magique: String = ""
var pouvoir_magique_id: String = ""
var archetype_pathfinder: String = ""

var don: String = ""
var don_id: String = ""
var competence: String = ""
var competence_id: String = ""

var equipement_depart: String = ""
var equipement_depart_id: String = ""

var feats: Array = []
var fiche_complete: Dictionary = {}
var fiche_stats: Dictionary = {}
var fiche_points_restants: int = 0


func to_profile(traits_gameplay: Dictionary, magie_pactes_enabled: bool) -> Dictionary:
	return {
		"genre": genre,
		"apparence": apparence,
		"portrait": portrait.duplicate(true),
		"pouvoir_magique": pouvoir_magique,
		"pouvoir_magique_id": pouvoir_magique_id,
		"archetype_pathfinder": archetype_pathfinder,
		"don": don,
		"don_id": don_id,
		"competence": competence,
		"competence_id": competence_id,
		"equipement_depart": equipement_depart,
		"equipement_depart_id": equipement_depart_id,
		"feats": feats.duplicate(true),
		"magie_pactes": magie_pactes_enabled,
		"traits_gameplay": traits_gameplay,
		"fiche_complete": fiche_complete.duplicate(true),
	}
