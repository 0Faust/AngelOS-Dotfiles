#!/usr/bin/env bash
set -euo pipefail
DIR=${1:-$HOME/.config/quickshell/angelos}
[[ -f "$DIR/modules/serp/widgets/ClockWidget.qml" ]] || { echo "Serpantinum is not installed in $DIR" >&2; exit 77; }
T=$(mktemp -d /tmp/serp-scale.XXXXXX)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/root" "$T/home/.config/angelos" "$T/rt"; chmod 700 "$T/rt"
for f in "$DIR"/*; do [[ "${f##*/}" == shell.qml ]] || ln -s "$f" "$T/root/"; done
python3 - "$DIR/shell.qml" > "$T/root/shell.qml" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
s=re.sub(r'(?m)^    [A-Z][A-Za-z0-9]* \{\}(?:\s*//.*)?\s*$', '', s)
s=re.sub(r'(?m)^    LazyLoader \{\n(?:.*\n)*?    \}\n', '', s)
print(s[:s.rfind('}')]+'    SerpScaleProbe {}\n}')
PY
cat > "$T/root/SerpScaleProbe.qml" <<'QML'
import QtQuick
import Quickshell
import qs.config
Scope {
    id: root
    Timer {
        interval: 2000; running: true
        onTriggered: {
            let c = Qt.createComponent(Quickshell.shellDir + "/modules/serp/widgets/ClockWidget.qml");
            if (c.status !== Component.Ready) { console.log("PROBE FAIL " + c.errorString()); Qt.quit(); return; }
            let a = c.createObject(root, {"widget": {"scale": 1}, "size": "m", "awake": false});
            let b = c.createObject(root, {"widget": {"scale": 1.2}, "size": "m", "awake": false});
            if (!a || !b) { console.log("PROBE FAIL create"); Qt.quit(); return; }
            const ok = a.timePx > 0 && b.timePx > a.timePx && Math.abs(b.timePx / a.timePx - 1.2) < 0.06;
            console.log("PROBE " + (ok ? "PASS " : "FAIL ") + "clock native size=" + a.timePx + ", scaled=" + b.timePx);
            let gpuComponent = Qt.createComponent(Quickshell.shellDir + "/modules/serp/widgets/SysmonWidget.qml");
            if (gpuComponent.status !== Component.Ready) { console.log("PROBE FAIL sysmon " + gpuComponent.errorString()); Qt.quit(); return; }
            let gpu = gpuComponent.createObject(root, {"widget": {"scale": 1}, "size": "m", "awake": false});
            if (!gpu) { console.log("PROBE FAIL sysmon creation"); Qt.quit(); return; }
            gpu.hasIntelGpu = true; gpu.gpuCount = 2; Config.desktop.sysmonGpus = "auto";
            let autoOn = gpu.showIntelGpu && gpu.readings.some(r => r.id === "gpu2");
            Config.desktop.sysmonGpus = "off";
            let off = !gpu.showIntelGpu && !gpu.readings.some(r => r.id === "gpu2");
            gpu.gpuCount = 1; Config.desktop.sysmonGpus = "auto";
            let autoSingle = !gpu.showIntelGpu;
            Config.desktop.sysmonGpus = "on";
            let on = gpu.showIntelGpu;
            console.log("PROBE " + (autoOn && off && autoSingle && on ? "PASS " : "FAIL ") + "GPU auto/on/off");
            gpu.destroy(); a.destroy(); b.destroy(); Qt.quit();
        }
    }
}
QML
printf '%s\n' '{"setup":{"complete":true},"updates":{"autoCheck":false},"y2k":{"sounds":false,"helper":false,"boot":false}}' > "$T/home/.config/angelos/settings.json"
env -i PATH="$PATH" LANG=C.UTF-8 HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_RUNTIME_DIR="$T/rt" QT_QPA_PLATFORM=offscreen ANGELOS_DEV=1 ANGELOS_SCREENS=__none__ ANGELOS_TEST=1 QS_NO_RELOAD_POPUP=1 QS_DISABLE_CRASH_HANDLER=1 timeout 30 quickshell -p "$T/root" > "$T/log" 2>&1 || true
sed -n 's/^.*\(PROBE .*\)/\1/p' "$T/log"
[[ $(grep -c 'PROBE PASS' "$T/log") -eq 2 ]] && ! grep -q 'PROBE FAIL' "$T/log" || { tail -15 "$T/log"; exit 1; }
