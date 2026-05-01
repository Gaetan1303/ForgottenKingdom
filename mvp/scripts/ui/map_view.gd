## scripts/ui/map_view.gd
## Contrôleur de la carte interactive des lieux d'Ingrid.
extends Control

@onready var location_markers: Control = $MapOverlay/LocationMarkers
@onready var tooltip: PanelContainer = $Tooltip
@onready var tooltip_title: Label = $Tooltip/TooltipVBox/TooltipTitle
@onready var tooltip_period: Label = $Tooltip/TooltipVBox/TooltipPeriod
@onready var tooltip_desc: RichTextLabel = $Tooltip/TooltipVBox/TooltipDesc
@onready var btn_go_chapter: Button = $Tooltip/TooltipVBox/BtnGoChapitre
@onready var btn_menu: Button = $Timeline/BtnMenu
@onready var map_image: TextureRect = $MapContainer/MapViewport/MapImage

const MAP_SIZE := Vector2(1280, 634)
const MARKER_SIZE := 24.0

var _selected_location: Dictionary = {}


func _ready() -> void:
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
	# Default to demon realm map if present
	var default := "res://assets/images/demon_realm_map.png"
	if ResourceLoader.exists(default):
		map_image.texture = load(default)
		_sync_location_markers_to_image()
		return
	# fallback other candidates
	var paths := [
		"res://assets/images/demon_realm_map_1024.png",
		"res://assets/images/demon_realm_map_512.png",
		"res://assets/images/yomihara.png",
	]
	for p in paths:
		if ResourceLoader.exists(p):
			map_image.texture = load(p)
			_sync_location_markers_to_image()
			return


func _set_map(which: String) -> void:
	match which:
		"demon":
			var p := "res://assets/images/demon_realm_map.png"
			if ResourceLoader.exists(p):
				map_image.texture = load(p)
		"yomi":
			var p2 := "res://assets/images/yomihara.png"
			if ResourceLoader.exists(p2):
				map_image.texture = load(p2)
		_: pass
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
	btn.text = "*"
	btn.flat = true

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

	# Couleur selon visite
	var col: Color = Color(0.8, 0.5, 1.0) if visited else Color(0.5, 0.3, 0.7, 0.7)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.8, 1))

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
