## Base card for all animated class selection buttons.
## Subclasses override _play_idle_animation() for their own visual identity.
## Follows Open/Closed: extend without modifying this class.
class_name BaseClassCard
extends Button

@export var icon_path: String = ""
@export var class_id_key: String = ""

var _icon_rect: TextureRect = null
var _card_tween: Tween = null


func _ready() -> void:
	_build_icon()
	_play_idle_animation()


## Inserts a TextureRect at index 0 of the "CardContent" VBox built by the slide.
func _build_icon() -> void:
	var content := find_child("CardContent", true, false) as VBoxContainer
	if content == null:
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "ClassIcon"
	_icon_rect.expand = true
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = Vector2(0, 64)
	_icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.texture = _load_icon_texture()
	content.add_child(_icon_rect)
	content.move_child(_icon_rect, 0)


## Resolves the best available texture from icon_path or class_id_key fallback.
func _load_icon_texture() -> Texture2D:
	var path := icon_path.strip_edges()
	if path != "":
		if path.begins_with("mvp/"):
			path = path.replace("mvp/", "")
		if not path.begins_with("res://"):
			path = "res://%s" % path
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				return tex
	if class_id_key != "":
		var png := "res://assets/class_icons/%s.png" % class_id_key
		if ResourceLoader.exists(png):
			var tex := load(png) as Texture2D
			if tex != null:
				return tex
	return null


## Default animation: gentle float. Override in subclasses.
func _play_idle_animation() -> void:
	if _icon_rect == null:
		return
	_idle_pulse(Color(1, 1, 1, 1), Vector2.ONE, 1.1, 0.4)


func _new_idle_tween() -> Tween:
	_kill_tween()
	_card_tween = create_tween().set_loops()
	return _card_tween


func _idle_pulse(color: Color, scale: Vector2, duration: float, interval: float) -> void:
	if _icon_rect == null:
		return
	_new_idle_tween()
	_card_tween.tween_property(_icon_rect, "modulate", color, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale", scale, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_property(_icon_rect, "modulate", Color.WHITE, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(interval)


func _idle_rotation(color: Color, rotation: float, duration: float, interval: float) -> void:
	if _icon_rect == null:
		return
	_new_idle_tween()
	_card_tween.tween_property(_icon_rect, "rotation_degrees", rotation, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", color, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_property(_icon_rect, "rotation_degrees", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(interval)


func _idle_position(color: Color, offset: Vector2, duration: float, interval: float) -> void:
	if _icon_rect == null:
		return
	_new_idle_tween()
	_card_tween.tween_property(_icon_rect, "position", _icon_rect.position + offset, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", color, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_property(_icon_rect, "position", _icon_rect.position, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.parallel().tween_property(_icon_rect, "modulate", Color.WHITE, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_card_tween.tween_interval(interval)


func _kill_tween() -> void:
	if _card_tween != null and _card_tween.is_valid():
		_card_tween.kill()
	_card_tween = null
