# GRUB Theme

Thème GRUB sombre avec fond personnalisé, icônes et menu graphique pour un poste Fedora / Windows en double démarrage.

## Organisation

Chaque variante est autonome et contient son fond, sa configuration, ses icônes et ses assets :

```text
themes/
├── skeleton/
│   ├── theme.txt
│   ├── background.png
│   ├── icons/
│   └── archive/        # anciens assets, non installés
├── void-terminal/
│   ├── theme.txt
│   ├── background.png
│   └── icons/
└── link-start/
    ├── theme.txt
    ├── background.png
    └── icons/
```

La racine contient seulement l’installateur, les tests et la documentation.

Le thème ne modifie pas les entrées de démarrage. Fedora et Windows doivent déjà être détectés et présents dans le `grub.cfg` généré par la machine. GRUB associe les icônes aux classes des entrées de menu.

## Installation sur Fedora

Depuis ce dossier cloné sur Fedora, lancer :

```bash
sudo bash ./install.sh
```

Le script sauvegarde la configuration actuelle, installe le thème avec des permissions strictes, détecte BIOS/UEFI, régénère `grub.cfg` et vérifie les fichiers. Il ne redémarre pas la machine.

La configuration finale dans `/etc/default/grub` est :

```ini
GRUB_GFXMODE=1920x1080,1600x900,1280x720,auto
GRUB_THEME="/boot/grub2/themes/skeleton/theme.txt"
```

Regénérer ensuite la configuration GRUB avec la commande adaptée à l’installation Fedora utilisée. L’icône Fedora est prévue pour les entrées portant la classe `fedora`, et l’icône Windows pour la classe `windows`. Les autres entrées n’ont plus d’icône dédiée dans ce thème.

## État

Version visuelle 3, SIGNAL LOST : squelette ASCII et éclipse magenta à droite, panneau intégré au fond, polices JetBrains Mono / Blackice Term, ligne active en gras et cyan, icônes ASCII ramenées à 24 px et espacement de 48 px entre les entrées. Installation avec `sudo bash ./install.sh skeleton`.

Le mode 16:9 est demandé pour préserver les proportions. Si aucun mode demandé n'est disponible, le firmware choisit le mode de secours `auto`. Les titres particulièrement longs, dont celui du secours Fedora, peuvent encore être tronqués. L'aperçu est simulé : la validation finale se fait au démarrage sur la machine.

## Deuxième thème : VOID TERMINAL

Variante indépendante dans `themes/void-terminal/` : éclipse spatiale originale, menu à gauche, sélection cyan et lignes compactes. Les deux variantes réutilisent les icônes Fedora et Windows. Les entrées de secours et de firmware sont conservées.

Vérifier les fichiers sans droits administrateur et sans installation :

```bash
bash ./install.sh --check void-terminal
bash ./install.sh --check skeleton
```

Tests des trois variantes et des entrées invalides : `bash tests/check.sh` (sans droits administrateur).

Installer la nouvelle variante sur Fedora :

```bash
sudo bash ./install.sh void-terminal
```

Revenir au thème squelette :

```bash
sudo bash ./install.sh skeleton
```

Sans argument, l'installateur choisit toujours `skeleton`. Chaque variante s'installe dans `/boot/grub2/themes/<nom>`, avec sa propre référence `GRUB_THEME`. Chaque installation sauvegarde la configuration précédente ; aucun redémarrage automatique.

Le contrôle `--check` vérifie les fichiers, leur type PNG et la référence au fond ; il ne simule pas GRUB. Les longues entrées peuvent encore être tronquées selon la résolution disponible. La police utilisée est `Unifont Regular 16`, déjà utilisée par le thème d'origine.

Inspiration de composition : [TomorrowX6/arch-grub](https://github.com/TomorrowX6/arch-grub), consulté le 15 septembre 2026. Configuration rédigée pour cette variante ; aucune image ni police du dépôt de référence n'est distribuée ici. Fond original généré avec l'outil image intégré, direction : « éclipse bleu glace à droite, terminal spatial abandonné, gauche sombre dégagée, sans texte ni personnage ».

## LINK START : adaptation directe du thème de TomorrowX6

Cette variante reprend les fichiers du thème `blackice` : mise en page, polices PF2,
sélection, cadres, progression, défilement et icônes Fedora/Windows.
Le fond reprend le décor HUD avec une ville cyberpunk à la place du personnage.
Les crédits et la licence des polices sont dans `themes/link-start/CREDITS.md` et `OFL.txt`.

```bash
bash ./install.sh --check link-start
sudo bash ./install.sh link-start
```

Installation dans `/boot/grub2/themes/link-start`. Cette variante demande les modes
1920×1080, 1600×900, 1280×720, puis `auto` en dernier recours. Si le firmware ne
propose aucun de ces modes, le fond 16:9 peut être déformé dans le mode de secours.
Les autres variantes et leurs fichiers restent disponibles.
