# Prologue mémoriel et verticale à six approches

Passe du 10 septembre 2026, effectuée dans `mvp/` sur la branche active `Dev`, initialement propre à `8885b00`. La branche locale `dev` était un ancêtre de 77 commits ; aucun changement de branche ni fusion n’a été effectué. Exécution locale : Godot **4.4.stable.official.4c311cbee**.

La verticale relie maintenant **trois tableaux → six souvenirs → création → présent avec Kael → galeries à six résolutions → atelier → relique**. Les galeries constituent la situation de démonstration ; leur résolution ne prétend pas terminer toute la campagne des Neuf Maisons.

## Architecture

| Composant | Responsabilité |
| --- | --- |
| `domain/narrative_objective.gd` | Objectif identifié, description, statut, méthodes autorisées, résolution et objectif suivant. |
| `domain/objective_resolution.gd` | Méthode, conséquences, réputation, relations, coût et événements futurs sérialisables. |
| `domain/loop_action_result.gd` | Contrat d’action : refus/acceptation, réussite/échec, événement, dépenses, gains, corruption et nouvel état. |
| `services/narrative_objective_service.gd` | Enregistrement d’objectifs, validation unique d’une méthode autorisée, progression et vérification des objectifs finaux configurés. |
| `services/power_loop_service.gd` | Règles communes d’espionnage, diplomatie, occulte, commandement et transformation. Lit des états ; retourne un résultat. |
| `services/power_campaign_service.gd` | Applique ce résultat aux services et ressources canoniques, au calendrier, aux objectifs et au journal. |
| `services/memory_tutorial_service.gd` | Séquences et étapes pilotées par leurs événements, acquittement, passage, affinités et simulation sauvegardée. |
| `ui/tutorials/memory_tutorial_view.gd` | Vue commune aux six souvenirs, avec consigne, état visible, actions, feedback et résumé. |
| `ui/tutorials/tutorial_highlight.gd` | Assombrissement et cadre de focus génériques, sans progression temporisée. |
| `ui/tutorials/character_animation_controller.gd` | Contrat `FK_Chibi_Humanoid_v1`, poses génériques, indépendant de Spine. |
| `ui/tutorials/placeholder_animator.gd` | Silhouette vectorielle légère et poses animées. |
| `ui/power_routes_panel.gd` | Accès aux approches dans le vrai Clan Hub et présentation des résultats par `EventResultView`. |

Les règles réutilisent `TacticalCombatService`, `RefugeService`, `CorruptionService`, `PactService`, les réserves et le pool de soldats du `ClanManager`, `SaveSystem`, le calendrier existant et la fenêtre de résultat commune. `ClanManager` reçoit uniquement une adaptation de ses conditions de fin ; les nouvelles boucles résident dans les services.

Les données de contenu se trouvent dans `data/intro_vn.json`, `data/tutorials/memories.json` et `data/power_actions.json`. Une seule vue interprète les six leçons ; il n’existe pas six scripts de tutoriel indépendants.

## Prologue

`intro_vn.tscn` conserve son interface et son effet d’écriture, avec trois nouveaux tableaux :

1. **Le duel** : proximité avec le frère, rivalité, coups devenus dangereux, défaite de l’enfant.
2. **L’Essence volée** : transfert, douleur et vide, sans exposer toute la mécanique.
3. **La mort supposée** : effondrement et voix de la sœur dans le noir, puis les souvenirs.

Le rôle véritable de la sœur reste ambigu. Ses intentions et les détails de la reconstruction ne sont pas révélés. Les portraits existants du père et de la mère sont utilisés dans leurs leçons. Les autres intervenants utilisent les silhouettes prévues pour cette passe.

Les cinq tableaux précédents sont conservés comme **données de reprise** dans `intro_vn_legacy.json` : une ancienne ouverture garde son index et ses choix, dans la même scène et le même lecteur.

## Tutoriels

| Mentor | Mécanique | Action demandée | Ressources ou états | Résultat observable |
| --- | --- | --- | --- | --- |
| Père | Combat personnel | Attaquer, fortifier la garde, observer le soir | PV, dégâts, soldats, phase | Les vraies règles tactiques appliquent l’attaque et la riposte ; la garde réduit les dégâts. |
| Mère | Combat magique, rituel, pacte | Lancer le Trait d’Éther ; choisir cercle ou pacte ; sceller | Mana et corruption | Le mana est dépensé ; le passage est scellé contre un prix occulte annoncé. |
| Garde Silencieuse | Observation/infiltration | Choisir une opération | Renseignements, faits masqués, exposition | Rondes et passage, ou secret et motivation, deviennent connus ; l’exposition détériore la relation. |
| Émissaire de la Maison | Micro-négociation | Écouter, puis offrir des vivres ou révéler le secret | Vivres, or, Renseignements, réputation, obligation | Accord de ravitaillement ou trêve fragile, sans combat ultérieur imposé. |
| Père | Commandement | Choisir avant/arrière puis donner l’ordre | Soldats, formation, moral, fatigue | Le passage est pris par l’escorte ; la formation change les pertes sans attaque de l’héritier. |
| Sœur | Artisanat/transformation | Récupérer des composants, choisir une méthode | Bois, fer, pierre/mana/Essence ; ESP, TRA, ESE | Automate normal, exceptionnel ou altéré ; échec possible avec récupération et nouvel essai. |

Treize étapes jouables, avec une seule consigne principale à la fois. Chaque action validée attend la confirmation de sa conséquence. Les mauvais événements et les doubles clics ne font pas avancer les étapes. Les leçons peuvent être passées ; `skipped` reste distinct de `completed`.

Les archives du Hub permettent de revoir chacune des six leçons. La relecture crée un exercice local et ne change ni les réserves du présent ni les affinités acquises. Le résumé final et l’identité affichent les approches pratiquées sans recommander une classe unique.

## Boucles de jeu et progression

- **Combat** : l’expédition et sa grille restent actives. La garde devient également une action du combat réel. Le retour dépose les outils, l’expérience et les blessures, puis enregistre la méthode `combat`.
- **Occulte** : cercle ou pacte prépare un sceau ; mana, protection, secret et risque influencent le coût de corruption. Le pacte du présent passe par le `PactService` canonique et son accomplissement est sauvegardé.
- **Espionnage** : observation ou infiltration révèle des faits ; ceux-ci ouvrent de faux ordres et une option diplomatique, réduisent les pertes militaires ou les risques de transformation et de sceau.
- **Diplomatie** : une audience révèle un intérêt ; vivres, secret, compétence et relation influencent le prix de l’accord. La méthode laisse réputation, relation et obligation futures.
- **Commandement** : recrutement dans le pool canonique, placement de deux formations et ordre donné à Kael. Renseignements, dispositifs et compétence de commandement réduisent les pertes. Kael doit être disponible.
- **Artisanat** : l’établi portatif donne une solution avant la restauration de l’atelier. Matière, composant, catalyseur, méthode et caractéristiques participent au résultat. Un automate résout les galeries ou soutient les troupes ; la récupération évite un blocage après échec.

Les préparatifs, faits et objets débloquent de vraies actions. Les compteurs de pratique et l’historique conservent la provenance pour les réactions ultérieures. L’ancienne défaite automatique « pas de soldats, peu d’or, pas d’alliance » est désactivée pour les campagnes v3 : elles disposent de la récupération quotidienne du refuge.

## Un objectif, six résolutions

Objectif : `secure_galleries` — sécuriser le passage et retrouver les outils de la Maison.

| Méthode | Parcours concret | Compromis |
| --- | --- | --- |
| `combat` | Expédition → inspection → combat tactique → outils → retour | Risque personnel, mana éventuel, blessures, hostilité des survivants. |
| `espionage` | Observer → détourner les ordres | Or, Renseignements, deux décisions, risque d’exposition et enquête future. |
| `diplomacy` | Audience → garantir des vivres ; ou infiltration → révéler le secret | Ressources, relation, réputation et obligation ou trêve fragile. |
| `occult` | Cercle ou pacte → sceau | Mana et corruption, avec risque de résonance supplémentaire. |
| `command` | Équiper l’escorte → formation → ordre | Or, nourriture, soldats perdus, fatigue, Kael disponible. |
| `craft` | Composants → automate → déploiement | Matériaux, catalyseur, risque d’échec/altération ; dispositif durable. |

Toutes valident `status = completed`, conservent leur `resolution_method`, donnent accès aux outils et à `rebuild_refuge`, puis permettent de restaurer l’atelier et d’examiner la relique. La résolution ne peut pas distribuer une seconde récompense, y compris après chargement.

`NarrativeObjectiveService` accepte aussi d’autres identifiants et une liste `ending_objectives`. La fin vérifie leur accomplissement quelle que soit la méthode, avec une preuve de contrat pour les six approches. Cette infrastructure n’écrit pas à elle seule les scénarios et épilogues de toute la campagne.

## Sauvegarde et migration

| Propriétaire | Données nouvelles |
| --- | --- |
| `progress.json / opening` | Version, identifiant de partie, stade, index du prologue, brouillon ; séquence/étape, résultats à confirmer, leçons terminées/passées, affinités, événements, simulation et état du tirage pendant les souvenirs. |
| `clan.json / campaign.memories` | Bilan final des souvenirs, événements, affinités et progression. La simulation terminée est retirée et le bilan quitte `opening`. |
| `campaign.power_routes` | Objectifs/résolutions, connaissances, préparatifs, artefacts/recettes/qualités, formation/moral/fatigue, progression des voies, exposition, relation locale, coûts historiques, événements futurs et résultat en attente. |
| Services canoniques | Réserves, pool de soldats, corruption et pactes restent dans leurs données de sauvegarde existantes. Les voies ne conservent que l’identifiant du pacte. |

Le marqueur `campaign.opening_run_id` permet de reprendre une coupure entre l’écriture du clan créé et la fermeture de l’ouverture. Un ancien clan ayant déjà récupéré les outils ne reçoit pas de seconde récompense. Si sa méthode n’est pas établie, elle reste `legacy`.

`WorldState` conserve son rôle existant de snapshot en shadow mode. Cette passe n’effectue pas sa migration complète ; `campaign` reste détenu par `ClanManager`, transportable avec le reste de son état, sans second service mutable des réserves ou relations de Maisons.

## Tests et commandes

Les commandes et résultats finaux sont consignés dans [checks.txt](checks.txt). Le lanceur reproductible crée une copie temporaire du projet, isole chaque dossier utilisateur et refuse tout `SCRIPT ERROR` ou `ERROR` dans le boot et les tests :

```bash
bash scripts/test_memorial_prologue.sh --all
```

Sans `--all`, il exécute les onze suites ciblées. `scripts/ci_test.sh` inclut également les nouveaux tests de domaine, de reprise et de navigation.

Les nouveaux tests couvrent les événements requis, les confirmations, les six parcours, les secrets, les échecs de fabrication, les coûts, les doubles clics, la progression sans combat personnel, la sauvegarde de chaque étape, les anciens formats, les six relectures depuis les archives, la reprise de création et le cycle de pacte. Le test d’expédition existant prouve la résolution par un vrai combat, puis son dépôt de butin.

## Vérification visuelle

Exécution **non headless** sur OpenGL/Mesa Intel UHD 620, canevas 1280 × 720. Les images ont été capturées depuis le viewport Godot puis inspectées. Une largeur manquante des onglets du Hub a été corrigée après cette inspection et un contrôle de géométrie ajouté.

Captures retenues : [duel](prologue_0.png), [mort supposée](prologue_2.png), [combat mémoriel](memory_0.png), [résumé](memory_summary.png), [identité](creation_identity.png), [diplomatie au Hub](present_diplomacy.png), [artisanat au Hub](present_craft.png).

## Régressions, périmètre et limites

- La preuve jouable porte sur les galeries, l’atelier et la relique. Les neuf Maisons et tous les événements de la campagne n’ont pas encore été convertis en objectifs offrant six résolutions ; la condition historique de soumission des neuf Maisons demeure en complément du contrat de fin par objectifs.
- Les événements futurs et les méthodes sont conservés, mais tous les dialogues, réactions différées et épilogues correspondants ne sont pas écrits.
- Les formations sont une première version tactique utilisant le pool de soldats existant ; pas de système complet d’officiers, doctrines et équipements individuels. Les silhouettes sont des placeholders, sans rig Spine.
- La durée d’apprentissage de 25–30 minutes reste à mesurer avec des joueurs. Les séquences sont courtes et peuvent être passées ; les exécutions automatisées ne mesurent pas le temps de découverte.
- Le rendu nouveau est vérifié à 1280 × 720 sur Linux/OpenGL. Les autres résolutions, le Web et l’exécution distante de GitHub Actions ne sont pas validés par cette passe. Les workflows existants pointent encore sur leur image Godot 4.7.2 ; la compatibilité locale revendiquée ici est celle de Godot 4.4 réellement exécuté.
- L’import dans l’environnement restreint émet des diagnostics d’éditeur sur ses sockets et dialogues de progression, ainsi que des avertissements de doublons d’UID d’anciens assets. Aucun de ces messages n’est une erreur de script ; les journaux du boot et des tests sont contrôlés séparément.

## Runtime

La matrice finale et les marqueurs réellement exécutés figurent dans [checks.txt](checks.txt). Les PASS concernent la verticale et le périmètre décrits ci-dessus.
