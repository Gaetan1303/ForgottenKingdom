## tests/test_xp_level.gd
extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var clan_mgr := get_root().get_node("ClanManager")
	assert(clan_mgr != null)
	# Ensure fiches initialized
	clan_mgr._initialiser_fiches_personnage_et_domaine()
	var start_lvl := int(clan_mgr.fiche_hero.get("niveau", 1))
	var start_xp := int(clan_mgr.fiche_hero.get("experience", 0))
	# Give enough XP to level up twice (threshold = 100 * lvl)
	var give := 100 * start_lvl + 100 * (start_lvl + 1) + 10
	clan_mgr.donner_experience(give)
	var new_lvl := int(clan_mgr.fiche_hero.get("niveau", 1))
	assert(new_lvl >= start_lvl + 2)
	print("SMOKE_OK: xp_level")
	quit(0)
