# Cahier des Charges — CDPI
## Royaumes Démoniques : L'Histoire d'Ingrid

**Version :** 1.0  
**Date :** 10 avril 2026  
**Contexte :** Cahier de Projet Informatique (CDPI)  
**Public cible :** Tout public  

---

## Sommaire

1. [Présentation et contexte](#1-présentation-et-contexte)
2. [Objectifs du projet](#2-objectifs-du-projet)
3. [Périmètre et livrables](#3-périmètre-et-livrables)
4. [Acteurs du système](#4-acteurs-du-système)
5. [Exigences fonctionnelles — MVP](#5-exigences-fonctionnelles--mvp)
6. [Exigences fonctionnelles — Jeu complet](#6-exigences-fonctionnelles--jeu-complet)
7. [Exigences non-fonctionnelles](#7-exigences-non-fonctionnelles)
8. [Contraintes](#8-contraintes)
9. [Technologies recommandées](#9-technologies-recommandées)
10. [Architecture du système](#10-architecture-du-système)
11. [Glossaire](#11-glossaire)

---

## 1. Présentation et contexte

### 1.1 Contexte applicatif

Le projet s'inscrit dans le cadre du CDPI. Il vise à produire une application interactive inspirée de l'univers narratif des **9 Nobles du Demon Realm** (九魔界貴族), en centrant l'expérience sur le personnage d'**Ingrid (イングリッド)** — Chevalière de l'Enfer, noble démoniaque et bras droit d'Edwin Black au sein de l'organisation Nomad.

L'application est structurée en deux livrables successifs :

- **MVP** : parcours narratif interactif retraçant l'histoire d'Ingrid (visual novel illustré, animé, géolocalisé)
- **Jeu complet** : RPG de gestion politique et stratégique, inspiré de *Stellaris*, dans lequel le joueur incarne un noble démon cherchant à restaurer son clan anéanti

### 1.2 Origine du lore

Le lore source est celui de l'univers Taimanin (*Taimanin Murasaki*, *Taimanin Asagi 3*, *Taimanin RPGX*, *Action Taimanin*). Le projet en tire l'univers et les personnages pour en produire une **adaptation originale, tout public**, axée sur les arcs narratifs héroïques, politiques et stratégiques.

---

## 2. Objectifs du projet

| # | Objectif | Priorité |
|---|---|---|
| O1 | Proposer un parcours narratif interactif et illustré de l'histoire d'Ingrid en français | Haute (MVP) |
| O2 | Permettre à l'utilisateur de naviguer sur une carte chronologique du parcours d'Ingrid | Haute (MVP) |
| O3 | Intégrer des images officielles et des animations du personnage | Haute (MVP) |
| O4 | Proposer un jeu de type RPG gestion avec création de personnage | Haute (V1) |
| O5 | Implémenter un cycle journalier (Matin / Après-midi / Nuit) | Haute (V1) |
| O6 | Permettre la conquête progressive des 9 Maisons nobles démoniques | Haute (V1) |
| O7 | Fournir un système de pacte permettant de recruter des PNJ | Moyenne (V1) |
| O8 | Intégrer des événements narratifs (Visual Novel) à chaque phase-clé | Haute (V1) |

---

## 3. Périmètre et livrables

### 3.1 MVP — Histoire interactive d'Ingrid

**Périmètre** : Application de type visual novel interactif.

| Fonctionnalité | Description |
|---|---|
| Narration par chapitres | 11 chapitres retraçant chronologiquement la vie d'Ingrid |
| Illustrations | Artwork d'Ingrid par chapitre (images libres de droits ou générées) |
| Animations | Scènes animées (entrée/sortie de personnage, effets de flammes violettes) |
| Carte interactive | Timeline géographique sur une carte du Demon Realm / Japon |
| Navigation | Choix de chapitre libre, progression linéaire ou exploratoire |
| Langue | Français intégral |

#### Chapitres narratifs (MVP)

| # | Titre | Période | Lieux-clés |
|---|---|---|---|
| Prologue | Les Origines Nobles | Antiquité | Demon Realm, lignée noble |
| I | L'Alliance des 9 Nobles | Antiquité | Nine Noble Dominion |
| II | Le Rituel Primordial | Antiquité | Temples des Hell Knights |
| III | La Sauveure de Greenfort | Antiquité | Greenfort Village |
| IV | L'Ordre du Dragon Noir | Antiquité–Époque moderne | King's Rock |
| V | La Rencontre avec Edwin Black | ~2060 | Demon Realm |
| VI | Le Monde des Humains | 2063 | Yomihara, Japon |
| VII | L'Affaire Sabato | 2075 | Chaos Arena, Yomihara |
| VIII | La Guerre des Ombres | 2082–2086 | UFS, Japon |
| IX | Le Gardien de Yomihara | 2084–2088 | Yomihara, Palace of Darkness |
| Épilogue | La Recherche | 2088+ | Amidahara, Yomihara |

---

### 3.2 Jeu complet — RPG Gestion Démonique

**Périmètre** : Jeu hybride Visual Novel + gestion stratégique + RPG.

**Pitch narratif :** Tu incarnes un jeune noble démon dont le clan a été anéanti par l'un des neuf grands clans démoniques. Ta famille est morte, ton blason est brisé. Seul face au Demon Realm, tu dois reconstruire ton clan, rallier des alliés, espionner et conquérir les Maisons nobles, jusqu'à affronter le clan qui t'a tout pris.

---

## 4. Acteurs du système

```
┌─────────────────────────────────────────────────────┐
│                   ACTEURS                           │
├──────────────────┬──────────────────────────────────┤
│ Joueur           │ Utilisateur principal de l'appli │
│ Personnage héros │ Avatar créé par le joueur (PJ)   │
│ PNJ             │ Alliés, marchands, mentors        │
│ Nobles démons    │ Antagonistes / événements clés   │
│ Ingrid           │ Personnage-clé (MVP + PNJ V1)    │
└──────────────────┴──────────────────────────────────┘
```

---

## 5. Exigences fonctionnelles — MVP

### EF-MVP-01 : Narration par chapitres
- Le système doit afficher le texte narratif chapitre par chapitre
- Chaque chapitre doit être accessible depuis un menu principal
- Le joueur peut avancer/reculer dans un chapitre

### EF-MVP-02 : Illustrations et animations
- Chaque chapitre doit afficher au minimum une illustration d'Ingrid
- Les transitions entre scènes doivent être animées (fondu, glissement)
- Des effets de flamme violette (signature d'Ingrid) doivent apparaître sur les scènes d'action

### EF-MVP-03 : Carte interactive
- Une carte du Demon Realm et du Japon (Yomihara) doit être accessible
- Chaque lieu important de la vie d'Ingrid est marqué sur la carte
- Cliquer sur un marqueur ouvre le chapitre associé ou affiche un résumé

### EF-MVP-04 : Progression et sauvegarde
- La progression du joueur est sauvegardée (chapitre atteint)
- Un indicateur visuel montre les chapitres déjà lus

### EF-MVP-05 : Interface tout public
- Aucun contenu adulte
- Interface en français
- Accessibilité : police lisible, contrastes élevés

---

## 6. Exigences fonctionnelles — Jeu complet

### 6.1 Création de personnage

#### EF-JEU-01 : Apparence
- Choix du nom
- Sélection de traits physiques (couleur de peau, yeux, cheveux, corpulence)
- Affichage d'un avatar 2D généré à partir des sélections

#### EF-JEU-02 : Classe de personnage
Cinq classes disponibles :

| Classe | Rôle | Bonus de départ |
|---|---|---|
| Chevalier Sombre | Guerrier-tank | +Force, +Armure |
| Mage du Pacte | Lanceur de sorts | +Magie, +Affinité démoniaque |
| Stratège des Ombres | Espionage/diplomatie | +Renseignement, +Charisme |
| Forgeron de Sang | Artisanat/bâtiment | +Craft, +Ressources |
| Sang Noble | Polyvalent, bonus pactes | +Charisme, +Magie mineure |

#### EF-JEU-03 : Pouvoirs et dons
- Sélection de 2 pouvoirs magiques parmi une liste (ex: Pyrokynésie, Télékinésie, Invocation)
- Sélection de 1 don passif (ex: Régénération, Vision démoniaque, Empathie des monstres)

#### EF-JEU-04 : Compétences de départ
- Attribution de 5 points dans des compétences : Combat, Magie, Espionnage, Artisanat, Diplomatie, Commandement

#### EF-JEU-05 : Équipement de départ
- Attribution automatique selon la classe (ex: épée + armure légère pour Chevalier)
- Option de choisir un équipement alternatif dans un pool de 3 items

---

### 6.2 Introduction narrative (Visual Novel)

#### EF-JEU-06 : Intro du monde
- Séquence Visual Novel non-interactive (~10 minutes de lecture)
- Présentation du Demon Realm, des 9 Nobles, du contexte politique
- Présentation de la famille du joueur et de sa destruction
- Ton : grave, épique, tout public

---

### 6.3 Cycle journalier

Le jeu se déroule en **journées**, chacune divisée en 3 phases.

#### EF-JEU-07 : Phase Matin — Décisions
Le joueur choisit parmi les actions disponibles :

| Action | Description | Ressources requises |
|---|---|---|
| Attaquer un bastion | Assault d'une position ennemie | Soldats, énergie |
| Récolter des ressources | Bois, pierre, or, énergie mystique | Travailleurs |
| Espionner | Obtenir des informations sur une Maison noble | Agent discret |
| Partir en ville | Commerce, recrutement, quêtes | Liberté d'action |
| Chasser un monstre | Capture d'un monstre pour pacte | Chasseurs |
| Événement libre | Activité narrative spéciale déclenchée par le contexte | — |

#### EF-JEU-08 : Phase Après-midi — Résolution
- Affichage animé du résultat de l'action choisie le matin
- Gains ou pertes de ressources, de soldats, d'influence
- Scène narrative éventuelle (VN) si l'action déclenche un événement

#### EF-JEU-09 : Phase Nuit — Gestion du Bastion
Trois options disponibles :

| Activité | Description |
|---|---|
| Interagir avec les PNJ | Dialogues, quêtes, affinité |
| Crafter | Construire un bâtiment, forger une arme ou un item |
| Réaliser un Pacte | Transformer un monstre capturé en PNJ allié |

---

### 6.4 Système de Bastion

#### EF-JEU-10 : Ressources
Quatre ressources principales :

| Ressource | Usage |
|---|---|
| Or | Commerce, recrutement, bribes |
| Énergie mystique | Magie, pactes, bâtiments |
| Soldats | Attaques, défense |
| Influence | Diplomatie, réputation auprès des clans |

#### EF-JEU-11 : Bâtiments
Exemples de bâtiments construisibles :

| Bâtiment | Effet |
|---|---|
| Caserne | +Recrutement de soldats/jour |
| Tour de magie | +Énergie mystique/jour |
| Salle des pactes | Débloque les pactes évolués |
| Bibliothèque des ombres | +Renseignement passif |
| Forge de sang | Amélioration d'équipements |
| Quartiers de PNJ | Logement des alliés recrutés |

---

### 6.5 Conquête des Maisons Nobles

#### EF-JEU-12 : Progression par Maison
Chaque Maison noble se conquiert en 4 étapes :

```
[Espionnage] → [Infiltration de bastions] → [Contrôle des ressources vitales] 
       → [Assaut final du château] → [Capture du Noble Démon chef]
```

#### EF-JEU-13 : Neuf Maisons nobles (9 Nobles of the Demon Realm)
Le jeu oppose le joueur à 9 clans adverses à conquérir progressivement (difficulté croissante). Le clan qui a détruit la famille du joueur est le 9e et dernier.

#### EF-JEU-14 : Capture des chefs nobles
- Après conquête du château, le chef noble est capturé
- Il peut être : recruté comme PNJ puissant, échangé diplomatiquement, ou vaincu
- Exemple : **Ingrid** est le chef (ou général) de l'une des Maisons, capturée en fin de conquête

---

### 6.6 Système de PNJ et Pactes

#### EF-JEU-15 : Pactes démoniques
- Un monstre chassé peut être transformé en PNJ via un rituel de Pacte nocturne
- Le PNJ obtenu a un rôle (combattant, artisan, espion, diplomate) selon le type de monstre
- Chaque PNJ a un niveau d'affinité avec le joueur, évoluant via les interactions nocturnes

---

## 7. Exigences non-fonctionnelles

| Code | Exigence | Critère |
|---|---|---|
| ENF-01 | Performance | 60 FPS stable sur PC moyen (8 Go RAM, GPU intégré) |
| ENF-02 | Accessibilité | Police ≥ 16px, contrastes WCAG AA, navigation clavier |
| ENF-03 | Langue | 100% en français (interface + narration) |
| ENF-04 | Sauvegarde | Auto-save à chaque transition de phase |
| ENF-05 | Sécurité | Pas de données personnelles collectées |
| ENF-06 | Portabilité | Export Windows 10+, Linux, potentiellement Web (HTML5) |
| ENF-07 | Maintenabilité | Code modulaire, commenté en français |
| ENF-08 | Extensibilité | Architecture permettant d'ajouter des chapitres / Maisons |

---

## 8. Contraintes

| Type | Contrainte |
|---|---|
| Légale | Adaptation tout public, aucun contenu adulte |
| Droits | Assets originaux ou libres de droits uniquement (pas d'assets officiels Taimanin sans autorisation) |
| Technique | Pas de serveur backend requis pour le MVP |
| Budget | Logiciels gratuits uniquement (Godot 4, Krita, GIMP, Audacity) |
| Délai | MVP livrable en premier, jeu complet en phase 2 |

---

## 9. Technologies recommandées

### 9.1 Moteur de jeu : **Godot 4** ✅ Recommandé

| Critère | Godot 4 | Ren'Py | RPG Maker MZ |
|---|---|---|---|
| Visual Novel | ✅ Oui (plugin VN ou natif) | ✅ Natif | ⚠️ Limité |
| Gestion stratégique | ✅ Flexible | ❌ Inadapté | ⚠️ Partiel |
| RPG custom | ✅ Complet | ❌ Inadapté | ✅ Bon |
| Cartes interactives | ✅ Oui | ⚠️ Limité | ⚠️ Limité |
| Export multi-plateforme | ✅ Win/Linux/Mac/Web | ✅ Win/Linux/Mac | ✅ Win |
| Gratuit | ✅ Oui | ✅ Oui | ❌ Payant |
| Courbe d'apprentissage | Moyenne | Faible | Faible |
| Extensibilité | ✅ Excellente | ❌ Faible | ⚠️ Moyenne |

**Choix : Godot 4** — seul moteur couvrant l'intégralité des besoins (VN + gestion + RPG + carte) de façon native, gratuit, et maintenable.

### 9.2 Langage : **GDScript** (natif Godot, syntaxe Python)

### 9.3 Assets graphiques
- **Krita** / **GIMP** : création et retouche d'illustrations
- **Inkscape** : éléments vectoriels (carte, UI)
- Générateurs d'images IA (Stable Diffusion local) pour les illustrations du MVP si nécessaire

### 9.4 Audio
- **Audacity** : montage audio
- Musiques libres de droits (OpenGameArt.org, Incompetech)

### 9.5 Gestion de projet
- **Git** + GitHub : versioning
- **Mermaid** (dans Markdown) : diagrammes UML et state machines
- **VS Code** : édition de fichiers, documentation

---

## 10. Architecture du système

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION GODOT 4                          │
│                                                                 │
│  ┌─────────────────┐      ┌──────────────────────────────────┐ │
│  │   MODULE MVP    │      │        MODULE JEU COMPLET        │ │
│  │  (Visual Novel) │      │                                  │ │
│  │                 │      │  ┌──────────┐  ┌──────────────┐  │ │
│  │  ChapterManager │      │  │ GameLoop │  │CharacterMgr  │  │ │
│  │  StoryRenderer  │      │  │  (Phases)│  │(Création PJ) │  │ │
│  │  MapController  │      │  └──────────┘  └──────────────┘  │ │
│  │  AnimPlayer     │      │  ┌──────────┐  ┌──────────────┐  │ │
│  │  SaveSystem     │      │  │ClanManager│  │  WorldMap    │  │ │
│  └────────┬────────┘      │  │(Bastion) │  │  (9 Maisons) │  │ │
│           │               │  └──────────┘  └──────────────┘  │ │
│           │               │  ┌──────────┐  ┌──────────────┐  │ │
│           │               │  │ VNEngine │  │  SaveSystem  │  │ │
│           │               │  │(Événemts)│  │              │  │ │
│           │               │  └──────────┘  └──────────────┘  │ │
│           └──────────────►│                                  │ │
│                           └──────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                   COUCHE DONNÉES                          │ │
│  │  Resources (JSON/TRES) : chapitres, PNJ, bâtiments,      │ │
│  │  cartes, événements, Maisons nobles                       │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 11. Glossaire

| Terme | Définition |
|---|---|
| Demon Realm | Monde démoniaque, univers principal du jeu |
| Hell Knight | Ordre militaire démoniaque au service des 9 Nobles |
| Nine Noble Dominion | Territoire gouverné par les 9 Grandes Maisons nobles démoniques |
| Nomad | Organisation criminelle/politique fondée par Edwin Black |
| Grenier | Dragon noir scellé dans le corps d'Ingrid |
| Bastion | Forteresse du joueur, base de reconstruction du clan |
| Pacte | Rituel transformant un monstre capturé en PNJ allié |
| Phase | Segment temporel d'une journée de jeu (Matin / Après-midi / Nuit) |
| PJ | Personnage joueur |
| PNJ | Personnage non-joueur |
| VN | Visual Novel — format narratif interactif |
| CDC | Cahier des Charges |
| CDPI | Cahier de Projet Informatique |
