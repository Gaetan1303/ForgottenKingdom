# Migration vers le projet Godot unique `mvp/`

## Audit préalable — 11 septembre 2026

Base : `Dev`, commit `693a1f8`, arbre propre. La branche locale `dev`
(`ce81184`) est un ancêtre de `Dev`, 78 commits en arrière. Aucun changement
de branche ni fusion : la version actuelle du tutoriel reste la référence.

Le dossier demandé comme `/Game` est réellement `game/` (Linux sensible à la
casse). Il contient neuf fichiers JSON/YAML, aucun projet, script, asset ou scène.
`mvp/project.godot` est déjà l'unique projet. L'inventaire exhaustif par fichier,
taille et catégorie est dans [MVP_INITIAL_INVENTORY.tsv](MVP_INITIAL_INVENTORY.tsv).
Les occurrences demandées, y compris `res://`, `user://`, chemins historiques,
temporaires et documentation, sont dans [MVP_INITIAL_REFERENCES.tsv](MVP_INITIAL_REFERENCES.tsv).
Ces deux fichiers figent l'état **avant** modification.

`mvp/` possède 184 scripts, 27 scènes, 6 ressources `.tres`, 20 JSON, 4 YAML,
14 CSV de progression, 2 shaders, 81 images PNG/WebP, et les sources audio
MP3/OGG/WAV. Aucun shader ou police ne vient de `game/` ; la police est celle
du thème Godot. Aucun shell HTML personnalisé. Les fichiers de cache copiés
dans `assets/audio/music/` et les traductions générées par l'import erroné des
CSV de statistiques ne sont pas des sources. Aucun `.godot/` n'est suivi par Git.

## Table de décision avant suppression

| Ancien fichier | Destination canonique | Référencé par | Classement et action |
| --- | --- | --- | --- |
| `game/clan/etat_clan_defaut.json` | `mvp/data/clan/etat_clan_defaut.json` | `ClanManager.DEFAULT_STATE_PATH` utilise déjà mvp | OBSOLETE : supprimer l'ancien état Ingrid, conserver Veyr et les champs actuels |
| `game/phases/config_tour.json` | `mvp/data/phases/config_tour.json` | `GameDataLoader` utilise déjà mvp | OBSOLETE : conserver les résultats normalisés et la configuration actuelle |
| `game/events/evenements_jour_nuit.json` | `mvp/data/events/evenements_jour_nuit.json` | données événementielles mvp | OBSOLETE : ancien canon remplacé par Veyr |
| `game/characters/affinites_pnj_initiales.json` | `mvp/data/clan/affinites_pnj_initiales.json` | `GameDataLoader` utilise déjà mvp | OBSOLETE : conserver les factions et affinités actuelles |
| `game/characters/creation_personnage.yaml` | `mvp/data/classes.json`, `feats.json`, `abilities.json`, `equipment.json`, `character_traits.json` | création modulaire, `GameDataLoader` | OBSOLETE : ancien système de trois classes remplacé par quatorze classes |
| `game/world/nine_noble_houses.yaml` | `mvp/data/world/houses.json` | monde Veyr, test d'identité originale | OBSOLETE : ancien lore externe ; ne pas le réintroduire |
| `game/world/lore_monde.yaml` | `mvp/data/library_entries.json`, `mvp/story/chroniques_veyr.yaml` | bibliothèque et narration actuelles | OBSOLETE : ancien canon externe sans lecteur runtime |
| `game/world/chevaliers_infernaux.yaml` | monde Veyr dans `mvp/data/` | aucun consommateur de l'ancien fichier | OBSOLETE : conception historique, pas une dépendance |
| `game/world/especes_demoniaques.yaml` | profils et créatures dans `mvp/scripts/`, `mvp/resources/` | aucun consommateur de l'ancien fichier | OBSOLETE : conception historique, pas une dépendance |

Aucune migration ni fusion de ces neuf fichiers n'est nécessaire : leurs
fonctions sont remplacées ou abandonnées. L'historique Git suffit pour retrouver
les anciennes versions. Leur suppression est différée jusqu'aux tests et à
l'export Web réussis.

Autres doublons repérés : quatre GDScripts à la racine `scripts/{ui,data,utils}`
ne sont accessibles depuis aucun `res://` du projet. Leurs versions actives sont
dans `mvp/scripts/`, dont la création modulaire. Le faux preset Android dans
`mvp/godot_presets/` n'est pas un preset d'export Godot valide et n'a aucun lecteur.

## Chemins et export à corriger

- Aucune dépendance runtime à `game/`, `/tmp` ou un répertoire utilisateur Linux.
  Une mention historique dans l'en-tête de `ClanManager` doit être corrigée.
- `/tmp` dans les outils de validation sert à isoler les tests et sauvegardes :
  ce n'est pas une ressource embarquée et doit rester un répertoire temporaire.
- Les sauvegardes et portraits importés par le joueur restent dans `user://`.
- Les JSON, YAML et CSV lus par `FileAccess` doivent être explicitement exportés.
- Les ressources importées doivent être trouvées avec `ResourceLoader`, y compris
  la musique et les illustrations d'événements. Les noms avec espaces/accents
  sont conservés quand les références correspondent exactement aux sources.
- La configuration Web doit utiliser Compatibility et un seul thread.
- Le preset est unique ; les outils doivent déterminer la racine par leur propre
  chemin, sans sélection d'un autre projet ni dépendance au répertoire courant.
- Pages doit publier `build/web` contenant `index.html`, `.wasm`, `.pck`, `.js`.
- CI et export doivent employer Godot 4.4 et ses templates de même version.

## Autoloads et frontières

Les sept autoloads ont une portée globale effective : `GameManager` orchestre
les transitions, `SaveSystem` les slots, `AudioManager` la continuité audio,
`ChapterLoader` la narration, `ClanManager` la façade de partie, `GameDataLoader`
les données partagées et `DungeonGenerator` la génération d'expéditions.
Leurs chemins sont tous sous `res://scripts/autoload/`. Les collaborations entre
managers restent runtime ; aucun autoload ne précharge un autre singleton.
L'import propre et le démarrage doivent confirmer l'absence de cycle de compilation.

## Audio

Les sources sont déjà dans `mvp/assets/audio/`. Deux `AudioStreamPlayer` sont
créés par `AudioManager` ; aucun lecteur 2D/3D ni bus personnalisé n'est défini.
Les bus Music/SFX nommés par le code sont maintenant fournis par `default_bus_layout.tres`. Le démarrage Web attendra
un clic, toucher ou clavier, puis utilisera le contexte audio du moteur.
Le chargement de musique actuel via `FileAccess.file_exists` est incompatible
avec les remappages d'import du PCK. Les fondus et le comportement desktop restent. Les callbacks de fondu sont libérés à leur fin. Les trois SFX `click`, `whoosh` et `swing` ont été testés via le service ; les scènes existantes n'appellent pas `play_sfx`, et aucun nouveau déclencheur UI/combat n'a été ajouté.

Références : [export Web Godot 4.4](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html),
[FileAccess Godot 4.4](https://docs.godotengine.org/en/4.4/classes/class_fileaccess.html).

## État final et suppressions

`game/` a été supprimé après 55 contrôles réussis, démarrage et export Web dans
une copie contenant seulement `mvp/`. Aucun fichier de `game/` n'a été déplacé :
les neuf remplaçants métier étaient déjà actifs. Leurs anciennes variantes ne
sont pas fusionnées dans le canon Veyr.

[Le manifeste de nettoyage](MVP_CLEANUP.tsv) détaille 476 autres suppressions :
266 traductions accidentelles des CSV, 79 `.md5`, 57 `.ctex`, 57 UID de dérivés,
8 `.mp3str`, 4 logs, 4 scripts racine remplacés et 1 faux preset. **485 fichiers
supprimés au total**, sans suppression d'image, son, CSV ou donnée runtime utile.
Les 14 `.csv.import` utilisent désormais `keep` ; la lecture des statistiques
reste brute et leurs sources sont explicitement incluses dans l'export.

Le resolver trouve les ressources importées et n'essaie plus de récupérer des
images depuis le cache `.godot/imported` à la place de sources manquantes. Le
chargement du portrait dans l'ancienne façade de création utilise également
`ResourceLoader` pour `res://` et conserve les images utilisateur en base64.
Le générateur YAML `EditorScript` reste un outil d'éditeur, jamais un autoload ;
son fichier `user://yaml_convert.py` n'est pas une dépendance du jeu exporté.

Le contrôle `scripts/audit_mvp_paths.py` valide l'unique projet, les chemins runtime,
les outils CI/export, la casse des ressources et l'absence des arbres historiques.
Ses rejets ont aussi été vérifiés avec des fixtures contenant `res://Game/`,
`/tmp/runtime.json` et `/opt/runtime.json`. Les répertoires temporaires des outils
sont distincts des dépendances runtime.

## Validation effectuée

- Avant modification (`Dev@693a1f8`) : **51/51 tests historiques**, démarrage OK.
- Avant suppression de `game/` : **55/55 contrôles** = 51 tests historiques,
  2 nouveaux tests (`test_clan_economy_compatibility`, `test_export_resources`),
  import et démarrage. La caractérisation économique passait aussi sur l'ancien code.
- Après suppression : la même suite complète **55/55**, et démarrage direct du
  répertoire de travail avec Godot 4.4 et dossiers utilisateur isolés.
- Aucune erreur de parsing ou compilation ni régression de test restante.
- Import headless : diagnostics connus du moteur (sockets restreintes/dialogue de
  progression) et UID dupliqués de certains alias de sources ; ils sont conservés
  dans les résultats bruts, pas assimilés à des échecs métier. La CI échoue sur les
  erreurs de scripts/import réelles, y compris quand Godot retourne zéro.
- Export Godot 4.4 avec templates officiels `4.4.stable` : HTML, WASM, JS et PCK
  produits. Le chargement depuis le **PCK seul** valide 80 textures dans `assets/`,
  48 flux audio, 38 données JSON/YAML/CSV et 27 scènes. L'icône du projet s'ajoute
  aux textures d'assets, d'où 81 sources d'images dans l'inventaire complet.
- `test_prologue_navigation.gd` exécuté depuis le PCK : `PROLOGUE_NAVIGATION_OK`.
  Parcours réel conservé : menu → slot → introduction → six souvenirs/tutoriels
  → création → domaine/Brèche-Sèche → expédition ; sauvegarde/reprise et relecture
  sans double application des gains également vérifiées.
- Chromium : menu, nouvelle campagne, introduction et premier souvenir affichés,
  aucun 404 ni erreur JavaScript. Aucun démarrage de piste avant interaction ;
  signal audio non nul après clic. Contexte suspendu puis repris sur interaction.

Les résultats détaillés et les SHA-256 de l'export final sont enregistrés dans
[MVP_VALIDATION.json](MVP_VALIDATION.json). Le build produit est conservé dans
`build/web/` (ignoré par Git), les logs et captures dans `build/validation/`.
La sonde desktop finale retourne `DESKTOP_AUDIO_OK` avec un code zéro et sans erreur
à la fermeture ; les pics SFX mesurés sont 0,752 (click), 0,385 (whoosh), 0,839 (swing).
Le chargement des portraits par l'ancienne façade a aussi été testé depuis le PCK.
Le contrôle final Chromium 153 retourne `WEB_AUDIO_OK` : zéro piste avant geste,
signal après clic, contexte `suspended` puis `running` avec pic 0,112 après reprise,
zéro 404 et zéro erreur JavaScript. La mesure attend un signal sur plusieurs
échantillons afin de ne pas confondre une amorce silencieuse et un défaut de lecture.

## Reproduire

```bash
./scripts/ci_test.sh
./scripts/export_web.sh
# Vérifier les ressources avec le pack sans dépendre du projet source :
godot --headless --main-pack build/web/index.pck --script "$PWD/mvp/scripts/tests/test_export_resources.gd"
# Vérification de navigation sur le pack (avec un XDG_DATA_HOME de test isolé) :
godot --headless --main-pack build/web/index.pck --script "$PWD/mvp/scripts/tests/test_prologue_navigation.gd"
# Mixage desktop, sans haut-parleurs si Dummy est utilisé :
godot --path mvp --audio-driver Dummy --script res://tools/check_desktop_audio.gd
```

Les scripts de test de pack et la sonde desktop doivent également être lancés avec
`XDG_CONFIG_HOME` et `XDG_DATA_HOME` isolés, comme les autres suites. Le script CI
le fait automatiquement. Les logs/exports restent ignorés dans `build/` ou le
répertoire de validation temporaire ; seuls les résultats synthétiques sont documentés.

## Limites et legacy restant

- GitHub Actions/Pages n'ont pas été déclenchés à distance. Le workflow pointe sur
  `build/web`, vérifie les quatre fichiers et utilise `Dev` avec Godot 4.4 ; les
  paramètres Pages du dépôt et une URL publique ne sont pas certifiés par ce test local.
- La validation navigateur couvre Chromium local, pas Safari/iOS ni tous les
  périphériques. Le mixage desktop est mesuré ; aucune écoute humaine des haut-parleurs
  n'est revendiquée. IndexedDB reste soumis aux réglages de stockage du navigateur.
- Les alias de noms d'assets historiques (accents/encodages) restent dans `mvp/`
  pour ne pas casser les références existantes. Certains conservent des UID d'import
  dupliqués : leurs chemins exacts et leur chargement ont été vérifiés.
- Huit chemins optionnels sans source sont explicitement documentés par l'audit :
  deux cartes procédurales, quatre portraits de profils à repli, l'icône facultative
  d'arrêt et la texture facultative de l'ancienne scène d'animation. Ils n'appellent
  pas de preload manquant ; aucun asset de remplacement n'a été inventé.
- Les shims de compatibilité `CreatureFactory`, `CreatureProfile`, `ResourcePathResolver`
  restent dans `mvp/` et héritent des implémentations canoniques. `WorldState` et son
  adaptateur restent des snapshots/transitions, sans logique ajoutée.

