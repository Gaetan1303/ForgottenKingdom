> Rapport historique de la première fondation. Le parcours et les validations actuels (Kael seule, automates, arrivée, corruption) sont dans [le rapport suivant](../arrival/README.md).

# Socle du prologue jouable — 6 septembre 2026

Implémentation sur `22-refonte-de-lintro-avec-la-nouvelle-histoire`, à partir du commit `7fdd486`, conformément à la confirmation de conserver cette branche. Aucune fusion ni modification de branche.

## Parcours livré

Une nouvelle partie conserve le créateur actuel (10 points, +1 par point, bonus de classe séparés, identité de Maison sauvegardée), puis ouvre une introduction de six séquences. Deux choix interactifs remplacent la longue exposition ; sauver les cristaux ou un registre produit des gains distincts et persistants.

La Brèche-Sèche devient la vue initiale du hub. Kael, Vaelen, Miri et Sylas utilisent le registre de personnages existant. Le joueur peut réparer un grenier, une palissade, ou privilégier les galeries. Une réparation consomme une décision de demi-journée, ses vrais matériaux et une affectation de soutien du planificateur existant. La ration disparue offre deux décisions avec coût de nourriture et conséquence d’affinité.

Une sortie emporte l’héritier et un ou deux compagnons disponibles. Les premières galeries contiennent une observation, deux goules, puis une cache. Le combat sur une grille de 6 × 4 cases propose initiative, déplacement, attaque, Trait d’Éther, portée, coût de mana et fin de tour. Les dégâts sont expliqués. Le mana est celui du domaine ; le butin et l’expérience rejoignent les systèmes canoniques au retour. Les compagnons gravement blessés deviennent indisponibles jusqu’aux soins ou à l’aube. Une retraite reste possible.

L’atelier coûte les matériaux rapportés, produit du fer et ouvre la forge. Examiner la relique permet de la sceller ou de laisser résonner la Cicatrice de Sang : le second choix consomme essence et âme contre du mana. L’objectif devient naturellement la restauration du refuge et l’enquête sur la destruction de la Maison. Les sorties suivantes réutilisent le générateur existant de dix étages avec le même combat tactique.

Les objectifs, décisions, aides déjà vues, bâtiments, état du combat, butin et état des compagnons sont conservés. Le chargement rejoint l’introduction au bon choix ou la sortie active. Les archives n’affichent que les découvertes et les aides connues pour ces nouvelles campagnes. Les modes d’aide complète, réduite et désactivée ne conditionnent aucune décision narrative.

## Architecture et compatibilité

- `ClanManager.campaign` est un champ supplémentaire de la sauvegarde du clan, écrit avec les ressources et le registre des habitants. Il n’existe pas de sauvegarde métier concurrente dans `progress.json`.
- `RefugeService` porte les règles du domaine, les coûts, la production, les conséquences sociales, les soins et la première résonance. Les réparations réutilisent `assigner_pnj_support_journee` et le calcul de `PnjDailyPlannerService`.
- `TacticalCombatService` porte les règles de combat et valide chaque commande avant mutation. `DungeonGenerator` orchestre le parcours, les unités, le butin, les retours et leur persistance.
- Le script existant `tutorial_director.gd`, jusque-là non déclaré comme autoload et non utilisé, devient un petit catalogue d’objectifs et d’aides dérivés des accomplissements réels.
- `refuge_panel.gd` s’insère dans la colonne existante du hub ; `dungeon_view.gd` reste la scène d’exploration. Les illustrations, thèmes et effets existants sont conservés, avec des corrections ciblées de placement.
- Une ancienne sauvegarde sans `campaign` garde son parcours et son donjon historique. Les nouvelles réserves et la production modeste du refuge ne lui sont pas appliquées.
- Le monde courant contient neuf Couronnes. Ces données sont conservées ; le sceau effacé introduit un mystère sans réécrire les Maisons pour imposer les huit familles évoquées dans le document initial.

## Validation exécutée

Godot **4.4.stable.official.4c311cbee**. Import et exécution dans `/tmp/fk-prologue-validation/project`, avec `XDG_CONFIG_HOME` et `XDG_DATA_HOME` isolés. Aucun lancement de l’éditeur dans le dépôt de travail.

| Contrôle | Résultat |
| --- | --- |
| `test_playable_prologue.gd` | `PLAYABLE_PROLOGUE_OK` : coûts, affectations, refus sans mutation, combat gagnable, sauvegarde au milieu du combat, butin et expérience sans doublon, blessures, soins, atelier, production, deux choix de résonance, modes d’aide et bornes d’UI |
| `test_prologue_navigation.gd` | `PROLOGUE_NAVIGATION_OK` : ouverture du créateur, traitement de sa validation, choix par signaux de boutons, rechargement via l’écran de slots, transitions intro/hub/donjon et retour |
| `test_character_creation_point_buy.gd` | `CHARACTER_CREATION_POINT_BUY_OK` |
| `test_character_creation_smoke.gd` | `CHARACTER_CREATION_SMOKE_OK` ; avertissement de ressources encore référencées à la fermeture |
| `test_character_clan_reference.gd` | `CHARACTER_CLAN_REFERENCE_OK` |
| `test_domain_services.gd` | `DOMAIN_SERVICES_OK` |
| `test_compile_smoke.gd` | `COMPILE_SMOKE_OK` |
| `test_original_identity.gd` | `ORIGINAL_IDENTITY_OK` |
| Démarrage `--headless --quit-after 10` | Code de sortie 0, aucune erreur de script bloquante |
| Rendu X11 / OpenGL | Captures réelles du refuge, du combat et de l’introduction à 1280 × 720 ; introduction également vérifiée à 960 × 540 ; infobulle au focus clavier vérifiée |
| `git diff --check`, `bash -n scripts/ci_test.sh` | Réussite |

Les deux nouveaux tests sont ajoutés à `scripts/ci_test.sh`. La navigation automatisée utilise le traitement final du créateur et des signaux de boutons ; elle ne constitue pas une traversée manuelle de chaque champ du créateur.

Le contrôle graphique a permis de corriger un choix coupé en bas de l’introduction, la largeur du bandeau de ressources, la largeur des raccourcis du refuge et une infobulle dont la hauteur devenait excessive. Les infobulles se ferment au changement de focus ; Page précédente / Page suivante fait défiler les textes longs.

### Captures

- [Introduction et choix](intro.png)
- [Refuge central](refuge.png)
- [Combat tactique](combat.png)
- [Infobulle au clavier](infobulle-clavier.png)

## Limites constatées

Ce lot est un **socle jouable**, avec une présentation tactique fonctionnelle. Il ne reproduit pas l’ensemble de Disgaea : pas de terrain isométrique, de lancer d’unités, de chaînes d’attaques ou de progression démesurée. L’équilibrage des dix étages n’a pas fait l’objet d’une campagne longue de test.

L’Architecture de l’Âme est introduite par une décision à coût réel, mais un système complet d’assimilation, de transformations visuelles et de Liaisons Primordiales n’est pas livré ici. ESP, TRA et ESE restent les caractéristiques canoniques de prérequis ; cette première résonance n’invente aucun jet secondaire. Le compteur de traces de reconstruction est narratif et persistant : il ne déclenche pas de nouvelle IA géopolitique. Il n’y a pas de nouvelle mécanique de fatigue ; les disponibilités et blessures existantes sont utilisées.

Les blessures durables de ce parcours concernent les compagnons : l’héritier retrouve ses points de vie à la préparation suivante. Le combat emploie une capacité de base commune ; il n’exécute pas encore tout le catalogue des capacités choisies à la création.

Deux problèmes de tests préexistants ont été distingués du lot :

- `test_persistence_effects.gd:16` échoue sur son attente de bonus de vigueur. L’échec a été reproduit dans une copie rétablie à `HEAD`, avec les mêmes données. Il ne valide donc pas ce contrat, avant ou après ce lot.
- L’import global rencontre le test historique `test_family_portraits.gd`, qui référence `resolve_family_portrait` et `resize_for_import`, absents de cette branche. Les scènes du parcours testé et les tests listés ci-dessus se chargent ; cet ancien test n’est pas présenté comme réussi.

Certaines fermetures de scènes lors des captures émettent un avertissement `ObjectDB` / ressource encore référencée, sans erreur pendant les interactions contrôlées. Export Web, parcours navigateur et test manuel prolongé non effectués.

## Fichiers modifiés ou ajoutés

Données :

- `mvp/data/intro_vn.json`
- `mvp/data/ui_visual_bindings.json`

État, règles et chargement :

- `mvp/scripts/autoload/clan_manager.gd`
- `mvp/scripts/autoload/dungeon_generator.gd`
- `mvp/scripts/autoload/game_data_loader.gd`
- `mvp/scripts/autoload/tutorial_director.gd`
- `mvp/scripts/data/stat_defs.gd`
- `mvp/scripts/services/refuge_service.gd` (ajout)
- `mvp/scripts/services/tactical_combat_service.gd` (ajout)

Interface :

- `mvp/scripts/ui/character_creation/character_creation_screen.gd`
- `mvp/scripts/ui/character_creation/slides/slide_02_class_stats.gd`
- `mvp/scripts/ui/clan_hub.gd`
- `mvp/scripts/ui/dungeon_view.gd`
- `mvp/scripts/ui/intro_vn.gd`
- `mvp/scripts/ui/slot_select.gd`
- `mvp/scripts/ui/refuge_panel.gd` (ajout)
- `mvp/scripts/ui/components/keyboard_tooltip.gd` (ajout)

Vérification et documentation :

- `mvp/scripts/tests/test_playable_prologue.gd` (ajout)
- `mvp/scripts/tests/test_prologue_navigation.gd` (ajout)
- `scripts/ci_test.sh`
- `docs/validation/prologue/README.md` et quatre captures PNG (ajouts)
