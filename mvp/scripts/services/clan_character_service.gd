## Profil, traits, progression et âme du héros. L'état est injecté ; les
## notifications de sauvegarde et de fin sont traitées par l'orchestrateur.
class_name ClanCharacterService
extends RefCounted
const ContextType = preload("res://scripts/services/clan_service_context.gd")
const StatDefsClass = preload("res://scripts/data/stat_defs.gd")
const CharacterBuildServiceClass = preload("res://scripts/data/character_build_service.gd")
const FKHelpers = preload("res://scripts/utils/fk_helpers.gd")
var context: ContextType
func _init(p_context: ContextType) -> void:
	context = p_context

func get_traits_gameplay() -> Dictionary:
	return (context.state.profil_personnage.get("traits_gameplay", {}) as Dictionary).duplicate(true)

func get_bonus_score_action(action_id: String) -> int:
	var traits := get_traits_gameplay()
	var caps := _get_traits_caps()
	var map_bonus := traits.get("bonus_score_actions", {}) as Dictionary
	var cap := int(caps.get("bonus_per_action_max", 3))
	return clampi(int(map_bonus.get(action_id, 0)), -cap, cap)

func appliquer_passifs_nuit() -> String:
	var traits := get_traits_gameplay()
	var caps := _get_traits_caps()
	var details: Array[String] = []

	var regen_ame := clampi(int(traits.get("night_soul_regen", 0)), 0, int(caps.get("night_soul_regen", 4)))
	if regen_ame > 0:
		context.state.barre_ame = clampi(context.state.barre_ame + regen_ame, 0, 100)
		details.append("Ame +%d" % regen_ame)

	var rep_gain := clampi(int(traits.get("night_reputation_gain", 0)), 0, int(caps.get("night_reputation_gain", 2)))
	if rep_gain > 0:
		context.economy.gain_state(context, {"reputation": rep_gain})
		details.append("Reputation +%d" % rep_gain)

	if details.is_empty():
		return ""
	return "Passifs de nuit: %s" % FKHelpers.join_array(details, ", ")

func get_resume_traits_actifs() -> String:
	var traits := get_traits_gameplay()
	if traits.is_empty():
		return "Traits actifs: aucun"

	var parts: Array[String] = []
	var mana_reduc := int(traits.get("mana_cost_reduction_pct", 0))
	if mana_reduc > 0:
		parts.append("Rituels -%d%% mana" % mana_reduc)

	var sold_reduc := int(traits.get("soldats_cost_reduction_attaquer_pct", 0))
	if sold_reduc > 0:
		parts.append("Attaquer -%d%% soldats" % sold_reduc)

	var regen_ame := int(traits.get("night_soul_regen", 0))
	if regen_ame > 0:
		parts.append("Nuit: Ame +%d" % regen_ame)

	var rep_nuit := int(traits.get("night_reputation_gain", 0))
	if rep_nuit > 0:
		parts.append("Nuit: Reputation +%d" % rep_nuit)

	var map_bonus := traits.get("bonus_score_actions", {}) as Dictionary
	for action_id in map_bonus.keys():
		var val := int(map_bonus[action_id])
		if val != 0:
			parts.append("%s %+d" % [str(action_id), val])

	if parts.is_empty():
		return "Traits actifs: aucun effet chiffré"
	return "Traits actifs: %s" % FKHelpers.join_array(parts, " | ")

func _get_traits_caps() -> Dictionary:
	var loader: Object = context.data_loader
	if loader == null:
		return {}
	var traits_cfg: Dictionary = loader.get_character_traits()
	return (traits_cfg.get("caps", {}) as Dictionary).duplicate(true)

func get_profil_personnage() -> Dictionary:
	return context.state.profil_personnage.duplicate(true)

func get_fiche_complete() -> Dictionary:
	_ensure_fiche_complete()
	return (context.state.profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)

func get_personnage_niveau() -> int:
	_ensure_fiche_complete()
	var fiche := context.state.profil_personnage.get("fiche_complete", {}) as Dictionary
	return maxi(1, int(fiche.get("niveau", 1)))

func get_personnage_points_restants() -> int:
	_ensure_fiche_complete()
	var fiche := context.state.profil_personnage.get("fiche_complete", {}) as Dictionary
	return maxi(0, int(fiche.get("points_restants", 0)))

func get_personnage_feats() -> Array:
	return (context.state.profil_personnage.get("feats", []) as Array).duplicate(true)

func get_personnage_portrait_path() -> String:
	var portrait := context.state.profil_personnage.get("portrait", {}) as Dictionary
	return str(portrait.get("path", ""))

func set_personnage_portrait(payload: Dictionary, do_save: bool = false) -> void:
	if payload == null:
		return
	context.state.profil_personnage["portrait"] = (payload as Dictionary).duplicate(true)
	if do_save:
		context.save_requested.emit()

func get_personnage_experience() -> int:
	if context.state.fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	return int(context.state.fiche_hero.get("experience", 0))

func get_personnage_xp_for_next_level() -> int:
	if context.state.fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	var lvl := int(context.state.fiche_hero.get("niveau", 1))
	return 100 * lvl

func is_personnage_xp_full() -> bool:
	return get_personnage_experience() >= get_personnage_xp_for_next_level()

func apply_profile_sheet_update(stats_update: Dictionary, points_remaining: int, feats: Array = []) -> void:
	print("ClanManager.apply_profile_sheet_update: called; stats_update=", JSON.stringify(stats_update), " points_remaining=", points_remaining, " feats=", JSON.stringify(feats))
	# Store raw character stats (sanitized to character bounds)
	var raw_stats: Dictionary = StatDefsClass.sanitize_stats(
		stats_update,
		StatDefsClass.CHARACTER_MIN_STAT,
		StatDefsClass.CHARACTER_MAX_STAT,
		StatDefsClass.CHARACTER_MIN_STAT
	)

	_ensure_fiche_complete()
	var fiche := (context.state.profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	fiche["points_restants"] = maxi(0, int(points_remaining))
	fiche["stats_brutes"] = raw_stats.duplicate(true)
	context.state.profil_personnage["fiche_complete"] = fiche
	print("ClanManager.apply_profile_sheet_update: stored fiche_complete=", JSON.stringify(fiche))

	if not feats.is_empty():
		context.state.profil_personnage["feats"] = feats.duplicate(true)

	# Recompute clan-level stats (final values) from class, raw stats and feats
	var loader: Object = context.data_loader
	if loader == null:
		return
	var class_stats_bonus: Dictionary = {}
	if context.state.classe != "":
		# Get class data from centralized GameDataLoader
		var class_entry: Dictionary = loader.get_class_by_id(context.state.classe)
		if class_entry and not class_entry.is_empty():
			class_stats_bonus = class_entry.get("stats_bonus", {}) as Dictionary

	# Aggregate flat stat bonuses from feats through the canonical loader API.
	# feats.json is namespaced under "dons"/"capacites", so direct root lookup is invalid.
	var feats_bonus_stats: Dictionary = {}
	var current_feats: Array = context.state.profil_personnage.get("feats", []) as Array
	for f in current_feats:
		var fdef: Dictionary = loader.get_feat(str(f))
		var eff := (fdef.get("effects", {}) as Dictionary)
		var stats_eff := (eff.get("stats", {}) as Dictionary)
		for sk in stats_eff.keys():
			feats_bonus_stats[sk] = int(feats_bonus_stats.get(sk, 0)) + int(stats_eff[sk])

	# Compute final stats using CharacterBuildService
	var final_stats: Dictionary = CharacterBuildServiceClass.compute_final_stats(
		class_stats_bonus,
		raw_stats,
		{},
		{},
		feats_bonus_stats
	)

	# Persist final stats into clan-level `stats` used by other systems
	for key in StatDefsClass.STAT_KEYS:
		context.state.stats[key] = int(final_stats.get(key, 0))

	_sanitizer_stats()

	# Re-calculer et appliquer les effets dérivés des feats pour persistance et cohérence
	_compute_and_apply_profil_effects(context.state.profil_personnage, true)

	context.save_requested.emit()

func level_up_personnage(points_awarded: int = 10) -> Dictionary:
	_ensure_fiche_complete()
	var fiche := (context.state.profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	var current_lvl := maxi(1, int(fiche.get("niveau", 1)))
	fiche["niveau"] = current_lvl + 1
	fiche["points_restants"] = maxi(0, int(fiche.get("points_restants", 0))) + maxi(0, points_awarded)
	context.state.profil_personnage["fiche_complete"] = fiche
	context.save_requested.emit()
	return {
		"ok": true,
		"niveau": int(fiche.get("niveau", 1)),
		"points_restants": int(fiche.get("points_restants", 0)),
	}

func lancer_de(faces: int = 20) -> int:
	return context.rng.randi_range(1, faces)

func calculer_score_action(stat_principale: String, stat_secondaire: String = "") -> int:
	var score := int(context.state.stats.get(stat_principale, 5))
	if stat_secondaire != "":
		score += int(context.state.stats.get(stat_secondaire, 5))
	score += lancer_de(20)
	return score

func _sanitizer_stats() -> void:
	# Protège la boucle de gameplay contre une sauvegarde corrompue.
	context.state.stats = StatDefsClass.sanitize_stats(context.state.stats, StatDefsClass.CLAN_MIN_STAT, StatDefsClass.CLAN_MAX_STAT, 5)

	for cle in ["vigueur", "esprit", "presence", "discipline"]:
		var v := int(context.state.caracteristiques_hero.get(cle, 10))
		context.state.caracteristiques_hero[cle] = clampi(v, 1, 30)

	for cle in ["stabilite", "influence", "logistique", "autorite"]:
		var s := int(context.state.stats_clan.get(cle, 5))
		context.state.stats_clan[cle] = clampi(s, 1, 20)

func _compute_and_apply_profil_effects(profil: Dictionary, do_save: bool = false) -> void:
	if profil == null:
		return
	# Eviter double-application
	if bool(profil.get("computed_effects_applied", false)):
		return
	var total_pv_bonus := 0
	var total_mana_bonus := 0
	var loader: Object = context.data_loader
	if loader == null:
		return
	if profil.has("feats") and (profil.get("feats") is Array):
		for f in (profil.get("feats") as Array):
			var fid := str(f)
			var fdef: Dictionary = loader.get_feat(fid)
			var eff := fdef.get("effects", {}) as Dictionary
			if eff.has("pv_bonus"):
				total_pv_bonus += int(eff.get("pv_bonus", 0))
			if eff.has("mana_bonus"):
				total_mana_bonus += int(eff.get("mana_bonus", 0))

	# Appliquer PV bonus à la caractéristique 'vigueur' et à la fiche_hero si initialisée
	if total_pv_bonus != 0:
		context.state.caracteristiques_hero["vigueur"] = int(context.state.caracteristiques_hero.get("vigueur", 10)) + total_pv_bonus
		if context.state.fiche_hero.has("caracteristiques"):
			var fic := context.state.fiche_hero.duplicate(true)
			var car := (fic.get("caracteristiques", context.state.caracteristiques_hero) as Dictionary).duplicate(true)
			car["vigueur"] = int(car.get("vigueur", int(context.state.caracteristiques_hero.get("vigueur", 10))))
			fic["caracteristiques"] = car
			context.state.fiche_hero = fic

	# Appliquer mana bonus aux ressources initiales
	if total_mana_bonus != 0:
		context.state.ressources["mana"] = int(context.state.ressources.get("mana", 0)) + total_mana_bonus

	# Persister un résumé des effets pour traçabilité
	profil["computed_effects"] = {"pv_bonus": total_pv_bonus, "mana_bonus": total_mana_bonus}
	profil["computed_effects_applied"] = true
	# Écriture optionnelle : si do_save, sauvegarder le nouveau flag et résumé
	if do_save:
		context.save_requested.emit()

func donner_experience(amount: int) -> void:
	if amount <= 0:
		return
	if context.state.fiche_hero.is_empty():
		_initialiser_fiches_personnage_et_domaine()
	var current_xp := int(context.state.fiche_hero.get("experience", 0))
	var current_lvl := int(context.state.fiche_hero.get("niveau", 1))
	current_xp += int(amount)
	context.state.fiche_hero["experience"] = current_xp
	_check_level_up()
	# Notify listeners that experience changed
	context.resources_changed.emit()

func _check_level_up() -> void:
	var lvl := int(context.state.fiche_hero.get("niveau", 1))
	var xp := int(context.state.fiche_hero.get("experience", 0))
	var required := 100 * lvl
	var leveled := false
	while xp >= required:
		xp -= required
		lvl += 1
		leveled = true
		required = 100 * lvl
	context.state.fiche_hero["niveau"] = lvl
	context.state.fiche_hero["experience"] = xp
	if leveled:
		context.level_changed.emit(lvl)
		context.save_requested.emit()

func _forcer_magie_pactes() -> void:
	context.state.profil_personnage["magie_pactes"] = true
	var competences: Array = (context.state.profil_personnage.get("competences_depart", []) as Array).duplicate(true)
	if not competences.has("Magie des Pactes"):
		competences.append("Magie des Pactes")
	context.state.profil_personnage["competences_depart"] = competences

func _initialiser_fiches_personnage_et_domaine() -> void:
	context.state.fiche_hero = {
		"nom": context.state.nom_personnage,
		"classe": context.state.classe,
		"profil": context.state.profil_personnage.duplicate(true),
		"caracteristiques": context.state.caracteristiques_hero.duplicate(true),
		"stats_hero": context.state.stats.duplicate(true),
		"niveau": 1,
		"experience": 0,
		"stats_clan": context.state.stats_clan.duplicate(true),
	}

	context.state.fiches_domaine = {
		"forgeron": {
			"nom": "Forgeron",
			"niveau": 1,
			"specialite": "Armes et armures",
			"actif": false,
			"affinite": int(context.state.affinites_pnj.get("forgeron", 0)),
		},
		"alchimiste": {
			"nom": "Alchimiste",
			"niveau": 1,
			"specialite": "Potions et explosifs",
			"actif": false,
			"affinite": int(context.state.affinites_pnj.get("alchimiste", 0)),
		},
		"intendant": {
			"nom": "Intendant",
			"niveau": 1,
			"specialite": "Logistique et taxes",
			"actif": false,
			"affinite": int(context.state.affinites_pnj.get("intendant", 0)),
		},
		"arcaniste": {
			"nom": "Arcaniste",
			"niveau": 1,
			"specialite": "Rituels et pactes",
			"actif": false,
			"affinite": int(context.state.affinites_pnj.get("arcaniste", 0)),
		},
	}

func _ensure_fiche_complete() -> void:
	var fiche := (context.state.profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	if fiche.is_empty():
		fiche = {
			"niveau": 1,
			"points_restants": 0,
		}
	if not fiche.has("niveau"):
		fiche["niveau"] = 1
	if not fiche.has("points_restants"):
		fiche["points_restants"] = 0
	fiche["niveau"] = maxi(1, int(fiche.get("niveau", 1)))
	fiche["points_restants"] = maxi(0, int(fiche.get("points_restants", 0)))
	context.state.profil_personnage["fiche_complete"] = fiche

func _normalize_loaded_character_sheet() -> void:
	var fiche: Dictionary = (context.state.profil_personnage.get("fiche_complete", {}) as Dictionary).duplicate(true)
	if fiche.is_empty():
		return
	var loaded_scores: Dictionary = fiche.get("character_scores", fiche.get("stats_brutes", {})) as Dictionary
	if loaded_scores.is_empty():
		return
	var canonical_scores: Dictionary = StatDefsClass.sanitize_stats(loaded_scores, 1, 30, StatDefsClass.CHARACTER_MIN_STAT)
	fiche["stats_brutes"] = canonical_scores.duplicate(true)
	fiche["character_scores"] = canonical_scores.duplicate(true)
	fiche["modifiers"] = CharacterBuildServiceClass.build_modifiers(canonical_scores)
	fiche["derived_stats"] = CharacterBuildServiceClass.build_derived_stats(fiche["modifiers"] as Dictionary)
	context.state.profil_personnage["fiche_complete"] = fiche

func magie_pactes_active() -> bool:
	return bool(context.state.profil_personnage.get("magie_pactes", false))

func utiliser_forme_dragon(cout_ame: int = 25) -> bool:
	if context.state.barre_ame <= 0:
		return false
	context.state.barre_ame = maxi(0, context.state.barre_ame - cout_ame)
	context.state.forme_dragon_utilisee += 1
	context.resources_changed.emit()
	if context.state.barre_ame <= 0:
		context.soul_depleted.emit()
	return true
