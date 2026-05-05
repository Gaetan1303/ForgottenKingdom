## Global manager coordinating data and validation across creation slides.
class_name CharacterCreationManager
extends Node

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const JsonPersistenceService = preload("res://scripts/services/json_persistence_service.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")
const CharacterCreationDataType = preload("res://scripts/ui/character_creation/creation_data.gd")
const CharacterCreationFlowType = preload("res://scripts/ui/character_creation/creation_flow_controller.gd")

const FEAT_CONFLICT_MAP := {
	"toughness": ["evasion"],
	"ritual_caster": ["weapon_mastery"],
	"shield_wall": ["sneak_mastery"],
	"battle_engineer": ["mana_efficiency"],
	"silver_tongue": ["intimidating_presence"],
}

const EQUIPMENT_COMPATIBILITY := {
	"Arme lourde + bouclier": {"weapon": ["Arme lourde"], "armor": ["Armure lourde"]},
	"Catalyseur runique": {"weapon": ["Catalyseur runique"], "armor": ["Robe runique", "Armure legere"]},
	"Lames jumelles": {"weapon": ["Lames jumelles"], "armor": ["Armure legere", "Aucun"]},
	"Lance de guerre": {"weapon": ["Lance"], "armor": ["Armure lourde", "Armure legere"]},
}

signal slide_changed(step_index)
signal data_changed(data)
signal validation_failed(step_index, message)
signal draft_saved(path)
signal draft_loaded(path)
signal creation_completed(final_payload)

var data = CharacterCreationDataType.new()
var _flow = CharacterCreationFlowType.new()


func get_current_step() -> int:
	return _flow.current_step


func get_data() -> Resource:
	return data


func update_from_slide(step_index: int, payload: Dictionary) -> void:
	match step_index:
		CharacterCreationFlowType.Step.BASIC_INFO:
			_apply_slide1(payload)
		CharacterCreationFlowType.Step.CLASS_AND_STATS:
			_apply_slide2(payload)
		CharacterCreationFlowType.Step.FEATS_AND_ABILITIES:
			_apply_slide3(payload)
		CharacterCreationFlowType.Step.ITEMS_AND_EQUIPMENT:
			_apply_slide4(payload)
		CharacterCreationFlowType.Step.REVIEW_AND_CONFIRM:
			_apply_slide5(payload)
	emit_signal("data_changed", data)


func try_go_next() -> bool:
	var message := _validate_step(_flow.current_step)
	if message != "":
		emit_signal("validation_failed", _flow.current_step, message)
		return false
	if _flow.is_last_step():
		emit_signal("creation_completed", _build_final_payload())
		return true
	_flow.go_next()
	emit_signal("slide_changed", _flow.current_step)
	return true


func go_previous() -> void:
	_flow.go_previous()
	emit_signal("slide_changed", _flow.current_step)


func go_to(step_index: int) -> void:
	_flow.go_to(step_index)
	emit_signal("slide_changed", _flow.current_step)


func save_draft(path: String = "user://saves/creation_draft.json") -> bool:
	var payload := {
		"step_index": _flow.current_step,
		"creation_data": data.to_dict(),
	}
	var ok := JsonPersistenceService.write_json_atomic(path, payload)
	if ok:
		emit_signal("draft_saved", path)
	return ok


func load_draft(path: String = "user://saves/creation_draft.json") -> bool:
	var payload := JsonPersistenceService.read_json_with_backup(path)
	if payload.is_empty():
		return false
	var creation_data: Dictionary = {}
	if payload.has("creation_data"):
		creation_data = payload["creation_data"] as Dictionary
	data.load_dict(creation_data)
	var step_index := 0
	if payload.has("step_index"):
		step_index = int(payload["step_index"])
	_flow.go_to(step_index)
	emit_signal("data_changed", data)
	emit_signal("slide_changed", _flow.current_step)
	emit_signal("draft_loaded", path)
	return true


func _apply_slide1(payload: Dictionary) -> void:
	if payload.has("character_name"):
		data.character_name = str(payload["character_name"])
	if payload.has("clan_name"):
		data.clan_name = str(payload["clan_name"])
	if payload.has("portrait_payload"):
		data.portrait_payload = (payload["portrait_payload"] as Dictionary).duplicate(true)
	if payload.has("appearance_id"):
		data.appearance_id = str(payload["appearance_id"])
	if payload.has("racial_power_id"):
		data.racial_power_id = str(payload["racial_power_id"])


func _apply_slide2(payload: Dictionary) -> void:
	if payload.has("class_id"):
		data.class_id = str(payload["class_id"])
	var incoming_stats: Dictionary = {}
	if payload.has("stats"):
		incoming_stats = payload["stats"] as Dictionary
	data.stats = StatDefs.sanitize_stats(
		incoming_stats,
		StatDefs.CHARACTER_MIN_STAT,
		StatDefs.CHARACTER_MAX_STAT,
		StatDefs.CHARACTER_MIN_STAT
	)


func _apply_slide3(payload: Dictionary) -> void:
	data.selected_feats = []
	if payload.has("selected_feats"):
		data.selected_feats = (payload["selected_feats"] as Array).duplicate(true)
	data.selected_abilities = []
	if payload.has("selected_abilities"):
		data.selected_abilities = (payload["selected_abilities"] as Array).duplicate(true)


func _apply_slide4(payload: Dictionary) -> void:
	data.inventory_items = []
	if payload.has("inventory_items"):
		data.inventory_items = (payload["inventory_items"] as Array).duplicate(true)
	data.equipped_items_by_slot = {}
	if payload.has("equipped_items_by_slot"):
		data.equipped_items_by_slot = (payload["equipped_items_by_slot"] as Dictionary).duplicate(true)


func _apply_slide5(payload: Dictionary) -> void:
	data.confirmation_accepted = payload.has("confirmation_accepted") and bool(payload["confirmation_accepted"])


func _validate_step(step_index: int) -> String:
	match step_index:
		CharacterCreationFlowType.Step.BASIC_INFO:
			if data.character_name.strip_edges().length() < 2:
				return "Le nom du personnage doit contenir au moins 2 caracteres."
			if data.clan_name.strip_edges().length() < 2:
				return "Le nom du clan doit contenir au moins 2 caracteres."
			if data.racial_power_id.strip_edges().is_empty():
				return "Selectionnez un pouvoir racial."
		CharacterCreationFlowType.Step.CLASS_AND_STATS:
			if data.class_id.strip_edges().is_empty():
				return "Selectionnez une classe."
			if data.points_remaining() < 0:
				return "Le total de points depasse le pool autorise."
		CharacterCreationFlowType.Step.FEATS_AND_ABILITIES:
			var msg := _validate_feats_and_conflicts()
			if msg != "":
				return msg
		CharacterCreationFlowType.Step.ITEMS_AND_EQUIPMENT:
			var equip_msg := _validate_equipment_slots()
			if equip_msg != "":
				return equip_msg
		CharacterCreationFlowType.Step.REVIEW_AND_CONFIRM:
			if not data.confirmation_accepted:
				return "Confirmez la creation pour terminer."
	return ""


func _validate_feats_and_conflicts() -> String:
	if data.selected_feats.size() > 2:
		return "Selectionnez au maximum deux dons pour ce personnage."
	if data.selected_abilities.size() > 1:
		return "Selectionnez une seule competence principale."
	var feats_defs := GameDataLoader.get_feats()
	for feat_id in data.selected_feats:
		var feat_key := str(feat_id)
		var def: Dictionary = {}
		if feats_defs.has(feat_key):
			def = feats_defs[feat_key] as Dictionary
		if def.is_empty():
			continue
		var prereq: Dictionary = {}
		if def.has("prerequisite"):
			prereq = def["prerequisite"] as Dictionary
		var required_stats: Dictionary = {}
		if prereq.has("stats"):
			required_stats = prereq["stats"] as Dictionary
		for stat_key in required_stats.keys():
			var required_value := int(required_stats[stat_key])
			var actual_stat := int(data.stats[str(stat_key)]) if data.stats.has(str(stat_key)) else 0
			if actual_stat < required_value:
				return "Prerequis non remplis pour le don %s." % str(feat_id)
		var conflicts: Array = []
		if def.has("conflicts_with"):
			conflicts = def["conflicts_with"] as Array
		for conflict_id in conflicts:
			if conflict_id in data.selected_feats:
				return "Conflit detecte entre dons: %s et %s." % [str(feat_id), str(conflict_id)]
		var extra_conflicts: Array = []
		if FEAT_CONFLICT_MAP.has(feat_key):
			extra_conflicts = FEAT_CONFLICT_MAP[feat_key] as Array
		for conflict_id in extra_conflicts:
			if conflict_id in data.selected_feats:
				return "Conflit detecte entre dons: %s et %s." % [str(feat_id), str(conflict_id)]
	return ""


func _validate_equipment_slots() -> String:
	var used_slots := {}
	for slot_name in data.equipped_items_by_slot.keys():
		var slot := str(slot_name)
		if used_slots.has(slot):
			return "Le slot %s est utilise plusieurs fois." % slot
		used_slots[slot] = true
	var inventory_item := ""
	if data.inventory_items.size() > 0:
		inventory_item = str(data.inventory_items[0])
	if inventory_item != "" and EQUIPMENT_COMPATIBILITY.has(inventory_item):
		var rules := EQUIPMENT_COMPATIBILITY[inventory_item] as Dictionary
		var selected_weapon = str(data.equipped_items_by_slot["weapon"]) if data.equipped_items_by_slot.has("weapon") else "Aucun"
		var allowed_weapon: Array = []
		if rules.has("weapon"):
			allowed_weapon = rules["weapon"] as Array
		if selected_weapon != "Aucun" and not allowed_weapon.has(selected_weapon):
			return "Le choix d'arme est incompatible avec l'objet de depart."
		var selected_armor = str(data.equipped_items_by_slot["armor"]) if data.equipped_items_by_slot.has("armor") else "Aucun"
		var allowed_armor: Array = []
		if rules.has("armor"):
			allowed_armor = rules["armor"] as Array
		if selected_armor != "Aucun" and not allowed_armor.has(selected_armor):
			return "Le choix d'armure est incompatible avec l'objet de depart."
	return ""


func _build_final_payload() -> Dictionary:
	var classe_data := CharacterCreationRules.get_class_data(data.class_id)
	var feats_defs := GameDataLoader.get_feats()
	var stats_finales := CharacterCreationRules.compute_final_stats_for_creation(
		classe_data,
		data.stats,
		"",
		"",
		feats_defs,
		data.selected_feats
	)

	return {
		"created_at_unix": Time.get_unix_time_from_system(),
		"flow_step": _flow.current_step,
		"character": data.to_dict(),
		"final_stats": stats_finales,
	}
