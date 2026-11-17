import QtQuick
import qs.config
import qs.services

// Relic's reference-facing, *functional* skin selector. Its tiles change the
// same Config settings as the normal six-card picker; the original picker
// remains available below, including Windose and Stream.
Item {
    id: root
    width: parent ? parent.width : Theme.u * 280
    readonly property int s: Theme.u
    readonly property int gap: s * 4
    readonly property int cols: width >= s * 210 ? 4 : 2
    readonly property int tileW: Math.floor((width - gap * (cols - 1)) / cols)
    readonly property int tileH: s * 48
    implicitHeight: title.implicitHeight + s * 5 + tiles.height + s * 5 + preview.height + s * 5 + actions.height
    height: implicitHeight

    PxText {
        id: title
        text: I18n.t("✝  Выбор скина", "✝  Choose a skin")
        kind: "title"
        font.bold: true
        color: Theme.text
    }
    Rectangle {
        x: 0
        y: title.implicitHeight + s * 2
        width: parent.width
        height: s
        color: Theme.relicGold
    }
    Flow {
        id: tiles
        y: title.implicitHeight + s * 5
        width: parent.width
        spacing: root.gap
        height: Math.ceil(4 / root.cols) * root.tileH + (Math.ceil(4 / root.cols) - 1) * spacing
        Repeater {
            model: [
                { id: "classic", name: "Classic", icon: "window" },
                { id: "win10", name: "Win10", icon: "grid" },
                { id: "goldengate", name: "Golden Gate", icon: "home" },
                { id: "relic", name: "Relic", icon: "sparkle" }
            ]
            Item {
                id: tile
                required property var modelData
                readonly property bool selected: Config.settingsUi.skin === modelData.id
                width: root.tileW
                height: root.tileH
                PxBox {
                    anchors.fill: parent
                    color: tile.selected ? Theme.mix(Theme.faceAlt, Theme.relicCrimson, 0.28) : Theme.faceAlt
                    edgeColor: tile.selected ? Theme.relicGold : Theme.edge
                    shadow: tile.selected
                    shadowSize: root.s
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.s * 2
                    visible: tile.selected
                    color: "transparent"
                    border.width: root.s
                    border.color: Theme.relicGold
                }
                Image {
                    visible: tile.modelData.id === "relic"
                    source: Qt.resolvedUrl("../assets/relic/relic-cathedral.svg")
                    x: root.s * 4
                    y: root.s * 4
                    width: parent.width - root.s * 8
                    height: parent.height - root.s * 16
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                    asynchronous: true
                }
                PxIcon {
                    visible: tile.modelData.id !== "relic"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.s * 8
                    name: tile.modelData.icon
                    pixel: Math.max(1, root.s * 3)
                    ink: Theme.relicGold
                    fill: Theme.text
                    light: Theme.relicCrimson
                }
                PxText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.s * 3
                    text: tile.modelData.name
                    font.bold: tile.selected
                    color: Theme.text
                }
                PxText {
                    visible: tile.selected
                    anchors.right: parent.right
                    anchors.rightMargin: root.s * 3
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.s * 3
                    text: "✓"
                    color: Theme.relicGold
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: tile.modelData.name
                    Accessible.onPressAction: Config.settingsUi.skin = tile.modelData.id
                    onClicked: Config.settingsUi.skin = tile.modelData.id
                }
            }
        }
    }

    PxBox {
        id: preview
        y: tiles.y + tiles.height + root.s * 5
        width: parent.width
        height: root.s * (root.cols === 4 ? 69 : 94)
        color: Theme.faceAlt
        Row {
            anchors.fill: parent
            anchors.margins: root.s * 5
            spacing: root.s * 6
            Image {
                width: Math.min(parent.height, Math.max(root.s * 33, (preview.width - root.s * 16) * 0.26))
                height: parent.height
                source: Qt.resolvedUrl("../assets/relic/relic-cathedral.svg")
                smooth: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Column {
                width: root.cols === 4 ? Math.max(root.s * 48, (preview.width - root.s * 26) * 0.43) : Math.max(root.s * 50, preview.width - x - root.s * 13)
                spacing: root.s * 2
                PxText {
                    text: "Relic (Sanctum)"
                    kind: "title"
                    font.bold: true
                    color: Theme.text
                }
                PxText {
                    text: I18n.t("Завет и Пепел", "Covenant and Ash")
                    color: Theme.relicGold
                    kind: "body"
                }
                PxText {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: I18n.t("Сакрально-инфернальная готика в пиксельной эстетике. Кованый металл, позолоченные реликвии и тёмный кармин.", "Sacred-infernal gothic pixel art: forged iron, gilded relics and deep carmine.")
                    color: Theme.textDim
                    kind: "tiny"
                }
            }
            Column {
                visible: root.cols === 4
                spacing: root.s * 4
                width: Math.max(0, preview.width - x - root.s * 11)
                Repeater {
                    model: [
                        I18n.t("Тёмная тема (Инферно)", "Dark theme (Inferno)"),
                        I18n.t("Светлая тема (Пергамент)", "Light theme (Parchment)"),
                        I18n.t("Пиксельные иконки Relic", "Relic pixel icons"),
                        I18n.t("Пиксельные окна", "Pixel windows")
                    ]
                    Row {
                        required property string modelData
                        spacing: root.s * 2
                        Rectangle {
                            width: root.s * 7
                            height: width
                            color: Theme.face
                            border.color: Theme.relicGold
                            border.width: root.s
                            PxText { anchors.centerIn: parent; text: "✓"; color: Theme.relicGold; kind: "tiny" }
                        }
                        PxText {
                            text: modelData
                            kind: "tiny"
                            color: Theme.text
                            width: Math.max(0, preview.width * 0.21)
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
    Row {
        id: actions
        y: preview.y + preview.height + root.s * 5
        spacing: root.gap
        PxButton {
            text: I18n.t("Тёмная (Инферно)", "Dark (Inferno)")
            icon: "moon"
            accent: Config.appearance.mode !== "light"
            onClicked: Config.appearance.mode = "dark"
        }
        PxButton {
            text: I18n.t("Светлая (Пергамент)", "Light (Parchment)")
            icon: "sun"
            accent: Config.appearance.mode === "light"
            onClicked: Config.appearance.mode = "light"
        }
        PxButton {
            text: I18n.t("Обои собора", "Cathedral wallpaper")
            icon: "image"
            onClicked: {
                Shell.settingsPage = "wallpaper";
                Shell.settingsSub = "";
            }
        }
    }
}
