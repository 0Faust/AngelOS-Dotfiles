pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Month grid + notification history.
BarPopup {
    id: root

    title: Theme.relic ? I18n.t("Календарь", "Calendar") : I18n.exe(I18n.t("календарь", "calendar"))
    panelId: "calendar"                  // `angelos panel calendar`, a gesture (services/Gestures)
    icon: "calendar"
    contentWidth: Theme.u * 170
    contentHeight: Theme.u * 255

    property date month: new Date()
    onVisibleChanged: if (visible) {
        month = new Date();
        Notifs.markRead();
    }

    readonly property var days: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const count = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < offset; i++)
            out.push(0);
        for (let d = 1; d <= count; d++)
            out.push(d);
        return out;
    }

    Column {
        anchors.fill: parent
        spacing: Theme.u * 4

        Row {
            width: parent.width
            PxButton {
                id: prevMonth
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                icon: "arrowLeft"
                onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() - 1, 1)
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - prevMonth.width - nextMonth.width
                horizontalAlignment: Text.AlignHCenter
                kind: "title"
                font.family: Theme.relic ? Theme.fontTitle : Theme.fontBody
                color: Theme.relic ? Theme.relicGold : Theme.text
                text: I18n.locale.standaloneMonthName(root.month.getMonth()) + " " + root.month.getFullYear()
            }
            PxButton {
                id: nextMonth
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                icon: "arrowRight"
                onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + 1, 1)
            }
        }

        Grid {
            id: grid
            columns: 7
            width: parent.width
            readonly property int cell: Math.floor(width / 7)
            Repeater {
                model: [I18n.t("пн", "Mon"), I18n.t("вт", "Tue"), I18n.t("ср", "Wed"), I18n.t("чт", "Thu"), I18n.t("пт", "Fri"), I18n.t("сб", "Sat"), I18n.t("вс", "Sun")]
                PxText {
                    required property string modelData
                    required property int index
                    width: grid.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    dim: !(Theme.relic && index >= 5)
                    color: Theme.relic && index >= 5 ? Theme.relicCrimson : Theme.textDim
                }
            }
            Repeater {
                model: root.days
                Item {
                    id: day
                    required property int modelData
                    readonly property var now: new Date()
                    readonly property bool today: modelData === now.getDate() && root.month.getMonth() === now.getMonth() && root.month.getFullYear() === now.getFullYear()
                    width: grid.cell
                    height: Theme.u * 11
                    Rectangle {
                        visible: Theme.relic && day.today
                        anchors.centerIn: parent
                        width: Theme.u * 11
                        height: Theme.u * 9
                        color: Theme.relicCrimson
                        border.width: Theme.u
                        border.color: Theme.relicGold
                    }
                    PxIcon {
                        visible: !Theme.relic && day.today
                        anchors.centerIn: parent
                        name: "heart"
                        pixel: Theme.u
                    }
                    PxText {
                        anchors.centerIn: parent
                        visible: day.modelData > 0
                        text: day.modelData
                        color: day.today ? (Theme.relic ? "#f4e6cf" : "#ffffff") : Theme.text
                        font.bold: day.today
                    }
                }
            }
        }

        Item {
            visible: Theme.relic
            width: parent.width
            height: Theme.u
            Rectangle { anchors.fill: parent; color: Theme.relicGold }
            Rectangle {
                anchors.centerIn: parent
                width: Theme.u * 5
                height: Theme.u
                color: Theme.relicCrimson
            }
        }

        Row {
            width: parent.width
            spacing: Theme.u * 3
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                kind: "title"
                font.family: Theme.relic ? Theme.fontTitle : Theme.fontBody
                color: Theme.relic ? Theme.relicGold : Theme.text
                text: I18n.t("Уведомления", "Notifications")
                width: parent.width - dnd.width - clear.width - Theme.u * 6
            }
            PxToggle {
                id: dnd
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("тихо", "Quiet")
                checked: Config.notifications.dnd
                onToggled: c => Config.notifications.dnd = c
            }
            PxButton {
                id: clear
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                icon: "trash"
                onClicked: Notifs.clearHistory()
            }
        }

        PxBox {
            width: parent.width
            height: parent.height - y
            sunken: !Theme.relic
            outline: !Theme.relic
            flat: Theme.relic
            color: Qt.alpha(Theme.sunken, 0.72)

            Rectangle {
                visible: Theme.relic
                anchors.fill: parent
                color: "transparent"
                border.width: Theme.u
                border.color: Theme.relicBronze
            }

            PxScroll {
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                contentHeight: list.implicitHeight

                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.u * 2
                    PxText {
                        visible: Notifs.history.length === 0
                        text: I18n.t("  никто не пишет… ♡", "  No activity… ♡")
                        dim: true
                        height: Theme.u * 20
                    }
                    Repeater {
                        model: Notifs.history
                        Item {
                            id: h
                            required property var modelData
                            width: list.width
                            height: hcol.implicitHeight + Theme.u * 6
                            Rectangle {
                                anchors.fill: parent
                                color: hm.containsMouse ? (Theme.relic ? Theme.mix(Theme.faceAlt, Theme.relicCrimson, 0.2) : Theme.mix(Theme.face, Theme.accent, 0.12)) : (Theme.relic ? Qt.alpha(Theme.face, 0.55) : "transparent")
                                border.width: Theme.relic ? Theme.u : 0
                                border.color: hm.containsMouse ? Theme.relicGold : Qt.alpha(Theme.relicBronze, 0.45)
                            }
                            AppIcon {
                                id: hicon
                                x: Theme.u * 2
                                y: Theme.u * 3
                                iconName: h.modelData.icon || ""
                                size: Theme.u * 10
                            }
                            Column {
                                id: hcol
                                x: hicon.width + Theme.u * 5
                                y: Theme.u * 3
                                width: parent.width - x - Theme.u * 12
                                PxText {
                                    width: parent.width
                                    text: h.modelData.summary
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                PxText {
                                    width: parent.width
                                    text: Notifs.safeMarkup(h.modelData.body)
                                    textFormat: Text.StyledText
                                    linkColor: Theme.accent2
                                    onLinkActivated: l => Notifs.openLink(l)
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    dim: true
                                }
                                PxText {
                                    text: h.modelData.appName + " · " + Qt.formatTime(new Date(h.modelData.time), "HH:mm")
                                    kind: "tiny"
                                    dim: true
                                }
                            }
                            MouseArea {
                                id: hm
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifs.removeHistory(h.modelData.hid)
                            }
                        }
                    }
                }
            }
        }
    }
}
