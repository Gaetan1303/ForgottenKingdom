extends SceneTree

const ResourcePathResolverScript = preload("res://scripts/utils/resource_path_resolver.gd")
const CorruptionServiceScript = preload("res://scripts/services/corruption_service.gd")
const CreatureProfileScript = preload("res://scripts/data/creature_profile.gd")
const CreatureFactoryScript = preload("res://scripts/factory/creature_factory.gd")
const CreatureRosterServiceScript = preload("res://scripts/services/creature_roster_service.gd")
const SoldierAssignmentServiceScript = preload("res://scripts/services/soldier_assignment_service.gd")
const ClanHouseServiceScript = preload("res://scripts/services/clan_house_service.gd")
const ClanEconomyServiceScript = preload("res://scripts/services/clan_economy_service.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_test_paths(failures)
	_test_corruption(failures)
	_test_creatures(failures)
	_test_soldiers(failures)
	_test_houses(failures)
	_test_economy(failures)
	_finish(failures)


func _test_paths(failures: Array[String]) -> void:
	var path: String = ResourcePathResolverScript.data("clan/etat_clan_defaut.json")
	if path != "res://data/clan/etat_clan_defaut.json" or not ResourcePathResolverScript.file_exists(path):
		failures.append("ResourcePathResolver: résolution data invalide")
	var resolved: String = ResourcePathResolverScript.resolve(path)
	if resolved != path:
		failures.append("ResourcePathResolver: resolve invalide")


func _test_corruption(failures: Array[String]) -> void:
	var service: Object = CorruptionServiceScript.new()
	service.call("register_character", "test", 60.0, ["loyal"])
	var result: Dictionary = service.call("apply_corruption", "source", "test", 70.0) as Dictionary
	if not bool(result.get("ok", false)):
		failures.append("CorruptionService: corruption refusée")
		return
	var profile: Dictionary = service.call("get_profile", "test") as Dictionary
	if int(profile.get("level", 0)) <= 0:
		failures.append("CorruptionService: niveau inchangé")
	var purified: Dictionary = service.call("apply_purification", "test", 10.0) as Dictionary
	if not bool(purified.get("ok", false)):
		failures.append("CorruptionService: purification refusée")


func _test_creatures(failures: Array[String]) -> void:
	var factory: Object = CreatureFactoryScript.new()
	var profile: Resource = factory.call("generate_profile", {
		"species_id": "imp",
		"nom": "Test Imp",
		"stats": {"force": 12},
	}) as Resource
	if profile == null or not bool(profile.call("is_valid")):
		failures.append("CreatureFactory: profil invalide")
		return
	var roster_service: Object = CreatureRosterServiceScript.new()
	var added: Dictionary = roster_service.call("add", [], profile) as Dictionary
	if not bool(added.get("ok", false)):
		failures.append("CreatureRosterService: ajout refusé")
		return
	var available: Array = roster_service.call("get_available", added.get("roster", []) as Array) as Array
	if available.size() != 1:
		failures.append("CreatureRosterService: disponibilité invalide")


func _test_soldiers(failures: Array[String]) -> void:
	var service: Object = SoldierAssignmentServiceScript.new()
	var pool: Array = []
	for index: int in range(5):
		pool.append({"id": "soldat_%d" % index, "etat": "disponible"})
	var assigned: Dictionary = service.call("assign", pool, {}, "mission_a", 2) as Dictionary
	if not bool(assigned.get("ok", false)):
		failures.append("SoldierAssignmentService: assignation refusée")
		return
	var released: Dictionary = service.call(
		"release",
		assigned.get("pool", []) as Array,
		assigned.get("assignments", {}) as Dictionary,
		"mission_a"
	) as Dictionary
	if not bool(released.get("ok", false)) or (released.get("pool", []) as Array).size() != 5:
		failures.append("SoldierAssignmentService: libération invalide")


func _test_houses(failures: Array[String]) -> void:
	var service: Object = ClanHouseServiceScript.new()
	var houses: Array = [{
		"id": 1,
		"nom": "Test",
		"relation": "neutre",
		"revelee": false,
		"espionnee": false,
		"bastions": [{"id": "b1", "defense": 3, "conquis": false}],
	}]
	var spied: Dictionary = service.call("mark_spied", houses, 1) as Dictionary
	if not bool(spied.get("ok", false)):
		failures.append("ClanHouseService: espionnage refusé")
		return
	var conquered: Dictionary = service.call("conquer_bastion", spied.get("houses", []) as Array, 1, "b1") as Dictionary
	if not bool(conquered.get("ok", false)) or str((conquered.get("house", {}) as Dictionary).get("relation", "")) != "soumise":
		failures.append("ClanHouseService: conquête invalide")


func _test_economy(failures: Array[String]) -> void:
	var service: Object = ClanEconomyServiceScript.new()
	if service == null:
		failures.append("ClanEconomyService: script non instanciable")
		return
	var resources: Dictionary = {"or": 100, "soldats": 50}
	var paid: Dictionary = service.call("spend", resources, {"or": 30}) as Dictionary
	if not bool(paid.get("ok", false)) or int((paid.get("resources", {}) as Dictionary).get("or", 0)) != 70:
		failures.append("ClanEconomyService: paiement invalide")
	var rejected: Dictionary = service.call("spend", resources, {"or": 101}) as Dictionary
	if bool(rejected.get("ok", true)):
		failures.append("ClanEconomyService: coût impossible accepté")


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("DOMAIN_SERVICES_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error("DOMAIN_SERVICES_FAIL: %s" % failure)
	quit(1)
