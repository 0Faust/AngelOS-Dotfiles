pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Quick Look (macOS's Space): a look at a file without opening it (modules/quicklook).
// Nautilus asks for it itself — Space on a file calls org.gnome.NautilusPreviewer, the name
// GNOME's sushi would hold; scripts/quicklook.py holds it while angelOS runs and passes the
// file here. Arrows go back to Nautilus, which moves its selection and asks again.
// Also: `angelos quicklook <file>`, Space on a file in the launcher's search.
Singleton {
    id: root

    property bool open: false
    property string path: ""
    property var info: null                 // scripts/quicklook.py info
    property string strip: ""               // a video's frames in a row (quicklook.py strip): the trimming strip
    property bool loading: false
    property bool fromNautilus: false
    property bool nameOurs: false           // Nautilus's previewer name is ours (else sushi's)

    readonly property bool wanted: Config.quicklook.enabled && Quickshell.env("ANGELOS_TEST") !== "1" && (!Shell.dev || Quickshell.env("ANGELOS_QUICKLOOK") === "1")
    readonly property string script: Quickshell.shellPath("scripts/quicklook.py")
    // The daemon only holds Nautilus's previewer name (org.gnome.NautilusPreviewer):
    // with no Nautilus window nobody can ask it for a preview, so it is not started
    // and the 32 MB python process stays unspent (still running for two minutes
    // after the last Nautilus window: the previewer is asked again on every arrow).
    readonly property bool fileManagerHere: (Niri.windows || []).some(w => /nautilus/i.test(String(w.app_id || "")))
    onFileManagerHereChanged: if (fileManagerHere)
        nautilusKeep.restart()
    Timer {
        id: nautilusKeep
        interval: 120000
    }
    readonly property bool daemonNeeded: wanted && (fileManagerHere || nautilusKeep.running)

    function show(p, nautilus) {
        if (!p)
            return;
        fromNautilus = !!nautilus;
        Achievements.note("explore", "quicklook");
        path = p;
        info = null;
        strip = "";
        stripper.running = false;
        loading = true;
        reader.command = ["python3", script, "info", p];
        reader.running = true;
        if (!open) {
            open = true;
            tell({
                "cmd": "visible",
                "v": true
            });
        }
    }
    function close() {
        if (!open)
            return;
        open = false;
        reader.running = false;
        tell({
            "cmd": "visible",
            "v": false
        });
    }
    // the arrows: Nautilus moves on and calls ShowFile again
    function step(dir) {
        if (fromNautilus)
            tell({
                "cmd": "select",
                "dir": dir
            });
    }
    function openIt() {
        Quickshell.execDetached(["xdg-open", path]);
        close();
    }
    function tell(obj) {
        if (daemon.running)
            daemon.write(JSON.stringify(obj) + "\n");
    }
    function size(n) {
        if (n === undefined || n < 0)
            return "";
        if (n < 1024)
            return n + " " + I18n.t("Б", "B");
        const u = I18n.t(["КБ", "МБ", "ГБ", "ТБ"], ["KB", "MB", "GB", "TB"]);
        let i = -1;
        do {
            n /= 1024;
            i++;
        } while (n >= 1024 && i < 3)
        return (n < 10 ? n.toFixed(1) : Math.round(n)) + " " + u[i];
    }
    function duration(s) {
        s = Math.round(s || 0);
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60;
        return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(sec).padStart(2, "0");
    }

    Process {
        id: daemon
        running: root.daemonNeeded
        stdinEnabled: true
        command: ["python3", root.script, "serve"]
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try {
                    ev = JSON.parse(line);
                } catch (e) {
                    return;
                }
                if (ev.ev === "ready")
                    root.nameOurs = true;
                else if (ev.ev === "taken")
                    root.nameOurs = false;
                else if (ev.ev === "close")
                    root.close();
                else if (ev.ev === "show") {
                    if (ev.toggle && root.open && ev.path === root.path)
                        root.close();
                    else
                        root.show(ev.path, true);
                }
            }
        }
        onExited: root.nameOurs = false
    }
    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const j = JSON.parse(text);
                    if (j.path === root.path || !j.path)
                        root.info = j;
                    if (j.kind === "video" && j.path === root.path) {
                        stripper.command = ["python3", root.script, "strip", j.path];
                        stripper.running = true;
                    }
                } catch (e) {
                    root.info = {
                        "error": "info"
                    };
                }
            }
        }
        onExited: root.loading = false
    }
    Process {
        id: stripper
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    if (j.path === root.path && j.strip)
                        root.strip = j.strip;
                } catch (e) {}
            }
        }
    }
}
