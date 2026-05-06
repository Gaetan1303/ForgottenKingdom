## Resource model for the character creation flow.
class_name CharacterCreationData
extends Resource

const StatDefs = preload("res://scripts/data/stat_defs.gd")

@export var character_name: String = ""
@export var clan_name: String = ""
@export var portrait_payload: Dictionary = {}
@export var appearance_id: String = ""
@export var racial_power_id: String = ""

@export var class_id: String = ""
@export var stats_points_pool: int = 10
@export var stats: Dictionary = {}

@export var selected_feats: Array = []
@export var selected_abilities: Array = []

@export var inventory_items: Array = []
@export var equipped_items_by_slot: Dictionary = {}

@export var confirmation_accepted: bool = false


func _init() -> void:
	if stats.is_empty():
		stats = StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)


func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"clan_name": clan_name,
		"portrait_payload": portrait_payload.duplicate(true),
		"appearance_id": appearance_id,
		"racial_power_id": racial_power_id,
		"class_id": class_id,
		"stats_points_pool": stats_points_pool,
		"stats": stats.duplicate(true),
		"selected_feats": selected_feats.duplicate(true),
		"selected_abilities": selected_abilities.duplicate(true),
		"inventory_items": inventory_items.duplicate(true),
		"equipped_items_by_slot": equipped_items_by_slot.duplicate(true),
		"confirmation_accepted": confirmation_accepted,
	}


func load_dict(payload: Dictionary) -> void:
	if payload.has("character_name"):
		character_name = str(payload["character_name"])
	else:
		character_name = ""
	if payload.has("clan_name"):
		clan_name = str(payload["clan_name"])
	else:
		clan_name = ""
	if payload.has("portrait_payload"):
		portrait_payload = (payload["portrait_payload"] as Dictionary).duplicate(true)
	else:
		portrait_payload = {}
	if payload.has("appearance_id"):
		appearance_id = str(payload["appearance_id"])
	else:
		appearance_id = ""
	if payload.has("racial_power_id"):
		racial_power_id = str(payload["racial_power_id"])
	else:
		racial_power_id = ""
	if payload.has("class_id"):
		class_id = str(payload["class_id"])
	else:
		class_id = ""
	if payload.has("stats_points_pool"):
		stats_points_pool = int(payload["stats_points_pool"])
	else:
		stats_points_pool = 10
	var raw_stats: Dictionary = {}
	if payload.has("stats"):
		raw_stats = payload["stats"] as Dictionary
	stats = StatDefs.sanitize_stats(
		raw_stats,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)
	selected_feats = []
	if payload.has("selected_feats"):
		selected_feats = (payload["selected_feats"] as Array).duplicate(true)
	selected_abilities = []
	if payload.has("selected_abilities"):
		selected_abilities = (payload["selected_abilities"] as Array).duplicate(true)
	inventory_items = []
	if payload.has("inventory_items"):
		inventory_items = (payload["inventory_items"] as Array).duplicate(true)
	equipped_items_by_slot = {}
	if payload.has("equipped_items_by_slot"):
		equipped_items_by_slot = (payload["equipped_items_by_slot"] as Dictionary).duplicate(true)
	confirmation_accepted = payload.has("confirmation_accepted") and bool(payload["confirmation_accepted"])


func points_spent() -> int:
	var total := 0
	for key in StatDefs.STAT_KEYS:
		var value := int(stats[key]) if stats.has(key) else StatDefs.CHARACTER_MIN_STAT
		total += max(0, value - StatDefs.CHARACTER_MIN_STAT)
	return total


func points_remaining() -> int:
	return maxi(0, stats_points_pool - points_spent())
