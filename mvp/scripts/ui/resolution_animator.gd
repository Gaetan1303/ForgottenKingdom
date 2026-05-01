extends Node
class_name ResolutionAnimator

# ─────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────

const DURATION_MAIN := 1.2
const DURATION_POP  := 0.25

# ─────────────────────────────────────────────────────
# ANIMATION PRINCIPALE (barre + scores)
# ─────────────────────────────────────────────────────

func play_resolution(
	bar: Range,
	lbl_joueur: Label,
	lbl_res: Label,
	score_joueur: int,
	score_res: int,
	callback: Callable
) -> void:
	
	bar.value = 0
	
	var tween = create_tween()
	
	# Barre
	tween.tween_property(bar, "value", 100.0, DURATION_MAIN)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# Scores
	tween.parallel().tween_method(
		func(v): lbl_joueur.text = str(int(v)),
		0.0, float(score_joueur), DURATION_MAIN
	)
	
	tween.parallel().tween_method(
		func(v): lbl_res.text = str(int(v)),
		0.0, float(score_res), DURATION_MAIN
	)
	
	# Fin → callback
	tween.tween_callback(callback)

# ─────────────────────────────────────────────────────
# RESULTAT (POP + FADE)
# ─────────────────────────────────────────────────────

func play_result(label: Label, color: Color) -> void:
	label.scale = Vector2(0.6, 0.6)
	label.modulate = Color(color.r, color.g, color.b, 0.0)
	
	var tween = create_tween()
	
	# Animations parallèles
	tween.parallel()
	
	tween.tween_property(label, "modulate", Color(color.r, color.g, color.b, 1.0), DURATION_POP)
	
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), DURATION_POP)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_property(label, "scale", Vector2(1, 1), 0.1)

# ─────────────────────────────────────────────────────
# PULSE (COULEUR)
# ─────────────────────────────────────────────────────

func pulse(label: CanvasItem, color: Color, loops: int = 3) -> void:
	var tween = create_tween().set_loops(loops)
	
	tween.tween_property(label, "modulate", color * 1.3, 0.2)
	tween.tween_property(label, "modulate", color, 0.2)

# ─────────────────────────────────────────────────────
# SHAKE (IMPACT)
# ─────────────────────────────────────────────────────

func shake(node: Control, strength: float = 6.0, times: int = 6) -> void:
	var start_pos = node.position
	
	var tween = create_tween()
	
	for i in range(times):
		tween.tween_property(
			node,
			"position",
			start_pos + Vector2(randf_range(-strength, strength), 0),
			0.03
		)
	
	tween.tween_property(node, "position", start_pos, 0.05)

# ─────────────────────────────────────────────────────
# FLASH (OPTIONNEL)
# ─────────────────────────────────────────────────────

func flash(node: CanvasItem, color: Color) -> void:
	var tween = create_tween()
	
	node.modulate = color
	
	tween.tween_property(node, "modulate", Color.WHITE, 0.2)
