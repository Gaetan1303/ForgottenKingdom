# Projet CDPI — Royaumes Démoniques : L'Histoire d'Ingrid

Résumé professionnel
--------------------
Jeu narratif / prototype (MVP) développé avec Godot 4 : une histoire interactive autour d'Ingrid, couplée à une mécanique de gestion inspirée des 9 Maisons Nobles du Demon Realm. Ce dépôt contient le MVP jouable et les artefacts de conception (CDC, UML, machines à états).

Principaux objectifs
- MVP : récit interactif, scènes, illustrations et mécanismes de résolution.
- Jeu complet (phase 2) : RPG de gestion, reconstruction du clan et conquête des maisons nobles.

Structure du dépôt
------------------
Racine du projet : ce README. Le code Godot se trouve dans le dossier `mvp/`.

- `mvp/project.godot` : configuration du projet Godot 4.
- `mvp/scenes/` : scènes principales (`main_menu.tscn`, `clan_hub.tscn`, `creation_personnage.tscn`, etc.).
- `mvp/scripts/` : GDScript, singletons (`autoload/`), contrôleurs UI (`ui/`) et outils de données (`data/`).
- `mvp/assets/` : images et audio (BGM / SFX).
- `docs/` : cahier des charges et diagrammes (`01_CDC.md`, `02_UML.md`, `03_State_Machine.md`).

Prérequis
---------
- Godot Engine 4.x installé (version stable recommandée).
- (Optionnel) Python + pyyaml pour les scripts de génération de données.

Ouvrir le projet (Linux)
------------------------
1. Ouvrir Godot et importer le projet en pointant sur :

```
mvp/project.godot
```

2. Lancer la scène principale depuis l'éditeur (F5).

Commandes rapides (exemples)
---------------------------
Générer les données YAML→JSON (optionnel) :

```bash
pip install pyyaml
# exécuter le script GDScript 'scripts/data/yaml_to_json_builder.gd' depuis l'éditeur
```

Sur Linux, lancer Godot depuis la racine du dépôt :

```bash
godot mvp/project.godot
```

Tests et validation headless
---------------------------
Le dépôt contient des scripts de vérification/headless (smoke tests) pour valider le chargement de scènes et la boucle de jeu. Note : l'import des assets (fichiers dans `.godot/imported/`) est géré par l'éditeur Godot — ouvrir le projet dans l'éditeur au moins une fois pour générer ces dérivés.

Limitations connues
-------------------
- Certains fichiers importés (.ogg compressés / dérivés d'images) peuvent manquer si le projet n'a jamais été ouvert dans l'éditeur : ouvrir Godot et laisser l'import s'exécuter.
- Headless re-import automatique peut échouer selon la configuration de l'environnement CI ; privilégier l'import via l'éditeur quand possible.

Contribuer
---------
- Ouvrir une issue pour signaler un bug ou proposer une amélioration.
- Proposer des pull requests claires et ciblées (une fonctionnalité / correction par PR).
- Respecter la structure du projet et ajouter des tests/fichiers de données si nécessaire.

Points de contact et documentation
---------------------------------
- Cahier des charges et diagrammes : `docs/01_CDC.md`, `docs/02_UML.md`, `docs/03_State_Machine.md`.
- Pour lancer le MVP localement : voir `mvp/project.godot`.

Licence
-------
Consulter le fichier `LICENSE` à la racine du dépôt pour les termes de redistribution et d'utilisation.

