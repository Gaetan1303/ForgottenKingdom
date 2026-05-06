## Slide 4: starting items and equipment mapping.
class_name Slide04ItemsEquipment
extends CreationSlideBase


func enter_slide(data: Resource) -> void:
	var inventory := find_child("InventoryOption", true, false) as OptionButton
	if inventory and inventory.item_count == 0:
		for item_name in ["Arme lourde + bouclier", "Catalyseur runique", "Lames jumelles", "Lance de guerre"]:
			var idx := inventory.item_count
			inventory.add_item(item_name)
			inventory.set_item_metadata(idx, item_name)

	var weapon := find_child("WeaponSlotOption", true, false) as OptionButton
	if weapon and weapon.item_count == 0:
		for item_name in ["Aucun", "Arme lourde", "Lames jumelles", "Lance"]:
			var idx := weapon.item_count
			weapon.add_item(item_name)
			weapon.set_item_metadata(idx, item_name)

	var armor := find_child("ArmorSlotOption", true, false) as OptionButton
	if armor and armor.item_count == 0:
		for item_name in ["Aucun", "Armure legere", "Armure lourde", "Robe runique"]:
			var idx := armor.item_count
			armor.add_item(item_name)
			armor.set_item_metadata(idx, item_name)

	if data == null or not data.has_method("get"):
		return
	var inventory_items: Array = []
	var temp_inventory: Variant = data.get("inventory_items")
	if temp_inventory != null:
		inventory_items = temp_inventory as Array
	if inventory and inventory_items.size() > 0:
		_select_by_metadata(inventory, str(inventory_items[0]))
	var equipped: Dictionary = {}
	var temp_equipped: Variant = data.get("equipped_items_by_slot")
	if temp_equipped != null:
		equipped = temp_equipped as Dictionary
	if weapon:
		var chosen_weapon = str(equipped["weapon"]) if equipped.has("weapon") else "Aucun"
		_select_by_metadata(weapon, chosen_weapon)
	if armor:
		var chosen_armor = str(equipped["armor"]) if equipped.has("armor") else "Aucun"
		_select_by_metadata(armor, chosen_armor)


func collect_payload() -> Dictionary:
	return {
		"inventory_items": _collect_inventory(),
		"equipped_items_by_slot": _collect_equipment_map(),
	}


func _collect_inventory() -> Array:
	var inventory := find_child("InventoryOption", true, false) as OptionButton
	if inventory == null or inventory.item_count <= 0:
		return []
	var idx := maxi(0, inventory.selected)
	if idx >= inventory.item_count:
		idx = inventory.item_count - 1
	return [str(inventory.get_item_metadata(idx))]


func _collect_equipment_map() -> Dictionary:
	var out := {}
	var weapon := find_child("WeaponSlotOption", true, false) as OptionButton
	if weapon and weapon.item_count > 0:
		var widx := mini(maxi(0, weapon.selected), weapon.item_count - 1)
		out["weapon"] = str(weapon.get_item_metadata(widx))
	var armor := find_child("ArmorSlotOption", true, false) as OptionButton
	if armor and armor.item_count > 0:
		var aidx := mini(maxi(0, armor.selected), armor.item_count - 1)
		out["armor"] = str(armor.get_item_metadata(aidx))
	return out


func _select_by_metadata(option: OptionButton, wanted_id: String) -> void:
	if option == null or wanted_id.is_empty():
		return
	for i in range(option.item_count):
		if str(option.get_item_metadata(i)) == wanted_id:
			option.select(i)
			return


func _on_equipment_changed(_index: int = -1) -> void:
	var hint := find_child("CompatibilityHint", true, false) as Label
	if hint == null:
		return
	var inventory_choice := _collect_inventory()
	var equipment := _collect_equipment_map()
	var compatibility := _check_compatibility(inventory_choice, equipment)
	if compatibility != "":
		hint.text = compatibility
		hint.add_theme_color_override("font_color", Color8(255, 140, 110))
	else:
		hint.text = "Selectionnez des objets compatibles entre eux."
		hint.add_theme_color_override("font_color", Color8(200, 200, 200))


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
