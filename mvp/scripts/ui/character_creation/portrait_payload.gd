## Node helper for image upload and payload serialization inside the character creation flow.
class_name PortraitPayload
extends Control

@onready var _preview: TextureRect = null
@onready var _path_label: Label = null
@onready var _file_dialog: FileDialog = null

var portrait_data: Dictionary = {}

func _ready() -> void:
	_preview = find_child("PreviewBox", true, false) as TextureRect
	_path_label = find_child("PortraitPathLabel", true, false) as Label
	_file_dialog = find_child("PortraitFileDialog", true, false) as FileDialog
	if _file_dialog != null:
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_file_dialog.clear_filters()
		_file_dialog.add_filter("*.png ; PNG Image")
		_file_dialog.add_filter("*.jpg ; JPG Image")
		_file_dialog.add_filter("*.jpeg ; JPEG Image")
		_file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	_load_payload(portrait_data)

func to_dict() -> Dictionary:
	return portrait_data.duplicate(true)

func load_from_dict(payload: Dictionary) -> void:
	portrait_data = (payload.duplicate(true) if payload else {})
	_load_payload(portrait_data)

func reset() -> void:
	portrait_data = {}
	_clear_preview()

func _load_payload(payload: Dictionary) -> void:
	if payload.has("image_base64"):
		var base64 := str(payload["image_base64"])
		if base64 != "":
			var raw := Marshalls.base64_to_raw(base64)
			var image := Image.new()
			if image.load_png_from_buffer(raw) == OK:
				if _preview != null:
					_preview.texture = ImageTexture.create_from_image(image)
				if _path_label != null and payload.has("file_name"):
					_path_label.text = str(payload["file_name"])
				elif _path_label != null:
					_path_label.text = "Portrait chargé"
				return
	var file_path := str(payload["image_path"]) if payload.has("image_path") else ""
	if file_path != "" and FileAccess.file_exists(file_path):
		var file_image := _open_image_file(file_path)
		if file_image != null:
			if _preview != null:
				_preview.texture = ImageTexture.create_from_image(file_image)
			if _path_label != null and payload.has("file_name"):
				_path_label.text = str(payload["file_name"])
			elif _path_label != null:
				_path_label.text = file_path.get_file()
			return
	_clear_preview()

func _clear_preview() -> void:
	if _preview != null:
		_preview.texture = null
	if _path_label != null:
		_path_label.text = "Aucun portrait sélectionné"

func _on_file_selected(path: String) -> void:
	var image := _open_image_file(path)
	if image == null:
		return
	var texture := ImageTexture.create_from_image(image)
	if texture:
		if _preview != null:
			_preview.texture = texture
		portrait_data = {
			"file_name": path.get_file(),
			"image_path": path,
			"image_base64": Marshalls.raw_to_base64(image.save_png_to_buffer()),
		}
		if _path_label != null:
			_path_label.text = path.get_file()

func _on_upload_portrait_pressed() -> void:
	if _file_dialog != null:
		_file_dialog.popup_centered_ratio(0.6)

func _on_reset_portrait_pressed() -> void:
	reset()

func _open_image_file(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var image := Image.new()
	if image.load_png_from_buffer(bytes) == OK:
		return image
	if image.load_jpg_from_buffer(bytes) == OK:
		return image
	if image.load_webp_from_buffer(bytes) == OK:
		return image
	return null
