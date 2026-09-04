## autoload/game_manager.gd
## Singleton principal — gère la navigation entre scènes et l'état global du MVP.
extends Node

# Scènes enregistrées
const SCENES := {
	"main_menu":            "res://scenes/main_menu.tscn",
	"chapter_view":         "res://scenes/chapter_view.tscn",
	"chapter_select":       "res://scenes/chapter_select.tscn",
	"slot_select":          "res://scenes/slot_select.tscn",
	"map_view":             "res://scenes/map_view.tscn",
	"creation_personnage":  "res://scenes/character_creation/character_creation_screen.tscn",
	"clan_hub":             "res://scenes/clan_hub.tscn",
	"intro_vn":             "res://scenes/intro_vn.tscn",
	"resolution_action":    "res://scenes/resolution_action.tscn",
	"dungeon_view":         "res://scenes/dungeon_view.tscn",
	"pnj_manager":          "res://scenes/pnj_manager.tscn",
	"library_view":         "res://scenes/library_view.tscn",
}

# État global de la session
var current_chapter_id: int = 0
var current_scene_index: int = 0

# Référence à la scène active
var _current_scene: Node = null


func _ready() -> void:
	# La scène de démarrage est définie dans project.godot
	_current_scene = get_tree().current_scene
	_try_run_smoke_tests()
	if _is_headless_runtime():
		return
	# Global StopMusic UI removed to avoid duplicate audio controls
	# The main menu uses its own stop_icon footer button.


func _try_run_smoke_tests() -> void:
	if not _is_headless_runtime():
		return

	var args_user := OS.get_cmdline_user_args()
	var args_all := OS.get_cmdline_args()
	var run_smoke := args_user.has("--smoke-game-loop") or args_all.has("--smoke-game-loop") or OS.get_environment("FK_SMOKE") == "1"
	if not run_smoke:
		return

	push_warning("SMOKE_START: game loop")

	var failures: Array[String] = []

	var stats_bonus := {
		"force": 1,
		"magie": 1,
		"espionnage": 0,
		"artisanat": 0,
		"diplomatie": 0,
		"commandement": 1,
	}
	var profil := {
		"genre": "Femme",
		"apparence": "Noble exile",
		"pouvoir_magique": "Invocation de Faille",
		"pouvoir_magique_id": "demon_invocation",
		"archetype_pathfinder": "Ensorceleur abyssal (inspiration Magicien)",
		"don": "Tacticien de Champ de Bataille",
		"don_id": "battlefield_tactician",
		"competence": "Rituel occulte",
		"competence_id": "rituel_occulte",
		"equipement_depart": "Catalyseur runique",
		"equipement_depart_id": "catalyseur_runique",
		"magie_pactes": true,
		"traits_gameplay": {
			"mana_cost_reduction_pct": 30,
			"soldats_cost_reduction_attaquer_pct": 10,
			"bonus_score_actions": {"attaquer": 2, "recruter_pnj": 1},
			"night_soul_regen": 3,
			"night_reputation_gain": 1,
		},
	}

	ClanManager.nouvelle_partie("Aren", "Clan Test", "hellcaster", stats_bonus, profil)
	if ClanManager.nom_clan != "Clan Test":
		failures.append("nom_clan non initialise")

	var cout_recruter: Dictionary = ClanManager.get_action_cout_modifie("recruter", {"mana": 35})
	if int(cout_recruter.get("mana", -1)) >= 35:
		failures.append("reduction mana non appliquee")
	var cout_attaquer: Dictionary = ClanManager.get_action_cout_modifie("attaquer", {"soldats": 10})
	if int(cout_attaquer.get("soldats", 999)) >= 10:
		failures.append("reduction soldats non appliquee")

	if ClanManager.get_bonus_score_action("attaquer") <= 0:
		failures.append("bonus score attaquer absent")

	ClanManager.barre_ame = 90
	var rep_avant := ClanManager.get_ressource("reputation", 0)
	var msg_passifs: String = ClanManager.appliquer_passifs_nuit()
	if ClanManager.barre_ame <= 90:
		failures.append("passifs nuit: ame non regeneree")
	if ClanManager.get_ressource("reputation", 0) <= rep_avant:
		failures.append("passifs nuit: reputation non augmentee")
	if msg_passifs.is_empty():
		failures.append("passifs nuit: message vide")

	ClanManager.barre_ame = 0
	var etat_defaite: Dictionary = ClanManager.evaluer_etat_partie()
	if str(etat_defaite.get("etat", "")) != "defaite":
		failures.append("defaite barre_ame non detectee")

	if failures.is_empty():
		push_warning("SMOKE_OK: game loop")
		get_tree().quit(0)
		return

	for f in failures:
		push_error("SMOKE_FAIL: %s" % f)
	get_tree().quit(1)


## Change de scène avec un fondu optionnel.
func go_to(scene_key: String, data: Dictionary = {}) -> void:
	if not SCENES.has(scene_key):
		push_error("GameManager: scène inconnue '%s'" % scene_key)
		return

	# Sauvegarde la progression avant de changer de scène
	SaveSystem.save()

	get_tree().change_scene_to_file(SCENES[scene_key])
	# Attendre que la scène soit entièrement instanciée et _ready() exécuté
	await get_tree().process_frame
	await get_tree().process_frame
	_current_scene = get_tree().current_scene

	# Passe les données à la nouvelle scène si elle les accepte
	if data.size() > 0 and _current_scene.has_method("init_data"):
		_current_scene.init_data(data)


## Lance l'histoire depuis le début (chapitre 0, scène 0).
func start_story_from_beginning() -> void:
	current_chapter_id = 0
	current_scene_index = 0
	go_to("chapter_view", {"chapter_id": 0, "scene_index": 0})


## Ouvre un chapitre spécifique.
func open_chapter(chapter_id: int, scene_index: int = 0) -> void:
	current_chapter_id = chapter_id
	current_scene_index = scene_index
	go_to("chapter_view", {"chapter_id": chapter_id, "scene_index": scene_index})


## Retourne au menu principal.
func go_to_menu() -> void:
	go_to("main_menu")


## Ouvre la carte interactive.
func open_map() -> void:
	go_to("map_view")


## Ouvre la sélection de chapitres.
func open_chapter_select() -> void:
	go_to("chapter_select")


func open_slot_select() -> void:
	go_to("slot_select")


func open_library() -> void:
	go_to("library_view")


## ── Gameplay : gestion du clan ──────────────────────────────────────

## Lance une nouvelle partie → écran de création de personnage.
func start_new_game() -> void:
	go_to("creation_personnage")


## Ouvre le hub de gestion du clan.
func open_clan_hub() -> void:
	go_to("clan_hub")


## Ouvre la résolution d'une action avec les données de cible.
func open_resolution(action_data: Dictionary) -> void:
	go_to("resolution_action", action_data)


func open_dungeon() -> void:
	go_to("dungeon_view")


var _music_muted: bool = false


func _is_headless_runtime() -> bool:
	return OS.has_feature("headless") or DisplayServer.get_name() == "headless"

func toggle_music() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		idx = 0
	if not _music_muted:
		AudioServer.set_bus_volume_db(idx, -80.0)
		_music_muted = true
	else:
		AudioServer.set_bus_volume_db(idx, 0.0)
		_music_muted = false

func _deferred_connect_stop(stop_inst: Node) -> void:
	if not stop_inst:
		return
	var btn := stop_inst.get_node_or_null("BtnStopMusicGlobal")
	if btn:
		# try load icon at runtime for raster formats; skip SVG (import needed in editor)
		var icon_path := "res://assets/ui/stop_icon.svg"
		var ext := icon_path.get_extension().to_lower()
		if ext != "svg" and FileAccess.file_exists(icon_path):
			var tex := ResourceLoader.load(icon_path)
			if tex and tex is Texture2D:
				btn.icon = tex
				btn.text = ""
		btn.pressed.connect(func(): toggle_music())


## Déclenche le Bad End lié à la barre d'âme (Forme Dragon épuisée).
func declencher_bad_end_dragon() -> void:
	# Pour l'instant : retour au menu avec un message sauvegardé
	SaveSystem.set_value("bad_end_dragon", true)
	SaveSystem.save()
	go_to("main_menu")
