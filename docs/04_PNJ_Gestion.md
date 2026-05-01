# Boucle de gestion PNJ

## Objectif

Ce document définit la première tranche métier de la boucle Matin / Après-midi / Soir pour le mode gestion. Il sert de contrat de conception pour une implémentation orientée domaine, testable en headless et découplée de l'UI Godot.

## Principes

- Une journée est divisée en trois phases: `matin`, `apres_midi`, `soir`.
- Le `matin` sert à planifier les affectations.
- L'`apres_midi` résout les missions préparées le matin.
- Le `soir` applique les récupérations, rapports et conséquences.
- Une affectation n'exécute pas directement son résultat au moment de la sélection.
- Les calculs de mission doivent être déterministes à seed égale.

## Types de membres gérés

### Soldats

Les soldats sont une ressource agrégée. Ils n'ont pas de fiche individuelle dans cette première tranche.

Actions prévues:

- `collecter_bois`
- `collecter_fer`
- `collecter_pierre`
- `collecter_nourriture`
- `espionner`
- `securiser`

Chaque mission de soldat consomme un effectif affecté et produit un résultat chiffré.

### PNJ recrutes

Les PNJ recrutés sont générés ou récupérés via les systèmes de jeu. Ils possèdent une fiche légère.

Champs minimaux:

- `id`
- `nom`
- `type`: `recrute`
- `niveau`
- `role`
- `stats`
- `traits`
- `etat`

### PNJ scenario

Les PNJ scénario représentent des personnages nommés, capturés ou narratifs, comme Ingrid.

Champs minimaux:

- `id`
- `nom`
- `type`: `scenario`
- `niveau`
- `role`
- `stats`
- `traits`
- `etat`
- `tags_narratifs`

## Actions PNJ

Un PNJ ne peut recevoir qu'une seule affectation active par phase de planification.

Deux familles d'actions sont couvertes dans cette tranche.

### Support heroique

Le PNJ rejoint l'action du hero et fournit un bonus borné.

Sorties attendues:

- bonus de score d'action
- bonus de survie
- message de rapport

Contraintes:

- le bonus dépend du `role`, du `niveau` et d'un modificateur de trait
- le bonus total est plafonné
- un PNJ indisponible ou blesse ne peut pas soutenir

### Expedition de donjon PNJ

Le PNJ part seul ou avec une abstraction de groupe léger dans un mini-donjon fixe de 4 salles.

Ordre des salles:

1. `combat_faible`
2. `evenement_aleatoire`
3. `repos`
4. `boss`

Le résultat final est un rapport structuré, pas une scène jouable.

## Contrat du mini-donjon PNJ

Une expédition est décrite par un objet de domaine sérialisable.

Champs minimaux:

- `expedition_id`
- `pnj_id`
- `seed`
- `rooms`
- `index_salle`
- `etat`
- `journal`
- `recompenses`
- `penalites`

### Salle 1: combat faible

- Test principal sur `commandement`, `force` ou `magie` selon le profil.
- Réussite: gain mineur.
- Échec: perte légère ou blessure.

### Salle 2: événement aléatoire

- Peut être `piege` ou `bonus`.
- Le tirage dépend uniquement de la seed.
- Les effets restent bornés et lisibles.

### Salle 3: repos

- Réduit une blessure légère ou accorde un bonus temporaire pour le boss.

### Salle 4: boss

- Résout l'issue finale de l'expédition.
- Produit récompense, blessure, KO, ou retour glorieux.

## Etats et transitions

### Etat d'un PNJ

Etats minimaux:

- `disponible`
- `assigne`
- `en_expedition`
- `blesse`
- `indisponible`

Règles:

- `disponible -> assigne` au matin
- `assigne -> disponible` après résolution simple
- `assigne -> en_expedition` quand l'action choisie est le donjon
- `en_expedition -> disponible` si retour sain
- `en_expedition -> blesse` si retour blessé
- `blesse -> disponible` après récupération validée

## Responsabilites logiques

### Service de planification

Responsable de:

- valider les affectations
- empêcher les doubles affectations
- produire un plan de journée immuable pour la résolution

### Service d'expédition PNJ

Responsable de:

- construire le mini-donjon à 4 salles
- résoudre les salles dans l'ordre
- produire un rapport final déterministe

### ClanManager

Responsable de:

- stocker l'état sérialisable
- exposer une API d'intégration minimale aux écrans
- appliquer les conséquences aux ressources et aux états de PNJ

Le `ClanManager` ne doit pas contenir la logique détaillée de résolution salle par salle.

## Contrats de test minimum

Les premiers tests TDD doivent couvrir:

- refus d'affecter deux fois le même PNJ
- refus d'affecter un PNJ blessé
- calcul stable d'un bonus de support à entrée identique
- génération d'une expédition toujours composée de 4 salles ordonnées
- résolution déterministe à seed fixe
- production d'un rapport final exploitable par l'UI

## Integration MVP

Cette tranche n'impose pas encore la nouvelle UI Matin / Après-midi / Soir. L'intégration minimale côté MVP consiste à:

- stocker une liste de PNJ gérés dans le `ClanManager`
- stocker le plan du matin
- déclencher une résolution headless
- restituer un rapport texte et des effets chiffrés