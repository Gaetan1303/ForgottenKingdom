# Livraison : ouverture, automates, arrivée et corruption

Branche conservée : `22-refonte-de-lintro-avec-la-nouvelle-histoire`.

## Résultat jouable

Nouvelle partie → souvenirs → réveil avec Kael seule → création → refuge. Les cinq étapes de création sont conservées, avec 10 points linéaires, une bande de classes dégagée, un bilan sur la slide 3 et des infobulles au clavier. Le repas clôt le tutoriel initial.

Le hub utilise maintenant l’automate des journées. Une expédition possède une arrivée sauvegardable, une inspection préalable et un retour possible avant combat. Le passage donne accès à l’observation, au combat sur grille et à la récupération des outils. Le retour dépose le butin une seule fois.

La corruption de l’Éther est raccordée au service existant : exposition annoncée, résistance, stades, malus du prochain combat, conservation au chargement et purification payante au refuge. L’Architecture de l’Âme reste verrouillée.

## Vérifications

Godot **4.4 stable**, copie temporaire de `mvp/`, import et répertoires XDG isolés. Les codes de sortie et l’absence d’erreurs de script ont été contrôlés, en plus des marqueurs de succès. Les [journaux des 13 tests](checks.log) sont conservés.

| Test ciblé | Résultat |
| --- | --- |
| `test_creation_classes_ui.gd` | Réussite : 14 classes, +/−, reset, infobulles hors cible et dans le viewport ; validation complète de deux fiches de classes différentes |
| `test_campaign_states.gd` | Réussite : graphe autorisé, réentrance, reprise sans effets, journées et arrivée persistante |
| `test_expedition_corruption.gd` | Réussite : seuils, résistance, contact unique, sauvegarde, malus, vraie commande UI de purification, coûts, migration sans corruption |
| `test_corruption_service.gd` | Réussite : contrat du service existant |
| `test_character_creation_point_buy.gd` | Réussite : réserve 10, coût linéaire, bonus séparés, prérequis |
| `test_character_creation_smoke.gd` | Réussite : chargement des scènes et progressions |
| `test_slide2_t_layout.gd` | Réussite : structure des conteneurs et statistiques |
| `test_character_clan_reference.gd` | Réussite : identité et compatibilité de sauvegarde |
| `test_domain_services.gd` | Réussite |
| `test_compile_smoke.gd` | Réussite |
| `test_original_identity.gd` | Réussite |
| `test_playable_prologue.gd` | Réussite : Kael seule, réparation, affectation, combat gagné par commandes, blessures, sacs, dépôt unique, atelier verrouillé |
| `test_prologue_navigation.gd` | Réussite : nouvelle partie depuis zéro, choix par boutons, validation par le gestionnaire des cinq étapes, reprise au seuil et en combat, inspection et entrée par les boutons réels |

Les tests de classes, d’automates et de corruption sont raccordés à `scripts/ci_test.sh`, avec les tests du prologue existants. Le runner a également été vérifié avec `bash -n`.

Exemple reproductible après copie et import du projet dans un répertoire temporaire :

```bash
XDG_CONFIG_HOME=/tmp/fk-config XDG_DATA_HOME=/tmp/fk-data godot --headless --path /tmp/fk-project --script res://scripts/tests/test_expedition_corruption.gd
```

## Rendu réel

Captures produites avec X11 et OpenGL Compatibility, sur les assets existants. Les surfaces rendues sont **1024 × 576**, **1280 × 720**, **1600 × 900**. Une demande de fenêtre 1024 × 768 conserve un rendu 16:9 dans cette configuration Godot ; elle ne prouve pas une adaptation native 4:3.

- [Souvenir fragmenté](opening_0.png), [réveil avec Kael](opening_2.png).
- [Slide 2 à 1280 × 720](slide2-1280x720.png), [petite surface](slide2-1024x576.png), [grande surface](slide2-1600x900.png).
- [Slide 3 à 1280 × 720](slide3-1280x720.png), [petite surface](slide3-1024x576.png), [grande surface](slide3-1600x900.png).
- [Infobulle clavier](tooltip-1280x720.png), [petite surface](tooltip-1024x576.png), [grande surface](tooltip-1600x900.png).
- [Arrivée au donjon](arrival.png), [purification au refuge](corruption.png).

## Limites connues

L’import global rencontre encore le test historique `test_family_portraits.gd`, qui référence `resolve_family_portrait` et `resize_for_import`, absents sur cette branche avant cette tâche. Cela ne permet pas d’annoncer toute la suite du dépôt verte. Les 13 tests ciblés ci-dessus passent sans cette erreur.

Les exports Web, la navigation avec une manette physique et une traversée entièrement manuelle de chaque champ ne sont pas validés ici. Les vérifications de navigation utilisent les scènes réelles, les signaux de boutons et le gestionnaire de validation ; les captures sont issues d’un vrai moteur de rendu. L’équilibrage des stades de corruption devra être éprouvé sur des parties longues.

Voir [les fichiers modifiés](FILES.md), [le flux](../../tutorial/TUTORIAL_FLOW.md), [la corruption](../../tutorial/CORRUPTION.md) et [les infobulles](../../ui/INFOBULLES.md).
