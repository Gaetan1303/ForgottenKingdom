class_name EquipmentSlotCard
extends PanelContainer

signal item_dropped(slot_id: String, payload: Dictionary)

const EMPTY_BG := Color(0.08, 0.07, 0.07, 0.95)
const FILLED_BG := Color(0.17, 0.11, 0.08, 0.95)
const BORDER := Color(0.61, 0.43, 0.29, 1.0)

@export var slot_id: String = ""
@export var slot_label: String = ""
@export var accepted_types: PackedStringArray = []

var equipped_item: Dictionary = {}

@onready var _title_label := get_node_or_null("Body/Title") as Label
@onready var _item_label := get_node_or_null("Body/Item") as Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_view()


func get_equipped_item() -> Dictionary:
	return equipped_item.duplicate(true)


func set_equipped_item(item: Dictionary) -> void:
	equipped_item = item.duplicate(true)
	_update_view()


func clear_item() -> void:
	equipped_item = {}
	_update_view()


func _update_view() -> void:
	if _title_label:
		_title_label.text = slot_label if not slot_label.is_empty() else slot_id.capitalize()
	if _item_label:
		_item_label.text = str(equipped_item.get("label", "(vide)"))
	add_theme_stylebox_override("panel", _make_style(not equipped_item.is_empty()))


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var payload := data as Dictionary
	if str(payload.get("kind", "")) != "equipment_item":
		return false
	if not payload.has("item"):
		return false
	var item := payload["item"] as Dictionary
	var item_slot := str(item.get("slot_type", ""))
	if accepted_types.is_empty():
		return true
	return accepted_types.has(item_slot)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	emit_signal("item_dropped", slot_id, (data as Dictionary).duplicate(true))


func _get_drag_data(_at_position: Vector2) -> Variant:
	if equipped_item.is_empty():
		return null
	var payload := {
		"kind": "equipment_item",
		"item": equipped_item.duplicate(true),
		"source": "slot",
		"source_slot": slot_id,
	}
	set_drag_preview(_build_drag_preview())
	return payload


func _build_drag_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(190, 64)
	var style := _make_style(true)
	style.bg_color = Color(0.23, 0.15, 0.10, 0.95)
	preview.add_theme_stylebox_override("panel", style)
	var name_label := Label.new()
	name_label.text = str(equipped_item.get("label", "Objet equipe"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(name_label)
	return preview


func _make_style(filled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FILLED_BG if filled else EMPTY_BG
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
