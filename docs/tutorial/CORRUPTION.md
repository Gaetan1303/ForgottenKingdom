# Corruption de l’Éther

La corruption est persistante pour le protagoniste (`hero`) et chaque compagnon du registre. `CorruptionService` possède les profils ; `ClanManager` expose la façade et inclut son export dans `corruption_state`. Les statistiques de base et la barre d’âme ne sont pas utilisées comme une seconde jauge de corruption.

## Exposition

Gain effectif = exposition × (1 − résistance / 100), borné entre 0 et 100.

La résistance initiale du protagoniste vaut `50 + 2 × ESE`, plafonnée à 90 %. Les compagnons reprennent la résistance du registre, ou 50 % par défaut. Les profils sauvegardés conservent leurs valeurs.

| Source | Exposition brute | Répétition |
| --- | ---: | --- |
| Examiner l’inscription | 0 | Observation libre |
| Toucher le sceau | 16, protagoniste seulement | Une fois par sortie |
| Descendre au donjon | 8, équipe | Une fois par sortie |
| Entrer dans un étage suivant | 8 + 2 × index d’étage (index 1 pour l’étage 2) | Une fois par étage |
| Défaite | 10, équipe | Une fois par sortie |

`run.exposures` est sauvegardé avec les profils après application. Recharger, revisiter l’inspection ou rafraîchir l’écran ne donne aucune exposition supplémentaire.

## Stades et malus

Les seuils métier restent ceux de `CorruptionStage`. Les libellés ci-dessous sont uniquement la présentation française de l’exposition à l’Éther ; les identifiants persistants existants restent inchangés.

| Niveau | Affichage | Initiative | Magie | PV maximum |
| --- | --- | ---: | ---: | ---: |
| 0 à moins de 20 | Stable | 0 | 0 | 0 |
| 20 à moins de 40 | Altéré | −1 | 0 | 0 |
| 40 à moins de 60 | Fragilisé | −2 | −1 | 0 |
| 60 à moins de 80 | Submergé | −3 | −1 | −4 |
| 80 à moins de 95 | Corrompu | −4 | −2 | −8 |
| 95 à 100 | Critique | −5 | −3 | −12 |

Les malus s’appliquent à la création du **prochain combat**, sur une copie de l’équipe. Initiative et magie restent au minimum à zéro, les PV maximum au minimum à un. Les PV courants sont plafonnés au nouveau maximum, sans résurrection ni soin gratuit. Une bataille chargée conserve son instantané exact ; les malus ne sont pas ajoutés une seconde fois. Même au stade critique, le repli et la purification restent disponibles.

## Purification

Au refuge, un panneau apparaît dès qu’un personnage a de la corruption. Il montre niveau, stade et effets via une infobulle. Purifier retire jusqu’à 10 points pour **4 mana et 1 nourriture**. La dépense n’a lieu que si le personnage existe, a de la corruption, dispose des ressources et qu’aucune sortie n’est en cours. Plusieurs purifications sont possibles et chacune paie son coût. Une purification au niveau zéro ne coûte rien.

L’Architecture de l’Âme reste instable et l’assimilation reste verrouillée. Ces règles forment la boucle jouable d’exposition et de récupération ; le service conserve ses autres API existantes sans ajouter d’écran de créatures ou de pactes au tutoriel.
