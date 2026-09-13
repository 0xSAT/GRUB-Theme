# GRUB Theme

Thème GRUB minimal sombre pour un poste Fedora / Windows en double démarrage.

## Contenu

- `theme.txt` : mise en page du menu graphique GRUB.

Le thème ne modifie pas les entrées de démarrage. Fedora et Windows doivent déjà être détectés et présents dans le `grub.cfg` généré par la machine.

## Installation sur Fedora

Copier le dossier du thème vers `/boot/grub2/themes/grub-theme/`, puis définir dans `/etc/default/grub` :

```ini
GRUB_GFXMODE=auto
GRUB_THEME="/boot/grub2/themes/grub-theme/theme.txt"
```

Regénérer ensuite la configuration GRUB avec la commande adaptée à l’installation Fedora utilisée.

## État

Première version sans logos ni images externes. Les icônes et le style de sélection pourront être ajoutés après validation du rendu de base.
