## scripts/ui/map_view.gd
## Contrôleur de la carte interactive des lieux d'Ingrid.
extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")

@onready var location_markers: Control = $MapOverlay/LocationMarkers
@onready var tooltip: PanelContainer = $Tooltip
@onready var tooltip_title: Label = $Tooltip/TooltipVBox/TooltipTitle
@onready var tooltip_period: Label = $Tooltip/TooltipVBox/TooltipPeriod
@onready var tooltip_desc: RichTextLabel = $Tooltip/TooltipVBox/TooltipDesc
@onready var btn_go_chapter: Button = $Tooltip/TooltipVBox/BtnGoChapitre
@onready var btn_menu: Button = $Timeline/BtnMenu
@onready var map_image: TextureRect = $MapContainer/MapViewport/MapImage

const MAP_SIZE := Vector2(1280, 634)
const MARKER_SIZE := 30.0

var _selected_location: Dictionary = {}


func _ready() -> void:
	FallenUI.apply(self, "map")
	AudioManager.play_music("map_ambient.ogg")
	btn_menu.pressed.connect(func(): GameManager.go_to_menu())
	btn_go_chapter.pressed.connect(_on_go_chapter)
	tooltip.hide()

	# Connect timeline buttons for map switching
	if $Timeline.has_node("BtnDemonRealm"):
		$Timeline/BtnDemonRealm.pressed.connect(func(): _set_map("demon"))
	if $Timeline.has_node("BtnJapon"):
		$Timeline/BtnJapon.pressed.connect(func(): _set_map("yomi"))

	# Connect stop-music button if present (now under MapOverlay)
	var btn_stop := get_node_or_null("MapOverlay/BtnStopMusic") as Button
	if btn_stop:
		btn_stop.pressed.connect(func(): AudioManager.stop_music())

	# Load default map and build markers
	_try_load_map_image()
	_build_markers()


func _try_load_map_image() -> void:
	var texture: Texture2D = ResourcePathResolverScript.load_texture("demon_realm_map.png", "res://assets/images")
	if texture == null:
		texture = ResourcePathResolverScript.load_texture("demon_realm_map_1024.png", "res://assets/images")
	if texture == null:
		texture = ResourcePathResolverScript.load_texture("demon_realm_map_512.png", "res://assets/images")
	if texture == null:
		texture = ResourcePathResolverScript.load_texture("yomihara.png", "res://assets/images")
	if texture != null:
		map_image.texture = texture
		_sync_location_markers_to_image()


func _set_map(which: String) -> void:
	var texture: Texture2D = null
	match which:
		"demon":
			texture = ResourcePathResolverScript.load_texture("demon_realm_map.png", "res://assets/images")
			if texture == null:
				texture = ResourcePathResolverScript.load_texture("demon_realm_map_1024.png", "res://assets/images")
		"yomi":
			texture = ResourcePathResolverScript.load_texture("yomihara.png", "res://assets/images")
			if texture == null:
				texture = ResourcePathResolverScript.load_texture("yomihara_1024.png", "res://assets/images")
		_:
			pass
	if texture != null:
		map_image.texture = texture
	_sync_location_markers_to_image()
	# Rebuild markers to reflect any region-specific filtering
	_build_markers()


func _sync_location_markers_to_image() -> void:
	# Ensure overlay marker container matches the displayed map size
	if map_image.texture:
		var tex_size: Vector2 = Vector2i(map_image.texture.get_width(), map_image.texture.get_height())
		# Use texture native size as authoritative fallback to avoid editor-specific Control sizes in headless
		location_markers.custom_minimum_size = tex_size


func _build_markers(region_filter: String = "") -> void:
	# Remove existing markers
	for child in location_markers.get_children():
		child.queue_free()

	var locations: Array[Dictionary] = ChapterLoader.get_locations()
	var visited: Array = SaveSystem.get_value("visited_locations", [])

	for loc in locations:
		var region := str(loc.get("region", "")).to_lower()
		if region_filter != "" and region.find(region_filter) == -1:
			continue
		var marker := _create_marker(loc, loc.get("id", "") in visited)
		location_markers.add_child(marker)


func _create_marker(loc: Dictionary, visited: bool) -> Control:
	var btn := Button.new()
	btn.name = "Marker_" + (loc.get("id", "unknown") as String)
	btn.text = "◆"
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Position relative (0.0–1.0) → pixel (Control parent)
	var base: Vector2 = Vector2(map_image.texture.get_width(), map_image.texture.get_height()) if map_image.texture else MAP_SIZE
	var px: int = int(float(loc.get("pos_x", 0.5)) * base.x)
	var py: int = int(float(loc.get("pos_y", 0.5)) * base.y)
	btn.custom_minimum_size = Vector2(MARKER_SIZE, MARKER_SIZE)
	# use anchors/offsets for precise placement within Control parent
	btn.anchor_left = 0.0
	btn.anchor_top = 0.0
	btn.anchor_right = 0.0
	btn.anchor_bottom = 0.0
	var off_x: int = px - int(MARKER_SIZE * 0.5)
	var off_y: int = py - int(MARKER_SIZE * 0.5)
	btn.offset_left = off_x
	btn.offset_top = off_y
	btn.offset_right = off_x + int(MARKER_SIZE)
	btn.offset_bottom = off_y + int(MARKER_SIZE)

	# Sceau cartographique : or pour les lieux visités, violet pour l'inconnu.
	var marker_color: Color = FallenUI.GOLD if visited else FallenUI.VIOLET
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.04, 0.02, 0.06, 0.82)
	normal_style.border_color = marker_color
	normal_style.set_border_width_all(1 if not visited else 2)
	normal_style.set_corner_radius_all(15)
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.18, 0.07, 0.20, 0.94)
	hover_style.border_color = FallenUI.GOLD
	hover_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_color_override("font_color", marker_color)
	btn.add_theme_color_override("font_hover_color", Color("fff1c8"))

	btn.pressed.connect(_on_marker_pressed.bind(loc, btn))
	return btn


func _on_marker_pressed(loc: Dictionary, marker: Button) -> void:
	_selected_location = loc

	tooltip_title.text = loc.get("nom", "?")
	tooltip_period.text = loc.get("region", "")
	tooltip_desc.text = loc.get("description", "")

	var ch_id: int = loc.get("chapitre_associe", -1)
	btn_go_chapter.visible = ch_id >= 0
	if ch_id >= 0:
		btn_go_chapter.text = "Chapitre %d" % (ch_id + 1)

	# Position du tooltip : à droite du marqueur, ou à gauche si trop près du bord
	# For Control marker, use global rect to compute tooltip position
	var mr_rect: Rect2 = marker.get_global_rect()
	var marker_center: Vector2 = mr_rect.position + mr_rect.size * 0.5
	var tp_x: float = marker_center.x + 30.0
	if tp_x + 300.0 > get_viewport_rect().size.x:
		tp_x = marker_center.x - 310.0
	var tp_y: float = clamp(marker_center.y - 40.0, 10.0, get_viewport_rect().size.y - tooltip.size.y - 10.0)
	tooltip.global_position = Vector2(tp_x, tp_y)
	tooltip.show()

	# Marque le lieu comme visité
	SaveSystem.visit_location(loc.get("id", ""))


func _on_go_chapter() -> void:
	var ch_id: int = _selected_location.get("chapitre_associe", -1)
	if ch_id >= 0:
		GameManager.open_chapter(ch_id, 0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Clic en dehors du tooltip → ferme le tooltip
		if tooltip.visible and not tooltip.get_global_rect().has_point(event.position):
			tooltip.hide()
			_selected_location = {}
	elif event.is_action_pressed("ui_cancel"):
		GameManager.go_to_menu()
