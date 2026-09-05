extends SceneTree

const SCENE := preload("res://scenes/character_creation/slides/slide_02_class_stats.tscn")

func _init() -> void:
	var slide := SCENE.instantiate()
	root.add_child(slide)

	_assert(slide.find_child("ClassesBand", true, false) != null, "bande horizontale des classes absente")
	_assert(slide.find_child("ClassesScroll", true, false) is ScrollContainer, "scroll horizontal des classes absent")
	_assert(slide.find_child("BottomSplit", true, false) is HBoxContainer, "partie basse en deux blocs absente")
	_assert(slide.find_child("StatsScroll", true, false) is ScrollContainer, "scroll des caractéristiques absent")
	_assert(slide.find_child("ProgressionSummary", true, false) is ScrollContainer, "scroll de progression absent")
	_assert(slide.find_child("PointsPoolLabel", true, false).text == "Points restants : 10 / 10", "budget initial incorrect")

	for key in ["force", "magie", "espionnage", "artisanat", "diplomatie", "commandement"]:
		_assert(slide.find_child("Stat_%s" % key, true, false) != null, "stat principale absente: %s" % key)
		_assert(slide.find_child("Info_%s" % key, true, false) != null, "icone info absente: %s" % key)

	for key in ["ESP", "TRA", "ESE"]:
		_assert(slide.find_child("Secondary_%s" % key, true, false) != null, "stat secondaire absente: %s" % key)
		_assert(slide.find_child("Info_%s" % key, true, false) != null, "icone info secondaire absente: %s" % key)

	print("PASS: slide 2 T layout structure")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("FAIL: %s" % message)
	quit(1)
