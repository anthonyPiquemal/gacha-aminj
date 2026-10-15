# Gacha Aminj

## Description du jeu

TODO

## Membres du projet

TODO

## Organisation du dépôt

```text
.
├── game/
│   ├── audio/    # Musiques et effets sonores
│   ├── core/     # Logique et systèmes centraux du jeu
│   ├── data/     # Données de configuration et de gameplay
│   ├── fonts/    # Polices utilisées par le jeu
│   ├── images/   # Illustrations et autres ressources visuelles
│   └── ui/       # Ressources liées à l'interface utilisateur
├── .gitignore
└── README.md
```

## Développement

Les contributions peuvent être organisées autour des axes suivants :

- intégrer les systèmes de jeu dans `game/core/` ;
- structurer les données dans `game/data/` ;
- ajouter les écrans et composants d’interface dans `game/ui/` ;
- centraliser les ressources audio, graphiques et typographiques dans les
  dossiers correspondants.

## Règles pour les commits

### Comment faire un commit ?

#### 1. `git add` — Préparer les fichiers

  La commande `git add` sélectionne les modifications que l'on souhaite inclure dans le prochain commit.

  ```bash
  git add fichier.rpy
  ```

  Cette commande prépare uniquement le fichier `fichier.rpy`.

  Pour préparer tous les fichiers modifiés :

  ```bash
  git add .
  ```

#### 2. `git commit` — Enregistrer les modifications

La commande `git commit` enregistre les modifications préparées dans l'historique local du projet.

```bash
git commit -m "add(fichier.rpy) : ajout de fichier.rpy au projet"
```

Le message doit respecter notre convention de commits.

#### 3. `git push` — Envoyer les modifications

La commande `git push` envoie les commits locaux vers le dépôt distant, par exemple sur GitHub.

```bash
git push
```

Les autres membres de l'équipe pourront alors récupérer les modifications envoyées.

#### 4. Workflow classique

Lorsqu'une fonctionnalité est terminée, suivre ces trois étapes :

```bash
git add fichier.rpy
git commit -m "add(fichier.rpy) : ajout de fichier.rpy au projet"
git push
```

### 1. Syntaxe des commits

Tous les commits doivent respecter le format suivant :

```text
type(fichier) : description courte
```

Exemple :

```text
modify(gacha.rpy) : ajout du tirage SSR
```

- **type** : indique la nature du changement.
- **fichier** : indique le fichier principalement concerné.
- **description courte** : explique le changement effectué.

### 2. Types de commits

| Type | Utilisation | Exemple |
| --- | --- | --- |
| `add` | Ajouter une fonctionnalité ou un fichier | `add(cards.rpy) : ajout des cartes LR` |
| `modify` | Modifier une fonctionnalité existante | `modify(gacha.rpy) : ajustement des probabilités` |
| `fix` | Corriger un bug | `fix(battle.rpy) : correction des dégâts` |
| `remove` | Supprimer du code ou un fichier | `remove(test.rpy) : suppression du fichier de test` |
| `style` | Modifier uniquement l'apparence | `style(screens.rpy) : amélioration du menu principal` |
| `refactor` | Réorganiser le code sans changer son comportement | `refactor(cards.rpy) : simplification des données` |
| `docs` | Modifier la documentation | `docs(README.md) : ajout des instructions` |

### 3. Règles à respecter

1. **Un commit = un changement cohérent.** Éviter de mélanger plusieurs modifications sans rapport.
2. **Rester court et précis.** Décrire le changement sans entrer dans les détails techniques inutiles.
3. **Utiliser une description claire.** Par exemple : ajout, correction, suppression ou amélioration.
4. **Faire des commits régulièrement.** Ne pas attendre la fin
