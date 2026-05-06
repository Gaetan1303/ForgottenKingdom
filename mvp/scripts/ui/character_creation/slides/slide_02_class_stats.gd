## Slide 2: class selection and stat allocation.
class_name Slide02ClassStats
extends CreationSlideBase

const StatDefs = preload("res://scripts/data/stat_defs.gd")
const CharacterCreationRules = preload("res://scripts/services/character_creation_rules_service.gd")


func enter_slide(data: Resource) -> void:
	var class_option := find_child("ClassOption", true, false) as OptionButton
	if class_option and class_option.item_count == 0:
		var classes: Dictionary = GameDataLoader.get_classes()
		var keys: Array = classes.keys()
		keys.sort()
		for key in keys:
			var cdef := classes[key] as Dictionary
			var idx := class_option.item_count
			var class_label: String = str(cdef["name"]) if cdef.has("name") else str(key)
			class_option.add_item(class_label)
			class_option.set_item_metadata(idx, str(key))
		class_option.item_selected.connect(_on_class_selected)

	if data == null or not data.has_method("get"):
		return

	if class_option:
		var class_id := ""
		var tmp_id: Variant = data.get("class_id")
		if tmp_id != null:
			class_id = str(tmp_id)
		for i in range(class_option.item_count):
			if str(class_option.get_item_metadata(i)) == class_id:
				class_option.select(i)
				break

	var incoming_stats: Dictionary = {}
	var tmp_stats: Variant = data.get("stats")
	if tmp_stats != null:
		incoming_stats = tmp_stats as Dictionary
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(incoming_stats[key]) if incoming_stats.has(key) else default_stat
			node.value = float(stat_value)


func collect_payload() -> Dictionary:
	return {
		"class_id": _selected_class_id(),
		"stats": _collect_stats(),
	}


func _selected_class_id() -> String:
	var class_option := find_child("ClassOption", true, false) as OptionButton
	if class_option == null or class_option.item_count <= 0:
		return ""
	var idx := maxi(0, class_option.selected)
	if idx >= class_option.item_count:
		idx = class_option.item_count - 1
	var meta: Variant = class_option.get_item_metadata(idx)
	return "" if meta == null else str(meta)


func _collect_stats() -> Dictionary:
	var out := StatDefs.make_default_stats(StatDefs.CHARACTER_MIN_STAT)
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			out[key] = int(node.value)
	return out


func _on_class_selected(index: int) -> void:
	var class_option := find_child("ClassOption", true, false) as OptionButton
	if class_option == null or index < 0 or index >= class_option.item_count:
		return
	var class_id := str(class_option.get_item_metadata(index))
	var point_buy := CharacterCreationRules.apply_point_buy_for_class(class_id, 10)
	var stats: Dictionary = {}
	if point_buy.has("stats"):
		stats = point_buy["stats"] as Dictionary
	for key in StatDefs.STAT_KEYS:
		var node := find_child("Stat_%s" % key, true, false) as SpinBox
		if node:
			var default_stat := StatDefs.CHARACTER_MIN_STAT
			var stat_value := int(stats[key]) if stats.has(key) else default_stat
			node.value = float(stat_value)
