extends SceneTree

const Rules = preload("res://scripts/services/character_creation_rules_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var save_system := root.get_node("SaveSystem")
	var clan_manager := root.get_node("ClanManager")
	var game_data_loader := root.get_node("GameDataLoader")
	save_system.set_active_slot("character_stats_roundtrip")

	var purchased_scores := {
		"force": 9,
		"magie": 9,
		"espionnage": 10,
		"artisanat": 11,
		"diplomatie": 9,
		"commandement": 10,
	}
	var spent := 0
	for key in StatDefs.STAT_KEYS:
		spent += int(purchased_scores[key]) - StatDefs.CHARACTER_MIN_STAT
	_check(spent == 10, "la distribution doit utiliser exactement 10 points")

	var class_data := Rules.get_class_data("demon_blade")
	var result: Dictionary = Rules.build_character_result_for_creation(class_data, purchased_scores, "", "", game_data_loader.get_feats(), [])
	var final_scores: Dictionary = result.character_scores
	_check(final_scores == {
		"force": 13,
		"magie": 9,
		"espionnage": 10,
		"artisanat": 11,
		"diplomatie": 9,
		"commandement": 11,
	}, "score de base + bonus explicite + points distribués")
	_check(int(final_scores.artisanat) == 11, "un score 11 doit rester 11")
	_check(int(result.modifiers.artisanat) == 0, "le modificateur de 11 doit rester séparé")

	var profile := {
		"feats": [],
		"fiche_complete": {
			"points_restants": 0,
			"purchased_scores": purchased_scores,
			"stats_brutes": final_scores,
			"character_scores": final_scores,
			"modifiers": result.modifiers,
			"derived_stats": result.derived_stats,
		},
	}
	clan_manager.nouvelle_partie("Aren", "Cendres", "demon_blade", final_scores, profile)
	_check(clan_manager.get_stats() == final_scores, "ClanManager doit conserver les scores validés sans recalcul")
	_check(clan_manager.charger_sauvegarde(), "la sauvegarde doit être rechargeable")
	_check(clan_manager.get_stats() == final_scores, "les scores doivent rester identiques après rechargement")
	var saved_scores: Dictionary = clan_manager.get_fiche_complete().get("character_scores", {})
	_check(saved_scores == final_scores and int(saved_scores.artisanat) == 11, "la fiche canonique doit conserver exactement les scores")

	var feats: Dictionary = game_data_loader.get_feats()
	_check(feats.has("robustesse") and not feats.has("dons") and not feats.has("_meta"), "get_feats doit retourner directement les dons")
	_check(not game_data_loader.get_feat("robustesse").is_empty(), "get_feat doit lire un don par son ID")
	_check(game_data_loader.has_method("get_ability") and not game_data_loader.get_ability("second_souffle").is_empty(), "get_ability doit lire une capacité par son ID")

	if failures.is_empty():
		print("CHARACTER_STATS_ROUNDTRIP_OK")
	else:
		for failure in failures:
			push_error("CHARACTER_STATS_ROUNDTRIP_FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
