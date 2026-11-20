#!/usr/bin/env bash
# angelOS: подтянуть правки MixaDoDs (upstream) в форк — одной командой.
#
#   fork-sync-upstream.sh                 подтянуть и запушить в форк
#   fork-sync-upstream.sh --dry-run       только показать, что нового (ничего не меняется)
#   fork-sync-upstream.sh --no-push       подтянуть, но оставить только локально
#   fork-sync-upstream.sh --marker        показать, от какого коммита апстрима считаем
#   fork-sync-upstream.sh --set-marker    забыть про всё, что было до текущего tip апстрима
#
# The "upstream" remote in the fork is a record only: its fetch refspec names a branch that does
# not exist, so a stray "git fetch upstream" stops at once instead of pulling upstream's ~1 GB of
# history. Fetching is this script's job, and it never touches the fork's own repository: upstream
# lives in a separate blobless copy (~/.local/share/angelos/upstream-dotfiles), where its commits
# are turned into patches — only the files those commits touch are downloaded.
#
# Why not "git merge upstream/main": after the history cleanup the fork and upstream share no
# commits at all (every hash differs), so a merge would be one huge conflict over the whole tree.
# Instead the commits upstream made since the last sync are applied one by one ("git am") on top of
# the fork's main, and the last upstream commit taken is remembered in .git/angelos-upstream-synced.
#
# The panel (Settings → Updates) is untouched: it compares main with origin/main (the fork), and
# the script pushes by default, so after it the panel says "you are up to date" instead of
# "the branch has commits of its own".
set -Eeuo pipefail
export GIT_TERMINAL_PROMPT=0        # never wait for a login prompt in a shell-driven run

UPSTREAM_NAME="${ANGELOS_UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${ANGELOS_UPSTREAM_URL:-https://github.com/MixaDoDs/AngelOS-Dotfiles.git}"
FORK_URL="${ANGELOS_FORK_URL:-https://github.com/0Faust/AngelOS-Dotfiles.git}"
HELPER="${ANGELOS_UPSTREAM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/angelos/upstream-dotfiles}"
MARKER_NAME="angelos-upstream-synced"
DRY=0
PUSH=1

say() { printf '» %s\n' "$*"; }
die() { printf '✕ %s\n' "$*" >&2; exit "${2:-1}"; }
norm() { local u="${1%.git}"; printf '%s' "${u%/}"; }

REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "${ANGELOS_REPO:-$HOME/AngelOS-Dotfiles}")"
[[ -d "$REPO/.git" ]] || die "$REPO — не репозиторий dotfiles" 2
MARKER="$(git -C "$REPO" rev-parse --git-path "$MARKER_NAME")"
[[ "$MARKER" == /* ]] || MARKER="$REPO/$MARKER"

# the helper copy of upstream: bare and blobless (commits and trees), files fetched on demand
ensure_helper() {
  if [[ ! -d "$HELPER" ]]; then
    mkdir -p "$(dirname "$HELPER")"
    git clone -q --bare --filter=blob:none --no-tags "$UPSTREAM_URL" "$HELPER" \
      || die "не удалось скачать $UPSTREAM_URL (сеть?)" 6
    return 0
  fi
  git -C "$HELPER" remote set-url origin "$UPSTREAM_URL" 2>/dev/null \
    || git -C "$HELPER" remote add origin "$UPSTREAM_URL"
  git -C "$HELPER" fetch -q --prune --no-tags --filter=blob:none origin \
      '+refs/heads/main:refs/heads/main' \
    || die "не удалось обновить копию апстрима в $HELPER (сеть?)" 6
}
upstream_tip() { git -C "$HELPER" rev-parse refs/heads/main; }
upstream_log() { git -C "$HELPER" log -1 --format='%h %s' "$1" 2>/dev/null | cut -c1-110; }

while (($#)); do
  case "$1" in
    -h|--help) awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
    --dry-run) DRY=1 ;;
    --no-push) PUSH=0 ;;
    --marker)
      [[ -f "$MARKER" ]] || die "точки отсчёта ещё нет — запустите без параметров" 2
      cat "$MARKER"
      exit 0 ;;
    --set-marker)
      ensure_helper
      printf '%s\n' "$(upstream_tip)" >"$MARKER"
      say "точка отсчёта передвинута на текущий tip апстрима: $(upstream_log "$(upstream_tip)")"
      exit 0 ;;
    *) die "неизвестный параметр: $1 (--help)" 2 ;;
  esac
  shift
done

# the fork's own record of upstream: a URL to look at, with a refspec that matches no branch, so a
# plain "git fetch upstream" fails instead of downloading a gigabyte of history
if [[ "$(git -C "$REPO" remote get-url "$UPSTREAM_NAME" 2>/dev/null || true)" != "$UPSTREAM_URL" ]]; then
  if git -C "$REPO" remote get-url "$UPSTREAM_NAME" >/dev/null 2>&1; then
    git -C "$REPO" remote set-url "$UPSTREAM_NAME" "$UPSTREAM_URL"
  else
    git -C "$REPO" remote add "$UPSTREAM_NAME" "$UPSTREAM_URL"
  fi
fi
git -C "$REPO" config "remote.$UPSTREAM_NAME.fetch" \
  "+refs/heads/angelos-upstream-is-reference-only:refs/remotes/$UPSTREAM_NAME/none"
git -C "$REPO" config "remote.$UPSTREAM_NAME.tagOpt" --no-tags

if ((PUSH)); then
  ORIGIN="$(git -C "$REPO" remote get-url origin 2>/dev/null || true)"
  [[ -n "$ORIGIN" ]] || die "в $REPO нет remote origin — некуда пушить" 2
  [[ "$(norm "$ORIGIN")" == "$(norm "$FORK_URL")" ]] \
    || die "origin = $ORIGIN, а не форк ($FORK_URL): не пушу. С --no-push переносить можно" 8
fi

say "смотрю апстрим…"
ensure_helper
NEW="$(upstream_tip)"

if [[ ! -f "$MARKER" ]]; then
  printf '%s\n' "$NEW" >"$MARKER"
  say "точка отсчёта задана: $(upstream_log "$NEW")"
  say "всё, что апстрим сделает после неё, подтянется следующим запуском"
  exit 0
fi
MARK="$(cat "$MARKER")"

if ! git -C "$HELPER" cat-file -e "$MARK^{commit}" 2>/dev/null \
   || ! git -C "$HELPER" merge-base --is-ancestor "$MARK" "$NEW" 2>/dev/null; then
  printf '%s\n' "$NEW" >"$MARKER"
  say "апстрим переписал историю (прежний ориентир исчез) — точка отсчёта сдвинута на текущий tip"
  say "ничего не переносил: сравнить не с чем"
  exit 0
fi

LIST="$(git -C "$HELPER" rev-list --reverse --no-merges "$MARK..$NEW")" \
  || die "не удалось перечислить коммиты апстрима" 6
if [[ -z "$LIST" ]]; then
  printf '%s\n' "$NEW" >"$MARKER"
  say "у апстрима ничего нового с $(upstream_log "$MARK")"
  exit 0
fi
mapfile -t PICKS <<<"$LIST"

say "новых правок: ${#PICKS[@]}"
for c in "${PICKS[@]}"; do
  printf '   %s\n' "$(upstream_log "$c")"
done

if ((DRY)); then
  say "это --dry-run: ничего не менял"
  exit 0
fi

BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == main ]] || die "вы на ветке $BRANCH: переключитесь на main" 3
[[ -z "$(git -C "$REPO" status --porcelain)" ]] \
  || die "в рабочей папке есть незакоммиченные изменения: сначала закоммитьте или уберите их" 3

TMP="$(mktemp -d /tmp/angelos-sync.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# the commits as patches: their files are read from the helper, which downloads just those
git -C "$HELPER" format-patch -q --no-signature --binary --stdout "$MARK..$NEW" >"$TMP/patches.mbox" \
  || die "не удалось собрать патчи из копии апстрима" 6

BEFORE="$(git -C "$REPO" rev-parse HEAD)"
if ! git -C "$REPO" am -3 -q "$TMP/patches.mbox" >"$TMP/am.log" 2>&1; then
  git -C "$REPO" am --abort 2>/dev/null || true
  git -C "$REPO" reset -q --hard "$BEFORE"
  sed -n 's/^error: //p' "$TMP/am.log" | head -5 | sed 's/^/      /'
  die "правка меняет файлы, которые в форке переписаны: её надо перенести вручную. Репозиторий возвращён как был ($(git -C "$REPO" log --oneline -1 "$BEFORE"))" 4
fi
say "перенесено: $(git -C "$REPO" rev-list --count "$BEFORE"..HEAD)"

# the repo's own check: a fork that installs itself must still parse
CHECK="$REPO/.config/quickshell/angelos/scripts/qml-check.sh"
if [[ -f "$CHECK" ]]; then
  if bash "$CHECK" >"$TMP/check.log" 2>&1; then
    say "qml-check: $(tail -1 "$TMP/check.log" | sed 's/^qml-check: //')"
  else
    tail -5 "$TMP/check.log" | sed 's/^/      /'
    die "qml-check не прошёл — не пушу. Откатить: git -C $REPO reset --hard $BEFORE" 5
  fi
fi

if ((PUSH)); then
  git -C "$REPO" push -q origin main \
    || die "не удалось запушить: коммиты остались локально (откат: git -C $REPO reset --hard $BEFORE)" 7
  say "запушено в форк — в Настройках → Обновления снова «последняя версия»"
else
  say "не пушу (--no-push): коммиты только локально, панель будет считать их «своими»"
fi

printf '%s\n' "$NEW" >"$MARKER"
say "ок; следующая точка отсчёта: $(upstream_log "$NEW")"
