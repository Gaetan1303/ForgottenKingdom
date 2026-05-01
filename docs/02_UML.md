# Diagrammes UML — Royaumes Démoniques

> Tous les diagrammes sont écrits en **Mermaid** (rendu dans VS Code avec l'extension *Markdown Preview Mermaid Support*, ou sur GitHub).

---

## Sommaire

1. [Diagramme de cas d'utilisation — MVP](#1-diagramme-de-cas-dutilisation--mvp)
2. [Diagramme de cas d'utilisation — Jeu complet](#2-diagramme-de-cas-dutilisation--jeu-complet)
3. [Diagramme de classes — Domaine métier RPG](#3-diagramme-de-classes--domaine-métier-rpg)
4. [Diagramme de classes — MVP (Histoire Ingrid)](#4-diagramme-de-classes--mvp-histoire-ingrid)
5. [Diagramme de séquence — Cycle journalier](#5-diagramme-de-séquence--cycle-journalier)
6. [Diagramme de séquence — Conquête d'une Maison noble](#6-diagramme-de-séquence--conquête-dune-maison-noble)
7. [Diagramme de composants — Architecture Godot 4](#7-diagramme-de-composants--architecture-godot-4)

---

## 1. Diagramme de cas d'utilisation — MVP

```mermaid
graph TD
    Joueur(["👤 Joueur"])

    subgraph MVP ["MVP — Histoire interactive d'Ingrid"]
        UC1["Consulter le menu principal"]
        UC2["Choisir un chapitre"]
        UC3["Lire un chapitre narratif"]
        UC4["Voir les illustrations et animations"]
        UC5["Naviguer sur la carte interactive"]
        UC6["Cliquer sur un lieu de la carte"]
        UC7["Reprendre la progression sauvegardée"]
        UC8["Revenir au menu"]
    end

    Joueur --> UC1
    UC1 --> UC2
    UC1 --> UC7
    UC2 --> UC3
    UC3 --> UC4
    UC3 --> UC8
    UC1 --> UC5
    UC5 --> UC6
    UC6 --> UC3
```

---

## 2. Diagramme de cas d'utilisation — Jeu complet

```mermaid
graph TD
    Joueur(["👤 Joueur"])

    subgraph CREATION ["Création du personnage"]
        UC_APPAR["Définir l'apparence"]
        UC_CLASSE["Choisir une classe"]
        UC_POUV["Choisir les pouvoirs et dons"]
        UC_COMP["Répartir les compétences"]
        UC_EQUIP["Choisir l'équipement de départ"]
    end

    subgraph VN_INTRO ["Introduction Visual Novel"]
        UC_INTRO["Lire l'introduction du Demon Realm"]
        UC_INTRO2["Découvrir la destruction du clan"]
    end

    subgraph MATIN ["Phase Matin — Décisions"]
        UC_ATT["Attaquer un bastion ennemi"]
        UC_RECOLTE["Récolter des ressources"]
        UC_SPY["Espionner une Maison noble"]
        UC_VILLE["Partir en ville"]
        UC_CHASSE["Chasser un monstre"]
    end

    subgraph APMIDI ["Phase Après-midi — Résolution"]
        UC_RESULTAT["Voir le résultat de l'action"]
        UC_EVT["Déclencher un événement narratif (VN)"]
    end

    subgraph NUIT ["Phase Nuit — Gestion"]
        UC_PNJ["Interagir avec les PNJ"]
        UC_CRAFT["Crafter bâtiment / arme / item"]
        UC_PACTE["Réaliser un pacte démonique"]
    end

    subgraph EVENEMENTS ["Événements clés — Conquête"]
        UC_ESP["Espionner la Maison noble cible"]
        UC_INFIL["Infiltrer et prendre des bastions"]
        UC_CTRL["Contrôler les ressources vitales"]
        UC_ASSAUT["Assaut final du château"]
        UC_CAPTURE["Capturer le chef noble démon"]
    end

    Joueur --> UC_APPAR
    Joueur --> UC_CLASSE
    Joueur --> UC_POUV
    Joueur --> UC_COMP
    Joueur --> UC_EQUIP

    UC_EQUIP --> UC_INTRO
    UC_INTRO --> UC_INTRO2

    UC_INTRO2 --> UC_ATT
    Joueur --> UC_ATT
    Joueur --> UC_RECOLTE
    Joueur --> UC_SPY
    Joueur --> UC_VILLE
    Joueur --> UC_CHASSE

    UC_ATT --> UC_RESULTAT
    UC_RECOLTE --> UC_RESULTAT
    UC_SPY --> UC_RESULTAT
    UC_CHASSE --> UC_RESULTAT
    UC_RESULTAT --> UC_EVT

    Joueur --> UC_PNJ
    Joueur --> UC_CRAFT
    Joueur --> UC_PACTE

    Joueur --> UC_ESP
    UC_ESP --> UC_INFIL
    UC_INFIL --> UC_CTRL
    UC_CTRL --> UC_ASSAUT
    UC_ASSAUT --> UC_CAPTURE
```

---

## 3. Diagramme de classes — Domaine métier RPG

```mermaid
classDiagram
    class Joueur {
        +String nom
        +Apparence apparence
        +ClassePersonnage classe
        +Stats stats
        +List~Pouvoir~ pouvoirs
        +List~Don~ dons
        +List~Competence~ competences
        +List~Item~ equipement
        +evoluer()
        +obtenirStats() Stats
    }

    class Stats {
        +int force
        +int magie
        +int espionnage
        +int artisanat
        +int diplomatie
        +int commandement
        +int pointsDeVie
        +int pointsDeMagie
        +calculerTotal() int
    }

    class ClassePersonnage {
        <<enumeration>>
        CHEVALIER_SOMBRE
        MAGE_DU_PACTE
        STRATEGE_DES_OMBRES
        FORGERON_DE_SANG
        SANG_NOBLE
    }

    class Pouvoir {
        +String nom
        +String description
        +int coutMagie
        +String element
        +utiliser(cible)
    }

    class Don {
        +String nom
        +String description
        +String effetPassif
        +appliquer()
    }

    class Clan {
        +String nom
        +Blason blason
        +Ressources ressources
        +List~Batiment~ batiments
        +List~PNJ~ membres
        +Territoire territoire
        +int niveauReputation
        +construire(batiment)
        +recruter(pnj)
        +calculerRevenues() Ressources
    }

    class Blason {
        +String nomFamille
        +String couleur
        +String embleme
        +bool estRestauré
        +restaurer()
    }

    class Ressources {
        +int or
        +int energieMystique
        +int soldats
        +int influence
        +ajouter(type, quantité)
        +depenser(type, quantité) bool
    }

    class Batiment {
        +String nom
        +String description
        +int coutConstruction
        +Map~String_int~ production
        +bool estConstruit
        +construire()
        +getProduction() Map
    }

    class JourneeDeJeu {
        +int numero
        +PhaseJeu phaseActuelle
        +List~Decision~ decisionsDisponibles
        +EvenementNarratif evenement
        +changerPhase(phase)
        +resoudreDecision(decision) Resultat
    }

    class PhaseJeu {
        <<enumeration>>
        MATIN
        APRES_MIDI
        NUIT
    }

    class Decision {
        +TypeDecision type
        +String description
        +Cible cible
        +Ressources cout
        +Resultat resoudre()
    }

    class TypeDecision {
        <<enumeration>>
        ATTAQUER
        RECOLTER
        ESPIONNER
        ALLER_EN_VILLE
        CHASSER
        EVENEMENT_LIBRE
    }

    class Resultat {
        +bool succes
        +Ressources gains
        +Ressources pertes
        +String texteNarratif
        +EvenementNarratif evenementDeclenche
    }

    class PNJ {
        +String nom
        +TypePNJ type
        +int niveauAffinite
        +Monster origineMonster
        +List~Dialogue~ dialogues
        +interagir() Dialogue
        +evoluerAffinite(valeur)
    }

    class TypePNJ {
        <<enumeration>>
        COMBATTANT
        ARTISAN
        ESPION
        DIPLOMATE
        MENTOR
    }

    class MaisonNoble {
        +String nom
        +NobleDemon chef
        +Territoire territoire
        +List~Bastion~ bastions
        +Ressources ressourcesVitales
        +StatutMaison statut
        +int niveauEspionnage
        +calculerDefense() int
    }

    class StatutMaison {
        <<enumeration>>
        INCONNUE
        ESPIONNEE
        INFILTREE
        PARTIELLEMENT_CONQUISE
        CONQUISE
    }

    class NobleDemon {
        +String nom
        +MaisonNoble maison
        +int puissance
        +bool estCapture
        +Stats stats
        +combattre(adversaire) Resultat
        +seRendre() bool
    }

    class EvenementNarratif {
        +String titre
        +List~SceneVN~ scenes
        +TypeEvenement type
        +jouер()
    }

    class Pacte {
        +Monster monstre
        +PNJ pnjResultant
        +int coutEnergie
        +bool realiser() PNJ
    }

    Joueur "1" --> "1" Stats
    Joueur "1" --> "1" ClassePersonnage
    Joueur "1" --> "0..*" Pouvoir
    Joueur "1" --> "0..*" Don
    Joueur "1" --> "1" Clan

    Clan "1" --> "1" Blason
    Clan "1" --> "1" Ressources
    Clan "1" --> "0..*" Batiment
    Clan "1" --> "0..*" PNJ

    JourneeDeJeu "1" --> "1" PhaseJeu
    JourneeDeJeu "1" --> "1..*" Decision
    Decision "1" --> "1" TypeDecision
    Decision "1" --> "1" Resultat
    Resultat "0..1" --> "1" EvenementNarratif

    PNJ "1" --> "1" TypePNJ
    Pacte "1" --> "1" PNJ

    MaisonNoble "1" --> "1" NobleDemon
    MaisonNoble "1" --> "1" StatutMaison
```

---

## 4. Diagramme de classes — MVP (Histoire Ingrid)

```mermaid
classDiagram
    class IngridMVP {
        +List~Chapitre~ chapitres
        +Progression progression
        +CarteMonde carte
        +ChapitreActuel chapitreActuel
        +demarrer()
        +chargerProgression()
        +sauvegarder()
    }

    class Chapitre {
        +int numero
        +String titre
        +String periodeHistorique
        +List~Scene~ scenes
        +List~Lieu~ lieuxCles
        +Illustration illustrationPrincipale
        +List~Animation~ animations
        +bool estLu
        +lire()
        +marquerLu()
    }

    class Scene {
        +String texteNarratif
        +Illustration illustration
        +Animation animationEntree
        +Animation animationSortie
        +Audio musiqueFond
        +afficher()
        +passer()
    }

    class Illustration {
        +String cheminFichier
        +String description
        +String sourceCredit
        +charger()
    }

    class Animation {
        +String type
        +float duree
        +jouer()
        +arreter()
    }

    class Lieu {
        +String nom
        +float latitude
        +float longitude
        +String description
        +int chapitreAssocie
        +Illustration image
    }

    class CarteMonde {
        +List~Lieu~ lieux
        +String regionActive
        +afficher()
        +centrerSur(lieu)
        +surCliquerLieu(lieu)
    }

    class Progression {
        +int dernierChapitreLu
        +List~int~ chapitresVus
        +float pourcentageCompletion
        +sauvegarder()
        +charger()
        +marquerChapitre(numero)
    }

    IngridMVP "1" --> "11" Chapitre
    IngridMVP "1" --> "1" CarteMonde
    IngridMVP "1" --> "1" Progression
    Chapitre "1" --> "1..*" Scene
    Chapitre "1..*" --> "0..*" Lieu
    Scene "1" --> "0..1" Illustration
    Scene "1" --> "0..2" Animation
    CarteMonde "1" --> "0..*" Lieu
```

---

## 5. Diagramme de séquence — Cycle journalier

```mermaid
sequenceDiagram
    actor Joueur
    participant UI as Interface UI
    participant GameLoop as GameLoop
    participant PhaseManager as PhaseManager
    participant DecisionManager as DecisionManager
    participant ClanManager as ClanManager
    participant VNEngine as VNEngine

    Note over Joueur, VNEngine: ── PHASE MATIN ──

    GameLoop ->> PhaseManager: demarrerPhaseMatin()
    PhaseManager ->> UI: afficherMenuDecisions()
    UI ->> Joueur: Afficher les actions disponibles
    Joueur ->> UI: Choisir une action (ex: Espionner)
    UI ->> DecisionManager: confirmerDecision(ESPIONNER, cible)
    DecisionManager ->> ClanManager: verifierRessources(cout)
    ClanManager -->> DecisionManager: OK
    DecisionManager ->> DecisionManager: enregistrerDecision()
    DecisionManager -->> UI: décision_enregistrée

    Note over Joueur, VNEngine: ── PHASE APRÈS-MIDI ──

    GameLoop ->> PhaseManager: demarrerPhaseApresMidi()
    PhaseManager ->> DecisionManager: resoudreDecisionDuMatin()
    DecisionManager ->> DecisionManager: calculerResultat()
    DecisionManager ->> ClanManager: appliquerGains(resultat)
    DecisionManager -->> PhaseManager: resultat(succes, gains, texte)
    PhaseManager ->> UI: afficherResultat(resultat)
    UI ->> Joueur: Afficher l'animation de résolution

    alt Événement narratif déclenché
        PhaseManager ->> VNEngine: jouerEvenement(evenement)
        VNEngine ->> UI: afficherSceneVN()
        UI ->> Joueur: Afficher le visual novel
        Joueur ->> UI: Avancer dans la scène
        UI ->> VNEngine: sceneTerminee()
        VNEngine -->> PhaseManager: evenementTermine()
    end

    Note over Joueur, VNEngine: ── PHASE NUIT ──

    GameLoop ->> PhaseManager: demarrerPhaseNuit()
    PhaseManager ->> UI: afficherMenuNuit()
    UI ->> Joueur: Interagir avec PNJ / Crafter / Pacte

    alt Interaction PNJ
        Joueur ->> UI: choisirPNJ(pnj)
        UI ->> VNEngine: afficherDialogue(pnj)
        VNEngine -->> UI: dialogueTerminé()
    else Crafter un élément
        Joueur ->> UI: choisirCraft(batiment)
        UI ->> ClanManager: lancerConstruction(batiment)
        ClanManager -->> UI: constructionLancee()
    else Réaliser un Pacte
        Joueur ->> UI: choisirMonstre(monstre)
        UI ->> ClanManager: realiserPacte(monstre)
        ClanManager -->> UI: PNJ(pnjCree)
    end

    GameLoop ->> PhaseManager: finJournee()
    PhaseManager ->> GameLoop: demarrerNouvelleJournee()
```

---

## 6. Diagramme de séquence — Conquête d'une Maison noble

```mermaid
sequenceDiagram
    actor Joueur
    participant UI as Interface UI
    participant WorldMap as Carte du Monde
    participant ConquestManager as ConquestManager
    participant MaisonNoble as MaisonNoble
    participant VNEngine as VNEngine

    Joueur ->> WorldMap: selectionnerMaisonNoble(maison)
    WorldMap ->> ConquestManager: getStatutMaison(maison)
    ConquestManager -->> UI: StatutMaison.INCONNUE

    Note over Joueur, VNEngine: ÉTAPE 1 — Espionnage

    Joueur ->> UI: choisirAction(ESPIONNER, maison)
    UI ->> ConquestManager: espionner(maison, nbJours)
    loop Chaque jour d'espionnage
        ConquestManager ->> MaisonNoble: decouvrir(information)
        MaisonNoble -->> ConquestManager: InfoDecouverte
    end
    ConquestManager ->> MaisonNoble: setStatut(ESPIONNEE)
    ConquestManager -->> UI: espionnageComplet(infos)

    Note over Joueur, VNEngine: ÉTAPE 2 — Infiltration des bastions

    Joueur ->> UI: choisirAction(ATTAQUER_BASTION, bastion)
    UI ->> ConquestManager: attaquerBastion(bastion)
    ConquestManager ->> MaisonNoble: calculerDefense(bastion)
    MaisonNoble -->> ConquestManager: valeurDefense
    ConquestManager ->> ConquestManager: resoudreCombat(attaque, defense)
    ConquestManager -->> UI: resultatCombat(victoire)
    ConquestManager ->> MaisonNoble: setStatut(PARTIELLEMENT_CONQUISE)

    Note over Joueur, VNEngine: ÉTAPE 3 — Assaut final

    Joueur ->> UI: lancerAssautFinal(maison)
    UI ->> VNEngine: jouerEvenementCle("assaut_" + maison.nom)
    VNEngine ->> Joueur: Cinématique d'assaut (VN)

    ConquestManager ->> MaisonNoble: combattreSeigneur()
    MaisonNoble -->> ConquestManager: resultat(victoire)

    ConquestManager ->> MaisonNoble: capturer(chef)
    MaisonNoble -->> ConquestManager: NobleDemon(capture=true)

    ConquestManager ->> MaisonNoble: setStatut(CONQUISE)
    VNEngine ->> Joueur: Scène de capture du chef noble
    ConquestManager -->> UI: victoire(maison, chef_capture)
```

---

## 7. Diagramme de composants — Architecture Godot 4

```mermaid
graph TB
    subgraph Godot4 ["Projet Godot 4"]

        subgraph Core ["Composants Core"]
            GameManager["GameManager\n(Autoload Singleton)"]
            SaveSystem["SaveSystem\n(Autoload Singleton)"]
            AudioManager["AudioManager\n(Autoload Singleton)"]
            EventBus["EventBus\n(Autoload Singleton)"]
        end

        subgraph MVP_Module ["Module MVP — Histoire Ingrid"]
            ChapterManager["ChapterManager"]
            StoryRenderer["StoryRenderer\n(labels, images)"]
            MapController["MapController\n(carte interactive)"]
            AnimationPlayer2["AnimationPlayer\n(effets, transitions)"]
            ChapterData["ChapterData\n(Resources JSON)"]
        end

        subgraph Game_Module ["Module Jeu Complet"]
            subgraph Creation ["Création Personnage"]
                CharacterCreator["CharacterCreator"]
                AppearanceEditor["AppearanceEditor"]
            end

            subgraph GameLoop_Module ["Boucle de jeu"]
                PhaseManager["PhaseManager"]
                DecisionManager["DecisionManager"]
                ResolutionEngine["ResolutionEngine"]
            end

            subgraph Clan_Module ["Gestion Clan"]
                ClanManager["ClanManager"]
                BuildingSystem["BuildingSystem"]
                ResourceManager["ResourceManager"]
                PactSystem["PactSystem"]
            end

            subgraph World_Module ["Monde & Conquête"]
                WorldMapUI["WorldMapUI"]
                ConquestManager["ConquestManager"]
                HouseManager["HouseManager\n(9 Maisons nobles)"]
            end

            subgraph VN_Module ["Visual Novel Engine"]
                VNEngine["VNEngine"]
                DialogueParser["DialogueParser"]
                CharacterDisplay["CharacterDisplay"]
            end
        end

        subgraph Data ["Données (Resources)"]
            ChapterRes["chapitres/*.tres"]
            NPCRes["pnj/*.tres"]
            BuildingRes["batiments/*.tres"]
            HouseRes["maisons/*.tres"]
            EventRes["evenements/*.tres"]
            MapRes["cartes/*.tres"]
        end
    end

    GameManager --> PhaseManager
    GameManager --> ChapterManager
    SaveSystem --> GameManager
    EventBus --> VNEngine
    EventBus --> PhaseManager

    ChapterManager --> StoryRenderer
    ChapterManager --> AnimationPlayer2
    ChapterManager --> MapController
    ChapterManager --> ChapterRes

    PhaseManager --> DecisionManager
    PhaseManager --> ResolutionEngine
    ResolutionEngine --> ClanManager
    ResolutionEngine --> VNEngine

    ClanManager --> ResourceManager
    ClanManager --> BuildingSystem
    ClanManager --> PactSystem

    ConquestManager --> HouseManager
    ConquestManager --> VNEngine

    VNEngine --> DialogueParser
    VNEngine --> CharacterDisplay

    HouseManager --> HouseRes
    ClanManager --> BuildingRes
    VNEngine --> EventRes
```
