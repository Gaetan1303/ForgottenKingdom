# Création : évaluation avec Kael

La création suit le réveil. Elle conserve cinq étapes et les contrats de `CharacterCreationManager`, `CreationFlowController` et `CharacterCreationRulesService` : identité, classe/caractéristiques, dons/capacités, équipement, fiche finale. La validation finale initialise le refuge et conduit au hub, sans rejouer les souvenirs.

## Disposition

La slide 2 conserve sa structure en T : bande horizontale de classes, puis caractéristiques à gauche et progression de classe à droite. `ClassesMargin` sépare les boutons des bords du défilement. Les illustrations et leurs tweens sont conservés ; seul leur espace réservé est réduit dans ce contexte. Le choix actif garde sa bordure, le focus clavier et l’infobulle sont accessibles. Les panneaux inférieurs défilent indépendamment, avec suivi du focus.

La slide 3 commence par le bilan avec Kael : nom, Maison, classe, caractéristiques finales, Esprit / Transfuge / Essence et points restants. Les cartes de dons et capacités suivent dans une zone défilante ; leurs contenus déterminent leur hauteur. Le bouton « Valider ces choix et préparer l’équipement » indique clairement l’étape suivante. La confirmation définitive reste sur la fiche finale. Les prérequis manquants sont affichés sur les cartes et les erreurs du gestionnaire restent visibles jusqu’à correction.

## Règles conservées

- Base de 8, réserve commune de **10 points**, coût linéaire de 1 pour +1.
- Les bonus de classe sont séparés des investissements. Changer de classe ne crée ni ne consomme de points.
- Le bouton Réinitialiser récupère les investissements en conservant la classe et ses bonus.
- Les prérequis de dons et capacités utilisent les caractéristiques finales affichées.
- Les anciennes réserves de brouillon à 18 sont normalisées à 10 par les règles existantes.
- `ESP`, `TRA`, `ESE`, `clan_id`, `clan_name` et les identifiants de classe restent les clés persistantes. Les libellés joueur sont français.

Les tableaux de classe proviennent des données du projet. Les classes à plusieurs caractéristiques principales conservent leurs bonus canoniques ; aucune valeur n’est remplacée par un profil générique. Voir [INFOBULLES.md](INFOBULLES.md) pour les orientations et les détails des calculs.

Le brouillon est enregistré dans le répertoire du slot après soumission et changement d’étape. Les retours conservent les choix. Une frappe non soumise au moment de fermer brutalement l’application n’est pas une sauvegarde automatique de champ.

Le projet utilise le canevas logique 1280 × 720 et son redimensionnement `canvas_items`. Les captures de validation couvrent des surfaces rendues de 1024 × 576, 1280 × 720 et 1600 × 900. La demande de fenêtre 1024 × 768 conserve ici le rendu 16:9 de Godot ; ce contrôle ne prétend pas valider une interface 4:3 native ou mobile. Voir le [rapport de validation](../validation/arrival/README.md).
