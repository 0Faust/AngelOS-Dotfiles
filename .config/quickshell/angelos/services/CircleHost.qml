pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The screenshot overlay (services/CircleSearch, modules/circle) runs in a process of its own
// (scripts/circle-proc.sh): this shell's main thread is busy with the bar, the Halo, the
// wallpapers, and the pointer waited behind them while picking. This is the shell's end of it:
// the process kept running (started again when it goes), opened through here (the screenshot
// key, `angelos capture`, Settings), told how things are (stream, motion, hell, privacy) and
// handed back what only the shell does — saving (Capture), the island, Quick Share, Settings.
// JSON lines over $XDG_RUNTIME_DIR/angelos/circle.sock (the other end:
// modules/circle/proc/services/CircleLink). The process not there within 3 s of a screenshot:
// the classic selector, so the shot isn't lost.
Singleton {
    id: root

    property bool open: false
    property string screenName: ""
    property int learnedCount: 0
    property var client: null
    readonly property bool connected: client !== null
    // a start that waits for the process
    property var pending: null
    property int fails: 0
    property real helloAt: 0                 // when the running process said hello (ms, 0: not yet)

    readonly property bool test: Quickshell.env("ANGELOS_TEST") === "1"
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos"
    // the dev stand's shell has its own (as WorkspaceAnim's ctl-dev.sock)
    readonly property string socketPath: runtimeDir + (Shell.dev ? "/circle-dev.sock" : "/circle.sock")
    readonly property string rootDir: runtimeDir + (Shell.dev ? "/circle-root-dev" : "/circle-root")
    property bool socketReady: false
    // Started on the first screenshot and stopped after ten quiet minutes: the overlay's own
    // Quickshell is a whole second process (~87 MB) that a screenshot tool used now and then
    // should not hold all day. The hooks below start it before opening, so the first shot
    // after a quiet while pays the start (the 3 s fallback still guards a broken start).
    readonly property int idleStopMs: 10 * 60 * 1000
    property double lastUse: 0
    property bool stopping: false

    readonly property var shellState: ({
            "t": "state",
            "onAir": StreamMode.onAir,
            "active": StreamMode.active,
            "calm": Motion.calm,
            "still": Motion.still,
            "hell": Theme.hell,
            "privacy": Privacy.hiddenNow.length > 0
        })
    onShellStateChanged: send(shellState)

    // wait: seconds before the picture, so a menu that started it has gone from the screen
    function start(screen, wait) {
        ask("start", screen, wait);
    }
    // the key again while it is open closes it
    function toggle(screen) {
        ask("toggle", screen, 0);
    }
    function forget() {
        send({
            "t": "forget"
        });
    }

    function ask(kind, screen, wait) {
        const name = screen || Niri.focusedOutput || Shell.primaryName;
        const ws = Niri.activeWorkspace(name);
        const m = {
            "t": kind,
            "screen": name,
            "wait": wait || 0,
            "ws": ws,
            "windows": ws ? Niri.windowsOn(ws.id) : [],
            "focused": Niri.focusedWindowId,
            "land": ShotEdit.placeOn(name),
            "barEdge": BarLayout.edge
        };
        if (send(m))
            return;
        pending = m;
        // a cold start (its own Quickshell boots, ~2 s) gets longer than one already up
        fallback.interval = proc.running ? 3000 : 7000;
        fallback.restart();
        wake();
    }
    // the overlay is needed: start its process if it is not up (it says hello and takes `pending`)
    function wake() {
        lastUse = Date.now();
        if (!proc.running && !test && socketReady)
            proc.running = true;
    }
    function send(obj) {
        if (!client)
            return false;
        client.write(JSON.stringify(obj) + "\n");
        client.flush();
        return true;
    }

    function take(sock, m) {
        lastUse = Date.now();
        if (m.t === "hello") {
            client = sock;
            helloAt = Date.now();
            learnedCount = m.learned || 0;
            send(shellState);
            if (pending) {
                send(pending);
                pending = null;
                fallback.stop();
            }
        } else if (m.t === "open") {
            open = !!m.on;
            screenName = m.screen || "";
        } else if (m.t === "learned") {
            learnedCount = m.n || 0;
        } else if (m.t === "save") {
            Capture.saveShot(m.frame, m.rect, m.opts || {}, r => send({
                    "t": "answer",
                    "id": m.id,
                    "r": r
                }));
        } else if (m.t === "island") {
            if (m.act === "search")
                Island.search(m.arg);
            else if (m.act === "open")
                Island.open(m.arg);
            else if (m.act === "lens")
                Island.lens(m.arg);
        } else if (m.t === "share") {
            QuickShare.share(m.paths || [], m.text || "");
        } else if (m.t === "settings") {
            Shell.openSettings(m.page, m.sub);
        }
    }

    // no process to open it: the old selector takes the shot
    Timer {
        id: fallback
        interval: 3000
        onTriggered: {
            if (!root.pending)
                return;
            root.pending = null;
            console.warn("CircleHost: the overlay's process is not there, the classic selector instead");
            Capture.launch(Capture.screenshotTool, "niri msg action screenshot");
        }
    }

    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1" && rm -f "$2"', "sh", root.runtimeDir, root.socketPath]
        onExited: code => {
            root.socketReady = code === 0;
            // no start here: the process comes up when a screenshot asks for it (wake)
        }
    }
    SocketServer {
        active: root.socketReady
        path: root.socketPath
        handler: Socket {
            id: sock
            onConnectedChanged: {
                if (!connected && root.client === sock) {
                    root.client = null;
                    root.open = false;
                }
            }
            parser: SplitParser {
                onRead: line => {
                    let m = null;
                    try {
                        m = JSON.parse(line);
                    } catch (e) {
                        return;
                    }
                    if (m)
                        root.take(sock, m);
                }
            }
        }
    }

    // the overlay's process, kept running; one that keeps dying is started again less often
    Process {
        id: proc
        command: ["sh", Quickshell.shellDir + "/scripts/circle-proc.sh", Quickshell.shellDir, root.rootDir]
        environment: ({
                "ANGELOS_CIRCLE_SOCK": root.socketPath
            })
        stderr: SplitParser {
            onRead: line => {
                if (line.trim())
                    console.log("circle: " + line);
            }
        }
        onExited: code => {
            root.client = null;
            root.open = false;
            if (root.stopping) {
                // a quiet stop, not a crash: no back-off, no restart
                root.stopping = false;
                root.fails = 0;
                root.helloAt = 0;
                return;
            }
            // only a process that lived a while counts as well: one dying right after its hello
            // was started again every 2 s for ever
            if (root.helloAt && Date.now() - root.helloAt > 30000)
                root.fails = 0;
            root.helloAt = 0;
            again.interval = Math.min(60000, 2000 * Math.pow(2, root.fails++));
            again.restart();
        }
    }
    Timer {
        id: again
        onTriggered: proc.running = true
    }
    // Pre-warm the screenshot overlay after the shell's first frame so Print/Mod+Shift+S opens
    // instantly; set ANGELOS_CIRCLE_WARM=0 to revert to on-demand cold starts and 10-min idle stop.
    readonly property bool keepWarm: Quickshell.env("ANGELOS_CIRCLE_WARM") !== "0"
    Timer {
        interval: 3500
        running: root.keepWarm && root.socketReady && !proc.running && !root.test
        onTriggered: root.wake()
    }
    // ten quiet minutes and the overlay's process goes (only when keepWarm is disabled)
    Timer {
        interval: 60000
        repeat: true
        running: !root.keepWarm && proc.running && !root.open && !root.test
        onTriggered: {
            if (root.open || !root.connected || !root.lastUse)
                return;
            if (Date.now() - root.lastUse > root.idleStopMs) {
                root.stopping = true;
                proc.running = false;
            }
        }
    }
}
