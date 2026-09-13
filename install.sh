#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
theme=/boot/grub2/themes/grub-theme
backup="/var/backups/grub-theme-$(date +%Y%m%d-%H%M%S)"
defaults=/etc/default/grub
panels=(nw n ne w c e sw s se)

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
warn() { printf '[WARN] %s\n' "$*" >&2; }

[[ $EUID -eq 0 ]] || die 'Lance avec : sudo bash ./install.sh'
command -v grub2-mkconfig >/dev/null || die 'grub2-mkconfig absent : installe grub2-tools'
command -v grub2-script-check >/dev/null || die 'grub2-script-check absent : installe grub2-tools'
command -v file >/dev/null || die 'file absent : installe le paquet file'

for path in \
    "$repo/theme.txt" \
    "$repo/background-grub-signal-skeleton.png" \
    "$repo/icons/fedora.png" \
    "$repo/icons/windows.png"; do
    [[ -f $path && ! -L $path ]] || die "Fichier manquant ou lien symbolique : $path"
done

for panel in "${panels[@]}"; do
    path="$repo/menu_${panel}.png"
    [[ -f $path && ! -L $path ]] || die "Tranche de panneau manquante : $path"
done

extra="$(find "$repo/icons" -maxdepth 1 -type f ! -name fedora.png ! -name windows.png -print -quit)"
[[ -z $extra ]] || die "Icône supplémentaire trouvée : $extra"

for image in \
    "$repo/background-grub-signal-skeleton.png" \
    "$repo/icons/fedora.png" \
    "$repo/icons/windows.png"; do
    [[ "$(file -b --mime-type "$image")" == image/png ]] || die "PNG invalide : $image"
done

for panel in "${panels[@]}"; do
    image="$repo/menu_${panel}.png"
    [[ "$(file -b --mime-type "$image")" == image/png ]] || die "PNG invalide : $image"
done

grep -Fq 'desktop-image: "background-grub-signal-skeleton.png"' "$repo/theme.txt" \
    || die 'theme.txt ne référence pas le fond attendu'
[[ -f $defaults ]] || die "$defaults introuvable"

install -d -o root -g root -m 0755 /boot/grub2/themes "$backup"
install -o root -g root -m 0600 "$defaults" "$backup/grub-defaults"
[[ ! -f /boot/grub2/grub.cfg ]] || install -o root -g root -m 0600 /boot/grub2/grub.cfg "$backup/grub.cfg"

stage="$(mktemp -d /boot/grub2/themes/.grub-theme.XXXXXX)"
trap '[[ -z "${stage}" ]] || rm -rf -- "${stage}"' EXIT
install -d -o root -g root -m 0755 "$stage/icons"
install -o root -g root -m 0644 "$repo/theme.txt" "$repo/background-grub-signal-skeleton.png" "$stage/"
install -o root -g root -m 0644 "$repo/icons/fedora.png" "$repo/icons/windows.png" "$stage/icons/"
install -o root -g root -m 0644 "$repo"/menu_*.png "$stage/"

[[ ! -L $theme ]] || die "Refus de remplacer le lien symbolique : $theme"
[[ ! -e $theme ]] || mv -- "$theme" "$backup/theme"
mv -- "$stage" "$theme"
stage=''

sed -i -E \
    -e '/^[[:space:]]*GRUB_THEME=/d' \
    -e '/^[[:space:]]*GRUB_GFXMODE=/d' \
    -e 's/^[[:space:]]*GRUB_TERMINAL_OUTPUT=/#&/' \
    "$defaults"
printf '\nGRUB_GFXMODE=auto\nGRUB_THEME="%s/theme.txt"\n' "$theme" >> "$defaults"
chown root:root "$defaults"
chmod 0644 "$defaults"

if [[ -d /sys/firmware/efi ]]; then
    grub_cfg=/etc/grub2-efi.cfg
    printf '[INFO] UEFI détecté\n'
else
    grub_cfg=/etc/grub2.cfg
    printf '[INFO] BIOS détecté\n'
fi

grub2-mkconfig -o "$grub_cfg"
grub2-script-check /boot/grub2/grub.cfg

for path in \
    "$theme/theme.txt" \
    "$theme/background-grub-signal-skeleton.png" \
    "$theme/icons/fedora.png" \
    "$theme/icons/windows.png"; do
    [[ "$(stat -c '%U:%G:%a' "$path")" == root:root:644 ]] || die "Permissions incorrectes : $path"
done

for panel in "${panels[@]}"; do
    path="$theme/menu_${panel}.png"
    [[ "$(stat -c '%U:%G:%a' "$path")" == root:root:644 ]] || die "Permissions incorrectes : $path"
done

has_class() {
    local class=$1
    grep -Eq -- "--class(=|[[:space:]])${class}([[:space:]]|$)" /boot/grub2/grub.cfg 2>/dev/null \
        || grep -R -Eq -- "^grub_class[[:space:]]+${class}([[:space:]]|$)" \
            /boot/loader/entries /boot/efi/loader/entries 2>/dev/null
}

has_class fedora || warn 'Classe fedora absente : son icône pourrait ne pas apparaître'
has_class windows || warn 'Classe windows absente : son icône pourrait ne pas apparaître'

printf '[INFO] Thème installé. Sauvegarde : %s\n[INFO] Aucun redémarrage effectué.\n' "$backup"
