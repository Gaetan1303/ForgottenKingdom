extends Control
const FallenUI = preload("res://scripts/ui/fallen_ui.gd")

const ITEM_DEF := [
	{"key":"new", "title":"Nouvelle partie", "desc":"Fonder une Maison déchue et reprendre votre héritage", "icon":"res://assets/icon/jeu.png"},
	{"key":"continue", "title":"Continuer", "desc":"Reprendre le dernier serment sauvegardé", "icon":"res://assets/images/clan/defaut.png"},
	{"key":"encyclo", "title":"Chroniques", "desc":"Relire les récits et secrets déjà révélés", "icon":"res://assets/images/clan/nine_nobles.png"},
	{"key":"options", "title":"Paramètres", "desc":"Audio, affichage et confort de jeu", "icon":""},
	{"key":"quit", "title":"Quitter", "desc":"Refermer les chroniques", "icon":""},
]

func _ready() -> void:
	FallenUI.apply(self, "main_menu")
	# Appliquer couleur de fond légère via script (évite problèmes de parsing du tscn)
	if has_node("Background"):
		$Background.color = UIColors.BG

	# Construire dynamiquement les éléments (scène légère et facile à debugger)
	var vbox := $MenuVBox
	# vider proprement les enfants existants
	while vbox.get_child_count() > 0:
		var c = vbox.get_child(0)
		vbox.remove_child(c)
		c.queue_free()
	for item in ITEM_DEF:
		var btn := MenuItem.new()
		btn.set_data(item.title, item.desc, item.icon)
		btn.name = "Btn_%s" % item.key
		vbox.add_child(btn)
		btn.pressed.connect(Callable(self, "_on_item_pressed").bind(item.key))

	# footer
	$Footer/SoundBtn.pressed.connect(_on_sound_toggled)

func _on_item_pressed(key: String) -> void:
	match key:
		"new":
			MenuActions.start_new_game()
		"continue":
			MenuActions.continue_game()
		"encyclo":
			MenuActions.open_encyclo()
		"options":
			MenuActions.open_options()
		"quit":
			MenuActions.quit_game()

func _on_sound_toggled() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var root = tree.root
		var am = root.get_node_or_null("AudioManager")
		if am and am.has_method("toggle_music"):
			am.toggle_music()
