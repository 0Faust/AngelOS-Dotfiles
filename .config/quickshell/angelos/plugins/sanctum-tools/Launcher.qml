import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// ":" prefix in Launcher: quick snippets + instant Sanctum actions (:keys, :focus, :pomo)
Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var plugin
    property string pluginId
    readonly property string prefix: ":"
    readonly property bool global: false
    signal changed

    readonly property string snippetPath: Config.home + "/.config/angelos/sanctum-snippets.json"
    property var snippets: [
        { "id": "restart", "title": "angelos restart", "text": Config.home + "/.config/quickshell/angelos/bin/angelos restart", "sub": "Перезапуск Quickshell" },
        { "id": "perf", "title": "angelos perf", "text": Config.home + "/.config/quickshell/angelos/bin/angelos perf 10", "sub": "Замер производительности" },
        { "id": "qml", "title": "qml-check", "text": "bash " + Config.home + "/AngelOS-Dotfiles/.config/quickshell/angelos/scripts/qml-check.sh " + Config.home + "/AngelOS-Dotfiles/.config/quickshell/angelos", "sub": "Проверка QML" },
        { "id": "sync", "title": "sync-live", "text": "bash " + Config.home + "/AngelOS-Dotfiles/scripts/sync-live.sh --dry-run", "sub": "Проверка синхронизации repo → live" }
    ]

    FileView {
        id: snipFile
        path: root.snippetPath
        printErrors: false
        watchChanges: true
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed) && parsed.length > 0) {
                    root.snippets = parsed;
                    root.changed();
                }
            } catch (e) {}
        }
    }

    function query(text, prefixed) {
        const q = String(text || "").trim().toLowerCase();
        const actions = [
            { "id": "act:keys", "title": I18n.t("Хоткеи Niri", "Niri Shortcuts"), "subtitle": I18n.t("Открыть шпаргалку горячих клавиш", "Open keybinds cheatsheet"), "icon": "keyboard", "score": 100 },
            { "id": "act:focus", "title": I18n.t("Тихий / Игровой профиль", "Focus / Game Profile"), "subtitle": I18n.t("Переключить DND + calm-анимации", "Toggle DND + calm motion"), "icon": "moon", "score": 95 },
            { "id": "act:pomo", "title": I18n.t("Помодоро 25/5 + авто-DND", "Pomodoro 25/5 + auto-DND"), "subtitle": I18n.t("Фокус-сессия в Нимбе с тихим режимом", "Focus session in Halo with DND"), "icon": "clock", "score": 90 }
        ];
        const out = [];
        for (const a of actions) {
            if (!q || (a.title + " " + a.subtitle + " " + a.id).toLowerCase().includes(q))
                out.push(a);
        }
        for (const s of root.snippets) {
            const hay = (String(s.id || "") + " " + String(s.title || "") + " " + String(s.sub || "") + " " + String(s.text || "")).toLowerCase();
            if (!q || hay.includes(q)) {
                out.push({
                    "id": "snip:" + (s.id || s.title),
                    "title": s.title || s.id,
                    "subtitle": (s.sub ? s.sub + " · " : "") + I18n.t("Enter — скопировать", "Enter copies"),
                    "icon": "copy",
                    "score": q && String(s.title || "").toLowerCase().startsWith(q) ? 85 : 50
                });
            }
        }
        return out.slice(0, 30);
    }

    function activate(id) {
        if (id === "act:keys") {
            Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "keys"]);
        } else if (id === "act:focus") {
            Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "focus"]);
        } else if (id === "act:pomo") {
            Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "pomo"]);
        } else if (id.startsWith("snip:")) {
            const key = id.slice(5);
            const found = root.snippets.find(s => (s.id || s.title) === key);
            if (found && found.text)
                Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "_", String(found.text)]);
        }
    }
}
