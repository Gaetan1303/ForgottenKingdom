## Vue modale commune des résultats. Elle affiche uniquement des données déjà
## résolues et n'applique jamais de conséquence métier.
class_name EventResultView
extends Control

const Presenter = preload("res://scripts/ui/event_result_presenter.gd")

signal result_confirmed

var _already_confirmed: bool = false
var _presented_result: Dictionary = {}

@onready var _title: Label = $ModalCenter/Panel/Layout/Header/Title
@onready var _illustration_frame: Control = $ModalCenter/Panel/Layout/ContentScroll/Content/IllustrationFrame
@onready var _illustration: TextureRect = $ModalCenter/Panel/Layout/ContentScroll/Content/IllustrationFrame/Illustration
@onready var _description: Label = $ModalCenter/Panel/Layout/ContentScroll/Content/Description
@onready var _effects: VBoxContainer = $ModalCenter/Panel/Layout/ContentScroll/Content/Effects
@onready var _continue_button: Button = $ModalCenter/Panel/Layout/Footer/ContinueButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_continue_button.visible = true
	_continue_button.disabled = false
	if not _continue_button.pressed.is_connected(_on_continue_pressed):
		_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.grab_focus()


func present(raw_result: Dictionary) -> void:
	_presented_result = Presenter.normalize(raw_result)
	_already_confirmed = false
	visible = true
	_title.text = str(_presented_result.get("title", "Résultat"))
	_description.text = str(_presented_result.get("description", ""))
	var texture := Presenter.resolve_illustration(str(_presented_result.get("illustration_path", "")))
	_illustration.texture = texture
	_illustration_frame.visible = texture != null
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_render_effects(_presented_result.get("effects", []) as Array)
	_continue_button.visible = true
	_continue_button.disabled = false
	_continue_button.grab_focus()


func confirm_result() -> void:
	_on_continue_pressed()


func get_presented_result() -> Dictionary:
	return _presented_result.duplicate(true)


func get_continue_button() -> Button:
	return _continue_button


func get_illustration_rect() -> TextureRect:
	return _illustration


func _on_continue_pressed() -> void:
	if _already_confirmed:
		return
	_already_confirmed = true
	_continue_button.disabled = true
	result_confirmed.emit()
	hide()


func _render_effects(entries: Array) -> void:
	for child in _effects.get_children():
		child.queue_free()
	for entry_value in entries:
		if not (entry_value is Dictionary):
			continue
		var entry := entry_value as Dictionary
		var row := HBoxContainer.new()
		row.name = "EffectRow"
		row.add_theme_constant_override("separation", 8)
		var icon_path := str(entry.get("icon_path", ""))
		if not icon_path.is_empty():
			var icon := TextureRect.new()
			icon.name = "EffectIcon"
			icon.custom_minimum_size = Vector2(24, 24)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = Presenter.resolve_illustration(icon_path)
			if icon.texture != null:
				row.add_child(icon)
		var label := Label.new()
		label.name = "EffectText"
		label.text = str(entry.get("text", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		_effects.add_child(row)
