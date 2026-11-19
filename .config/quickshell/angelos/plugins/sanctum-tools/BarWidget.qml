import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Compact Sanctum Tools button on the bar:
//   LMB: Niri shortcuts cheatsheet
//   RMB: clean Sanctum action menu (Shortcuts, Pomodoro 25/5, Quiet/DND)
PxButton {
    id: root

    property var plugin
    property bool above: true
    readonly property string barTip: I18n.t("Хоткеи Niri (ПКМ — меню Sanctum)", "Niri shortcuts (RMB — Sanctum menu)")

    compact: true
    flat: true
    icon: "sparkle"
    checked: ctxMenu.visible
    onClicked: Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "keys"])
    onRightClicked: {
        const p = root.mapToItem(null, Math.round(root.width / 2), root.above ? 0 : root.height);
        ctxMenu.popup([
            {
                "label": I18n.t("Хоткеи Niri", "Niri Shortcuts"),
                "icon": "keyboard",
                "run": () => Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "keys"])
            },
            {
                "label": I18n.t("Помодоро 25/5 + тихо", "Pomodoro 25/5 + DND"),
                "icon": "clock",
                "run": () => Quickshell.execDetached(["qs", "-c", "angelos", "ipc", "call", "sanctum", "pomo"])
            },
            {
                "label": I18n.t("Режим «Тихо» (DND)", "Do Not Disturb"),
                "icon": "moon",
                "checked": () => !!Config.notifications.dnd,
                "keepOpen": true,
                "run": () => { Config.notifications.dnd = !Config.notifications.dnd; }
            }
        ], I18n.t("Sanctum Tools", "Sanctum Tools"), p.x, p.y);
    }

    PxMenu {
        id: ctxMenu
        parentWindow: root.QsWindow.window
        kind: "panel"
        panelId: "sanctum-tools-menu"
        readonly property string side: BarLayout.side
        anchor.edges: root.above ? Edges.Top | Edges.Left : Edges.Bottom | Edges.Left
        anchor.gravity: side === "left" ? Edges.Bottom | Edges.Right : side === "right" ? Edges.Bottom | Edges.Left : root.above ? Edges.Top | Edges.Left : Edges.Bottom | Edges.Left
    }
}
