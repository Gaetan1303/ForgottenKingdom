# Royaume Déchu — Les Cendres de Veyr

Projet Godot 4.4 orienté RPG de gestion / dark fantasy.

## Source de vérité

Ce dossier `mvp/` est désormais l’unique projet actif. Les anciennes branches de lore externes ne font plus partie de cette distribution.

## Boucle cible

Matin → préparation / gestion
Après-midi → missions / actions / exploration
Nuit → PNJ / pactes / récupération
Fin de journée → simulation du monde

## Contenu original

L’univers repose sur Veyr, la Fracture, les Neuf Couronnes et les Marches Libres. Voir `docs/IDENTITE_VEYR.md`.

## Bibliothèque

Le menu **Bibliothèque** agrège le lore, les Maisons, classes, talents, capacités et systèmes à partir des données JSON du jeu.

## Génération procédurale

`NameGeneratorService` génère des noms de PNJ et de Maisons mineures. Les profils PNJ reçoivent également une statistique de `combativite` et un `temperament`.

## Cartes

Les futures cartes ComfyUI doivent être déposées dans `assets/maps/` sous les noms documentés dans `assets/maps/README.md`.
