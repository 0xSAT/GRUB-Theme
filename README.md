# GRUB Theme

Thème GRUB sombre avec fond personnalisé, icônes et menu graphique pour un poste Fedora / Windows en double démarrage.

## Contenu

- `theme.txt` : mise en page du menu graphique GRUB.
- `background-grub-signal-skeleton.png` : squelette ASCII avec halo d’éclipse et signaux néon, utilisé par le thème actuel.
- `menu_*.png` : neuf tranches du panneau verre fumé derrière le menu.
- `select_*.png` : neuf tranches du halo de sélection de l’entrée active.
- `icons/fedora.png` : icône Fedora F en ASCII glitch sombre, dans le style de l’icône Windows.
- `icons/windows.png` : icône Windows en ASCII glitch sur fond transparent.
- `install.sh` : installation vérifiée et sauvegardée sur Fedora.

Le thème ne modifie pas les entrées de démarrage. Fedora et Windows doivent déjà être détectés et présents dans le `grub.cfg` généré par la machine. GRUB associe les icônes aux classes des entrées de menu.

## Installation sur Fedora

Depuis ce dossier cloné sur Fedora, lancer :

```bash
sudo bash ./install.sh
```

Le script sauvegarde la configuration actuelle, installe le thème avec des permissions strictes, détecte BIOS/UEFI, régénère `grub.cfg` et vérifie les fichiers. Il ne redémarre pas la machine.

La configuration finale dans `/etc/default/grub` est :

```ini
GRUB_GFXMODE=auto
GRUB_THEME="/boot/grub2/themes/grub-theme/theme.txt"
```

Regénérer ensuite la configuration GRUB avec la commande adaptée à l’installation Fedora utilisée. L’icône Fedora est prévue pour les entrées portant la classe `fedora`, et l’icône Windows pour la classe `windows`. Les autres entrées n’ont plus d’icône dédiée dans ce thème.

## État

Version visuelle 2 : interface HUD cyberpunk sobre, menu décalé à gauche, sélection lumineuse, barre de délai et raccourcis clavier. Le squelette ASCII reste visible sur la droite, sans personnage ajouté.

## Deuxième thème : VOID TERMINAL

Variante indépendante dans `themes/void-terminal/` : éclipse spatiale originale, menu à gauche, sélection cyan et lignes compactes. Les deux variantes réutilisent les icônes Fedora et Windows. Les entrées de secours et de firmware sont conservées.

Vérifier les fichiers sans droits administrateur et sans installation :

```bash
bash ./install.sh --check void-terminal
bash ./install.sh --check skeleton
```

Tests des deux variantes et des entrées invalides : `bash tests/check.sh` (sans droits administrateur).

Installer la nouvelle variante sur Fedora :

```bash
sudo bash ./install.sh void-terminal
```

Revenir au thème squelette :

```bash
sudo bash ./install.sh skeleton
```

Sans argument, l'installateur choisit toujours `skeleton`. VOID TERMINAL s'installe dans `/boot/grub2/themes/void-terminal`, avec sa propre référence `GRUB_THEME`. Chaque installation sauvegarde la configuration précédente ; aucun redémarrage automatique.

Le contrôle `--check` vérifie les fichiers, leur type PNG et la référence au fond ; il ne simule pas GRUB. Les longues entrées peuvent encore être tronquées selon la résolution disponible. La police utilisée est `Unifont Regular 16`, déjà utilisée par le thème d'origine.

Inspiration de composition : [TomorrowX6/arch-grub](https://github.com/TomorrowX6/arch-grub), consulté le 15 septembre 2026. Configuration rédigée pour cette variante ; aucune image ni police du dépôt de référence n'est distribuée ici. Fond original généré avec l'outil image intégré, direction : « éclipse bleu glace à droite, terminal spatial abandonné, gauche sombre dégagée, sans texte ni personnage ».
