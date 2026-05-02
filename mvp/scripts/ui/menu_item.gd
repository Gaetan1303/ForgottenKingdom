extends Button
class_name MenuItem

@export var icon_path: String = ""
@export var title_text: String = ""
@export var desc_text: String = ""

func _ready() -> void:
	# Construire l'affichage minimal si non défini dans l'éditeur
	if get_child_count() == 0:
		var h := HBoxContainer.new()
		h.name = "Layout"

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		h.add_child(icon)

		var v := VBoxContainer.new()
		v.name = "Texts"
		var title := Label.new()
		title.name = "Title"
		title.text = title_text
		title.add_theme_color_override("font_color", UIColors.TEXT)
		var desc := Label.new()
		desc.name = "Desc"
		desc.text = desc_text
		desc.add_theme_color_override("font_color", UIColors.MUTED)
		v.add_child(title)
		v.add_child(desc)

		h.add_child(v)
		add_child(h)

	# Style minimal: fond transparent, gros padding
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	self.focus_mode = Control.FOCUS_NONE

func set_data(title: String, desc: String, icon_p: String) -> void:
	title_text = title
	desc_text = desc
	icon_path = icon_p
	var icon = get_node_or_null("Layout/Icon")
	if icon and icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	var t = get_node_or_null("Layout/Texts/Title")
	if t:
		t.text = title_text
	var d = get_node_or_null("Layout/Texts/Desc")
	if d:
		d.text = desc_text
