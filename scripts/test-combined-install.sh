#!/usr/bin/env bash
# Exercise installer orchestration without network, sudo, user files, or packages.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
T=$(mktemp -d /tmp/angelos-installer-test.XXXXXX)
trap 'rm -rf -- "$T"' EXIT
mkdir -p "$T/bin" "$T/home/.config/quickshell/angelos"
export HOME="$T/home" TEST_TRACE="$T/trace" PATH="$T/bin:$PATH" INSTALL_INTEL_GPU=0
cat > "$T/bin/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == clone ]]; then
  d=${@: -1}
  mkdir -p "$d/.git" "$d/kit" "$d/files/codex-plugins/AngelOS-Typer" "$d/files/codex-plugins/AngelOS-Room"
  cat > "$d/install.sh" <<'SCRIPT'
#!/usr/bin/env bash
if false; then
  kit_patch mac-cursor mac-tint pixora-mac mac-settings-lights dock-spacing
fi
printf 'kit-install\n' >> "$TEST_TRACE"
SCRIPT
  cat > "$d/kit/kit.py" <<'PY'
import json
names=['serp-skin','skin-morph','privacy-capture','stack-memory','dock-spacing','mac-tint','pixora-mac','mac-settings-lights']
print(json.dumps({'patches':[{'name':n,'state':'on'} for n in names]}))
PY
  printf 'print("typer")\n' > "$d/files/codex-plugins/AngelOS-Typer/install.py"
  printf 'print("room")\n' > "$d/files/codex-plugins/AngelOS-Room/install.py"
  exit 0
fi
if [[ "$1" == -C && "$3" == checkout ]]; then exit 0; fi
if [[ "$1" == -C && "$3" == apply ]]; then [[ ${TEST_FAIL_PATCH:-0} != 1 ]]; exit; fi
exit 1
SH
cat > "$T/bin/sudo" <<'SH'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$TEST_TRACE"
[[ ${TEST_FAIL_SUDO:-0} != 1 ]]
SH
chmod +x "$T/bin/git" "$T/bin/sudo"
if TEST_FAIL_PATCH=1 bash "$ROOT/install-with-pc-kit.sh" --kit-only >"$T/failure" 2>&1; then
  echo 'FAIL: a patch error was ignored' >&2; exit 1
fi
[[ ! -e "$HOME/pc-kit" && ! -e "$TEST_TRACE" ]] || { echo 'FAIL: patch failure changed installation'; exit 1; }
mkdir "$HOME/pc-kit"
printf keep > "$HOME/pc-kit/marker"
if bash "$ROOT/install-with-pc-kit.sh" --kit-only >"$T/existing" 2>&1; then
  echo 'FAIL: existing pc-kit was overwritten' >&2; exit 1
fi
[[ $(cat "$HOME/pc-kit/marker") == keep && ! -e "$TEST_TRACE" ]] || { echo 'FAIL: existing pc-kit changed'; exit 1; }
PC_KIT_DIR="$HOME/fresh-kit" bash "$ROOT/install-with-pc-kit.sh" --kit-only >"$T/success" 2>&1
[[ -f "$HOME/fresh-kit/kit/kit.py" ]] && grep -q '^kit-install$' "$TEST_TRACE" && grep -q 'Готово' "$T/success" || { echo 'FAIL: installation did not complete'; exit 1; }
rm -f "$TEST_TRACE"
if PC_KIT_DIR="$HOME/interrupted" TEST_FAIL_SUDO=1 bash "$ROOT/install-with-pc-kit.sh" --kit-only >"$T/interrupted" 2>&1; then
  echo 'FAIL: a package installation error was ignored' >&2; exit 1
fi
[[ -f "$HOME/interrupted/.git/angelos-combined-install" ]] || { echo 'FAIL: no resume marker'; exit 1; }
PC_KIT_DIR="$HOME/interrupted" bash "$ROOT/install-with-pc-kit.sh" --resume-kit >"$T/resumed" 2>&1
[[ ! -e "$HOME/interrupted/.git/angelos-combined-install" ]] && grep -q 'Готово' "$T/resumed" || { echo 'FAIL: resume did not complete'; exit 1; }
echo 'Combined installer: patch failure, existing checkout, fresh install, and resume passed.'
