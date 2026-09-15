#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
defaults=/etc/default/grub
panels=(nw n ne w c e sw s se)

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
warn() { printf '[WARN] %s\n' "$*" >&2; }

check_only=false
if [[ ${1:-} == --check ]]; then
    check_only=true
    shift
fi
[[ $# -le 1 ]] || die 'Usage : bash ./install.sh [--check] [skeleton|void-terminal]'
variant=${1:-skeleton}
case "$variant" in
    skeleton)
        source_dir=$repo
        theme=/boot/grub2/themes/grub-theme
        background=background-grub-signal-skeleton.png
        sprites=()
        for panel in "${panels[@]}"; do
            sprites+=("menu_${panel}.png" "select_${panel}.png")
        done
        ;;
    void-terminal)
        source_dir="$repo/themes/void-terminal"
        theme=/boot/grub2/themes/void-terminal
        background=background.png
        sprites=(select_w.png select_c.png select_e.png)
        ;;
    *) die "Thème inconnu : $variant (skeleton ou void-terminal)" ;;
esac
assets=(theme.txt "$background" "${sprites[@]}")

command -v file >/dev/null || die 'file absent : installe le paquet file'

for asset in "${assets[@]}"; do
    path="$source_dir/$asset"
    [[ -f $path && ! -L $path ]] || die "Fichier manquant ou lien symbolique : $path"
    if [[ $asset == *.png ]]; then
        [[ "$(file -b --mime-type "$path")" == image/png ]] || die "PNG invalide : $path"
    fi
done

for path in "$repo/icons/fedora.png" "$repo/icons/windows.png"; do
    [[ -f $path && ! -L $path ]] || die "Fichier manquant ou lien symbolique : $path"
    [[ "$(file -b --mime-type "$path")" == image/png ]] || die "PNG invalide : $path"
done

extra="$(find "$repo/icons" -maxdepth 1 -type f ! -name fedora.png ! -name windows.png -print -quit)"
[[ -z $extra ]] || die "Icône supplémentaire trouvée : $extra"

grep -Fxq "desktop-image: \"$background\"" "$source_dir/theme.txt" \
    || die 'theme.txt ne référence pas le fond attendu'
if "$check_only"; then
    printf '[INFO] Fichiers vérifiés : %s (aucune installation effectuée).\n' "$variant"
    exit 0
fi

[[ $EUID -eq 0 ]] || die 'Lance avec : sudo bash ./install.sh [skeleton|void-terminal]'
command -v grub2-mkconfig >/dev/null || die 'grub2-mkconfig absent : installe grub2-tools'
command -v grub2-script-check >/dev/null || die 'grub2-script-check absent : installe grub2-tools'
[[ -f $defaults ]] || die "$defaults introuvable"
install -d -o root -g root -m 0755 /var/backups
backup="$(mktemp -d /var/backups/grub-theme-$(date +%Y%m%d-%H%M%S)-XXXXXX)"

install -d -o root -g root -m 0755 /boot/grub2/themes "$backup"
install -o root -g root -m 0600 "$defaults" "$backup/grub-defaults"
[[ ! -f /boot/grub2/grub.cfg ]] || install -o root -g root -m 0600 /boot/grub2/grub.cfg "$backup/grub.cfg"

stage="$(mktemp -d /boot/grub2/themes/.grub-theme.XXXXXX)"
trap '[[ -z "${stage}" ]] || rm -rf -- "${stage}"' EXIT
install -d -o root -g root -m 0755 "$stage/icons"
for asset in "${assets[@]}"; do
    install -o root -g root -m 0644 "$source_dir/$asset" "$stage/"
done
install -o root -g root -m 0644 "$repo/icons/fedora.png" "$repo/icons/windows.png" "$stage/icons/"

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

for asset in "${assets[@]}" icons/fedora.png icons/windows.png; do
    path="$theme/$asset"
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
