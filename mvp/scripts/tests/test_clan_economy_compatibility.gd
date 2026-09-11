extends SceneTree

var _failures: Array[String] = []
var _signals := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var clan = root.get_node("ClanManager")
	clan.ressources_mises_a_jour.connect(func(): _signals += 1)
	clan.ressources = {"or": 10, "mana": 4, "soldats": 3, "custom": 7}
	clan._soldats_disponibles = ["S1", "S2", "S3"]
	clan._soldat_next_id = 4
	_check(clan.peut_payer({"or": 10}) and not clan.peut_payer({"or": 11}), "coût disponible")
	_check(clan.peut_payer({"absent": -1}), "coût signé historique")
	clan.payer({"or": 30, "mana": -2, "absent": 5, "soldats": 2})
	_check(clan.ressources == {"or": 0, "mana": 6, "soldats": 1, "custom": 7, "absent": 0}, "débit sans précondition")
	_check(clan._soldats_disponibles == ["S1"] and _signals == 2, "IDs et signaux du débit")
	clan.gagner({"or": -5, "mana": 3, "custom": 2, "unknown": 10, "soldats": -3})
	_check(clan.ressources == {"or": -5, "mana": 9, "soldats": 1, "custom": 9, "absent": 0}, "gain signé et clés inconnues")
	_check(clan._soldats_disponibles == ["S1"] and _signals == 4, "gain soldats négatif")
	clan.gagner({"soldats": 900})
	_check(clan.ressources.soldats == 600 and clan._soldats_disponibles.size() == 600, "plafond soldats")
	_check(clan._soldats_disponibles[1] == "S4" and clan._soldat_next_id == 603, "continuité des IDs")
	var snapshot: Dictionary = clan.get_ressources()
	snapshot.or = 10000
	_check(clan.get_ressource("or") == -5 and clan.get_ressource("missing", 42) == 42, "lecture isolée")
	clan.ressources_par_tour = {"or": -1, "soldats": 900, "extra": 12}
	clan._sanitizer_ressources()
	_check(clan.ressources.or == 0 and clan.ressources.custom == 9, "normalisation sans perte de champs")
	_check(clan.ressources_par_tour.or == 0 and clan.ressources_par_tour.soldats == 900, "production non plafonnée")
	clan.affinites_pnj = {"forgeron": 50}
	clan.fiches_domaine = {
		"forgeron": {"actif": true, "niveau": 6},
		"alchimiste": {"actif": true, "niveau": 5, "affinite": -100},
		"intendant": {"actif": true, "niveau": 4, "affinite": 100},
		"arcaniste": {"actif": false, "niveau": 20},
	}
	clan.campaign = {}
	var production: Dictionary = clan.get_production_totale({"or": 10, "mana": 3, "extra": 2})
	_check(production.or == 38 and production.mana == 5 and production.fer == 8 and production.pierre == 2 and production.essence == 2 and production.nourriture == 2 and production.extra == 2, "bonus domaines et arrondis")
	clan.campaign = {"active": true}
	clan.ressources_par_tour = {"or": 2}
	_check(clan.get_production_totale({"or": 999}).or == 30, "priorité production de campagne")
	clan.profil_personnage["traits_gameplay"] = {"mana_cost_reduction_pct": 20, "soldats_cost_reduction_attaquer_pct": 10}
	_check(clan.get_action_cout_modifie("recruter", {"mana": 35}).mana == 28, "réduction mana")
	_check(clan.get_action_cout_modifie("attaquer", {"soldats": 10}).soldats == 9, "réduction soldats")
	_check(clan.get_action_cout_modifie("espionner", {"mana": 35}).mana == 35, "action sans réduction")
	# Même format de sauvegarde, y compris pool d'IDs et production.
	clan.sauvegarder()
	var saved: Dictionary = clan.get_ressources()
	var saved_pool: Array = clan._soldats_disponibles.duplicate()
	clan.ressources = {}
	clan._soldats_disponibles = []
	_check(clan.charger_sauvegarde(), "rechargement sauvegarde")
	for key in saved:
		_check(clan.get_ressource(key) == int(saved[key]), "aller-retour ressource %s" % key)
	_check(clan._soldats_disponibles == saved_pool, "aller-retour IDs")
	if _failures.is_empty():
		print("CLAN_ECONOMY_COMPATIBILITY_OK")
	else:
		for failure in _failures:
			push_error(failure)
	quit(0 if _failures.is_empty() else 1)
