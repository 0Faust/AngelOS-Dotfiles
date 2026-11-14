#!/usr/bin/env bash
# Install this fork and the selected pc-kit features for the current user.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KIT_DIR="${PC_KIT_DIR:-$HOME/pc-kit}"
KIT_REPO=https://github.com/Frostpix11/pc-kit-share.git
KIT_REV=59edb7b

[[ $EUID -ne 0 ]] || { echo 'Запустите от своего пользователя, не от root.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Сначала установите git.' >&2; exit 1; }
[[ ! -e "$KIT_DIR" && ! -L "$KIT_DIR" ]] || {
  echo "Каталог $KIT_DIR уже существует. Чтобы не перезаписать ваши изменения, выберите новый путь через PC_KIT_DIR." >&2
  exit 1
}
[[ "${1:-}" == "" || "${1:-}" == --kit-only ]] && [[ $# -le 1 ]] || { echo 'Использование: ./install-with-pc-kit.sh [--kit-only]' >&2; exit 2; }
mkdir -p "$(dirname "$KIT_DIR")"
STAGE=$(mktemp -d "$(dirname "$KIT_DIR")/.pc-kit-install.XXXXXX")
trap 'rm -rf -- "$STAGE"' EXIT
printf '\nЗагрузка pc-kit (версия %s)...\n' "$KIT_REV"
git clone --no-checkout "$KIT_REPO" "$STAGE/repo"
git -C "$STAGE/repo" checkout --detach "$KIT_REV"
for patch in "$ROOT/patches/pc-kit/serp-customizations.patch" "$ROOT/patches/pc-kit/preserve-selected-wallpaper.patch" "$ROOT/patches/pc-kit/laptop-diagnostics.patch"; do
  git -C "$STAGE/repo" apply --check "$patch"
  git -C "$STAGE/repo" apply "$patch"
done
# Preserve the user's cursor selection: install the other Golden Gate features only.
python3 - "$STAGE/repo/install.sh" <<'PYCODE'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "  kit_patch mac-cursor mac-tint pixora-mac mac-settings-lights dock-spacing"
new = "  kit_patch mac-tint pixora-mac mac-settings-lights dock-spacing"
if s.count(old) != 1:
    raise SystemExit("Не удалось безопасно исключить смену курсора")
p.write_text(s.replace(old, new))
PYCODE
if [[ "${1:-}" != --kit-only ]]; then
  printf '\nУстановка AngelOS: следуйте вопросам установщика.\n'
  ANGELOS_SELF_UPDATE=0 bash "$ROOT/install.sh"
fi
[[ -d "$HOME/.config/quickshell/angelos" ]] || { echo 'AngelOS не найден. Сначала установите этот форк.' >&2; exit 1; }
mv "$STAGE/repo" "$KIT_DIR"
printf '\nУстановка выбранных компонентов pc-kit...\n'
# Plugins first: re-installing them after serp can overwrite its Celestia changes.
bash "$KIT_DIR/install.sh" plugins mac morph walls privacy fixes windows serp
# The upstream codex step skips both tools before first login, so install them directly.
sudo pacman -S --needed --noconfirm python-gobject gtk4 libadwaita gtksourceview5 librsvg
python3 -I "$KIT_DIR/files/codex-plugins/AngelOS-Typer/install.py" --no-default
python3 -I "$KIT_DIR/files/codex-plugins/AngelOS-Room/install.py"
# The upstream wrapper reports some failed patches as warnings; verify selected patches.
python3 - "$KIT_DIR" <<'PY'
import json, subprocess, sys
kit = sys.argv[1]
r = subprocess.run([sys.executable, kit + '/kit/kit.py', 'status', '--json'], capture_output=True, text=True)
try:
    states = {x['name']: x['state'] for x in json.loads(r.stdout)['patches']}
except (ValueError, KeyError) as exc:
    raise SystemExit('Не удалось проверить состояние pc-kit: ' + str(exc))
required = ['serp-skin', 'skin-morph', 'privacy-capture', 'stack-memory', 'dock-spacing', 'mac-tint', 'pixora-mac', 'mac-settings-lights']
failed = [name for name in required if states.get(name) != 'on']
if failed:
    raise SystemExit('Некоторые патчи не установлены: ' + ', '.join(failed) + '. Проверьте kit status.')
PY
printf '\nГотово. Войдите в сессию angelOS и включите Serpantinum в настройках внешнего вида.\n'
printf 'pc-kit: %s. Статус: kit status.\n' "$KIT_DIR"
