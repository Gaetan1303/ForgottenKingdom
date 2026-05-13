class_name InventoryItemCard
extends PanelContainer

const NORMAL_BG := Color(0.11, 0.08, 0.06, 0.95)
const BORDER := Color(0.57, 0.42, 0.30, 1.0)

var item_data: Dictionary = {}

@onready var _name_label := get_node_or_null("Body/Name") as Label
@onready var _slot_label := get_node_or_null("Body/Slot") as Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not has_theme_stylebox_override("panel"):
		add_theme_stylebox_override("panel", _make_style())
	_update_view()


func set_item_data(data: Dictionary) -> void:
	item_data = data.duplicate(true)
	_update_view()


func get_item_data() -> Dictionary:
	return item_data.duplicate(true)


func _update_view() -> void:
	if _name_label:
		_name_label.text = str(item_data.get("label", ""))
	if _slot_label:
		var slot := str(item_data.get("slot_type", ""))
		_slot_label.text = "Type: %s" % slot.capitalize()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data.is_empty():
		return null
	var payload := {
		"kind": "equipment_item",
		"item": item_data.duplicate(true),
		"source": "inventory",
	}
	set_drag_preview(_build_drag_preview())
	return payload


func _build_drag_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(190, 64)
	var style := _make_style()
	style.bg_color = Color(0.21, 0.14, 0.10, 0.95)
	preview.add_theme_stylebox_override("panel", style)
	var name_label := Label.new()
	name_label.text = str(item_data.get("label", "Objet"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(name_label)
	return preview


func _make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = NORMAL_BG
	style.border_color = BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style
