## Contrat des actions stratégiques ; aucun état parallèle ni règle commune.
class_name ClanActionService
extends RefCounted

const Context = preload("res://scripts/services/clan_service_context.gd")
var context: Context

func _init(p_context: Context) -> void:
	context = p_context

func can_execute(_action: Dictionary) -> bool:
	return false

func execute(_action: Dictionary) -> Dictionary:
	return {}

static func action_used(ctx: Context) -> bool:
	if ctx.state.daily_phase == "apres_midi": return true
	return ctx.state.action_jour_effectuee if ctx.state.moment_journee == "jour" else ctx.state.action_nuit_effectuee

static func mark_used(ctx: Context) -> void:
	if ctx.state.moment_journee == "jour":
		ctx.state.action_jour_effectuee = true
	else:
		ctx.state.action_nuit_effectuee = true

static func reset_night(ctx: Context) -> void:
	ctx.state.action_nuit_effectuee = false

static func reset_day(ctx: Context) -> void:
	ctx.state.action_jour_effectuee = false
	ctx.state.action_nuit_effectuee = false
