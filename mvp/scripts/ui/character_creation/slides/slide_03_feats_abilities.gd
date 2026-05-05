## Slide 3: feats and abilities selection.
class_name Slide03FeatsAbilities
extends CreationSlideBase


func enter_slide(data: Resource) -> void:
	var feat_list := find_child("FeatList", true, false) as ItemList
	if feat_list and feat_list.get_item_count() == 0:
		var feats := GameDataLoader.get_feats()
		var fkeys: Array = feats.keys()
		fkeys.sort()
		for fid in fkeys:
			var f := feats[fid] as Dictionary
			var idx := feat_list.get_item_count()
			var feat_name = str(f["name"]) if f.has("name") else str(fid)
			feat_list.add_item(feat_name)
			feat_list.set_item_metadata(idx, str(fid))

	var ability_list := find_child("AbilityList", true, false) as ItemList
	if ability_list and ability_list.get_item_count() == 0:
		var abilities := GameDataLoader.get_abilities()
		var akeys: Array = abilities.keys()
		akeys.sort()
		for aid in akeys:
			var a := abilities[aid] as Dictionary
			var idx := ability_list.get_item_count()
			var ability_name = str(a["name"]) if a.has("name") else str(aid)
			ability_list.add_item(ability_name)
			ability_list.set_item_metadata(idx, str(aid))

	if data == null or not data.has_method("get"):
		return
	var selected_feats: Array = []
	if data.has_method("get"):
		var tmp_feats: Variant = data.get("selected_feats")
		if tmp_feats != null:
			selected_feats = tmp_feats as Array
	if feat_list:
		_select_items_by_metadata(feat_list, selected_feats)
	var selected_abilities: Array = []
	if data.has_method("get"):
		var tmp_abilities: Variant = data.get("selected_abilities")
		if tmp_abilities != null:
			selected_abilities = tmp_abilities as Array
	if ability_list:
		_select_items_by_metadata(ability_list, selected_abilities)


func collect_payload() -> Dictionary:
	return {
		"selected_feats": _collect_selected_ids("FeatList"),
		"selected_abilities": _collect_selected_ids("AbilityList"),
	}


func _collect_selected_ids(node_name: String) -> Array:
	var item_list := find_child(node_name, true, false) as ItemList
	if item_list == null:
		return []
	var collected: Array = []
	for i in range(item_list.get_item_count()):
		if item_list.is_selected(i):
			var meta: Variant = item_list.get_item_metadata(i)
			if meta != null:
				collected.append(str(meta))
	return collected


func _select_items_by_metadata(item_list: ItemList, wanted_ids: Array) -> void:
	if item_list == null or wanted_ids.size() == 0:
		return
	for i in range(item_list.get_item_count()):
		var meta: Variant = item_list.get_item_metadata(i)
		if meta != null and str(meta) in wanted_ids:
			item_list.select(i)


func _on_ability_selected(index: int) -> void:
	var ability_list := find_child("AbilityList", true, false) as ItemList
	if ability_list == null:
		return
	var selected_id := str(ability_list.get_item_metadata(index))
	var suggested_feats := GameDataLoader.get_feats_for_ability(selected_id)
	var feat_list := find_child("FeatList", true, false) as ItemList
	if feat_list == null:
		return

	# Highlight suggested feats without reprovisioning the full list
	for i in range(feat_list.get_item_count()):
		var meta := str(feat_list.get_item_metadata(i))
		if suggested_feats.has(meta):
			feat_list.set_item_custom_bg_color(i, Color8(68, 142, 181, 96))
		else:
			feat_list.set_item_custom_bg_color(i, Color(0, 0, 0, 0))
