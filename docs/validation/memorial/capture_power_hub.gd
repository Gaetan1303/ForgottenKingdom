extends SceneTree
const Refuge = preload("res://scripts/services/refuge_service.gd")
func _init() -> void:
 call_deferred("run")
func capture(title: String) -> void:
 for _i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/fk-memorial-validation/" + title + ".png")
func run() -> void:
 root.size = Vector2i(1280, 720)
 var cm := root.get_node("ClanManager")
 root.get_node("SaveSystem").set_active_slot("capture_hub")
 cm.nouvelle_partie("Aren", "Maison des Cendres", "hellcaster", {})
 Refuge.initialize(cm)
 cm.campaign.version = 3
 Refuge.prioritize_galleries(cm)
 Refuge.social_choice(cm, true)
 cm.advance_day_phase()
 cm.advance_day_phase()
 root.get_node("GameManager").open_clan_hub()
 for _i in range(8): await process_frame
 var routes: Control
 for node in current_scene.find_children("*", "VBoxContainer", true, false):
  if node.get_script() != null and node.get_script().resource_path.ends_with("power_routes_panel.gd"): routes = node
 if routes != null:
  current_scene.get_node("ContenuPrincipal/PanneauMaisons").scroll_vertical = int(routes.position.y)
  for route in ["diplomacy", "espionage", "occult", "command", "craft"]:
   routes._select(route)
   await capture("present_" + route)
 print("POWER_HUB_RENDER_OK")
 quit(0)
