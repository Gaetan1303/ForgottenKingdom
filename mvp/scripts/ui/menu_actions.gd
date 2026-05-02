extends Node
class_name MenuActions

static func start_new_game() -> void:
    var tree = Engine.get_main_loop() as SceneTree
    if not tree:
        return
    var gm = tree.root.get_node_or_null("GameManager")
    if gm and gm.has_method("start_new_game"):
        gm.start_new_game()

static func continue_game() -> void:
    var tree = Engine.get_main_loop() as SceneTree
    if not tree:
        return
    var root = tree.root
    var ss = root.get_node_or_null("SaveSystem")
    if ss and ss.has_method("load_last_save"):
        ss.load_last_save()
        return
    var gm = root.get_node_or_null("GameManager")
    if gm and gm.has_method("open_slot_select"):
        gm.open_slot_select()

static func open_encyclo() -> void:
    var tree = Engine.get_main_loop() as SceneTree
    if not tree:
        return
    var gm = tree.root.get_node_or_null("GameManager")
    if gm and gm.has_method("go_to"):
        gm.go_to("chapter_select")

static func open_options() -> void:
    var tree = Engine.get_main_loop() as SceneTree
    if not tree:
        return
    var gm = tree.root.get_node_or_null("GameManager")
    if gm and gm.has_method("go_to"):
        gm.go_to("main_menu")

static func quit_game() -> void:
    var tree = Engine.get_main_loop() as SceneTree
    if tree:
        tree.quit()
