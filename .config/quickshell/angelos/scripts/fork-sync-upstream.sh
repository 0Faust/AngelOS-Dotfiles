#!/usr/bin/env bash
# angelOS: подтянуть правки MixaDoDs (upstream) в форк — одной командой.
#
#   fork-sync-upstream.sh                 подтянуть и запушить в форк
#   fork-sync-upstream.sh --dry-run       только показать, что нового (ничего не меняется)
#   fork-sync-upstream.sh --no-push       подтянуть, но оставить только локально
#   fork-sync-upstream.sh --marker        показать, от какого коммита апстрима считаем
#   fork-sync-upstream.sh --set-marker    забыть про всё, что было до текущего tip апстрима
#
# Why not "git merge upstream/main": after the history cleanup the fork and upstream share no
# commits at all (every hash differs), so a merge would be one huge conflict over the whole tree.
# Instead the commits upstream made since the last sync are applied one by one ("git cherry-pick")
# on top of the fork's main, and the last upstream commit taken is remembered in
# .git/angelos-upstream-synced. Upstream is fetched with --filter=blob:none: commits and trees
# only, the files of a commit are downloaded when that commit is applied — so the fork's own
# repository stays as small as it is now.
#
# The panel (Settings → Updates) is untouched: it compares main with origin/main (the fork), and
# the script pushes by default, so after it the panel says "you are up to date" instead of
# "the branch has commits of its own".
set -Eeuo pipefail

UPSTREAM_URL="https://github.com/MixaDoDs/AngelOS-Dotfiles.git"
MARKER_NAME="angelos-upstream-synced"
DRY=0
PUSH=1

say() { printf '» %s\n' "$*"; }
die() { printf '✕ %s\n' "$*" >&2; exit "${2:-1}"; }

while (($#)); do
  case "$1" in
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dry-run) DRY=1 ;;
    --no-push) PUSH=0 ;;
    --marker)
      REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/AngelOS-Dotfiles")"
      m="$(git -C "$REPO" rev-parse --git-path "$MARKER_NAME")"
      [[ -f "$m" ]] || die "точки отсчёта ещё нет — запустите без параметров" 2
      printf '%s\n' "$(cat "$m")"
      exit 0 ;;
    --set-marker)
      REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/AngelOS-Dotfiles")"
      git -C "$REPO" fetch -q --no-tags --filter=blob:none upstream main 2>/dev/null || true
      git -C "$REPO" rev-parse upstream/main >"$(git -C "$REPO" rev-parse --git-path "$MARKER_NAME")"
      say "точка отсчёта передвинута на текущий tip апстрима: $(git -C "$REPO" log --oneline -1 upstream/main)"
      exit 0 ;;
    *) die "неизвестный параметр: $1 (--help)" 2 ;;
  esac
  shift
done

REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo "${ANGELOS_REPO:-$HOME/AngelOS-Dotfiles}")"
[[ -d "$REPO/.git" ]] || die "$REPO — не репозиторий" 2
cd "$REPO"

# upstream: the maintainer's repository, fetched light (trees only, files on demand)
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$UPSTREAM_URL"
else
  git remote add upstream "$UPSTREAM_URL"
fi
git config remote.upstream.promisor true
git config remote.upstream.partialclonefilter blob:none
git config remote.upstream.tagOpt --no-tags

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == main ]] || die "вы на ветке $BRANCH: переключитесь на main" 3
[[ -z "$(git status --porcelain)" ]] || die "в рабочей папке есть незакоммиченные изменения: сначала закоммитьте или уберите их" 3

say "смотрю апстрим…"
git fetch -q --no-tags --filter=blob:none upstream main:refs/remotes/upstream/main \
  || die "не удалось получить $UPSTREAM_URL (сеть?)" 6
NEW="$(git rev-parse upstream/main)"
MARKER="$(git rev-parse --git-path "$MARKER_NAME")"

if [[ ! -f "$MARKER" ]]; then
  printf '%s\n' "$NEW" >"$MARKER"
  say "точка отсчёта задана: $(git log --oneline -1 "$NEW")"
  say "всё, что апстрим сделает после неё, подтянется следующим запуском"
  exit 0
fi
MARK="$(cat "$MARKER")"

if ! git cat-file -e "$MARK^{commit}" 2>/dev/null || ! git merge-base --is-ancestor "$MARK" "$NEW" 2>/dev/null; then
  printf '%s\n' "$NEW" >"$MARKER"
  say "апстрим переписал историю (прежний ориентир исчез) — точка отсчёта сдвинута на текущий tip"
  say "ничего не переносил: сравнить не с чем"
  exit 0
fi

mapfile -t PICKS < <(git rev-list --reverse --no-merges "$MARK..$NEW")
if ((${#PICKS[@]} == 0)); then
  printf '%s\n' "$NEW" >"$MARKER"
  say "у апстрима ничего нового с $(git log --oneline -1 "$MARK")"
  exit 0
fi

say "новых правок: ${#PICKS[@]}"
for c in "${PICKS[@]}"; do
  printf '   %s %s\n' "$(git log -1 --format=%h "$c")" "$(git log -1 --format=%s "$c" | cut -c1-72)"
done

if ((DRY)); then
  say "это --dry-run: ничего не менял"
  exit 0
fi

BEFORE="$(git rev-parse HEAD)"
for c in "${PICKS[@]}"; do
  if ! git cherry-pick -x "$c" >/tmp/angelos-sync.log 2>&1; then
    git cherry-pick --abort 2>/dev/null || true
    git reset -q --hard "$BEFORE"
    printf '✕ не удалось перенести: %s\n' "$(git log -1 --format='%h %s' "$c")"
    sed -n 's/^error: //p' /tmp/angelos-sync.log | head -5 | sed 's/^/      /'
    die "правка меняет файлы, которые в форке переписаны: нужно переносить вручную. Репозиторий возвращён как был ($(git log --oneline -1 "$BEFORE"))" 4
  fi
done

say "перенесено: ${#PICKS[@]}"

# the repo's own check: a fork that installs itself must still parse
CHECK="$REPO/.config/quickshell/angelos/scripts/qml-check.sh"
if [[ -x "$CHECK" ]]; then
  if bash "$CHECK" >/tmp/angelos-sync-check.log 2>&1; then
    say "qml-check: $(tail -1 /tmp/angelos-sync-check.log)"
  else
    tail -5 /tmp/angelos-sync-check.log | sed 's/^/      /'
    die "qml-check не прошёл — не пушу. Откатить: git reset --hard $BEFORE" 5
  fi
fi

if ((PUSH)); then
  git push -q origin main || die "не удалось запушить: коммиты остались локально ($(git log --oneline -1 "$BEFORE")…$(git log --oneline -1))" 7
  say "запушено в форк — в Настройках → Обновления снова «последняя версия»"
else
  say "не пушу (--no-push): коммиты только локально"
fi

printf '%s\n' "$NEW" >"$MARKER"
say "ок; следующая точка отсчёта: $(git log --oneline -1 "$NEW")"
