pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Desktop widget: Sanctum Daily Tasks checklist with JSON persistence
Item {
    id: root

    property string screenName
    property var widget
    property string size: "m"
    property string frameKind: "window"
    property bool face: true
    readonly property bool passive: false

    readonly property string savePath: Config.home + "/.config/angelos/sanctum-tasks.json"
    property var tasks: [
        { "text": I18n.t("Проверить обновления системы", "Check system updates"), "done": false }
    ]

    implicitWidth: Theme.u * (size === "s" ? 110 : size === "l" ? 156 : 134)
    implicitHeight: Math.max(Theme.u * 50, col.implicitHeight)

    function persist() {
        const payload = JSON.stringify(root.tasks);
        Quickshell.execDetached(["python3", "-c", "import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[2],encoding='utf-8')", root.savePath, payload]);
    }

    function addTask(t) {
        const clean = String(t || "").trim();
        if (!clean)
            return;
        root.tasks = root.tasks.concat([{ "text": clean, "done": false }]);
        persist();
    }

    function toggleTask(idx) {
        const copy = root.tasks.slice();
        if (!copy[idx])
            return;
        copy[idx] = { "text": copy[idx].text, "done": !copy[idx].done };
        root.tasks = copy;
        persist();
    }

    function removeTask(idx) {
        const copy = root.tasks.slice();
        copy.splice(idx, 1);
        root.tasks = copy;
        persist();
    }

    FileView {
        path: root.savePath
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed))
                    root.tasks = parsed;
            } catch (e) {}
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3

        Row {
            width: parent.width
            spacing: Theme.u * 2
            PxField {
                id: addField
                width: parent.width - addBtn.width - Theme.u * 2
                placeholder: I18n.t("+ задача…", "+ task…")
                onAccepted: {
                    root.addTask(text);
                    text = "";
                }
            }
            PxButton {
                id: addBtn
                compact: true
                text: "+"
                onClicked: {
                    root.addTask(addField.text);
                    addField.text = "";
                }
            }
        }

        PxText {
            visible: root.tasks.length === 0
            text: I18n.t("Все задачи выполнены ✦", "All tasks done ✦")
            dim: true
            kind: "tiny"
        }

        Repeater {
            model: root.tasks
            Row {
                id: tRow
                required property var modelData
                required property int index
                width: col.width
                spacing: Theme.u * 2

                PxCheck {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: !!tRow.modelData.done
                    onToggled: root.toggleTask(tRow.index)
                }
                PxText {
                    width: parent.width - Theme.u * 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: tRow.modelData.text || ""
                    elide: Text.ElideRight
                    font.strikeout: !!tRow.modelData.done
                    dim: !!tRow.modelData.done
                    color: tRow.modelData.done ? Theme.textDim : (Theme.relic ? "#faecc8" : Theme.text)
                }
                PxButton {
                    compact: true
                    flat: true
                    icon: "close"
                    onClicked: root.removeTask(tRow.index)
                }
            }
        }
    }
}
