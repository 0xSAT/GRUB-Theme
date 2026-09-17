#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
defaults=/etc/default/grub

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
warn() { printf '[WARN] %s\n' "$*" >&2; }

check_only=false
gfxmode=auto
if [[ ${1:-} == --check ]]; then
    check_only=true
    shift
fi
[[ $# -le 1 ]] || die 'Usage : bash ./install.sh [--check] [skeleton|void-terminal|link-start]'
variant=${1:-skeleton}
case "$variant" in
    skeleton|link-start)
        gfxmode=1920x1080,1600x900,1280x720,auto
        ;;
    void-terminal)
        ;;
    *) die "Thème inconnu : $variant (skeleton, void-terminal ou link-start)" ;;
esac
source_dir="$repo/themes/$variant"
icons_dir="$source_dir/icons"
theme="/boot/grub2/themes/$variant"
background=background.png

command -v file >/dev/null || die 'file absent : installe le paquet file'

for path in \
    "$source_dir/theme.txt" \
    "$source_dir/$background" \
    "$icons_dir/fedora.png" \
    "$icons_dir/windows.png"; do
    [[ -f $path && ! -L $path ]] || die "Fichier manquant ou lien symbolique : $path"
done

link="$(find "$source_dir" -type l -print -quit)"
[[ -z $link ]] || die "Lien symbolique interdit : $link"

while IFS= read -r -d '' path; do
    [[ "$(file -b --mime-type "$path")" == image/png ]] || die "PNG invalide : $path"
done < <(find "$source_dir" -type f -name '*.png' -print0)

while IFS= read -r -d '' path; do
    [[ "$(od -An -tx1 -N12 "$path" | tr -d ' \n')" == 46494c450000000450464632 ]] \
        || die "Police PF2 invalide : $path"
done < <(find "$source_dir" -type f -name '*.pf2' -print0)

extra="$(find "$icons_dir" -maxdepth 1 -type f ! -name fedora.png ! -name windows.png -print -quit)"
[[ -z $extra ]] || die "Icône supplémentaire trouvée : $extra"

grep -Fxq "desktop-image: \"$background\"" "$source_dir/theme.txt" \
    || die 'theme.txt ne référence pas le fond attendu'
if "$check_only"; then
    printf '[INFO] Fichiers vérifiés : %s (aucune installation effectuée).\n' "$variant"
    exit 0
fi

[[ $EUID -eq 0 ]] || die 'Lance avec : sudo bash ./install.sh [skeleton|void-terminal|link-start]'
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
while IFS= read -r -d '' path; do
    relative=${path#"$source_dir/"}
    [[ $relative == archive/* ]] && continue
    install -D -o root -g root -m 0644 "$path" "$stage/$relative"
done < <(find "$source_dir" -type f -print0)

[[ ! -L $theme ]] || die "Refus de remplacer le lien symbolique : $theme"
[[ ! -e $theme ]] || mv -- "$theme" "$backup/theme"
mv -- "$stage" "$theme"
stage=''

sed -i -E \
    -e '/^[[:space:]]*GRUB_THEME=/d' \
    -e '/^[[:space:]]*GRUB_GFXMODE=/d' \
    -e '/^[[:space:]]*GRUB_TIMEOUT=/d' \
    -e 's/^[[:space:]]*GRUB_TERMINAL_OUTPUT=/#&/' \
    "$defaults"
printf '\nGRUB_GFXMODE=%s\nGRUB_THEME="%s/theme.txt"\nGRUB_TIMEOUT=15\n' \
    "$gfxmode" "$theme" >> "$defaults"
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

while IFS= read -r -d '' path; do
    [[ "$(stat -c '%U:%G:%a' "$path")" == root:root:644 ]] || die "Permissions incorrectes : $path"
done < <(find "$theme" -type f -print0)

has_class() {
    local class=$1
    grep -Eq -- "--class(=|[[:space:]])${class}([[:space:]]|$)" /boot/grub2/grub.cfg 2>/dev/null \
        || grep -R -Eq -- "^grub_class[[:space:]]+${class}([[:space:]]|$)" \
            /boot/loader/entries /boot/efi/loader/entries 2>/dev/null
}

has_class fedora || warn 'Classe fedora absente : son icône pourrait ne pas apparaître'
has_class windows || warn 'Classe windows absente : son icône pourrait ne pas apparaître'

printf '[INFO] Thème installé. Sauvegarde : %s\n[INFO] Aucun redémarrage effectué.\n' "$backup"
