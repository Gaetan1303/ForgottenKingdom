extends SceneTree

# Use global CharacterBuildService class_name from data scripts

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array = []
	# Test: feats_bonus merged into base before modifiers
	var class_bonus := {"force": 0, "magie": 0, "espionnage": 0, "artisanat": 0, "diplomatie": 0, "commandement": 0}
	var raw := {"force": 12, "magie": 12, "espionnage": 10, "artisanat": 10, "diplomatie": 10, "commandement": 10}
	var bonus_comp := {}
	var bonus_arc := {}
	var feats_bonus := {"force": 2, "magie": 1}
	var out := CharacterBuildService.compute_final_stats(class_bonus, raw, bonus_comp, bonus_arc, feats_bonus)
	# Note: compute_final_stats sanitizes class base with CLAN_MIN_STAT=1,
	# so initial base values are 1 before feats_bonus is merged.
	# Expected: force base = 1 + 2 -> then + modifier(raw.force=12 => +1) => 4
	if int(out.get("force", -999)) != 4:
		failures.append("feats_bonus: force attendu 4, obtenu %s" % str(out.get("force")))
	# Expected: magie base = 1 +1 -> modifier(raw.magie=12 => +1) => 3
	if int(out.get("magie", -999)) != 3:
		failures.append("feats_bonus: magie attendu 3, obtenu %s" % str(out.get("magie")))
	if failures.size() == 0:
		print("SMOKE_OK: feats_bonus")
		quit(0)
		return
	for f in failures:
		push_error("SMOKE_FAIL: %s" % f)
	quit(1)
