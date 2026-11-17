#!/usr/bin/env bash
# Switch an existing AngelOS installation to the 0Faust fork without failing on
# pre-existing ~/AngelOS-Dotfiles or ~/pc-kit directories.
set -euo pipefail

FORK_REPO="https://github.com/0Faust/AngelOS-Dotfiles.git"
FORK_DIR="${ANGELOS_FORK_DIR:-$HOME/AngelOS-Dotfiles}"
KIT_DIR="${PC_KIT_DIR:-$HOME/pc-kit}"
KIT_MODE="auto"   # auto | with | skip

while (($#)); do
  case "$1" in
    --with-kit) KIT_MODE="with" ;;
    --skip-kit) KIT_MODE="skip" ;;
    -h|--help)
      echo "Использование: $0 [--with-kit|--skip-kit]"
      echo "  --with-kit  установить pc-kit даже при наличии каталога (в новый PC_KIT_DIR или после бэкапа)"
      echo "  --skip-kit  обновить только AngelOS из форка, не трогая pc-kit"
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
  git clone "$FORK_REPO" "$FORK_DIR"
fi

chmod +x "$FORK_DIR/install.sh" "$FORK_DIR/install-with-pc-kit.sh" "$FORK_DIR/install-fork.sh" 2>/dev/null || true

printf '\n==> Установка файлов форка поверх текущего AngelOS...\n'
ANGELOS_SELF_UPDATE=0 bash "$FORK_DIR/install.sh"

install_kit=0
case "$KIT_MODE" in
  with) install_kit=1 ;;
  skip) install_kit=0 ;;
  auto)
    if [[ ! -e "$KIT_DIR" && ! -L "$KIT_DIR" ]]; then
      install_kit=1
    else
      printf '\nКаталог %s уже существует — пропускаю повторную установку pc-kit (для переустановки: %s --with-kit).\n' "$KIT_DIR" "$0"
    fi
    ;;
esac

if ((install_kit)); then
  if [[ -e "$KIT_DIR" || -L "$KIT_DIR" ]]; then
    KIT_BACKUP="${KIT_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Переношу прежний $KIT_DIR в $KIT_BACKUP..."
    mv -- "$KIT_DIR" "$KIT_BACKUP"
  fi
  PC_KIT_DIR="$KIT_DIR" bash "$FORK_DIR/install-with-pc-kit.sh" --kit-only
fi

if [[ -x "$HOME/.config/quickshell/angelos/bin/angelos" ]] && pgrep -x qs >/dev/null 2>&1; then
  printf '\n==> Перезапуск оболочки angelOS...\n'
  "$HOME/.config/quickshell/angelos/bin/angelos" restart || true
fi

printf '\nГотово! Форк 0Faust установлен поверх AngelOS.\n'
