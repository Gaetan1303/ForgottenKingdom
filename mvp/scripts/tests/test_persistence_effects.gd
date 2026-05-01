## tests/test_persistence_effects.gd
extends SceneTree

func _initialize() -> void:
	var clan_mgr := get_root().get_node("ClanManager")
	assert(clan_mgr != null)
	# Prepare a fake profile with feats that give pv and mana bonuses
	var profil := {
		"feats": ["toughness", "mana_efficiency"]
	}
	# Call helper to compute and apply on the singleton instance
	clan_mgr._compute_and_apply_profil_effects(profil, true)
	# After application, profil should have computed_effects and flag
	assert(profil.has("computed_effects"))
	var ce := profil.get("computed_effects") as Dictionary
	assert(int(ce.get("pv_bonus", -999)) == 3)
	assert(int(ce.get("mana_bonus", -999)) == 5)
	# And ClanManager state should have been updated accordingly
	assert(int(clan_mgr.caracteristiques_hero.get("vigueur", 0)) >= 10 + 3)
	assert(int(clan_mgr.ressources.get("mana", 0)) >= 100 + 5)
	print("SMOKE_OK: persistence_effects")
	quit(0)
