#!/usr/bin/env bash
# Switch an existing AngelOS installation to the 0Faust fork cleanly (without pc-kit).
set -euo pipefail

FORK_REPO="https://github.com/0Faust/AngelOS-Dotfiles.git"
FORK_DIR="${ANGELOS_FORK_DIR:-$HOME/AngelOS-Dotfiles}"

while (($#)); do
  case "$1" in
    -h|--help)
      echo "Использование: $0"
      echo "  Обновляет AngelOS до форка 0Faust с оригинальными оптимизациями AngelOS."
      exit 0
      ;;
    *)
      echo "Неизвестный параметр: $1" >&2
      exit 2
      ;;
  esac
  shift
done

[[ $EUID -ne 0 ]] || { echo 'Запустите от своего пользователя, не от root.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Сначала установите git.' >&2; exit 1; }

printf '\n==> Подготовка репозитория форка в %s...\n' "$FORK_DIR"
if [[ -d "$FORK_DIR/.git" ]]; then
  if [[ -n "$(git -C "$FORK_DIR" status --porcelain)" ]]; then
    echo "Найдены локальные изменения в $FORK_DIR — сохраняю в git stash..."
    git -C "$FORK_DIR" stash push -u -m "backup-before-0faust-fork-$(date +%Y%m%d-%H%M%S)" || true
  fi
  if git -C "$FORK_DIR" remote get-url fork >/dev/null 2>&1; then
    git -C "$FORK_DIR" remote set-url fork "$FORK_REPO"
  else
    git -C "$FORK_DIR" remote add fork "$FORK_REPO"
  fi
  git -C "$FORK_DIR" fetch fork main
  git -C "$FORK_DIR" checkout -B main fork/main
else
  if [[ -e "$FORK_DIR" || -L "$FORK_DIR" ]]; then
    BACKUP="${FORK_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Каталог $FORK_DIR уже существует (не git-репозиторий) — переношу в $BACKUP..."
    mv -- "$FORK_DIR" "$BACKUP"
  fi
  # --filter=blob:none: the whole history of commits, blobs fetched on demand — a repository whose
  # history weighs a gigabyte installs like a hundred-megabyte one. A server without filters falls
  # back to a full clone instead of failing.
  if ! git clone --filter=blob:none "$FORK_REPO" "$FORK_DIR" 2>/dev/null; then
    rm -rf -- "$FORK_DIR"
    git clone "$FORK_REPO" "$FORK_DIR"
  fi
fi

chmod +x "$FORK_DIR/install.sh" "$FORK_DIR/install-fork.sh" 2>/dev/null || true

# Старый pc-kit больше не нужен: сторож сам накатывал бы патчи обратно, а game-detect ломал
# определение игр (Dota 2 в Steam Linux Runtime). Откатываем патчи; саму папку удалим после
# успешной установки (если она упадёт — папка останется, чтобы тема не пропала).
KIT_DIR="${PC_KIT_DIR:-$HOME/pc-kit}"
if [[ -e "$HOME/.config/systemd/user/kit-update.path" || -L "$HOME/.local/bin/kit" || -d "$KIT_DIR/files/patches" ]]; then
  printf '\n==> Найден старый pc-kit: отключаю сторож и откатываю его патчи (папка %s удалится после установки)...\n' "$KIT_DIR"
  systemctl --user disable --now kit-update.path kit-update.service >/dev/null 2>&1 || true
  rm -f "$HOME/.config/systemd/user/kit-update.path" "$HOME/.config/systemd/user/kit-update.service"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  if [[ -L "$HOME/.local/bin/kit" ]]; then rm -f "$HOME/.local/bin/kit"; fi
  for p in "$KIT_DIR"/files/patches/*/apply.py; do
    [[ -f "$p" ]] || continue
    echo "  откат: $(basename "$(dirname "$p")")"
    python3 "$p" revert >/dev/null 2>&1 || true
  done
fi

printf '\n==> Установка файлов форка поверх текущего AngelOS...\n'
ANGELOS_SELF_UPDATE=0 bash "$FORK_DIR/install.sh"

# оригинальный niri-game-mode AngelOS (без патчей pc-kit) и его сервис
if [[ -f "$FORK_DIR/.local/bin/niri-game-mode" ]]; then
  mkdir -p "$HOME/.local/bin"
  install -m 755 "$FORK_DIR/.local/bin/niri-game-mode" "$HOME/.local/bin/niri-game-mode"
  rm -f "$HOME/.local/bin/niri-game-mode.angelos-orig" "$HOME"/.local/bin/niri-game-mode.bak.*
  systemctl --user restart niri-game-mode.service >/dev/null 2>&1 || true
fi

# Тема Serpantinum теперь в самих файлах форка — накатывать её нечем и не нужно.
# pc-kit больше не нужен: удаляем его целиком (папка — git-клон, восстановима) и
# добиваем файлы, которые были только у него.
if [[ -d "$KIT_DIR/files/patches" || -f "$KIT_DIR/files/serp-skin/apply.py" ]]; then
  printf '\n==> Удаляю старый pc-kit...\n'
  rm -rf -- "$KIT_DIR"
fi
for f in services/SerpKit.qml modules/serp/panels/SerpKitPanel.qml \
         modules/serp/panels/SerpKitTree.qml modules/serp/settings/PageKit.qml; do
  rm -f -- "$HOME/.config/quickshell/angelos/$f"
done

if [[ -x "$HOME/.config/quickshell/angelos/bin/angelos" ]] && pgrep -x qs >/dev/null 2>&1; then
  printf '\n==> Перезапуск оболочки angelOS...\n'
  "$HOME/.config/quickshell/angelos/bin/angelos" restart || true
fi

printf '\nГотово! Форк 0Faust установлен поверх AngelOS.\n'
