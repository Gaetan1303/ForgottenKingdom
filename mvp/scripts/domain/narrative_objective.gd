## Un objectif porte des méthodes autorisées, jamais une condition de boss unique.
extends RefCounted

const Resolution = preload("res://scripts/domain/objective_resolution.gd")
var id: String
var description: String
var status: String = "active"
var resolution_methods: Array = []
var resolution: Dictionary = {}
var next_objective: String = ""

func _init(data: Dictionary = {}) -> void:
	id = str(data.get("id", ""))
	description = str(data.get("description", ""))
	status = str(data.get("status", "active"))
	resolution_methods = data.get("resolution_methods", []).duplicate()
	resolution = data.get("resolution", {}).duplicate(true)
	next_objective = str(data.get("next_objective", ""))

func complete(result: Resolution) -> bool:
	if status != "active" or result.method not in resolution_methods:
		return false
	status = "completed"
	resolution = result.to_dict()
	return true

func to_dict() -> Dictionary:
	return {"id": id, "description": description, "status": status,
		"resolution_methods": resolution_methods.duplicate(),
		"resolution_method": str(resolution.get("method", "")), "resolution": resolution.duplicate(true), "next_objective": next_objective}
