## Frontière explicite entre l'état Production et le snapshot Phase 2.
class_name WorldStateAdapter
extends RefCounted

const WorldStateClass = preload("res://scripts/data/world_state.gd")


static func from_clan_manager(clan_manager) -> WorldState:
	var state := WorldStateClass.new()
	if clan_manager == null:
		return state
	state.legacy_state = {
		"tour_actuel": int(clan_manager.get("tour_actuel")),
		"moment_journee": str(clan_manager.get("moment_journee")),
		"ressources": (clan_manager.get("ressources") as Dictionary).duplicate(true),
		"maisons_nobles": (clan_manager.get("maisons_nobles") as Array).duplicate(true),
	}
	if clan_manager.has_meta("corruption_service"):
		var service = clan_manager.get_meta("corruption_service")
		if service != null:
			state.corruption_data = service.call("export_state") as Dictionary
	if clan_manager.has_meta("creature_roster"):
		var roster = clan_manager.get_meta("creature_roster")
		if roster != null:
			state.creature_roster = roster.call("export_state") as Dictionary
	if clan_manager.has_meta("pact_service"):
		var pacts = clan_manager.get_meta("pact_service")
		if pacts != null:
			state.pact_data = pacts.call("export_state") as Dictionary
	return state


static func apply_to_clan_manager(world_state: WorldState, clan_manager) -> void:
	if world_state == null or clan_manager == null:
		return
	if clan_manager.has_meta("corruption_service"):
		var service = clan_manager.get_meta("corruption_service")
		if service != null:
			service.call("import_state", world_state.corruption_data)
	if clan_manager.has_meta("creature_roster"):
		var roster = clan_manager.get_meta("creature_roster")
		if roster != null:
			roster.call("import_state", world_state.creature_roster)
	if clan_manager.has_meta("pact_service"):
		var pacts = clan_manager.get_meta("pact_service")
		if pacts != null:
			pacts.call("import_state", world_state.pact_data)
	_sync_corruption_to_legacy(clan_manager, world_state.corruption_data)


static func from_save_dict(data: Dictionary) -> WorldState:
	var state := WorldStateClass.new()
	state.legacy_state = (data.get("legacy_state", {}) as Dictionary).duplicate(true)
	state.corruption_data = (data.get("corruption_data", {}) as Dictionary).duplicate(true)
	state.creature_roster = (data.get("creature_roster", {}) as Dictionary).duplicate(true)
	state.pact_data = (data.get("pact_data", {}) as Dictionary).duplicate(true)
	return state


static func to_save_dict(world_state: WorldState) -> Dictionary:
	return {} if world_state == null else world_state.to_dict()


static func _sync_corruption_to_legacy(clan_manager, corruption_data: Dictionary) -> void:
	var legacy = clan_manager.get("pnj_gestion")
	if not (legacy is Dictionary):
		return
	var next_state := (legacy as Dictionary).duplicate(true)
	var roster := (next_state.get("roster", []) as Array).duplicate(true)
	var profiles := corruption_data.get("profiles", corruption_data) as Dictionary
	for index in range(roster.size()):
		if not (roster[index] is Dictionary):
			continue
		var pnj := (roster[index] as Dictionary).duplicate(true)
		var profile := profiles.get(str(pnj.get("id", "")), {}) as Dictionary
		if profile.is_empty():
			continue
		pnj["corruption"] = float(profile.get("level", 0.0))
		pnj["corruption_stage"] = int(profile.get("stage", 0))
		pnj["resistance_mentale"] = float(profile.get("resistance", 50.0))
		pnj["obedience"] = float(profile.get("obedience", 0.0))
		pnj["perversion"] = float(profile.get("perversion", 0.0))
		roster[index] = pnj
	next_state["roster"] = roster
	clan_manager.set("pnj_gestion", next_state)
