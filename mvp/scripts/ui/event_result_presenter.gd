## Normalise les résultats métier pour l'affichage. Ce presenter est pur : il
## n'applique jamais les effets et ne connaît ni ClanManager ni la navigation.
class_name EventResultPresenter
extends RefCounted

const ResourcePathResolver = preload("res://scripts/utils/resource_path_resolver.gd")
const VisualAssetCatalog = preload("res://scripts/ui/visual_asset_catalog.gd")

const EFFECT_LABELS := {
	"or_recupere": "Or gagné", "or_penalite": "Or perdu", "or_perdu": "Or perdu",
	"soldats_gain": "Soldats recrutés", "soldats_bonus": "Soldats gagnés",
	"pertes_soldats_pct": "Pertes en soldats", "soldats_perte_pct": "Pertes en soldats",
	"mana_gain": "Mana récupéré", "reputation_gain": "Réputation gagnée",
	"reputation_perte": "Réputation perdue", "renseignements_gain": "Renseignements gagnés",
	"affinite_pnj_gain": "Affinité PNJ", "pnj_recrute": "PNJ recruté",
	"production_or_bonus": "Production d'Or", "relation_perte": "Relation dégradée",
	"or_partage_par_tour": "Or partagé par tour", "relation": "Relation",
	"defense_bonus_tours": "Défense renforcée", "tours_disponibilite": "Tours de disponibilité",
	"bastion_conquis": "Bastion conquis", "famille_revelee": "Famille révélée",
	"bastions_reveles": "Bastions révélés", "ressources_cible_revelees": "Ressources révélées",
	"detail_chef_revele": "Chef identifié", "alerte_declenchee": "Alerte déclenchée",
	"non_agression": "Accord de non-agression", "ouvre_boutique_speciale": "Boutique spéciale ouverte",
}

const EFFECT_RESOURCES := {
	"or_recupere": "or", "or_penalite": "or", "or_perdu": "or", "production_or_bonus": "or", "or_partage_par_tour": "or",
	"soldats_gain": "soldats", "soldats_bonus": "soldats", "pertes_soldats_pct": "soldats", "soldats_perte_pct": "soldats",
	"mana_gain": "mana", "reputation_gain": "reputation", "reputation_perte": "reputation",
	"renseignements_gain": "renseignements", "relation": "relation", "relation_perte": "relation", "affinite_pnj_gain": "relation",
}

const NEGATIVE_EFFECTS := ["or_penalite", "or_perdu", "pertes_soldats_pct", "soldats_perte_pct", "reputation_perte", "relation_perte"]
const PERCENT_EFFECTS := ["pertes_soldats_pct", "soldats_perte_pct"]
const INTERNAL_EFFECTS := ["soldats_gain_min", "soldats_gain_max", "soldats_soft_cap", "soldats_soft_penalty_step", "soldats_soft_penalty_per_step", "pnj_role"]


static func normalize(raw_result: Dictionary) -> Dictionary:
	var effects_value: Variant = raw_result.get("effects", raw_result.get("effets", {}))
	return {
		"title": str(raw_result.get("title", raw_result.get("titre", "Résultat"))),
		"description": str(raw_result.get("description", raw_result.get("texte", ""))),
		"illustration_path": str(raw_result.get("illustration_path", raw_result.get("illustration", raw_result.get("image", "")))),
		"illustration_kind": str(raw_result.get("illustration_kind", "contain")),
		"effects": normalize_effects(effects_value),
		"severity": str(raw_result.get("severity", "neutral")),
		"effects_applied": bool(raw_result.get("effects_applied", true)),
	}


static func normalize_effects(raw_effects: Variant) -> Array:
	if raw_effects is Array:
		return _normalize_effect_array(raw_effects as Array)
	if not (raw_effects is Dictionary):
		return []
	var result: Array = []
	for raw_key in (raw_effects as Dictionary).keys():
		var key := str(raw_key)
		if key in INTERNAL_EFFECTS or key == "soldats_gain_formule" and (raw_effects as Dictionary).has("soldats_gain"):
			continue
		result.append(_effect_from_pair(key, (raw_effects as Dictionary)[raw_key]))
	return result


static func icon_for_resource(resource_id: String) -> String:
	var path := str(VisualAssetCatalog.RESOURCE_ICONS.get(resource_id, ""))
	if path.is_empty():
		push_warning("EventResultPresenter: aucune icône métier vérifiée pour '%s'; affichage texte uniquement" % resource_id)
		return ""
	if not ResourcePathResolver.file_exists(path):
		push_warning("EventResultPresenter: icône absente pour '%s': %s" % [resource_id, path])
		return ""
	return path


static func resolve_illustration(path: String) -> Texture2D:
	if path.strip_edges().is_empty():
		return null
	var normalized := ResourcePathResolver.normalize(path)
	var texture := ResourcePathResolver.load_texture(normalized, "res://assets/images")
	if texture == null:
		push_warning("EventResultPresenter: illustration introuvable: %s" % normalized)
	return texture


static func _normalize_effect_array(raw_effects: Array) -> Array:
	var result: Array = []
	for raw in raw_effects:
		if not (raw is Dictionary):
			continue
		var effect := (raw as Dictionary).duplicate(true)
		var resource_id := str(effect.get("resource_id", ""))
		effect["label"] = str(effect.get("label", resource_id.capitalize() if not resource_id.is_empty() else "Conséquence"))
		effect["icon_path"] = icon_for_resource(resource_id) if not resource_id.is_empty() else ""
		effect["text"] = str(effect.get("text", _format_amount(effect["label"], effect.get("amount", ""), false)))
		result.append(effect)
	return result


static func _effect_from_pair(key: String, value: Variant) -> Dictionary:
	var label := str(EFFECT_LABELS.get(key, key.replace("_", " ").capitalize()))
	var resource_id := str(EFFECT_RESOURCES.get(key, ""))
	var text := ""
	if value is bool:
		text = label if bool(value) else "%s : Non" % label
	elif value is int or value is float:
		var amount := float(value)
		if key in NEGATIVE_EFFECTS:
			amount = -absf(amount)
		text = _format_amount(label, amount, key in PERCENT_EFFECTS)
	else:
		text = "%s : %s" % [label, str(value)]
	return {
		"type": "resource" if not resource_id.is_empty() else "effect",
		"resource_id": resource_id, "amount": value, "raw_key": key,
		"label": label, "text": text, "icon_path": icon_for_resource(resource_id) if not resource_id.is_empty() else "",
	}


static func _format_amount(label: String, value: Variant, percent: bool) -> String:
	if not (value is int or value is float):
		return "%s : %s" % [label, str(value)]
	var amount := float(value)
	var numeric := str(int(amount)) if is_equal_approx(amount, float(int(amount))) else ("%.1f" % amount)
	var prefix := "+" if amount > 0.0 else ""
	return "%s : %s%s%s" % [label, prefix, numeric, "%" if percent else ""]
