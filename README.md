# GRUB Theme

Thème GRUB sombre avec fond personnalisé, icônes et menu graphique pour un poste Fedora / Windows en double démarrage.

## Contenu

- `theme.txt` : mise en page du menu graphique GRUB.
- `background-grub-signal-skeleton.png` : squelette ASCII avec halo d’éclipse et signaux néon, utilisé par le thème actuel.
- `icons/fedora.png` : icône Fedora F en ASCII glitch sombre, dans le style de l’icône Windows.
- `icons/windows.png` : icône Windows en ASCII glitch sur fond transparent.

Le thème ne modifie pas les entrées de démarrage. Fedora et Windows doivent déjà être détectés et présents dans le `grub.cfg` généré par la machine. GRUB associe les icônes aux classes des entrées de menu.

## Installation sur Fedora

Copier le dossier du thème vers `/boot/grub2/themes/grub-theme/`, puis définir dans `/etc/default/grub` :

```ini
GRUB_GFXMODE=auto
GRUB_THEME="/boot/grub2/themes/grub-theme/theme.txt"
```

Regénérer ensuite la configuration GRUB avec la commande adaptée à l’installation Fedora utilisée. L’icône Fedora est prévue pour les entrées portant la classe `fedora`, et l’icône Windows pour la classe `windows`. Les autres entrées n’ont plus d’icône dédiée dans ce thème.

## État

Version visuelle 1 : fond, icônes, titre, menu centré et barre de délai. Le style de sélection par image 9-slices pourra être ajouté si le rendu de base est validé.
