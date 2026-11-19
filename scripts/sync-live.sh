#!/usr/bin/env bash
# Safely sync changed files from the fork repo to the live Quickshell tree
# without overwriting files containing live kit/serp-skin/celestia/vm-patch hunks.
set -euo pipefail

REPO="/home/faust/AngelOS-Dotfiles/.config/quickshell/angelos"
LIVE="/home/faust/.config/quickshell/angelos"
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    shift
fi

PROTECTED=(
    "shell.qml"
    "services/Sounds.qml"
    "modules/background/Background.qml"
)

is_protected() {
    local rel="$1"
    for p in "${PROTECTED[@]}"; do
        [ "$rel" = "$p" ] && return 0
    done
    if [ -f "$LIVE/$rel" ] && grep -qE "serp-skin|celestia|vm-patch" "$LIVE/$rel" 2>/dev/null; then
        return 0
    fi
    return 1
}

copied=0
skipped=0
while IFS= read -r -d '' src; do
    rel="${src#"$REPO/"}"
    dst="$LIVE/$rel"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        continue
    fi
    if is_protected "$rel"; then
        echo "SKIP (live patch/protected): $rel"
        skipped=$((skipped + 1))
        continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "WOULD COPY: $rel"
    else
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
        echo "COPIED: $rel"
    fi
    copied=$((copied + 1))
done < <(find "$REPO" -type f -not -path '*/__pycache__/*' -not -name '*.pyc' -print0)

echo "sync-live: $copied synced, $skipped skipped (protected/live-patched)"
