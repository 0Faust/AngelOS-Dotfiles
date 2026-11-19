pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Sanctum Tools service:
//   - Niri Keybinds Cheatsheet overlay (`qs -c angelos ipc call sanctum keys`)
//   - 1-click Focus/Game Profile (`sanctum focus`: DND + calm motion, restores previous values)
//   - 1-click Pomodoro 25/5 with auto-DND (`sanctum pomo`)
Scope {
    id: root

    property var plugin
    property bool keysOpen: false
    property var binds: []
    property bool loadingBinds: false
    property bool focusActive: false
    property bool _prevDnd: false
    property string _prevMotion: "full"
    property bool pomoDndArmed: false

    function toggleKeys() {
        keysOpen = !keysOpen;
        if (keysOpen && binds.length === 0 && !loadingBinds)
            loadBinds();
    }

    function loadBinds() {
        if (bindProc.running)
            return;
        loadingBinds = true;
        bindProc.running = true;
    }

    function toggleFocus() {
        Config.notifications.dnd = !Config.notifications.dnd;
        focusActive = !!Config.notifications.dnd;
        return focusActive ? "dnd: on" : "dnd: off";
    }

    function startPomodoro() {
        const parsed = Timers.parse("помодоро 25/5", false);
        if (parsed)
            Timers.add(parsed);
        if (!Config.notifications.dnd) {
            _prevDnd = false;
            Config.notifications.dnd = true;
            pomoDndArmed = true;
        }
        return "pomodoro 25/5 started";
    }

    Connections {
        target: Timers
        function onRang(head, body) {
            if (root.pomoDndArmed) {
                root.pomoDndArmed = false;
                if (!root.focusActive)
                    Config.notifications.dnd = root._prevDnd;
            }
        }
    }

    Process {
        id: bindProc
        command: ["python3", Quickshell.shellDir + "/scripts/keybinds.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loadingBinds = false;
                try {
                    const data = JSON.parse(text);
                    root.binds = Array.isArray(data.binds) ? data.binds : [];
                } catch (e) {
                    root.binds = [];
                }
            }
        }
    }

    IpcHandler {
        target: "sanctum"
        function keys(): string {
            root.toggleKeys();
            return root.keysOpen ? "open" : "closed";
        }
        function focus(): string {
            return root.toggleFocus();
        }
        function pomo(): string {
            return root.startPomodoro();
        }
        function status(): string {
            return JSON.stringify({
                focus: root.focusActive,
                keysOpen: root.keysOpen,
                binds: root.binds.length
            });
        }
    }

    // ---- Niri Keybinds Cheatsheet Overlay ----
    LazyLoader {
        active: root.keysOpen
        PanelWindow {
            id: win
            screen: Shell.focusedScreen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Qt.alpha(Theme.shadow, 0.35)
            WlrLayershell.namespace: "angelos-sanctum-keys"
            WlrLayershell.layer: WlrLayer.Overlay
            // takes input: keybinds cheatsheet overlay (click outside closes)
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            RightClickGuard {}

            property string query: ""
            readonly property var filtered: {
                const q = query.trim().toLowerCase();
                if (!q)
                    return root.binds;
                return root.binds.filter(b => (String(b.key || "") + " " + String(b.title || "") + " " + String(b.action || "") + " " + String(b.section || "")).toLowerCase().includes(q));
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.keysOpen = false
            }

            PxWindow {
                id: card
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.u * 20, Theme.u * 280)
                height: Math.min(parent.height - Theme.u * 24, Theme.u * 240)
                title: I18n.t("Хоткеи Niri", "Niri Shortcuts")
                icon: "keyboard"
                onCloseClicked: root.keysOpen = false

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.fill: parent
                    spacing: Theme.u * 4

                    Row {
                        width: parent.width
                        spacing: Theme.u * 3
                        PxField {
                            id: searchField
                            width: parent.width - reloadBtn.width - Theme.u * 3
                            icon: "search"
                            keepFocus: true
                            placeholder: I18n.t("Поиск по клавишам или действиям… (Esc — закрыть)", "Filter keys or actions… (Esc closes)")
                            onEdited: win.query = text
                            onKeyPressed: e => {
                                if (e.key === Qt.Key_Escape) {
                                    root.keysOpen = false;
                                    e.accepted = true;
                                }
                            }
                        }
                        PxButton {
                            id: reloadBtn
                            compact: true
                            icon: "refresh"
                            text: I18n.t("Обновить", "Reload")
                            onClicked: root.loadBinds()
                        }
                    }

                    PxText {
                        visible: root.loadingBinds
                        text: I18n.t("Читаю config.kdl…", "Reading config.kdl…")
                        dim: true
                    }

                    PxBox {
                        width: parent.width
                        height: parent.height - searchField.height - Theme.u * 4
                        sunken: true
                        color: Qt.alpha(Theme.sunken, 0.85)
                        edgeColor: Theme.relic ? Theme.relicBronze : Theme.edge

                        ListView {
                            id: lv
                            anchors.fill: parent
                            anchors.margins: Theme.u * 3
                            clip: true
                            spacing: Theme.u * 2
                            model: win.filtered
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Rectangle {
                                required property var modelData
                                width: lv.width
                                height: Theme.u * 14
                                color: rowHover.containsMouse ? (Theme.relic ? Theme.mix(Theme.faceAlt, Theme.relicCrimson, 0.3) : Theme.mix(Theme.face, Theme.accent, 0.12)) : Qt.alpha(Theme.face, 0.55)
                                border.width: Theme.u
                                border.color: rowHover.containsMouse && Theme.relic ? Theme.relicGold : Qt.alpha(Theme.relic ? Theme.relicBronze : Theme.edge, 0.45)

                                HoverHandler {
                                    id: rowHover
                                }
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.u * 4
                                    anchors.rightMargin: Theme.u * 4
                                    spacing: Theme.u * 4
                                    PxText {
                                        width: Theme.u * 85
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.key || ""
                                        font.bold: true
                                        elide: Text.ElideRight
                                        color: Theme.relic ? Theme.relicGold : Theme.accent
                                    }
                                    PxText {
                                        width: parent.width - Theme.u * 89
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData.title || modelData.action || "")
                                        elide: Text.ElideRight
                                        color: Theme.relic ? Theme.relicInk : Theme.text
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
