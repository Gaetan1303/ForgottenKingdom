class_name ClanEventService
extends RefCounted
const ContextType = preload("res://scripts/services/clan_service_context.gd")
var context: ContextType
func _init(p_context: ContextType) -> void:
	context = p_context


func apply_effects(effets: Dictionary) -> void:
	# Gains directs
	if effets.has("or_recupere"):       context.economy.gain_state(context, {"or": int(effets["or_recupere"])})
	if effets.has("or_penalite"):       context.economy.pay(context, {"or": absi(int(effets["or_penalite"]))})
	if effets.has("mana_gain"):         context.economy.gain_state(context, {"mana": int(effets["mana_gain"])})
	if effets.has("soldats_gain"):      context.economy.gain_state(context, {"soldats": int(effets["soldats_gain"])})
	if effets.has("reputation_gain"):   context.economy.gain_state(context, {"reputation": int(effets["reputation_gain"])})
	if effets.has("renseignements_gain"): context.economy.gain_state(context, {"renseignements": int(effets["renseignements_gain"])})

	# Pertes en pourcentage
	if effets.has("pertes_soldats_pct"):
		var pct := int(effets["pertes_soldats_pct"])
		var pertes := int(context.state.ressources.get("soldats", 0)) * pct / 100
		context.economy.pay(context, {"soldats": maxi(1, pertes)})

	if effets.has("soldats_perte_pct"):
		var pct := int(effets["soldats_perte_pct"])
		var pertes := int(context.state.ressources.get("soldats", 0)) * pct / 100
		context.economy.pay(context, {"soldats": maxi(1, pertes)})

	# Pertes de réputation
	if effets.has("reputation_perte"):  context.economy.pay(context, {"reputation": int(effets["reputation_perte"])})
	if effets.has("relation_perte"):
		pass  # Géré par les scènes directement via modifier_relation

	if effets.has("pnj_recrute"):
		for _i in range(int(effets.get("pnj_recrute", 1))):
			context.recruitment_requested.emit(str(effets.get("pnj_role", "")))

	# Gains de renforcement (fortification)
	if effets.has("soldats_bonus"): context.economy.gain_state(context, {"soldats": int(effets["soldats_bonus"])})
	if effets.has("production_or_bonus"):
		context.state.ressources_par_tour["or"] = int(context.state.ressources_par_tour.get("or", 120)) + int(effets["production_or_bonus"])
		context.resources_changed.emit()

func draw_event(events: Array) -> Dictionary:
	for event in events:
		var data := event as Dictionary
		if data.is_empty() or not evaluate_conditions(str(data.get("condition", ""))): continue
		var probability := float(data.get("probabilite", 0.0))
		if probability > 0.0 and context.rng.randf() <= probability: return data.duplicate(true)
	return {}

func apply_event(event: Dictionary) -> Dictionary:
	if event.is_empty(): return {}
	apply_effects((event.get("effets", {}) as Dictionary).duplicate(true))
	var id := str(event.get("id", ""))
	if not id.is_empty() and not context.state.evenements_declenches.has(id):
		context.state.evenements_declenches.append(id)
	var title := str(event.get("titre", "Événement"))
	var body := str(event.get("texte", ""))
	return {"event": event, "message": "Événement: %s." % title if body.is_empty() else "Événement: %s — %s" % [title, body]}

func draw_and_apply(events: Array) -> String:
	return str(apply_event(draw_event(events)).get("message", ""))


func evaluate_conditions(condition: String) -> bool:
	var cond := condition.strip_edges()
	if cond.is_empty() or cond == "null":
		return true

	var clauses := cond.split("AND")
	for clause_raw in clauses:
		var clause := clause_raw.strip_edges()
		if clause.is_empty():
			continue
		if not _evaluer_clause_condition(clause):
			return false
	return true

func _evaluer_clause_condition(clause: String) -> bool:
	for op_any in [">=", "<=", "==", "!=", ">", "<", "="]:
		var op: String = str(op_any)
		var idx: int = clause.find(op)
		if idx == -1:
			continue

		var gauche: String = clause.substr(0, idx).strip_edges().to_lower()
		var droite: String = clause.substr(idx + op.length()).strip_edges()
		if op == "=":
			op = "=="

		var left_value: Variant = _valeur_condition(gauche)
		var right_value: Variant = _convertir_condition_value(droite)
		if left_value == null or right_value == null:
			return false
		return _comparer_condition(left_value, right_value, op)

	return false

func _valeur_condition(key: String) -> Variant:
	match key:
		"tour":
			return context.state.tour_actuel
		"moment_journee":
			return context.state.moment_journee
		_:
			if context.state.ressources.has(key):
				return int(context.state.ressources.get(key, 0))
	return null

func _convertir_condition_value(value: String) -> Variant:
	var v := value.strip_edges()
	if v.is_empty():
		return null

	if v.begins_with("\"") and v.ends_with("\"") and v.length() >= 2:
		return v.substr(1, v.length() - 2)

	if v.is_valid_int():
		return int(v)
	if v.is_valid_float():
		return float(v)

	return v.to_lower()

func _comparer_condition(a: Variant, b: Variant, op: String) -> bool:
	match op:
		">":
			return a > b
		"<":
			return a < b
		">=":
			return a >= b
		"<=":
			return a <= b
		"==":
			return a == b
		"!=":
			return a != b
	return false
