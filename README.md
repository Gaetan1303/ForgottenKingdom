# Royaume Déchu — Les Cendres de Veyr

Jeu narratif et de gestion sous Godot **4.4**. `mvp/` est l'unique projet
Godot : développement, tests, exports et GitHub Pages utilisent cette racine.

```bash
cd mvp
godot --editor project.godot
```

Depuis la racine du dépôt, l'import et le lancement peuvent aussi être exécutés
sans éditeur graphique :

```bash
godot --headless --path mvp --import
godot --path mvp
```

Les ressources embarquées sont sous `res://` dans `mvp/`. Les sauvegardes,
slots et portraits du joueur utilisent `user://`.

- `mvp/scenes/` : menu, introduction, souvenirs/tutoriel, création et domaine.
- `mvp/scripts/` : contrôleurs, services métier et tests.
- `mvp/assets/` : images, audio et shaders ; conserver les sources et les `.import`.
- `mvp/data/`, `mvp/story/`, `mvp/resources/` : données, lore et ressources Godot.
- `scripts/` : outils de validation et d'export, utilisables depuis tout répertoire.
- `docs/architecture/` : [migration](docs/architecture/MVP_MIGRATION.md) et
  [refactor de ClanManager](docs/architecture/CLAN_MANAGER_REFACTOR.md).

Validation complète, avec Godot 4.4 et Python 3 :

```bash
./scripts/ci_test.sh
```

Le contrôle des chemins s'exécute sur le dépôt. Les tests s'exécutent dans une
copie temporaire importée sans cache, avec un dossier utilisateur propre par
suite ; le chemin des résultats est affiché. Aucun fichier personnel de sauvegarde
n'est utilisé.

Export Web, avec les templates officiels de la même version que Godot :

```bash
./scripts/export_web.sh
python3 -m http.server --directory build/web 8000
```

Ouvrir `http://localhost:8000/`. Le premier clic, toucher ou appui clavier active
la musique dans le navigateur. Le preset utilise un seul thread et Compatibility
pour le Web. Les JSON, YAML et CSV sont inclus explicitement dans le PCK.
Les caches et exports sont ignorés par Git.

Les workflows CI/Pages utilisent la branche `Dev`. Pages publie `build/web`,
qui contient `index.html`, `index.wasm`, `index.pck` et `index.js`. Le réglage
GitHub Pages du dépôt doit utiliser **GitHub Actions**. Les paramètres distants
et le déploiement effectif se contrôlent sur GitHub.

Licence : voir [LICENSE](LICENSE).
