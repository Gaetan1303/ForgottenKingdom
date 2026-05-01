# Machines à états — Royaumes Démoniques

> Diagrammes écrits en **Mermaid** (stateDiagram-v2).

---

## Sommaire

1. [Machine à états principale — Le jeu global](#1-machine-à-états-principale--le-jeu-global)
2. [Machine à états — Cycle journalier](#2-machine-à-états--cycle-journalier)
3. [Machine à états — Phase Matin (décisions)](#3-machine-à-états--phase-matin-décisions)
4. [Machine à états — Phase Nuit (gestion)](#4-machine-à-états--phase-nuit-gestion)
5. [Machine à états — Conquête d'une Maison noble](#5-machine-à-états--conquête-dune-maison-noble)
6. [Machine à états — Combat](#6-machine-à-états--combat)
7. [Machine à états — MVP (parcours d'Ingrid)](#7-machine-à-états--mvp-parcours-dingrid)

---

## 1. Machine à états principale — Le jeu global

```mermaid
stateDiagram
    MENU_PRINCIPAL --> MVP_INGRID : "Voir l'histoire d'Ingrid"
    MENU_PRINCIPAL --> CREATION_PERSONNAGE : "Nouvelle partie (Jeu complet)"
    MENU_PRINCIPAL --> CHARGER_PARTIE : "Continuer"
    MENU_PRINCIPAL --> OPTIONS : "Options"
    MENU_PRINCIPAL --> [*] : "Quitter"

    MVP_INGRID --> MENU_PRINCIPAL : Retour menu

    CREATION_PERSONNAGE --> VN_INTRODUCTION : Personnage créé
    CHARGER_PARTIE --> BOUCLE_DE_JEU : Partie chargée

    VN_INTRODUCTION --> BOUCLE_DE_JEU : Intro terminée

    state BOUCLE_DE_JEU {
        [*] --> PHASE_MATIN
        PHASE_MATIN --> PHASE_APRES_MIDI : Action confirmée
        PHASE_APRES_MIDI --> PHASE_NUIT : Résolution terminée
        PHASE_NUIT --> PHASE_MATIN : Nouvelle journée
    }

    BOUCLE_DE_JEU --> EVENEMENT_CLE : Conditions de conquête atteintes
    EVENEMENT_CLE --> BOUCLE_DE_JEU : Événement résolu
    EVENEMENT_CLE --> VICTOIRE : 9e Maison conquise
    EVENEMENT_CLE --> DEFAITE : Joueur vaincu

    BOUCLE_DE_JEU --> PAUSE_MENU : Touche pause
    PAUSE_MENU --> BOUCLE_DE_JEU : Reprendre
    PAUSE_MENU --> SAUVEGARDE : Sauvegarder
    SAUVEGARDE --> PAUSE_MENU : Sauvegarde OK
    PAUSE_MENU --> MENU_PRINCIPAL : Quitter la partie

    VICTOIRE --> MENU_PRINCIPAL : Retour menu
    DEFAITE --> MENU_PRINCIPAL : Retour menu
    DEFAITE --> CREATION_PERSONNAGE : Recommencer
```

---

## 2. Machine à états — Cycle journalier

```mermaid
stateDiagram
    [*] --> DEBUT_JOURNEE

    DEBUT_JOURNEE --> PHASE_MATIN : Journée initialisée

    state PHASE_MATIN {
        [*] --> AFFICHAGE_DECISIONS
        AFFICHAGE_DECISIONS --> SELECTION_ACTION : Le joueur voit les options
        SELECTION_ACTION --> CONFIRMATION_ACTION : Action choisie
        CONFIRMATION_ACTION --> ACTION_VALIDEE : Ressources suffisantes
        CONFIRMATION_ACTION --> SELECTION_ACTION : Ressources insuffisantes
        ACTION_VALIDEE --> [*]
    }

    PHASE_MATIN --> PHASE_APRES_MIDI : Action confirmée

    state PHASE_APRES_MIDI {
        [*] --> RESOLUTION_ACTION
        RESOLUTION_ACTION --> AFFICHAGE_RESULTATS : Calcul terminé
        AFFICHAGE_RESULTATS --> EVENEMENT_NARRATIF : Événement déclenché
        AFFICHAGE_RESULTATS --> [*] : Pas d'événement
        EVENEMENT_NARRATIF --> [*] : VN terminé
    }

    PHASE_APRES_MIDI --> PHASE_NUIT : Résolution terminée

    state PHASE_NUIT {
        [*] --> CHOIX_ACTIVITE_NUIT
        CHOIX_ACTIVITE_NUIT --> INTERACTION_PNJ : Choisir PNJ
        CHOIX_ACTIVITE_NUIT --> CRAFT : Choisir de crafter
        CHOIX_ACTIVITE_NUIT --> PACTE : Choisir Pacte
        INTERACTION_PNJ --> [*] : Dialogue terminé
        CRAFT --> [*] : Construction lancée
        PACTE --> [*] : Pacte réalisé
    }

    PHASE_NUIT --> FIN_JOURNEE : Activité nuit terminée
    FIN_JOURNEE --> SAUVEGARDE_AUTO : Auto-save
    SAUVEGARDE_AUTO --> VERIF_EVENEMENT_CLE : Conditions vérifiées

    VERIF_EVENEMENT_CLE --> DEBUT_JOURNEE : Aucun événement clé
    VERIF_EVENEMENT_CLE --> EVENEMENT_CLE_CONQUETE : Seuil de conquête atteint
    EVENEMENT_CLE_CONQUETE --> DEBUT_JOURNEE : Événement clé résolu
```

---

## 3. Machine à états — Phase Matin (décisions)

```mermaid
stateDiagram
    [*] --> MENU_MATIN

    MENU_MATIN --> ATTAQUER_BASTION : Sélectionner "Attaquer"
    MENU_MATIN --> RECOLTER : Sélectionner "Récolter"
    MENU_MATIN --> ESPIONNER : Sélectionner "Espionner"
    MENU_MATIN --> ALLER_EN_VILLE : Sélectionner "Partir en ville"
    MENU_MATIN --> CHASSER_MONSTRE : Sélectionner "Chasser"
    MENU_MATIN --> EVENEMENT_LIBRE : Événement aléatoire disponible

    state ATTAQUER_BASTION {
        [*] --> CIBLE_SELECTION
        CIBLE_SELECTION --> VERIFICATION_SOLDATS : Cible choisie
        VERIFICATION_SOLDATS --> CONFIRMATION : Soldats suffisants
        VERIFICATION_SOLDATS --> CIBLE_SELECTION : Ressources insuffisantes (retour)
        CONFIRMATION --> [*] : Confirmé
    }

    state ESPIONNER {
        [*] --> CIBLE_MAISON
        CIBLE_MAISON --> VERIFICATION_AGENT : Maison choisie
        VERIFICATION_AGENT --> CONFIRMATION_SPY : Agent disponible
        VERIFICATION_AGENT --> CIBLE_MAISON : Pas d'agent (retour)
        CONFIRMATION_SPY --> [*]
    }

    state CHASSER_MONSTRE {
        [*] --> ZONE_CHASSE
        ZONE_CHASSE --> VERIFICATION_CHASSEURS : Zone choisie
        VERIFICATION_CHASSEURS --> CONFIRMATION_CHASSE : Chasseurs disponibles
        VERIFICATION_CHASSEURS --> ZONE_CHASSE : Ressources insuffisantes
        CONFIRMATION_CHASSE --> [*]
    }

    ATTAQUER_BASTION --> DECISION_VALIDEE : Action retenue
    RECOLTER --> DECISION_VALIDEE
    ESPIONNER --> DECISION_VALIDEE
    ALLER_EN_VILLE --> DECISION_VALIDEE
    CHASSER_MONSTRE --> DECISION_VALIDEE
    EVENEMENT_LIBRE --> DECISION_VALIDEE

    DECISION_VALIDEE --> [*]
```

---

## 4. Machine à états — Phase Nuit (gestion)

```mermaid
stateDiagram
    [*] --> MENU_NUIT

    MENU_NUIT --> SOUS_MENU_PNJ : "Interagir avec les PNJ"
    MENU_NUIT --> SOUS_MENU_CRAFT : "Crafter"
    MENU_NUIT --> SOUS_MENU_PACTE : "Réaliser un Pacte"

    state SOUS_MENU_PNJ {
        [*] --> LISTE_PNJ
        LISTE_PNJ --> DIALOGUE_PNJ : PNJ sélectionné
        DIALOGUE_PNJ --> AFFINITE_AUGMENTEE : Dialogue positif
        DIALOGUE_PNJ --> AFFINITE_INCHANGEE : Dialogue neutre
        AFFINITE_AUGMENTEE --> QUETE_DISPONIBLE : Affinité seuil atteint
        QUETE_DISPONIBLE --> [*]
        AFFINITE_INCHANGEE --> [*]
        AFFINITE_AUGMENTEE --> [*]
    }

    state SOUS_MENU_CRAFT {
        [*] --> CHOIX_TYPE_CRAFT
        CHOIX_TYPE_CRAFT --> CRAFT_BATIMENT : "Construire un bâtiment"
        CHOIX_TYPE_CRAFT --> CRAFT_ARME : "Forger une arme"
        CHOIX_TYPE_CRAFT --> CRAFT_ITEM : "Créer un item"
        CRAFT_BATIMENT --> VERIFICATION_RESSOURCES_CRAFT
        CRAFT_ARME --> VERIFICATION_RESSOURCES_CRAFT
        CRAFT_ITEM --> VERIFICATION_RESSOURCES_CRAFT
        VERIFICATION_RESSOURCES_CRAFT --> LANCEMENT_CONSTRUCTION : Ressources OK
        VERIFICATION_RESSOURCES_CRAFT --> CHOIX_TYPE_CRAFT : Ressources insuffisantes
        LANCEMENT_CONSTRUCTION --> [*]
    }

    state SOUS_MENU_PACTE {
        [*] --> LISTE_MONSTRES_CAPTURES
        LISTE_MONSTRES_CAPTURES --> SANS_MONSTRE : Aucun monstre capturé
        LISTE_MONSTRES_CAPTURES --> SELECTION_MONSTRE : Monstres disponibles
        SELECTION_MONSTRE --> RITUEL_PACTE : Monstre choisi
        RITUEL_PACTE --> VERIFICATION_ENERGIE_MYSTIQUE
        VERIFICATION_ENERGIE_MYSTIQUE --> SUCCES_PACTE : Énergie suffisante
        VERIFICATION_ENERGIE_MYSTIQUE --> ECHEC_PACTE : Énergie insuffisante
        SUCCES_PACTE --> PNJ_CREE : Monstre transformé
        PNJ_CREE --> [*]
        ECHEC_PACTE --> [*]
        SANS_MONSTRE --> [*]
    }

    SOUS_MENU_PNJ --> ACTIVITE_TERMINEE
    SOUS_MENU_CRAFT --> ACTIVITE_TERMINEE
    SOUS_MENU_PACTE --> ACTIVITE_TERMINEE
    ACTIVITE_TERMINEE --> [*]
```

---

## 5. Machine à états — Conquête d'une Maison noble

```mermaid
stateDiagram
    [*] --> MAISON_INCONNUE

    MAISON_INCONNUE --> MAISON_ESPIONNEE : Espionnage réussi (seuil d'info atteint)

    state MAISON_ESPIONNEE {
        [*] --> INFO_BASIQUE
        INFO_BASIQUE --> INFO_AVANCEE : Espionnage prolongé
        INFO_AVANCEE --> INFO_COMPLETE : Toutes ressources vitales identifiées
        INFO_COMPLETE --> [*]
    }

    MAISON_ESPIONNEE --> PHASE_INFILTRATION : Décision d'attaque prise

    state PHASE_INFILTRATION {
        [*] --> BASTION_1_INTACT
        BASTION_1_INTACT --> BASTION_1_CONQUIS : Attaque victorieuse
        BASTION_1_CONQUIS --> BASTION_2_INTACT
        BASTION_2_INTACT --> BASTION_2_CONQUIS : Attaque victorieuse
        BASTION_2_CONQUIS --> BASTION_3_INTACT
        BASTION_3_INTACT --> BASTION_3_CONQUIS : Attaque victorieuse
        BASTION_3_CONQUIS --> [*]

        BASTION_1_INTACT --> DEFAITE_PARTIELLE : Attaque échouée
        BASTION_2_INTACT --> DEFAITE_PARTIELLE
        BASTION_3_INTACT --> DEFAITE_PARTIELLE
        DEFAITE_PARTIELLE --> BASTION_1_INTACT : Reprendre plus tard
    }

    PHASE_INFILTRATION --> CONTROLE_RESSOURCES : Tous bastions pris

    state CONTROLE_RESSOURCES {
        [*] --> RESSOURCES_CONTESTEES
        RESSOURCES_CONTESTEES --> RESSOURCES_CONTROLEES : Occupation réussie
    }

    CONTROLE_RESSOURCES --> ASSAUT_FINAL : Ressources sécurisées

    state ASSAUT_FINAL {
        [*] --> CINEMATIQUE_ASSAUT
        CINEMATIQUE_ASSAUT --> COMBAT_BOSS : VN d'intro terminé
        COMBAT_BOSS --> VICTOIRE_ASSAUT : Joueur victorieux
        COMBAT_BOSS --> DEFAITE_ASSAUT : Joueur vaincu
        DEFAITE_ASSAUT --> [*] : Retour phase normale (perte de ressources)
        VICTOIRE_ASSAUT --> CAPTURE_CHEF
        CAPTURE_CHEF --> CHOIX_DESTIN_CHEF
        CHOIX_DESTIN_CHEF --> CHEF_RECRUTE : Recrutement
        CHOIX_DESTIN_CHEF --> CHEF_ECHANGE : Diplomatie
        CHOIX_DESTIN_CHEF --> CHEF_VAINCU : Élimination
    }

    ASSAUT_FINAL --> MAISON_CONQUISE : Assaut final réussi

    state MAISON_CONQUISE {
        [*] --> TERRITOIRE_INTEGRE
        TERRITOIRE_INTEGRE --> RESSOURCES_INTEGREES : Intégration clan
    }

    MAISON_CONQUISE --> [*]
```

---

## 6. Machine à états — Combat

```mermaid
stateDiagram
    [*] --> DEBUT_COMBAT

    DEBUT_COMBAT --> PHASE_COMBAT_ACTIVE : Combat initialisé (stats calculées)

    state PHASE_COMBAT_ACTIVE {
        [*] --> TOUR_JOUEUR

        state TOUR_JOUEUR {
            [*] --> SELECTION_ACTION_COMBAT
            SELECTION_ACTION_COMBAT --> ATTAQUE_NORMALE : "Attaquer"
            SELECTION_ACTION_COMBAT --> ATTAQUE_MAGIQUE : "Lancer un sort"
            SELECTION_ACTION_COMBAT --> UTILISER_ITEM : "Utiliser un item"
            SELECTION_ACTION_COMBAT --> FUIR : "Fuir"
            ATTAQUE_NORMALE --> CALCUL_DEGATS
            ATTAQUE_MAGIQUE --> CALCUL_DEGATS_MAGIE
            CALCUL_DEGATS --> [*]
            CALCUL_DEGATS_MAGIE --> [*]
            UTILISER_ITEM --> [*]
            FUIR --> [*]
        }

        TOUR_JOUEUR --> VERIFICATION_ENNEMI_KO : Action joueur terminée
        VERIFICATION_ENNEMI_KO --> TOUR_ENNEMI : Ennemi encore debout
        VERIFICATION_ENNEMI_KO --> FIN_COMBAT_VICTOIRE : Ennemi vaincu

        state TOUR_ENNEMI {
            [*] --> IA_CHOIX_ACTION
            IA_CHOIX_ACTION --> IA_ATTAQUE : Décision IA
            IA_CHOIX_ACTION --> IA_SORT : Décision IA
            IA_ATTAQUE --> CALCUL_DEGATS_ENNEMI
            IA_SORT --> CALCUL_DEGATS_ENNEMI
            CALCUL_DEGATS_ENNEMI --> [*]
        }

        TOUR_ENNEMI --> VERIFICATION_JOUEUR_KO : Action ennemi terminée
        VERIFICATION_JOUEUR_KO --> TOUR_JOUEUR : Joueur encore debout
        VERIFICATION_JOUEUR_KO --> FIN_COMBAT_DEFAITE : Joueur KO
    }

    PHASE_COMBAT_ACTIVE --> FIN_COMBAT_VICTOIRE : Ennemi vaincu
    PHASE_COMBAT_ACTIVE --> FIN_COMBAT_DEFAITE : Joueur KO
    PHASE_COMBAT_ACTIVE --> FIN_COMBAT_FUITE : Joueur a fui

    FIN_COMBAT_VICTOIRE --> RECOMPENSE : Gains calculés
    RECOMPENSE --> [*]

    FIN_COMBAT_DEFAITE --> ECRAN_DEFAITE
    ECRAN_DEFAITE --> [*] : Retour au menu / rebours

    FIN_COMBAT_FUITE --> [*] : Retour carte sans récompense
```

---

## 7. Machine à états — MVP (parcours d'Ingrid)

```mermaid
stateDiagram
    [*] --> MENU_MVP

    MENU_MVP --> PROLOGUE : "Commencer"
    MENU_MVP --> CARTE_INTERACTIVE : "Explorer la carte"
    MENU_MVP --> SELECTION_CHAPITRE : "Choisir un chapitre"
    MENU_MVP --> [*] : "Quitter"

    state PROLOGUE {
        [*] --> SCENE_INTRO
        SCENE_INTRO --> RECIT_ORIGINES : Affichage illustration
        RECIT_ORIGINES --> [*] : Chapitre terminé
    }

    PROLOGUE --> CHAPITRE_I

    state CHAPITRE_I {
        [*] --> SCENE_ALLIANCE
        SCENE_ALLIANCE --> SCENE_9NOBLES : Avancer
        SCENE_9NOBLES --> [*]
    }

    CHAPITRE_I --> CHAPITRE_II
    CHAPITRE_II --> CHAPITRE_III
    CHAPITRE_III --> CHAPITRE_IV
    CHAPITRE_IV --> CHAPITRE_V
    CHAPITRE_V --> CHAPITRE_VI
    CHAPITRE_VI --> CHAPITRE_VII
    CHAPITRE_VII --> CHAPITRE_VIII
    CHAPITRE_VIII --> CHAPITRE_IX
    CHAPITRE_IX --> EPILOGUE

    state EPILOGUE {
        [*] --> SCENE_FINALE
        SCENE_FINALE --> CREDITS
        CREDITS --> [*]
    }

    EPILOGUE --> MENU_MVP : Retour menu

    state CARTE_INTERACTIVE {
        [*] --> CARTE_AFFICHEE
        CARTE_AFFICHEE --> LIEU_SELECTIONNE : Clic sur marqueur
        LIEU_SELECTIONNE --> POPUP_LIEU : Afficher résumé
        POPUP_LIEU --> OUVRIR_CHAPITRE : "Lire le chapitre"
        POPUP_LIEU --> CARTE_AFFICHEE : Fermer popup
        OUVRIR_CHAPITRE --> [*]
        CARTE_AFFICHEE --> [*] : Retour
    }

    CARTE_INTERACTIVE --> MENU_MVP

    state SELECTION_CHAPITRE {
        [*] --> LISTE_CHAPITRES
        LISTE_CHAPITRES --> CHAPITRE_CIBLE : Chapitre sélectionné
        CHAPITRE_CIBLE --> [*]
    }

    SELECTION_CHAPITRE --> CHAPITRE_I : Si Prologue / I
    SELECTION_CHAPITRE --> CHAPITRE_V : Si accès direct V
    SELECTION_CHAPITRE --> EPILOGUE : Si accès Épilogue

    note right of SELECTION_CHAPITRE
        Les chapitres déjà lus
        sont accessibles librement.
        Les chapitres verrouillés
        nécessitent la progression.
    end note
```

---

## Tableau de synthèse des états

| Machine à états | Nb d'états | Complexité | Module |
|---|---|---|---|
| Jeu global | 12 | ★★★☆☆ | Core |
| Cycle journalier | 14 | ★★★☆☆ | GameLoop |
| Phase Matin | 10 | ★★☆☆☆ | DecisionManager |
| Phase Nuit | 15 | ★★★☆☆ | NightManager |
| Conquête Maison noble | 18 | ★★★★☆ | ConquestManager |
| Combat | 16 | ★★★☆☆ | CombatEngine |
| MVP Ingrid | 20+ | ★★☆☆☆ | ChapterManager |
