class_name InventoryItemGrid
extends GridContainer

signal item_dropped_in_grid(payload: Dictionary)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var payload := data as Dictionary
	return str(payload.get("kind", "")) == "equipment_item"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	emit_signal("item_dropped_in_grid", (data as Dictionary).duplicate(true))
