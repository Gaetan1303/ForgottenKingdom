extends Node2D

@export var texture_path: String = "res://assets/character.png"
@export var blink_texture_path: String = ""
@export var use_animated_sprite: bool = true
@export var animations_base_dir: String = "res://assets/animations/kiss"
@export var animation_name: String = "idle"
@export var anim_length: float = 1.0

var _time: float = 0.0
var _start_pos: Vector2 = Vector2.ZERO
var _sprite: Node2D = null
var _anim_sprite: AnimatedSprite2D = null
var _eyelid = null
var _start_eyelid_pos: Vector2 = Vector2.ZERO
var _closed_eyelid_pos: Vector2 = Vector2.ZERO
var _original_texture: Texture2D = null
var _blink_texture: Texture2D = null
@export var anim_fps: float = 12.0
@export var eyelid_width_factor: float = 0.45
@export var eyelid_alpha: float = 0.95
@export var use_eyelid_fallback: bool = false

var _frames_map: Dictionary = {}
var _current_anim_name: String = ""
var _current_frames: Array = []
var _frame_index: int = 0
var _frame_timer: float = 0.0
var _display_sprite: Sprite2D = null
var _blink_frames: Array = []
var _playing_blink: bool = false
var _blink_index: int = 0
var _blink_frame_time: float = 0.0

@export var bob_amplitude: float = 8.0
@export var bob_speed: float = 0.8
@export var breathe_amplitude: float = 0.03
@export var tilt_amplitude: float = 2.0
@export var tilt_speed: float = 0.25

@export var blink_min_interval: float = 2.0
@export var blink_max_interval: float = 5.0
@export var blink_duration: float = 0.12

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_blink_time: float = 0.0
var _is_blinking: bool = false
var _blink_elapsed: float = 0.0

func _ready():
	# choose between AnimatedSprite2D (preferred) or Sprite2D fallback
	var anim_node = null
	if use_animated_sprite:
		anim_node = get_node_or_null("AnimatedSprite2D")
		if anim_node == null:
			# try to find any AnimatedSprite2D descendant
			anim_node = _find_first_node_of_type(self, "AnimatedSprite2D")
		if anim_node == null:
			anim_node = AnimatedSprite2D.new()
			anim_node.name = "AnimatedSprite2D"
			anim_node.centered = true
			add_child(anim_node)
		_anim_sprite = anim_node

	# Sprite2D fallback (still used for procedural frames or single-texture setups)
	var sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = _find_first_sprite(self)
	if sprite == null and _anim_sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.centered = true
		add_child(sprite)

	var tex: Resource = null
	if texture_path != "" and ResourceLoader.exists(texture_path):
		tex = load(texture_path)
	if tex and sprite:
		# primary texture for Sprite2D fallback
		if sprite is Sprite2D:
			sprite.texture = tex
		_original_texture = tex

	# try load blink texture (optional). If present, we will swap textures during blink.
	if blink_texture_path != "":
		var btex = load(blink_texture_path)
		if btex and btex is Texture2D:
			_blink_texture = btex

	# Try load animations from directory (each subfolder = animation)
	var frames_map := _load_frame_arrays_from_dir(animations_base_dir)
	if frames_map.size() > 0:
		_frames_map = frames_map
		# create (or reuse) a display Sprite2D to show frames
		var display := get_node_or_null("Display") as Sprite2D
		if display == null:
			display = Sprite2D.new()
			display.name = "Display"
			display.centered = true
			add_child(display)
		_display_sprite = display
		# choose animation
		if "idle" in _frames_map:
			_current_anim_name = "idle"
		else:
			for k in _frames_map.keys():
				_current_anim_name = k
				break
		_current_frames = _frames_map.get(_current_anim_name, [])
		_frame_index = 0
		_frame_timer = 0.0
		if _current_frames.size() > 0 and _display_sprite:
			_display_sprite.texture = _current_frames[0]
			_original_texture = _display_sprite.texture
		if "blink" in _frames_map:
			_blink_frames = _frames_map["blink"]

	# store start position (use display sprite if present)
	if _display_sprite != null:
		_start_pos = _display_sprite.position
	else:
		var display_node: Node2D = _anim_sprite if _anim_sprite != null else sprite
		if display_node != null:
			_start_pos = display_node.position

	# Determine texture size (fallbacks if needed)
	var tex_w = 1
	var tex_h = 1
	if tex and tex.has_method("get_width"):
		tex_w = int(tex.get_width())
		tex_h = int(tex.get_height())
	elif sprite != null and sprite is Sprite2D and sprite.texture and sprite.texture.has_method("get_width"):
		tex_w = int(sprite.texture.get_width())
		tex_h = int(sprite.texture.get_height())
	elif _original_texture and _original_texture.has_method("get_width"):
		tex_w = int(_original_texture.get_width())
		tex_h = int(_original_texture.get_height())

	# Optional fallback blink overlay. Disabled by default because it can read as a black bar.
	if use_eyelid_fallback and _blink_texture == null and not ("blink" in _frames_map):
		# blink (eyelid) using Polygon2D
		var eyelid_h_px = int(tex_h * 0.22)
		# reduce eyelid width slightly to avoid a full-width black band
		var hw = tex_w * eyelid_width_factor
		var hh = max(eyelid_h_px, 4) * 0.5

		var eyelid = Polygon2D.new()
		eyelid.name = "Eyelid"
		eyelid.polygon = [
			Vector2(-hw, -hh),
			Vector2(hw, -hh),
			Vector2(hw, hh),
			Vector2(-hw, hh),
		]
		eyelid.modulate = Color(0, 0, 0, eyelid_alpha)

		var start_eyelid_pos = Vector2(0, -tex_h * 0.18)
		var closed_eyelid_pos = Vector2(0, -tex_h * 0.03)
		eyelid.position = start_eyelid_pos
		# Attach eyelid to whichever display node exists (Display sprite, AnimatedSprite2D, or fallback sprite)
		var eyelid_parent: Node = null
		if _display_sprite != null:
			eyelid_parent = _display_sprite
		elif _anim_sprite != null:
			eyelid_parent = _anim_sprite
		else:
			eyelid_parent = sprite
		if eyelid_parent:
			eyelid_parent.add_child(eyelid)
		_eyelid = eyelid
		_start_eyelid_pos = start_eyelid_pos
		_closed_eyelid_pos = closed_eyelid_pos

	# store sprite reference (use display sprite if present, otherwise AnimatedSprite2D or Sprite2D)
	if _display_sprite != null:
		_sprite = _display_sprite
	else:
		_sprite = _anim_sprite if _anim_sprite != null else sprite

	# init RNG and schedule first blink
	_rng.randomize()
	_next_blink_time = _time + _rng.randf_range(blink_min_interval, blink_max_interval)
	if _eyelid:
		# start nearly invisible; we'll show it only during a blink
		_eyelid.scale = Vector2(1, 0.02)
		_eyelid.visible = false

	# enable processing for procedural animation loop
	set_process(true)


func _find_first_sprite(root: Node) -> Sprite2D:
	for child in root.get_children():
		if child is Sprite2D:
			return child
		var res = _find_first_sprite(child)
		if res:
			return res
	return null


func _find_first_node_of_type(root: Node, type_name: String) -> Node:
	for child in root.get_children():
		if String(child.get_class()) == type_name:
			return child
		var res = _find_first_node_of_type(child, type_name)
		if res:
			return res
	return null


func _load_frames_from_dir(base_dir: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return frames

	# scan subdirectories (each subdir -> animation name)
	dir.list_dir_begin()
	var entry := dir.get_next()
	var found_any := false
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		if dir.current_is_dir():
			var anim_name := entry
			var sub := DirAccess.open(base_dir + "/" + anim_name)
			if sub:
				sub.list_dir_begin()
				var fname := sub.get_next()
				var files := []
				while fname != "":
					if not fname.begins_with(".") and not sub.current_is_dir():
						var ext := fname.get_extension().to_lower()
						if ext in ["png", "jpg", "jpeg", "webp", "bmp", "tga"]:
							files.append(fname)
					fname = sub.get_next()
				sub.list_dir_end()
				if files.size() > 0:
					files.sort()
					frames.add_animation(anim_name)
					for f in files:
						var p: String = base_dir + "/" + anim_name + "/" + f
						if ResourceLoader.exists(p):
							var t := load(p)
							if t and t is Texture2D:
								frames.add_frame(anim_name, t)
								found_any = true
		entry = dir.get_next()
	dir.list_dir_end()

	# if no subdirs, try files at base_dir as single 'idle' animation
	if not found_any:
		var dir2 := DirAccess.open(base_dir)
		if dir2:
			dir2.list_dir_begin()
			var f2 := dir2.get_next()
			var root_files := []
			while f2 != "":
				if not f2.begins_with(".") and not dir2.current_is_dir():
					var ex := f2.get_extension().to_lower()
					if ex in ["png", "jpg", "jpeg", "webp", "bmp", "tga"]:
						root_files.append(f2)
				f2 = dir2.get_next()
			dir2.list_dir_end()
			if root_files.size() > 0:
				root_files.sort()
				frames.add_animation("idle")
				for f in root_files:
					var p2: String = base_dir + "/" + f
					if ResourceLoader.exists(p2):
						var t2 := load(p2)
						if t2 and t2 is Texture2D:
							frames.add_frame("idle", t2)
							found_any = true

	return frames

func _load_frame_arrays_from_dir(base_dir: String) -> Dictionary:
	var res := {}
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return res

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		if dir.current_is_dir():
			var anim_name := entry
			var sub := DirAccess.open(base_dir + "/" + anim_name)
			if sub:
				sub.list_dir_begin()
				var fname := sub.get_next()
				var files := []
				while fname != "":
					if not fname.begins_with(".") and not sub.current_is_dir():
						var ext := fname.get_extension().to_lower()
						if ext in ["png", "jpg", "jpeg", "webp", "bmp", "tga"]:
							files.append(fname)
					fname = sub.get_next()
				sub.list_dir_end()
				if files.size() > 0:
					files.sort()
					var arr := []
					for f in files:
						var p: String = base_dir + "/" + anim_name + "/" + f
						if ResourceLoader.exists(p):
							var t := load(p)
							if t and t is Texture2D:
								arr.append(t)
					if arr.size() > 0:
						res[anim_name] = arr
		entry = dir.get_next()
	dir.list_dir_end()

	# if no subdirs, try files at base_dir as single 'idle' animation
	if res.size() == 0:
		var dir2 := DirAccess.open(base_dir)
		if dir2:
			dir2.list_dir_begin()
			var f2 := dir2.get_next()
			var root_files := []
			while f2 != "":
				if not f2.begins_with(".") and not dir2.current_is_dir():
					var ex := f2.get_extension().to_lower()
					if ex in ["png", "jpg", "jpeg", "webp", "bmp", "tga"]:
						root_files.append(f2)
				f2 = dir2.get_next()
			dir2.list_dir_end()
			if root_files.size() > 0:
				root_files.sort()
				var arr2 := []
				for f in root_files:
					var p2: String = base_dir + "/" + f
					if ResourceLoader.exists(p2):
						var t2 := load(p2)
						if t2 and t2 is Texture2D:
							arr2.append(t2)
				if arr2.size() > 0:
					res["idle"] = arr2

	return res


# AnimatedSprite2D blink helper removed — using manual frame playback via _frames_map instead.


func _process(delta: float) -> void:
	if _sprite == null:
		return
	_time += delta

	# Frame playback (manual) for current animation
	if _current_frames and _current_frames.size() > 0 and not _playing_blink:
		_frame_timer += delta
		var frame_dt: float
		if anim_length > 0.0 and _current_frames and _current_frames.size() > 0:
			frame_dt = anim_length / max(1.0, float(_current_frames.size()))
		else:
			frame_dt = 1.0 / max(0.0001, anim_fps)
		if _frame_timer >= frame_dt:
			var steps: int = int(_frame_timer / frame_dt)
			_frame_timer -= steps * frame_dt
			_frame_index = (_frame_index + steps) % _current_frames.size()
			if _display_sprite and _current_frames.size() > 0:
				_display_sprite.texture = _current_frames[_frame_index]

	# blinking playback via frames if available
	if _is_blinking:
		if _blink_frames and _blink_frames.size() > 0:
			# start blink playback
			if not _playing_blink:
				_playing_blink = true
				_blink_index = 0
				_blink_frame_time = blink_duration / max(1.0, float(_blink_frames.size()))
				_frame_timer = 0.0
				if _display_sprite:
					_display_sprite.texture = _blink_frames[0]
			else:
				_frame_timer += delta
				if _frame_timer >= _blink_frame_time:
					_frame_timer -= _blink_frame_time
					_blink_index += 1
					if _blink_index < _blink_frames.size():
						if _display_sprite:
							_display_sprite.texture = _blink_frames[_blink_index]
					else:
						# finished blink
						_playing_blink = false
						_is_blinking = false
						_blink_index = 0
						if _current_frames and _current_frames.size() > 0 and _display_sprite:
							_display_sprite.texture = _current_frames[_frame_index]
						_next_blink_time = _time + _rng.randf_range(blink_min_interval, blink_max_interval)
			# when using blink frames we handled the blink here; skip the other blink cases
			return

	# bobbing (sinus) and breathing
	var bob = sin(_time * bob_speed * TAU) * bob_amplitude
	var target_pos = _start_pos + Vector2(0, -bob)
	var smooth_t = clamp(10.0 * delta, 0.0, 1.0)
	_sprite.position = _sprite.position.lerp(target_pos, smooth_t)

	var s = 1.0 + breathe_amplitude * sin(_time * TAU * 0.5)
	var target_scale = Vector2(s, s)
	_sprite.scale = _sprite.scale.lerp(target_scale, smooth_t)

	# slight tilt for life (smoothed)
	var target_rot = tilt_amplitude * sin(_time * tilt_speed * TAU)
	_sprite.rotation_degrees = lerp(_sprite.rotation_degrees, target_rot, smooth_t)

	# blinking logic (random intervals, eased close/open)
	if _is_blinking:
		# If a single blink texture is provided and we are using a Sprite2D display
		if _blink_texture != null and _sprite is Sprite2D:
			_blink_elapsed += delta
			if _blink_elapsed >= blink_duration:
				# restore
				if _original_texture and _sprite:
					_sprite.texture = _original_texture
				_is_blinking = false
				_blink_elapsed = 0.0
				_next_blink_time = _time + _rng.randf_range(blink_min_interval, blink_max_interval)
		# polygon eyelid fallback
		elif _blink_frames.size() == 0:
			_blink_elapsed += delta
			var half = blink_duration * 0.5
			# initialize eyelid visibility/scale at blink start
			if _blink_elapsed <= delta:
				if _eyelid:
					_eyelid.visible = true
					_eyelid.scale = Vector2(1, 0.02)
			if _blink_elapsed < half:
				var p = _blink_elapsed / half
				var pe = sin(p * PI * 0.5)
				var scale_y = lerp(0.02, 1.0, pe)
				if _eyelid:
					_eyelid.scale = Vector2(1, scale_y)
			elif _blink_elapsed < blink_duration:
				var p = (_blink_elapsed - half) / half
				var pe = sin(p * PI * 0.5)
				var scale_y = lerp(1.0, 0.02, pe)
				if _eyelid:
					_eyelid.scale = Vector2(1, scale_y)
			else:
				_is_blinking = false
				_blink_elapsed = 0.0
				_next_blink_time = _time + _rng.randf_range(blink_min_interval, blink_max_interval)
				if _eyelid:
					_eyelid.scale = Vector2(1, 0.02)
					_eyelid.visible = false
	else:
		if _time >= _next_blink_time:
			_is_blinking = true
			_blink_elapsed = 0.0
			# If we have blink frames loaded in _frames_map, the top of _process handles playback.
			if "blink" in _frames_map:
				# nothing else to do; frame-based playback will start next tick
				pass
			# If using blink texture (Sprite2D) swap it now for the duration.
			elif _blink_texture != null and _sprite is Sprite2D:
				_sprite.texture = _blink_texture
