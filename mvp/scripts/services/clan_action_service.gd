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
