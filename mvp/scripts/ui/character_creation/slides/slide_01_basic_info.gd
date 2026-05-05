## Slide 1: base identity fields, portrait and racial power.
class_name Slide01BasicInfo
extends CreationSlideBase

const APPEARANCE_CHOICES := [
	{"id": "veteran_balafre", "label": "Veteran balafre"},
	{"id": "noble_exile", "label": "Noble exile"},
	{"id": "arcaniste_tatoue", "label": "Arcaniste tatoue"},
	{"id": "mercenaire_masque", "label": "Mercenaire masque"},
]


func enter_slide(data: Resource) -> void:
	var appearance := find_child("AppearanceOption", true, false) as OptionButton
	if appearance and appearance.item_count == 0:
		for choice in APPEARANCE_CHOICES:
			var idx := appearance.item_count
			var label: String = str(choice["label"]) if choice.has("label") else ""
			var value: String = str(choice["id"]) if choice.has("id") else ""
			appearance.add_item(label)
			appearance.set_item_metadata(idx, value)

	var powers := find_child("RacialPowerOption", true, false) as OptionButton
	if powers and powers.item_count == 0:
		var abilities: Dictionary = GameDataLoader.get_abilities()
		var keys: Array = abilities.keys()
		keys.sort()
		for aid in keys:
			var ability := abilities[aid] as Dictionary
			var idx := powers.item_count
			var power_name: String = str(ability["name"]) if ability.has("name") else str(aid)
			powers.add_item(power_name)
			powers.set_item_metadata(idx, str(aid))

	if data == null:
		return
	var name_line := find_child("CharacterName", true, false) as LineEdit
	if name_line:
		var name_value: String = ""
		if data.has_method("get"):
			name_value = str(data.call("get", "character_name"))
		name_line.text = name_value
	var clan_line := find_child("ClanName", true, false) as LineEdit
	if clan_line:
		var clan_value: String = ""
		if data.has_method("get"):
			clan_value = str(data.call("get", "clan_name"))
		clan_line.text = clan_value
	if appearance:
		var appearance_value: String = ""
		if data.has_method("get"):
			appearance_value = str(data.call("get", "appearance_id"))
		_select_by_metadata(appearance, appearance_value)
	if powers:
		var racial_value: String = ""
		if data.has_method("get"):
			racial_value = str(data.call("get", "racial_power_id"))
		_select_by_metadata(powers, racial_value)
	var portrait_node := find_child("PortraitUploadArea", true, false)
	if portrait_node and portrait_node.has_method("load_from_dict"):
		var portrait_payload: Dictionary = {}
		if data.has_method("get"):
			var temp_payload: Variant = data.call("get", "portrait_payload")
			if temp_payload != null:
				portrait_payload = temp_payload as Dictionary
		portrait_node.load_from_dict(portrait_payload)


func collect_payload() -> Dictionary:
	return {
		"character_name": _text_from_node("CharacterName"),
		"clan_name": _text_from_node("ClanName"),
		"appearance_id": _option_id_from_node("AppearanceOption"),
		"racial_power_id": _option_id_from_node("RacialPowerOption"),
		"portrait_payload": _portrait_payload(),
	}


func _text_from_node(node_name: String) -> String:
	var line := find_child(node_name, true, false) as LineEdit
	if line == null:
		return ""
	return line.text.strip_edges()


func _option_id_from_node(node_name: String) -> String:
	var option := find_child(node_name, true, false) as OptionButton
	if option == null or option.item_count <= 0:
		return ""
	var idx := maxi(0, option.selected)
	if idx >= option.item_count:
		idx = option.item_count - 1
	var meta: Variant = option.get_item_metadata(idx)
	return "" if meta == null else str(meta)


func _portrait_payload() -> Dictionary:
	var portrait_node := find_child("PortraitUploadArea", true, false)
	if portrait_node and portrait_node.has_method("to_dict"):
		return portrait_node.to_dict()
	return {}


func _select_by_metadata(option: OptionButton, wanted_id: String) -> void:
	if option == null or wanted_id.is_empty():
		return
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == wanted_id:
			option.select(i)
			return
