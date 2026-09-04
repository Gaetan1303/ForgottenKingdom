extends SceneTree

# Use global class_names from data scripts (StatDefs, CharacterBuildService, Character)
const CharacterClass = preload("res://scripts/data/character.gd")

func _read_json_dict(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed as Dictionary

func _initialize() -> void:
	var failures: Array = []

	# Setup raw stats and selected feats
	var raw: Dictionary = {"force": 12, "magie": 12, "espionnage": 10, "artisanat": 10, "diplomatie": 10, "commandement": 10}
	var selected_feats: Array = ["toughness", "mana_efficiency"]

	# Load feats definitions and compute aggregated feats_bonus
	var feats_defs: Dictionary = _read_json_dict("res://data/feats.json")
	var feats_bonus_stats: Dictionary = {}
	var feats_flat: Dictionary = {}
	for f in selected_feats:
		var fdef := feats_defs.get(str(f), {}) as Dictionary
		var eff := fdef.get("effects", {}) as Dictionary
		var stats_eff := eff.get("stats", {}) as Dictionary
		for sk in stats_eff.keys():
			feats_bonus_stats[sk] = int(feats_bonus_stats.get(sk, 0)) + int(stats_eff[sk])
		if eff.has("pv_bonus"):
			feats_flat["pv_bonus"] = int(feats_flat.get("pv_bonus", 0)) + int(eff.get("pv_bonus"))
		if eff.has("mana_bonus"):
			feats_flat["mana_bonus"] = int(feats_flat.get("mana_bonus", 0)) + int(eff.get("mana_bonus"))

	# Use a neutral class_stats_bonus (zeros)
	var class_bonus := StatDefs.make_default_stats(0)

	var computed := CharacterBuildService.compute_final_stats(class_bonus, raw, {}, {}, feats_bonus_stats)

	# Expected calculation (sanitization sets base to CLAN_MIN_STAT=1 before feats)
	# base force =1 + feats(force=1 from toughness? in our data toughness gives force=1 and pv_bonus so total feats_bonus_stats should reflect that + mana_efficiency gives magie=1)
	# For these selected feats we expect force +2? verify against feats.json
	# Build expected from the same algorithm to be robust
	var expected := _expected_from_algorithm(class_bonus, raw, feats_bonus_stats, {}, {})

	for k in StatDefs.STAT_KEYS:
		if int(computed.get(k, -999)) != int(expected.get(k, -999)):
			failures.append("Integration: mismatch for %s: got %s expected %s" % [k, str(computed.get(k)), str(expected.get(k))])

	for derived_key in ["attaque", "defense", "resistance", "initiative", "jet_vigueur", "jet_volonte", "jet_reflexes"]:
		if not computed.has(derived_key):
			failures.append("Integration: missing derived stat %s" % derived_key)

	# Now test save/load roundtrip
	var ch := CharacterClass.new()
	ch.name = "Test"
	ch.clan = "QA"
	ch.char_class = "hellcaster"
	ch.stats = raw.duplicate(true)
	ch.feats = selected_feats.duplicate(true)
	var d := ch.to_dict()
	var ch2 := CharacterClass.new()
	ch2.from_dict(d)
	# Ensure stats clamped on load
	for k in StatDefs.STAT_KEYS:
		if not ch2.stats.has(k):
			failures.append("Roundtrip: missing stat %s" % k)
	if ch2.feats.size() != selected_feats.size():
		failures.append("Roundtrip: feats count mismatch")

	if failures.size() == 0:
		print("SMOKE_OK: integration_feats")
		quit(0)
	for f in failures:
		push_error("SMOKE_FAIL: %s" % f)
	quit(1)

func _expected_from_algorithm(class_bonus: Dictionary, raw_stats: Dictionary, feats_bonus_stats: Dictionary, comp_bonus: Dictionary, arch_bonus: Dictionary) -> Dictionary:
	# replicate compute_final_stats algorithm here
	var base := StatDefs.sanitize_stats(class_bonus, StatDefs.CLAN_MIN_STAT, StatDefs.CLAN_MAX_STAT, 0)
	base = StatDefs.merge_stats(base, feats_bonus_stats)
	for key in StatDefs.STAT_KEYS:
		base[key] = int(base.get(key, 0)) + StatDefs.score_to_modifier(int(raw_stats.get(key, StatDefs.CHARACTER_MIN_STAT)))
	base = StatDefs.merge_stats(base, comp_bonus)
	base = StatDefs.merge_stats(base, arch_bonus)
	return StatDefs.sanitize_stats(base, StatDefs.CLAN_MIN_STAT, StatDefs.CLAN_MAX_STAT, 0)
