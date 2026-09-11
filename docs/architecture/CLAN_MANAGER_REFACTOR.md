# Refactor progressif de ClanManager

## Cartographie préalable

Base : `Dev@693a1f8`, `mvp/scripts/autoload/clan_manager.gd`, 1 915 lignes.
L'état sérialisé et l'API existante restent la frontière de compatibilité.

| Responsabilité | Méthodes concernées | État | Service cible | Migration |
| --- | --- | --- | --- | --- |
| Initialisation et campagne | `nouvelle_partie`, `_charger_etat_defaut` | identité, `campaign`, état complet | façade et services de campagne actuels | différée |
| Économie et production | `peut_payer`, `payer`, `gagner`, `get_ressource`, `_sanitizer_ressources`, `get_production_totale`, `_calculer_bonus_production_domaines`, `get_action_cout_modifie` | `ressources`, production, fiches et affinités | `ClanEconomyService` existant | cette migration |
| Identifiants soldats | `_add_soldiers`, `_remove_soldiers`, initialisation | pool, prochain ID | `SoldierAssignmentService` existant | helpers compatibles |
| Missions soldats et PNJ | planifier, annuler, ajuster, résoudre | `pnj_gestion.planning`, pool | `PnjDailyPlannerService`, `SoldierAssignmentService` | planificateur déjà délégué, migration complète différée |
| Domaines et relations PNJ | `modifier_affinite_pnj`, `recruter_pnj_domaine`, sanitizers | fiches et affinités | futur service de domaines | différée |
| Maisons nobles | `get_maison`, espionner, conquérir, relation, soumission | `maisons_nobles` | `ClanHouseService` existant | différée : contrats différents, ne pas modifier la victoire implicitement |
| Corruption | getters, application, purification, tick | `CorruptionService` | service existant | déjà déléguée |
| Créatures et entraînement | roster, assignation, entraînement | services et profils | `CreatureRosterService`, `CreatureFactory`, `CreatureProfile`, `TrainingSystem` | déjà déléguée |
| Pactes | `get_pact_service`, magie | `PactService`, profil | service existant | déjà partiellement déléguée |
| Tour, effets et événements | phases, `fin_de_tour`, effets, tirage, conditions, fin de partie | tour, rapports, historique | machine de phases et services actuels | orchestration conservée |
| Personnage et progression | fiches, statistiques, traits, XP, niveau, portraits | profil et fiche complète | `CharacterBuildService`, `StatDefs`, progression | déjà partiellement déléguée |
| Sauvegarde | `sauvegarder`, `charger_sauvegarde`, chemins | format historique complet | `JsonPersistenceService`, `SaveSystem` | orchestration conservée |
| Notifications et affichage | signaux ressources/tour/niveau, résumés de traits | aucun nouveau état | façade/UI existante | conservée, pas de bus global |
| Snapshots | adaptation du clan et sous-états | `WorldState` | `WorldStateAdapter` | inchangée |

## Contrats à préserver

`payer` est un débit sans précondition, plafonné à zéro pour les ressources
ordinaires ; `gagner` accepte des deltas signés et ignore les clés inconnues.
Les soldats passent par un pool d'IDs plafonné à 600 ; un gain négatif de soldats
n'en retire pas. Le nombre de signaux existant, les méthodes et les champs de
sauvegarde ne doivent pas changer. Les services purs `spend`/`gain` ont un contrat
plus strict : ils ne peuvent pas remplacer mécaniquement ces anciennes APIs.

Les lectures retournant des copies doivent continuer à isoler l'appelant.
La production de campagne prime sur la production générique, puis reçoit les
bonus des domaines. Les arrondis entiers, affinités, plafonds et réductions des
coûts d'action sont conservés.

## Architecture cible de cette étape

`UI → ClanManager → ClanEconomyService / SoldierAssignmentService → résultat`
puis application sur l'état existant, signal et sauvegarde selon l'appelant.
Aucun service ne manipule `Control`, `Label`, `Button` ou les scènes.
`WorldState` demeure un snapshot sérialisable et `WorldStateAdapter` la transition.
Aucune nouvelle logique royaume-personnage n'est ajoutée.

## Résultat de cette étape

`ClanManager` passe de **1 915 à 1 840 lignes**. Aucune méthode publique n'est retirée.
Les constantes de ressources et domaines viennent du service économique existant.

- `ClanEconomyService` détient maintenant le calcul de production des domaines,
  les coûts d'action modifiés, les débits/crédits historiques, les lectures de
  ressources et leur normalisation compatible (champs supplémentaires conservés,
  plafond des soldats uniquement pour le stock, pas pour la production).
- `SoldierAssignmentService` est utilisé pour l'ajout/retrait du pool d'IDs ; sa
  nouvelle opération `remove_soldiers` conserve le retrait par la fin de la liste.
- La façade conserve l'ordre des notifications, les anciennes signatures et la
  synchronisation `ressources.soldats` avec le pool. Les mises à jour de ressources
  ordinaires sont exécutées par le service sur le dictionnaire canonique.
- `spend`/`gain` stricts restent disponibles pour leurs consommateurs existants.
  `can_pay`/`debit`/`credit` expriment les règles historiques différentes ; il n'y
  a plus de seconde implémentation de ces calculs dans le manager.
- Aucune modification de `WorldState`, `WorldStateAdapter`, du format des sauvegardes,
  des scènes UI, des valeurs de progression ou des règles de victoire.

## Responsabilités restantes et prochaines étapes

L'état de partie et la sauvegarde restent dans la façade. Les missions de soldats,
les relations/domaines, les maisons nobles, le traitement d'événements, la progression
et les messages UI restent partiellement orchestrés par `ClanManager`.

Une migration suivante peut caractériser puis déléguer les maisons nobles : le
service actuel met la relation à `soumise` lors d'une conquête et rejette certains
statuts que la façade accepte. Une substitution directe changerait le jeu. La
même précaution s'applique aux anciennes missions basées sur `effectif` sans IDs.
Aucune de ces différences n'est corrigée implicitement dans cette étape.

## Validation

`test_clan_economy_compatibility.gd` passe sur le code initial et sur la façade
refactorée. Il couvre : coûts insuffisants et signés, débit sans précondition,
gains négatifs, clés inconnues, signaux, plafond 600, continuité des IDs, lectures
isolées, normalisation, production de campagne, bonus et arrondis des domaines,
réductions d'action et sauvegarde/rechargement.

Les **51 tests historiques** passent avant/après. Avec les deux nouveaux tests,
l'import et le démarrage, la suite compte **55 contrôles réussis**. Le parcours
intégral et la persistance sont également testés contre le PCK exporté. Voir
[MVP_MIGRATION.md](MVP_MIGRATION.md) pour les limites de validation Web/Pages.

