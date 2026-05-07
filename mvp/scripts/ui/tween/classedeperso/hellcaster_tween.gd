extends Button

class_name HellcasterTween

@export var icon_path: String = ""

@onready var sprite: TextureRect = get_node_or_null("Sprite2D")
@onready var flames_left: TextureRect = get_node_or_null("FlameLeft")
@onready var flames_right: TextureRect = get_node_or_null("FlameRight")

func _ready() -> void:
	_build_placeholders()
	_load_icon()
	idle_animation()
	flame_animation()

func _build_placeholders() -> void:
	if sprite == null:
		sprite = TextureRect.new()
		sprite.name = "Sprite2D"
		sprite.anchor_right = 1.0
		sprite.anchor_bottom = 1.0
		sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sprite.size_flags_vertical = Control.SIZE_FILL
		add_child(sprite)

	if flames_left == null:
		flames_left = TextureRect.new()
		flames_left.name = "FlameLeft"
		flames_left.scale = Vector2.ONE
		flames_left.modulate = Color(1, 1, 1, 1)
		flames_left.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		flames_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(flames_left)

	if flames_right == null:
		flames_right = TextureRect.new()
		flames_right.name = "FlameRight"
		flames_right.scale = Vector2.ONE
		flames_right.modulate = Color(1, 1, 1, 1)
		flames_right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		flames_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(flames_right)

func _load_icon() -> void:
	if icon_path == "":
		return
	var path := icon_path
	if path.begins_with("mvp/"):
		path = path.replace("mvp/", "")
	if not path.begins_with("res://"):
		path = "res://%s" % path
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D

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
	var tween = create_tween().set_loops()

	# pulse des flammes
	tween.parallel().tween_property(
		flames_left,
		"scale",
		Vector2(1.15, 1.15),
		0.5
	)
	
	tween.parallel().tween_property(
		flames_right,
		"scale",
		Vector2(1.15, 1.15),
		0.5
	)

	tween.parallel().tween_property(
		flames_left,
		"modulate:a",
		0.7,
		0.5
	)

	tween.parallel().tween_property(
		flames_right,
		"modulate:a",
		0.7,
		0.5
	)

	tween.parallel().tween_property(
		flames_left,
		"scale",
		Vector2.ONE,
		0.5
	)

	tween.parallel().tween_property(
		flames_right,
		"scale",
		Vector2.ONE,
		0.5
	)

	tween.parallel().tween_property(
		flames_left,
		"modulate:a",
		1.0,
		0.5
	)

	tween.parallel().tween_property(
		flames_right,
		"modulate:a",
		1.0,
		0.5
	)
