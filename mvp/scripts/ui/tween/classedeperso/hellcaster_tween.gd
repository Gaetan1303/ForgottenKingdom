extends Button

class_name HellcasterTween

@export var icon_path: String = ""

const HELLCASTER_ICON_PATH := "res://assets/class_icons/hellcaster.png"
const FLAME_TEXTURE_PATHS := [
	"res://assets/class_icons/flame.png",
]

@onready var sprite: TextureRect = get_node_or_null("Sprite2D")
@onready var flames_left: TextureRect = get_node_or_null("FlameLeft")
@onready var flames_right: TextureRect = get_node_or_null("FlameRight")

var _left_base_position: Vector2 = Vector2.ZERO
var _right_base_position: Vector2 = Vector2.ZERO
var _flame_tween: Tween

func _ready() -> void:
	_build_placeholders()
	_load_icon()
	flame_animation()

func _build_placeholders() -> void:
	var sprite_holder: Control = null
	if sprite == null:
		sprite = TextureRect.new()
		sprite.name = "Sprite2D"
		sprite.expand = true
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.custom_minimum_size = Vector2(96, 88)
		sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sprite.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var content = find_child("CardContent", true, false) as VBoxContainer
		if content != null:
			sprite_holder = Control.new()
			sprite_holder.name = "SpriteHolder"
			sprite_holder.custom_minimum_size = Vector2(0, 90)
			sprite_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sprite_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sprite_holder.clip_contents = false
			var sprite_spacer = Control.new()
			sprite_spacer.custom_minimum_size = Vector2(0, 0)
			sprite_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sprite_spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			content.add_child(sprite_spacer)
			content.add_child(sprite_holder)
			sprite_holder.add_child(sprite)
			sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
			sprite.offset_left = 8
			sprite.offset_top = -8
			sprite.offset_right = -8
			sprite.offset_bottom = -14
		else:
			add_child(sprite)

	if flames_left == null:
		flames_left = TextureRect.new()
		flames_left.name = "FlameLeft"
		flames_left.texture = _create_flame_texture()
		flames_left.modulate = Color(1, 0.45, 0.12, 0.9)
		flames_left.expand = true
		flames_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flames_left.custom_minimum_size = Vector2(22, 28)
		flames_left.position = Vector2(16, 8)
		flames_left.z_index = 10
		flames_left.visible = true
		flames_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sprite_holder != null:
			sprite_holder.add_child(flames_left)
		else:
			add_child(flames_left)

	if flames_right == null:
		flames_right = TextureRect.new()
		flames_right.name = "FlameRight"
		flames_right.texture = _create_flame_texture()
		flames_right.modulate = Color(1, 0.55, 0.15, 0.9)
		flames_right.expand = true
		flames_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flames_right.custom_minimum_size = Vector2(22, 28)
		flames_right.position = Vector2(88, 8)
		flames_right.z_index = 10
		flames_right.visible = true
		flames_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sprite_holder != null:
			sprite_holder.add_child(flames_right)
		else:
			add_child(flames_right)

	_left_base_position = flames_left.position
	_right_base_position = flames_right.position

func _load_icon() -> void:
	var path := icon_path
	if path == "":
		path = HELLCASTER_ICON_PATH
	if path.begins_with("mvp/"):
		path = path.replace("mvp/", "")
	if not path.begins_with("res://"):
		path = "res://%s" % path
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D
		if sprite.texture == null:
			print("[HellcasterTween] icon load failed:", path)
			sprite.texture = _create_placeholder_texture()
		else:
			print("[HellcasterTween] icon loaded:", path)
	else:
		print("[HellcasterTween] icon not found:", path)
		sprite.texture = _create_placeholder_texture()

func _create_placeholder_texture() -> Texture2D:
	var tex: Texture2D = _load_first_texture([
		HELLCASTER_ICON_PATH
	])
	if tex == null:
		print("[HellcasterTween] placeholder texture fallback not found")
	return tex

func _create_flame_texture() -> Texture2D:
	var tex: Texture2D = _load_first_texture(FLAME_TEXTURE_PATHS)
	if tex == null:
		print("[HellcasterTween] flame texture fallback not found")
	return tex

func _load_first_texture(paths: Array) -> Texture2D:
	for raw_path in paths:
		var path := String(raw_path)
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				return tex
	return null

func idle_animation() -> void:
	var tween = create_tween().set_loops()

	# monte légèrement
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y - 12,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# redescend
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func flame_animation() -> void:
	if flames_left == null or flames_right == null:
		return

	if _flame_tween != null:
		_flame_tween.kill()

	_left_base_position = flames_left.position
	_right_base_position = flames_right.position
	flames_left.scale = Vector2.ONE
	flames_right.scale = Vector2.ONE

	_flame_tween = create_tween().set_loops()

	# phase 1: montée + pulse
	_flame_tween.parallel().tween_property(flames_left, "position", _left_base_position + Vector2(-2, -6), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flame_tween.parallel().tween_property(flames_right, "position", _right_base_position + Vector2(2, -6), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flame_tween.parallel().tween_property(flames_left, "scale", Vector2(1.18, 1.18), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flame_tween.parallel().tween_property(flames_right, "scale", Vector2(1.16, 1.16), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flame_tween.parallel().tween_property(flames_left, "modulate:a", 0.62, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flame_tween.parallel().tween_property(flames_right, "modulate:a", 0.65, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# sépare bien les deux phases pour éviter des tweens concurrents sur la même propriété
	_flame_tween.tween_interval(0.02)

	# phase 2: retour
	_flame_tween.parallel().tween_property(flames_left, "position", _left_base_position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flame_tween.parallel().tween_property(flames_right, "position", _right_base_position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flame_tween.parallel().tween_property(flames_left, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flame_tween.parallel().tween_property(flames_right, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flame_tween.parallel().tween_property(flames_left, "modulate:a", 0.9, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flame_tween.parallel().tween_property(flames_right, "modulate:a", 0.9, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
