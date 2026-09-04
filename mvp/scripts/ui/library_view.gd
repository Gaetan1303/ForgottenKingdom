extends Control

var _sections: Array = []
var _category_list: ItemList
var _entry_list: ItemList
var _title: Label
var _body: RichTextLabel

func _ready() -> void:
	_build_ui()
	_sections = GameDataLoader.get_compendium_sections()
	_populate_categories()
	if not _sections.is_empty():
		_select_category(0)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.035, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)

	var h1 := Label.new()
	h1.text = "BIBLIOTHÈQUE DE VEYR"
	h1.add_theme_font_size_override("font_size", 30)
	h1.add_theme_color_override("font_color", Color(0.92, 0.82, 0.65, 1))
	heading.add_child(h1)

	var subtitle := Label.new()
	subtitle.text = "Monde · Couronnes · Classes · Talents · Capacités · Règles"
	subtitle.add_theme_color_override("font_color", Color(0.62, 0.58, 0.68, 1))
	heading.add_child(subtitle)

	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size = Vector2(120, 42)
	back.pressed.connect(func(): GameManager.go_to_menu())
	header.add_child(back)

	var columns := HSplitContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.split_offset = 285
	root.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(270, 0)
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)

	var cat_label := Label.new()
	cat_label.text = "Sections"
	cat_label.add_theme_font_size_override("font_size", 18)
	left.add_child(cat_label)

	_category_list = ItemList.new()
	_category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_list.select_mode = ItemList.SELECT_SINGLE
	_category_list.item_selected.connect(_select_category)
	left.add_child(_category_list)

	var right := HSplitContainer.new()
	right.split_offset = 320
	columns.add_child(right)

	var entries_box := VBoxContainer.new()
	entries_box.custom_minimum_size = Vector2(300, 0)
	right.add_child(entries_box)

	var entries_label := Label.new()
	entries_label.text = "Entrées"
	entries_label.add_theme_font_size_override("font_size", 18)
	entries_box.add_child(entries_label)

	_entry_list = ItemList.new()
	_entry_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_list.select_mode = ItemList.SELECT_SINGLE
	_entry_list.item_selected.connect(_select_entry)
	entries_box.add_child(_entry_list)

	var article := MarginContainer.new()
	article.add_theme_constant_override("margin_left", 18)
	article.add_theme_constant_override("margin_top", 8)
	article.add_theme_constant_override("margin_right", 8)
	article.add_theme_constant_override("margin_bottom", 8)
	right.add_child(article)

	var article_box := VBoxContainer.new()
	article_box.add_theme_constant_override("separation", 12)
	article.add_child(article_box)

	_title = Label.new()
	_title.text = "Sélectionnez une entrée"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(0.90, 0.72, 0.48, 1))
	article_box.add_child(_title)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 16)
	_body.add_theme_color_override("default_color", Color(0.84, 0.82, 0.86, 1))
	article_box.add_child(_body)

func _populate_categories() -> void:
	_category_list.clear()
	for section_data in _sections:
		var section := section_data as Dictionary
		_category_list.add_item(str(section.get("title", "Section")))
	if _category_list.item_count > 0:
		_category_list.select(0)

func _select_category(index: int) -> void:
	if index < 0 or index >= _sections.size():
		return
	_entry_list.clear()
	var section := _sections[index] as Dictionary
	var entries := section.get("entries", []) as Array
	for entry_data in entries:
		var entry := entry_data as Dictionary
		_entry_list.add_item(str(entry.get("title", "Entrée")))
		_entry_list.set_item_metadata(_entry_list.item_count - 1, entry.duplicate(true))
	if _entry_list.item_count > 0:
		_entry_list.select(0)
		_select_entry(0)
	else:
		_title.text = str(section.get("title", "Section"))
		_body.text = "Aucune entrée disponible."

func _select_entry(index: int) -> void:
	if index < 0 or index >= _entry_list.item_count:
		return
	var metadata: Variant = _entry_list.get_item_metadata(index)
	if not metadata is Dictionary:
		return
	var entry := metadata as Dictionary
	_title.text = str(entry.get("title", "Entrée"))
	_body.text = str(entry.get("text", ""))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_menu()
