## Service d'application: orchestration de la creation de personnage.
## Reutilise les services de regles et de traits sans dependre de l'UI Godot.
class_name CharacterCreationApplicationService
extends RefCounted

const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")
const CharacterTraitsRules = preload("res://scripts/services/character_traits_service.gd")


static func validate_identity(nom_personnage: String, nom_clan: String) -> String:
	if nom_personnage.strip_edges().length() < 2:
		return "Le nom du personnage doit contenir au moins 2 caractères."
	if nom_clan.strip_edges().length() < 2:
		return "Le nom du clan doit contenir au moins 2 caractères."
	return ""


static func validate_for_slide(ctx, slide_index: int) -> String:
	var identity_error := validate_identity(ctx.nom_personnage, ctx.nom_clan)
	if identity_error != "":
		return identity_error
	if slide_index >= 2 and ctx.classe_id == "":
		return "Veuillez choisir une classe avant de continuer."
	return ""


static func build_traits_gameplay(ctx, traits_data: Dictionary) -> Dictionary:
	if traits_data.is_empty():
		return CharacterTraitsRules.default_traits()
	return CharacterTraitsRules.build_traits(traits_data, ctx.don_id, ctx.pouvoir_magique_id, ctx.competence_id)


static func build_profile(ctx, traits_data: Dictionary, magie_pactes_enabled: bool = true) -> Dictionary:
	var traits_gameplay := build_traits_gameplay(ctx, traits_data)
	return ctx.to_profile(traits_gameplay, magie_pactes_enabled)


static func build_starting_competences(classe_data: Dictionary, competence_label: String, magie_pactes_label: String) -> Array:
	var competences: Array = (classe_data.get("competences", []) as Array).duplicate(true)
	var comp := competence_label.strip_edges()
	if not comp.is_empty():
		competences.append(comp)
	if not magie_pactes_label.strip_edges().is_empty():
		competences.append(magie_pactes_label)
	return competences


static func compute_final_stats(ctx, classe_data: Dictionary, feats_defs: Dictionary) -> Dictionary:
	return CharacterCreationRules.compute_final_stats_for_creation(
		classe_data,
		ctx.fiche_stats,
		ctx.competence_id,
		ctx.archetype_pathfinder,
		feats_defs,
		ctx.feats
	)


static func prepare_new_game_payload(
	ctx,
	classe_data: Dictionary,
	traits_data: Dictionary,
	feats_defs: Dictionary,
	magie_pactes_label: String
) -> Dictionary:
	var profile := build_profile(ctx, traits_data, true)
	profile["competences_depart"] = build_starting_competences(
		classe_data,
		str(profile.get("competence", "")),
		magie_pactes_label
	)
	# Valeurs par defaut demandees pour le profil de creation.
	profile["pere_name"] = "Vincent"
	profile["mere_name"] = "Aurys"

	return {
		"profile": profile,
		"stats_finales": compute_final_stats(ctx, classe_data, feats_defs),
	}
