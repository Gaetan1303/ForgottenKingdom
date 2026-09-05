extends SceneTree

const ClanIdentityType = preload("res://scripts/data/clan_identity.gd")
const CreationDataType = preload("res://scripts/ui/character_creation/creation_data.gd")
const CharacterType = preload("res://scripts/data/character.gd")

var _failures := 0


func _init() -> void:
	var expected_id := ClanIdentityType.id_from_name("Les Cendres")
	_assert(not expected_id.is_empty(), "l'identifiant de clan doit être généré")
	_assert(expected_id == ClanIdentityType.id_from_name("  les cendres  "), "l'identifiant doit être stable")

	var creation_data = CreationDataType.new()
	creation_data.set_clan_name("Les Cendres")
	var creation_payload: Dictionary = creation_data.to_dict()
	_assert(creation_payload.get("clan_id", "") == expected_id, "le brouillon doit contenir clan_id")
	_assert(creation_payload.get("clan_name", "") == "Les Cendres", "le brouillon doit contenir clan_name")

	var legacy_creation_data = CreationDataType.new()
	legacy_creation_data.load_dict({"clan": "Ancien Clan"})
	_assert(legacy_creation_data.clan_name == "Ancien Clan", "une ancienne clé clan doit rester lisible")
	_assert(not legacy_creation_data.clan_id.is_empty(), "un ancien brouillon doit recevoir un clan_id")

	var character = CharacterType.new("Ysra")
	character.from_dict({"name": "Ysra", "clan": "Ancien Clan"})
	var character_payload: Dictionary = character.to_dict()
	_assert(character_payload.get("clan", "") == "Ancien Clan", "la clé clan historique doit être préservée")
	_assert(character_payload.get("clan_name", "") == "Ancien Clan", "Character doit exposer clan_name")
	_assert(not str(character_payload.get("clan_id", "")).is_empty(), "Character doit exposer clan_id")

	if _failures == 0:
		print("CHARACTER_CLAN_REFERENCE_OK")
		quit(0)
		return
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CHARACTER_CLAN_REFERENCE_FAIL: %s" % message)
	_failures += 1
