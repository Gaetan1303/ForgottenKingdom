extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const DateTimeFormatterClass = preload("res://scripts/services/date_time_formatter.gd")

var _slots: Array = []
var _selected_slot_id: String = ""
var _portrait_texture_cache: Dictionary = {}

func _ready() -> void:
	FallenUI.apply(self, "default")
	_connect_ui()
	_refresh_slots()


func _connect_ui() -> void:
	$Root/Body/LeftPanel/LeftContent/SlotList.item_selected.connect(_on_slot_selected)
	$Root/Actions/BtnLoad.pressed.connect(_on_load_pressed)
	$Root/Actions/BtnNewOverwrite.pressed.connect(_on_new_overwrite_pressed)
	$Root/Actions/BtnDelete.pressed.connect(_on_delete_pressed)
	$Root/Actions/BtnBack.pressed.connect(_on_back_pressed)
	$ConfirmDelete.confirmed.connect(_on_confirm_delete)
	$Root/Body/RightPanel/RightContent/BtnSaveName.pressed.connect(_on_save_name_pressed)
	$ConfirmNewOverwrite.confirmed.connect(_on_confirm_new_overwrite)


func _refresh_slots() -> void:
	_slots = SaveSystem.list_slot_summaries()
	var list := $Root/Body/LeftPanel/LeftContent/SlotList as ItemList
	list.clear()
	for slot in _slots:
		var d := slot as Dictionary
		var sid := str(d.get("slot_id", "slot"))
		var active_mark := "* " if bool(d.get("is_active", false)) else ""
		var has_data := bool(d.get("has_clan", false)) or bool(d.get("has_progress", false))
		var slot_name := str(d.get("slot_name", ""))
		var display := slot_name if not slot_name.is_empty() else sid
		var label := "%s%s %s" % [active_mark, display, "(occupé)" if has_data else "(vide)"]
		list.add_item(label)
	if list.item_count > 0:
		list.select(0)
		_on_slot_selected(0)


func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	var slot := _slots[index] as Dictionary
	_selected_slot_id = str(slot.get("slot_id", ""))
	_render_summary(slot)


func _render_summary(slot: Dictionary) -> void:
	var txt := $Root/Body/RightPanel/RightContent/SummaryText as Label
	var portrait := $Root/Body/RightPanel/RightContent/PortraitPreview as TextureRect
	var slot_name_edit := $Root/Body/RightPanel/RightContent/SlotNameEdit as LineEdit
	var nom_clan := str(slot.get("nom_clan", ""))
	var nom_perso := str(slot.get("nom_personnage", ""))
	var tour := int(slot.get("tour_actuel", 0))
	var chapter := int(slot.get("last_chapter", 0))
	var scene := int(slot.get("last_scene", 0))
	var time_sec := float(slot.get("play_time_seconds", 0.0))
	var has_data := bool(slot.get("has_clan", false)) or bool(slot.get("has_progress", false))

	if not has_data:
		txt.text = "Slot vide.\n\nActions disponibles :\n- Nouvelle / Écraser : démarre une nouvelle campagne dans ce slot\n- Supprimer : nettoie complètement le slot"
		portrait.texture = null
		slot_name_edit.text = str(slot.get("slot_name", ""))
		return

	var updated_unix := int(slot.get("updated_at_unix", 0))
	var updated_str: String = DateTimeFormatterClass.format_local_datetime(updated_unix)
	var display_slot_name := _slot_display_name(slot)

	txt.text = "Nom du slot : %s\nClan : %s\nPersonnage : %s\nTour : %d\nChronique de Veyr : %d / scène %d\nTemps joué : %02dh%02d\nDernière sauvegarde : %s" % [
		display_slot_name,
		nom_clan if not nom_clan.is_empty() else "-",
		nom_perso if not nom_perso.is_empty() else "-",
		tour,
		chapter,
		scene,
		_format_play_time_hours(time_sec),
		_format_play_time_minutes(time_sec),
		updated_str,
	]

	portrait.texture = _texture_from_portrait_payload(slot.get("portrait", {}) as Dictionary)
	slot_name_edit.text = str(slot.get("slot_name", ""))


func _texture_from_portrait_payload(payload: Dictionary) -> Texture2D:
	if payload.is_empty():
		return null
	if str(payload.get("encoding", "")) != "png_base64":
		return null
	var encoded := str(payload.get("data", ""))
	if encoded.is_empty():
		return null
	var raw := Marshalls.base64_to_raw(encoded)
	if raw.is_empty():
		return null
	# Cache to avoid recreating textures for identical payloads
	var cache_key := String(encoded).sha256_text()
	if _portrait_texture_cache.has(cache_key):
		return _portrait_texture_cache[cache_key]
	var image := Image.new()
	if image.load_png_from_buffer(raw) != OK:
		return null
	var tex := ImageTexture.create_from_image(image)
	_portrait_texture_cache[cache_key] = tex
	return tex


func _exit_tree() -> void:
	if _portrait_texture_cache.size() > 0:
		print("slot_select: clearing portrait texture cache (count=", _portrait_texture_cache.size(), ")")
		_portrait_texture_cache.clear()


func _on_load_pressed() -> void:
	if _selected_slot_id.is_empty():
		_status("Sélectionnez un slot.")
		return
	SaveSystem.set_active_slot(_selected_slot_id)
	SaveSystem.load_save()
	if bool(SaveSystem.get_value("opening", {}).get("active", false)):
		GameManager.resume_campaign()
		return
	if not SaveSystem.slot_has_clan_save(_selected_slot_id):
		_status("Ce slot ne contient pas de campagne complète. Utilisez 'Nouvelle / Écraser'.")
		return
	if not ClanManager.charger_sauvegarde():
		_status("Impossible de charger l'état du clan pour ce slot.")
		return
	GameManager.resume_campaign()


func _on_new_overwrite_pressed() -> void:
	if _selected_slot_id.is_empty():
		_status("Sélectionnez un slot.")
		return
	# If the slot already contains data, ask for confirmation
	var summary := SaveSystem.get_slot_summary(_selected_slot_id)
	var has_data := bool(summary.get("has_clan", false)) or bool(summary.get("has_progress", false))
	SaveSystem.set_active_slot(_selected_slot_id)
	if has_data:
		$ConfirmNewOverwrite.popup_centered_ratio(0.4)
		return
	# otherwise proceed immediately
	SaveSystem.clear_slot(_selected_slot_id)
	GameManager.start_new_game()


func _on_confirm_new_overwrite() -> void:
	if _selected_slot_id.is_empty():
		return
	SaveSystem.clear_slot(_selected_slot_id)
	GameManager.start_new_game()


func _on_delete_pressed() -> void:
	if _selected_slot_id.is_empty():
		_status("Sélectionnez un slot.")
		return
	$ConfirmDelete.popup_centered_ratio(0.4)


func _on_confirm_delete() -> void:
	if _selected_slot_id.is_empty():
		return
	SaveSystem.delete_slot(_selected_slot_id)
	if _selected_slot_id == SaveSystem.get_active_slot():
		SaveSystem.load_save()
	_refresh_slots()
	_status("Slot supprimé: %s" % _selected_slot_id)


func _on_save_name_pressed() -> void:
	if _selected_slot_id.is_empty():
		_status("Sélectionnez un slot.")
		return
	var slot_name := str($Root/Body/RightPanel/RightContent/SlotNameEdit.text).strip_edges()
	SaveSystem.set_slot_name(_selected_slot_id, slot_name)
	_refresh_slots()
	_status("Nom du slot enregistré.")


func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")


func _status(message: String) -> void:
	$Root/Status.text = message


func _slot_display_name(slot: Dictionary) -> String:
	var sid := str(slot.get("slot_id", "slot"))
	var custom_name := str(slot.get("slot_name", "")).strip_edges()
	if custom_name.is_empty():
		return sid
	return custom_name


func _format_play_time_hours(time_sec: float) -> int:
	var total_seconds := int(time_sec)
	return int(floor(float(total_seconds) / 3600.0))


func _format_play_time_minutes(time_sec: float) -> int:
	var total_seconds := int(time_sec)
	var remainder := total_seconds % 3600
	return int(floor(float(remainder) / 60.0))
