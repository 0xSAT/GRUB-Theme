#!/usr/bin/env bash
# Read-only asset checks plus failures in a disposable fixture; never install.
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
bash -n "$repo/install.sh"
bash "$repo/install.sh" --check skeleton
bash "$repo/install.sh" --check void-terminal
bash "$repo/install.sh" --check link-start
bash "$repo/install.sh" --check
if bash "$repo/install.sh" --check ../invalid; then
    printf 'FAIL: unknown theme accepted\n' >&2
    exit 1
fi
fixture="$(mktemp -d)"
trap 'rm -f -- "$fixture/install.sh" "$fixture/theme.txt" "$fixture/background-grub-signal-hud.png"; rmdir -- "$fixture"' EXIT
cp -- "$repo/install.sh" "$fixture/install.sh"
if bash "$fixture/install.sh" --check skeleton; then
    printf 'FAIL: missing theme accepted\n' >&2
    exit 1
fi
printf 'desktop-image: "background-grub-signal-hud.png"\n' > "$fixture/theme.txt"
printf 'not a PNG\n' > "$fixture/background-grub-signal-hud.png"
if bash "$fixture/install.sh" --check skeleton; then
    printf 'FAIL: invalid PNG accepted\n' >&2
    exit 1
fi
printf 'PASS: all themes, default choice and invalid inputs\n'
