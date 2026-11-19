pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.serp
import "."

// serp-skin: the desktop clock in Serpantinum's face (angelOS's modules/desktop/widgets/
// ClockWidget, same settings and data). Stands still while nobody can see the desk.
//   S  the time, the short date and the degrees under it
//   M  a big Black HH:mm in the accent (seconds small beside it), the date, the weather pill
//   L  bigger, and the weather in words: feels like, wind, the day's ↑ ↓, the place
// The weather (services/Weather) is on unless its right-click toggle says no. In hell the roles
// are hell's already; between three and four in the night the date gives way to "hora diaboli".
Item {
    id: root
    // serp-skin: the desktop host draws a serp face at its natural size (zoom 1) and the face
    // takes the widget's own zoom here (Ctrl + wheel): text and shapes are laid out at the
    // final size, so nothing is stretched into a blur
    readonly property real zoom: DesktopWidgets.scaleOf(widget)
    function px(v) { return Serp.px(v * zoom) }

    property string screenName
    property var widget
    property string size: "m"
    property string frameKind: "window"
    property bool face: true
    readonly property bool passive: true     // nothing to click: no input copy needed
    readonly property var st: widget && widget.settings ? widget.settings : ({})
    readonly property bool seconds: !!st.seconds
    readonly property bool weatherOn: st.weather !== false && Weather.ok
    readonly property var wx: Weather.now || ({})

    implicitWidth: body.implicitWidth + (size === "s" ? 0 : root.px(16))
    implicitHeight: body.implicitHeight
    readonly property var locale: Qt.locale(I18n.english ? "en_US" : "ru_RU")
    // "пятница, 13 ноября" ("d MMMM" keeps the month's genitive in Russian)
    readonly property string dateText: locale.toString(clock.date, I18n.english ? "dddd, MMMM d" : "dddd, d MMMM")
    readonly property string shortDate: locale.toString(clock.date, I18n.english ? "ddd, MMM d" : "ddd, d MMM")
    readonly property bool witching: Theme.hell && clock.hours === 3
    readonly property int timePx: root.px(size === "s" ? 34 : size === "l" ? 76 : 56)

    SystemClock {
        id: clock
        enabled: !Shell.hiddenScreen(root.screenName)
        precision: root.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.px(root.size === "l" ? 10 : root.size === "s" ? 2 : 6)

        // the time: HH:mm in the accent, Black; the seconds small and quiet on its baseline
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.px(4)
            SText {
                id: hm
                text: I18n.time(clock.date, false)
                size: root.timePx
                black: true
                color: Serp.accent
                font.letterSpacing: root.timePx * 0.01
            }
            SText {
                visible: root.seconds
                anchors.baseline: hm.baseline
                text: String(clock.seconds).padStart(2, "0")
                size: Math.max(root.px(11), root.timePx * 0.32)
                bold: true
                color: Serp.subtext0
            }
        }

        // the date (S: short, with the degrees beside it)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.px(6)
            SText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.witching ? "hora diaboli" : root.size === "s" ? root.shortDate : root.dateText
                size: root.size === "s" ? root.px(11) : root.size === "l" ? root.px(17) : root.px(14)
                bold: true
                color: root.witching ? Serp.accent : Serp.subtext1
            }
            SIcon {
                visible: root.size === "s" && root.weatherOn
                anchors.verticalCenter: parent.verticalCenter
                name: SerpIcons.weather(Weather.now)
                size: root.px(12)
                color: Serp.subtext0
            }
            SText {
                visible: root.size === "s" && root.weatherOn
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.deg(root.wx.temp)
                size: root.px(11)
                bold: true
                color: Serp.text
            }
        }

        // M and L: the weather on a surface0 pill
        Rectangle {
            id: wxPill
            visible: root.size !== "s" && root.weatherOn
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property int pad: root.px(root.size === "l" ? 14 : 10)
            width: wxRow.implicitWidth + pad * 2
            height: wxRow.implicitHeight + root.px(root.size === "l" ? 12 : 8)
            radius: height / 2
            color: Serp.surface0
            border.width: 1
            border.color: Qt.tint(Serp.base, Qt.alpha(Serp.text, 0.12))  // opaque: blur noise showed through the clear line
            Row {
                id: wxRow
                anchors.centerIn: parent
                spacing: root.px(7)
                SIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: SerpIcons.weather(Weather.now)
                    size: root.px(root.size === "l" ? 18 : 15)
                    color: Serp.accent
                }
                SText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.deg(root.wx.temp)
                    size: root.px(root.size === "l" ? 15 : 13)
                    bold: true
                }
                SText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.words(root.wx.code)
                    size: root.px(root.size === "l" ? 14 : 12)
                    color: Serp.subtext0
                }
            }
        }

        // L: the weather in words, two quiet chips
        Row {
            visible: root.size === "l" && root.weatherOn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.px(6)
            Repeater {
                model: root.size === "l" && root.weatherOn ? 2 : 0
                Rectangle {
                    id: chip
                    required property int index
                    width: chipText.implicitWidth + root.px(18)
                    height: chipText.implicitHeight + root.px(8)
                    radius: height / 2
                    color: Serp.surface0
                    SText {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.index === 0 ? I18n.t("ощущается ", "feels like ") + Weather.deg(root.wx.feels) + " · " + I18n.t("ветер ", "wind ") + Math.round(root.wx.wind || 0) + I18n.t(" м/с", " m/s") : "↑ " + Weather.deg(root.wx.max) + "  ↓ " + Weather.deg(root.wx.min) + (Weather.place ? " · " + Weather.place.name : "")
                        size: root.px(11)
                        color: Serp.subtext0
                    }
                }
            }
        }
    }
}
