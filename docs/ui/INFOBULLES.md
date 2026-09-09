# Catalogue des infobulles

## Composant commun

`mvp/scripts/ui/components/keyboard_tooltip.gd` complète `Control.tooltip_text` par une lecture au focus. La souris utilise l’infobulle native Godot ; le clavier utilise un panneau commun dans une CanvasLayer, aux couleurs du thème. Tab / Maj+Tab parcourent les éléments, Page précédente / suivante font défiler les textes longs. La manette peut utiliser les actions de navigation UI Godot si elle est configurée.

Le panneau clavier est borné au viewport (largeur maximale 504 pixels marges comprises) et recherche une place à droite, à gauche, en dessous ou au-dessus sans recouvrir la cible. Il se ferme à la perte du focus ou lorsque le contrôle est masqué. Les parents défilants suivent le focus. Aucun autoload ni modèle métier supplémentaire n’est introduit.

## Caractéristiques

Pour les entrées suivantes : contexte = création, fiche ou refuge ; écran = slide 2 / panneau du personnage ; conditions = contrôle visible. Le texte détaillé ajoute base, investissement, bonus de classe, modificateur et total lorsqu’ils existent.

| ID | Nom / texte court | Texte détaillé |
| --- | --- | --- |
| stat.force | Force | Force — Puissance physique. Intervient dans les attaques au contact et la vigueur. |
| stat.magie | Magie | Magie — Maîtrise de l’Éther. Intervient dans les capacités et la résistance surnaturelle. |
| stat.espionnage | Espionnage | Espionnage — Vivacité, discrétion et observation. Détermine l’initiative en combat. |
| stat.artisanat | Artisanat | Artisanat — Compréhension des matériaux et maîtrise des outils. Intervient dans le soutien aux fortifications. |
| stat.diplomatie | Diplomatie | Diplomatie — Écoute, persuasion et négociation. Intervient dans les relations et les soutiens. |
| stat.commandement | Commandement | Commandement — Autorité et coordination. Intervient dans les soutiens et les points de vie en expédition. |
| stat.ESP | ESP | ESP — Esprit. Volonté, concentration et résistance mentale ; intervient dans les prérequis psychiques et occultes. |
| stat.TRA | TRA | TRA — Transfuge. Affinité avec les technologies étrangères, hybrides et magi-tech ; intervient dans leurs prérequis d’utilisation ou d’assimilation. |
| stat.ESE | ESE | ESE — Essence. Stabilité, pureté et nature de l’héritage sanguin ; intervient dans les prérequis de lignée et d’interaction avec le sang. |

## Valeurs dérivées et combat

Contexte : la fiche de création emploie les modificateurs de score ; le combat de la première expédition utilise les scores et les règles explicites du service tactique. L’infobulle d’initiative indique cette distinction. Les descriptions n’assimilent pas ces deux calculs.

| ID | Nom | Texte court et détaillé | Écran / conditions |
| --- | --- | --- | --- |
| derived.attaque | Attaque | 10 + modificateurs de Force et de Commandement | Slide 2, visible |
| derived.defense | Défense | 10 + modificateur d’Espionnage | Slide 2, visible |
| derived.resistance | Résistance | 10 + modificateur de Magie | Slide 2, visible |
| derived.initiative | Initiative | Modificateur d’Espionnage sur la fiche ; score d’Espionnage pour l’ordre du combat tactique | Slide 2 / combat |
| derived.vigueur | Vigueur | Modificateur de Force | Slide 2 |
| derived.volonte | Volonté | Modificateur de Magie | Slide 2 |
| derived.reflexes | Réflexes | Modificateur d’Espionnage | Slide 2 |
| battle.pv | Points de vie | PV courants / maximum ; maximum = 18 + Commandement + malus de corruption. À zéro, l’unité ne joue plus. | Cellule alliée occupée |
| battle.mana | Mana | Le Trait d’Éther consomme 3 mana du domaine ; attaque = Force ÷ 3 + 2, trait = Magie ÷ 2 + 3 | Commande / cellule alliée |
| battle.corruption | Corruption | Niveau, stade, résistance à l’exposition et malus du prochain combat | Cellule alliée / panneau du refuge |

## Classes

Chaque ID ci-dessous désigne une carte de la slide 2. Conditions : classe chargée depuis `data/classes.json`. Nom et texte court sont tirés des données ; le détail donne l’orientation et invite à spécialiser ou compenser avec les 10 points. Les forces correspondent aux scores recommandés ; la limite commune est de devoir répartir le même budget pour couvrir les autres besoins. Les bonus exacts sont calculés par le service existant et affichés dans les infobulles des caractéristiques.

### class.demon_blade

- ID : `class.demon_blade`
- Nom : Lame Cendrée
- Texte court : Combattant de première ligne qui canalise la résonance de Veyr dans son arme.
- Texte détaillé / style : Combattant de première ligne qui canalise la résonance de Veyr dans son arme. Caractéristiques recommandées : Force.
- Forces : orientation Force ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.hellcaster

- ID : `class.hellcaster`
- Nom : Arcaniste des Braises
- Texte court : Mage de guerre spécialisé dans les flux instables laissés par la Fracture.
- Texte détaillé / style : Mage de guerre spécialisé dans les flux instables laissés par la Fracture. Caractéristiques recommandées : Magie.
- Forces : orientation Magie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.shadowfang

- ID : `class.shadowfang`
- Nom : Croc du Voile
- Texte court : Éclaireur et assassin qui exploite les ruines, l’obscurité et la désinformation.
- Texte détaillé / style : Éclaireur et assassin qui exploite les ruines, l’obscurité et la désinformation. Caractéristiques recommandées : Espionnage.
- Forces : orientation Espionnage ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.soulwarden

- ID : `class.soulwarden`
- Nom : Gardien des Échos
- Texte court : Protecteur capable de stabiliser les âmes, les serments et les pactes fragiles.
- Texte détaillé / style : Protecteur capable de stabiliser les âmes, les serments et les pactes fragiles. Caractéristiques recommandées : Magie.
- Forces : orientation Magie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.hellranger

- ID : `class.hellranger`
- Nom : Pisteur des Ruines
- Texte court : Traqueur des étendues mortes, expert en reconnaissance et chasse aux Altérés.
- Texte détaillé / style : Traqueur des étendues mortes, expert en reconnaissance et chasse aux Altérés. Caractéristiques recommandées : Force, Espionnage.
- Forces : orientation Force, Espionnage ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.abyss_paladin

- ID : `class.abyss_paladin`
- Nom : Paladin de la Faille
- Texte court : Chevalier lié à un serment ancien, conçu pour tenir une ligne lorsque tout cède.
- Texte détaillé / style : Chevalier lié à un serment ancien, conçu pour tenir une ligne lorsque tout cède. Caractéristiques recommandées : Force, Commandement.
- Forces : orientation Force, Commandement ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.pactbound

- ID : `class.pactbound`
- Nom : Lié du Pacte
- Texte court : Occultiste qui négocie avec les Entités de Veyr au prix de dettes toujours plus lourdes.
- Texte détaillé / style : Occultiste qui négocie avec les Entités de Veyr au prix de dettes toujours plus lourdes. Caractéristiques recommandées : Magie, Diplomatie.
- Forces : orientation Magie, Diplomatie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.echo_bard

- ID : `class.echo_bard`
- Nom : Chantre des Échos
- Texte court : Diplomate mystique qui manipule mémoire, morale et résonance collective.
- Texte détaillé / style : Diplomate mystique qui manipule mémoire, morale et résonance collective. Caractéristiques recommandées : Diplomatie, Magie.
- Forces : orientation Diplomatie, Magie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.berserker_demon

- ID : `class.berserker_demon`
- Nom : Furie Cendrée
- Texte court : Guerrier de choc qui transforme douleur et fatigue en puissance immédiate.
- Texte détaillé / style : Guerrier de choc qui transforme douleur et fatigue en puissance immédiate. Caractéristiques recommandées : Force.
- Forces : orientation Force ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.void_monk

- ID : `class.void_monk`
- Nom : Moine du Vide
- Texte court : Combattant discipliné qui exploite les instants de silence entre deux flux d’Éther.
- Texte détaillé / style : Combattant discipliné qui exploite les instants de silence entre deux flux d’Éther. Caractéristiques recommandées : Espionnage, Force.
- Forces : orientation Espionnage, Force ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.wild_druid

- ID : `class.wild_druid`
- Nom : Druide des Friches
- Texte court : Gardien des formes de vie mutées qui ont survécu à la Fracture.
- Texte détaillé / style : Gardien des formes de vie mutées qui ont survécu à la Fracture. Caractéristiques recommandées : Magie, Artisanat.
- Forces : orientation Magie, Artisanat ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.blood_sorcerer

- ID : `class.blood_sorcerer`
- Nom : Thaumaturge Écarlate
- Texte court : Mage inné qui grave ses sorts dans sa propre vitalité.
- Texte détaillé / style : Mage inné qui grave ses sorts dans sa propre vitalité. Caractéristiques recommandées : Magie.
- Forces : orientation Magie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.infernal_artificer

- ID : `class.infernal_artificer`
- Nom : Artificier des Vestiges
- Texte court : Ingénieur mystique capable de réveiller les machines et reliques d’avant la Fracture.
- Texte détaillé / style : Ingénieur mystique capable de réveiller les machines et reliques d’avant la Fracture. Caractéristiques recommandées : Artisanat, Magie.
- Forces : orientation Artisanat, Magie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

### class.warlord

- ID : `class.warlord`
- Nom : Maître de Guerre
- Texte court : Chef de campagne spécialisé dans les escouades, la logistique et la pression politique.
- Texte détaillé / style : Chef de campagne spécialisé dans les escouades, la logistique et la pression politique. Caractéristiques recommandées : Commandement, Diplomatie.
- Forces : orientation Commandement, Diplomatie ; consulter les bonus affichés après sélection.
- Faiblesses : budget commun limité ; investir dans les autres besoins réduit les points disponibles pour cette spécialisation.
- Contexte : évaluation du personnage avec Kael.
- Écran concerné : slide 2.
- Conditions : carte visible, survol ou focus.

## Commandes d’interface

| ID | Nom | Texte court | Texte détaillé | Contexte / écran | Conditions |
| --- | --- | --- | --- | --- | --- |
| creation.points | Points disponibles | Budget commun : 10 | 1 point investi = +1 ; bonus de classe séparés | Création, slide 2 | Compteur visible |
| creation.invest | Augmenter / diminuer | Investir ou récupérer 1 point | Flèches haut/bas du SpinBox ; impossible de dépasser la réserve ou de retirer un bonus de classe | Création, slide 2 | Champ au focus ou survol |
| creation.reset | Réinitialiser | Récupérer les investissements | Conserve la classe et ses bonus | Création, slide 2 | Bouton visible |
| creation.next | Continuer / valider | Valider cette étape | Un message persistant explique les choix manquants | Création, navigation | Bouton visible |
| creation.previous | Retour | Revenir à l’étape précédente | Conserve les choix soumis | Création, navigation | Bouton visible |
| creation.feat.* | Don | Nom et description du catalogue | Effets et prérequis réels ; les prérequis sont aussi lisibles au focus | Création, slide 3 | Carte ou libellé des prérequis |
| creation.ability.* | Capacité | Nom et description du catalogue | Effets et prérequis réels | Création, slide 3 | Carte ou libellé des prérequis |
| dungeon.enter | Descendre avec Kael | Vérifier d’abord le passage | La brume expose l’équipe à l’Éther ; la résistance réduit le gain de corruption | Arrivée | Bouton désactivé avant inspection, raison également dans le texte de l’écran |
| dungeon.return | Retourner au refuge | Termine la sortie | Dépose les sacs une seule fois et conserve les blessures | Donjon | Expédition active |
| soul.locked | Architecture instable | Analyse incomplète | Assimilation indisponible ; observation de la relique sans dépense de ressources | Atelier | Atelier restauré |
| corruption.profile | Corruption | Niveau et stade | Résistance, formule d’exposition, malus et coût de purification | Refuge / combat | Personnage concerné |

Les variantes générées de dons et capacités réutilisent les mêmes données que leurs cartes. Il n’existe pas de copie séparée de leurs descriptions dans un service d’infobulles.
