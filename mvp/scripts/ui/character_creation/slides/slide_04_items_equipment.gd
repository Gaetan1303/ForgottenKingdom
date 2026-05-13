## Slide 4: Diablo-like inventory/equipment drag-and-drop.
class_name Slide04ItemsEquipment
extends CreationSlideBase

const MALE_PORTRAIT = preload("res://assets/images/PNJ/defaut/male.png")
const FEMALE_PORTRAIT = preload("res://assets/images/PNJ/defaut/female.png")

const SLOT_IDS := [
	"head",
	"torso",
	"hands",
	"legs",
	"boots",
	"main_hand",
	"off_hand",
	"amulet",
	"ring_right",
	"ring_left",
]

const SLOT_NODE_NAMES := {
	"head": "SlotHead",
	"torso": "SlotShoulders",
	"hands": "SlotHands",
	"legs": "SlotRingLeft",
	"boots": "SlotBoots",
	"main_hand": "SlotMainHand",
	"off_hand": "SlotOffHand",
	"amulet": "SlotChest",
	"ring_right": "SlotLegs",
	"ring_left": "SlotRingRight",
}

const DEFAULT_ITEMS := [
	{"id": "war_helm", "label": "Casque de guerre", "slot_type": "head"},
	{"id": "obsidian_spaulders", "label": "Armure d'obsidienne", "slot_type": "armor"},
	{"id": "demon_gauntlets", "label": "Gantelets demoniaques", "slot_type": "hands"},
	{"id": "war_boots", "label": "Bottes du front", "slot_type": "boots"},
	{"id": "blood_ring", "label": "Anneau de sang", "slot_type": "ring"},
	{"id": "ashen_ring", "label": "Anneau cendre", "slot_type": "ring"},
	{"id": "great_blade", "label": "Arme lourde", "slot_type": "weapon"},
	{"id": "twin_blades", "label": "Lames jumelles", "slot_type": "weapon"},
	{"id": "war_spear", "label": "Lance", "slot_type": "weapon"},
	{"id": "runic_catalyst", "label": "Catalyseur runique", "slot_type": "weapon"},
	{"id": "kite_shield", "label": "Bouclier cerf-volant", "slot_type": "offhand"},
	{"id": "heavy_armor", "label": "Armure lourde", "slot_type": "armor"},
	{"id": "light_armor", "label": "Armure legere", "slot_type": "armor"},
	{"id": "runic_robe", "label": "Robe runique", "slot_type": "armor"},
	{"id": "war_legs", "label": "Jambieres de guerre", "slot_type": "legs"},
	{"id": "obsidian_amulet", "label": "Amulette d'obsidienne", "slot_type": "amulet"},
]

var _inventory_items: Array = []
var _equipped_by_slot: Dictionary = {}
var _slot_nodes: Dictionary = {}


func enter_slide(data: Resource) -> void:
	_inventory_items = _default_inventory_items()
	_equipped_by_slot = {}
	_cache_slot_nodes()
	_connect_drag_drop_signals()
	_restore_from_data(data)
	_refresh_portrait(data)
	_rebuild_inventory_grid()
	_refresh_slot_cards()
	_update_compatibility_hint()


func collect_payload() -> Dictionary:
	var inventory_labels: Array = []
	for item in _inventory_items:
		inventory_labels.append(str((item as Dictionary).get("label", "")))

	var equipment_labels := {}
	for slot_id in _equipped_by_slot.keys():
		var item := _equipped_by_slot[slot_id] as Dictionary
		equipment_labels[str(slot_id)] = str(item.get("label", ""))

	var weapon_name := _extract_weapon_name()
	var armor_name := _extract_armor_name()
	equipment_labels["weapon"] = weapon_name
	equipment_labels["armor"] = armor_name

	var starter_loadout := _starter_loadout_from_weapon(weapon_name)
	var inventory_payload: Array = [starter_loadout]
	for label in inventory_labels:
		if label != starter_loadout:
			inventory_payload.append(label)

	return {
		"inventory_items": inventory_payload,
		"equipped_items_by_slot": equipment_labels,
	}


func _default_inventory_items() -> Array:
	var external_items: Array = []
	if GameDataLoader != null and GameDataLoader.has_method("get_equipment_items"):
		external_items = GameDataLoader.get_equipment_items()
	if external_items.size() > 0:
		var from_data: Array = []
		for item in external_items:
			if item is Dictionary:
				from_data.append((item as Dictionary).duplicate(true))
		if from_data.size() > 0:
			return from_data

	var out: Array = []
	for item in DEFAULT_ITEMS:
		out.append((item as Dictionary).duplicate(true))
	return out


func _cache_slot_nodes() -> void:
	_slot_nodes.clear()
	for slot_id in SLOT_IDS:
		var node_name := str(SLOT_NODE_NAMES.get(slot_id, ""))
		var slot_node := find_child(node_name, true, false)
		if slot_node != null:
			_slot_nodes[slot_id] = slot_node


func _connect_drag_drop_signals() -> void:
	var inventory_grid := find_child("InventoryGrid", true, false)
	if inventory_grid and not inventory_grid.is_connected("item_dropped_in_grid", Callable(self, "_on_inventory_drop")):
		inventory_grid.connect("item_dropped_in_grid", Callable(self, "_on_inventory_drop"))

	for slot_id in _slot_nodes.keys():
		var slot_node = _slot_nodes[slot_id]
		if slot_node and not slot_node.is_connected("item_dropped", Callable(self, "_on_slot_item_dropped")):
			slot_node.connect("item_dropped", Callable(self, "_on_slot_item_dropped"))


func _rebuild_inventory_grid() -> void:
	var grid := find_child("InventoryGrid", true, false) as GridContainer
	if grid == null:
		return
	for child in grid.get_children():
		child.queue_free()

	for item in _inventory_items:
		grid.add_child(_build_inventory_card(item as Dictionary))


func _build_inventory_card(item: Dictionary) -> Control:
	var card_scene := load("res://scenes/ui/character_creation/components/inventory_item_card.tscn")
	var card := card_scene.instantiate() as Control
	if card == null:
		return PanelContainer.new()
	card.custom_minimum_size = Vector2(148, 76)
	if card.has_method("set_item_data"):
		card.set_item_data(item)
	return card


func _refresh_slot_cards() -> void:
	for slot_id in _slot_nodes.keys():
		var slot_node = _slot_nodes[slot_id]
		if slot_node == null:
			continue
		if _equipped_by_slot.has(slot_id):
			slot_node.set_equipped_item(_equipped_by_slot[slot_id])
		else:
			slot_node.clear_item()


func _on_slot_item_dropped(slot_id: String, payload: Dictionary) -> void:
	if not payload.has("item"):
		return
	var incoming_item := (payload["item"] as Dictionary).duplicate(true)
	if not _slot_accepts(slot_id, incoming_item):
		return

	var source := str(payload.get("source", ""))
	var source_slot := str(payload.get("source_slot", ""))
	var replaced_item: Dictionary = {}
	if _equipped_by_slot.has(slot_id):
		replaced_item = (_equipped_by_slot[slot_id] as Dictionary).duplicate(true)

	if source == "inventory":
		_remove_inventory_item(str(incoming_item.get("id", "")))
	elif source == "slot":
		if source_slot == slot_id:
			return
		if source_slot != "" and _equipped_by_slot.has(source_slot):
			_equipped_by_slot.erase(source_slot)
		if not replaced_item.is_empty() and source_slot != "" and _slot_accepts(source_slot, replaced_item):
			_equipped_by_slot[source_slot] = replaced_item.duplicate(true)
			replaced_item = {}

	_equipped_by_slot[slot_id] = incoming_item
	if not replaced_item.is_empty():
		_inventory_items.append(replaced_item)

	_rebuild_inventory_grid()
	_refresh_slot_cards()
	_update_compatibility_hint()


func _on_inventory_drop(payload: Dictionary) -> void:
	if str(payload.get("source", "")) != "slot":
		return
	if not payload.has("item"):
		return
	var source_slot := str(payload.get("source_slot", ""))
	if source_slot != "" and _equipped_by_slot.has(source_slot):
		_equipped_by_slot.erase(source_slot)
	var item := (payload["item"] as Dictionary).duplicate(true)
	if not _inventory_contains_id(str(item.get("id", ""))):
		_inventory_items.append(item)
	_rebuild_inventory_grid()
	_refresh_slot_cards()
	_update_compatibility_hint()


func _slot_accepts(slot_id: String, item: Dictionary) -> bool:
	if not _slot_nodes.has(slot_id):
		return false
	var slot_node = _slot_nodes[slot_id]
	var accepted = slot_node.accepted_types as PackedStringArray
	if accepted.is_empty():
		return true
	return accepted.has(str(item.get("slot_type", "")))


func _remove_inventory_item(item_id: String) -> void:
	for i in range(_inventory_items.size()):
		var data := _inventory_items[i] as Dictionary
		if str(data.get("id", "")) == item_id:
			_inventory_items.remove_at(i)
			return


func _inventory_contains_id(item_id: String) -> bool:
	for item in _inventory_items:
		if str((item as Dictionary).get("id", "")) == item_id:
			return true
	return false


func _extract_weapon_name() -> String:
	if not _equipped_by_slot.has("main_hand"):
		return "Aucun"
	return str((_equipped_by_slot["main_hand"] as Dictionary).get("label", "Aucun"))


func _extract_armor_name() -> String:
	if not _equipped_by_slot.has("torso"):
		return "Aucun"
	return str((_equipped_by_slot["torso"] as Dictionary).get("label", "Aucun"))


func _starter_loadout_from_weapon(weapon_name: String) -> String:
	if weapon_name == "Arme lourde":
		return "Arme lourde + bouclier"
	if weapon_name == "Catalyseur runique":
		return "Catalyseur runique"
	if weapon_name == "Lames jumelles":
		return "Lames jumelles"
	if weapon_name == "Lance":
		return "Lance de guerre"
	return "Arme lourde + bouclier"


func _update_compatibility_hint() -> void:
	var hint := find_child("CompatibilityHint", true, false) as Label
	if hint == null:
		return
	var weapon := _extract_weapon_name()
	var armor := _extract_armor_name()
	var loadout := _starter_loadout_from_weapon(weapon)
	var warning := _check_compatibility([loadout], {"weapon": weapon, "armor": armor})
	if warning != "":
		hint.text = warning
		hint.add_theme_color_override("font_color", Color8(255, 140, 110))
	else:
		hint.text = "Configuration valide. Glisse les objets entre sac et slots pour optimiser le build."
		hint.add_theme_color_override("font_color", Color8(170, 230, 170))


func _restore_from_data(data: Resource) -> void:
	if data == null or not data.has_method("get"):
		return
	var equipped_any := false
	var temp_equipped: Variant = data.get("equipped_items_by_slot")
	if temp_equipped != null and temp_equipped is Dictionary:
		var equipped := temp_equipped as Dictionary
		for slot_id in SLOT_IDS:
			if not equipped.has(slot_id):
				continue
			var item_label := str(equipped[slot_id])
			var item := _pull_item_by_label(item_label)
			if not item.is_empty() and _slot_accepts(slot_id, item):
				_equipped_by_slot[slot_id] = item
				equipped_any = true

	if not equipped_any and temp_equipped != null and temp_equipped is Dictionary:
		var equipped_legacy := temp_equipped as Dictionary
		if equipped_legacy.has("weapon"):
			var weapon_item := _pull_item_by_label(str(equipped_legacy["weapon"]))
			if not weapon_item.is_empty() and _slot_accepts("main_hand", weapon_item):
				_equipped_by_slot["main_hand"] = weapon_item
		if equipped_legacy.has("armor"):
			var armor_item := _pull_item_by_label(str(equipped_legacy["armor"]))
			if not armor_item.is_empty() and _slot_accepts("torso", armor_item):
				_equipped_by_slot["torso"] = armor_item


func _pull_item_by_label(label: String) -> Dictionary:
	if label.is_empty() or label == "Aucun":
		return {}
	for i in range(_inventory_items.size()):
		var item := _inventory_items[i] as Dictionary
		if str(item.get("label", "")) == label:
			_inventory_items.remove_at(i)
			return item
	return {}


func _refresh_portrait(data: Resource) -> void:
	var portrait := find_child("CharacterPortrait", true, false) as TextureRect
	if portrait == null:
		return
	var texture: Texture2D = MALE_PORTRAIT
	if data != null and data.has_method("get"):
		var appearance_id := str(data.get("appearance_id"))
		if appearance_id.contains("noble") or appearance_id.contains("arcaniste"):
			texture = FEMALE_PORTRAIT
	portrait.texture = texture


func _to_pascal_case(value: String) -> String:
	var out := ""
	for part in value.split("_"):
		if part.is_empty():
			continue
		out += part.capitalize()
	return out


func _check_compatibility(inventory_choice: Array, equipment: Dictionary) -> String:
	if inventory_choice.size() == 0:
		return ""
	var inventory := str(inventory_choice[0])
	var map := {
		"Arme lourde + bouclier": {"weapon": ["Arme lourde"], "armor": ["Armure lourde"]},
		"Catalyseur runique": {"weapon": ["Catalyseur runique"], "armor": ["Robe runique", "Armure legere"]},
		"Lames jumelles": {"weapon": ["Lames jumelles"], "armor": ["Armure legere", "Aucun"]},
		"Lance de guerre": {"weapon": ["Lance"], "armor": ["Armure lourde", "Armure legere"]},
	}
	if not map.has(inventory):
		return ""
	var expected := map[inventory] as Dictionary
	var weapon = str(equipment["weapon"]) if equipment.has("weapon") else "Aucun"
	var armor = str(equipment["armor"]) if equipment.has("armor") else "Aucun"
	var allowed_weapon: Array = []
	if expected.has("weapon"):
		allowed_weapon = expected["weapon"] as Array
	if weapon != "Aucun" and not allowed_weapon.has(weapon):
		return "Attention: selection de l'arme incompatible avec l'objet principal."
	var allowed_armor: Array = []
	if expected.has("armor"):
		allowed_armor = expected["armor"] as Array
	if armor != "Aucun" and not allowed_armor.has(armor):
		return "Attention: selection de l'armure incompatible avec l'objet principal."
	return ""
