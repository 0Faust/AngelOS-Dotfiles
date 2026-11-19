import QtQuick
import qs.config

// Win98-style bevelled box. raised by default, `sunken` for inputs/pressed.
// By day (Theme.zine) it is flat: the outline alone, no bevels.
// `hell: Theme.hell` gives it hell's obsidian bevels (Theme.realm).
Item {
    id: root

    property bool hell: false
    readonly property string settingsSkin: hell ? "classic" : Theme.settingsSkinFor(root.parent)
    // the P5 settings window: a flat paper plate with a black outline
    readonly property bool p5: settingsSkin === "p5"
    readonly property bool relic: Theme.relic && !hell && !p5
    property color color: hell ? Theme.hellFace : p5 ? Theme.p5Paper2 : Theme.face
    property int bevel: settingsSkin === "windose" ? Math.max(1, Math.floor(Theme.u / 2)) : Theme.u
    property bool sunken: false
    property bool outline: true
    property bool prominent: false
    readonly property color relicFrame: prominent ? Theme.relicGold : Theme.relicBronze
    property bool flat: !relic && (settingsSkin === "windose" || p5 || (Theme.zine && !hell))
    property bool shadow: false
    property int shadowSize: Theme.u * 2
    property color shadowColor: Qt.alpha(Theme.shadow, Theme.shadowAlpha)
    property color hiColor: hell ? Theme.hellHi : settingsSkin === "windose" ? Theme.windoseLine : Theme.hi
    property color loColor: hell ? Theme.hellLo : settingsSkin === "windose" ? Theme.windoseLine : Theme.lo
    property color edgeColor: hell ? Theme.hellEdge : settingsSkin === "windose" ? Theme.windoseLine : p5 ? Theme.p5Black : Theme.edge
    readonly property int ob: outline ? bevel : 0
    // Crisp 1u obsidian outline + 1u gold/bronze rim (2u inset on buttons, 3u on large panels).
    readonly property int relicInset: outline ? (width >= Theme.u * 60 && height >= Theme.u * 50 ? Theme.u * 3 : Theme.u * 2) : Theme.u
    readonly property int inset: relic ? relicInset : ob + (flat ? 0 : bevel)
    default property alias content: inner.data

    // hard pixel shadow (right + bottom strips so translucent boxes stay clean)
    Rectangle {
        visible: root.shadow
        x: root.width
        y: root.shadowSize
        width: root.shadowSize
        height: root.height
        color: root.shadowColor
    }
    Rectangle {
        visible: root.shadow
        x: root.shadowSize
        y: root.height
        width: root.width
        height: root.shadowSize
        color: root.shadowColor
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.relic
        color: root.color
        border.width: root.ob
        border.color: root.edgeColor
    }
    // Pure QML crisp 16-bit bevels: 1u obsidian outer outline + 1u gold/bronze inner rim (no thick stacked bricks).
    Rectangle {
        visible: root.relic
        anchors.fill: parent
        color: root.color
        border.width: root.outline ? Theme.u : 0
        border.color: root.edgeColor === Theme.relicGold ? Theme.edge : root.edgeColor
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 6 && root.height >= Theme.u * 6
            anchors.fill: parent
            anchors.margins: Theme.u
            color: "transparent"
            border.width: Theme.u
            border.color: root.prominent && root.edgeColor === Theme.relicGold ? Theme.relicGold : root.sunken ? root.loColor : (root.prominent ? Theme.relicGold : Theme.relicBronze)
        }
        // Inner 1u forged bevel highlight/shadow on medium/large panels
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 20 && root.height >= Theme.u * 18
            x: Theme.u * 2
            y: Theme.u * 2
            width: parent.width - Theme.u * 4
            height: Theme.u
            color: root.sunken ? root.loColor : root.hiColor
        }
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 20 && root.height >= Theme.u * 18
            x: Theme.u * 2
            y: Theme.u * 2
            width: Theme.u
            height: parent.height - Theme.u * 4
            color: root.sunken ? root.loColor : root.hiColor
        }
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 20 && root.height >= Theme.u * 18
            x: Theme.u * 2
            y: parent.height - Theme.u * 3
            width: parent.width - Theme.u * 4
            height: Theme.u
            color: root.sunken ? root.hiColor : root.loColor
        }
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 20 && root.height >= Theme.u * 18
            x: parent.width - Theme.u * 3
            y: Theme.u * 2
            width: Theme.u
            height: parent.height - Theme.u * 4
            color: root.sunken ? root.hiColor : root.loColor
        }
    }
    Repeater {
        model: root.relic && root.outline && root.width >= Theme.u * 60 && root.height >= Theme.u * 50 ? 4 : 0
        Item {
            required property int index
            readonly property int s: Theme.u
            readonly property bool isRight: index % 2 === 1
            readonly property bool isBottom: index >= 2
            x: isRight ? root.width - s * 6 : 0
            y: isBottom ? root.height - s * 6 : 0
            width: s * 6
            height: s * 6
            // Carved outer L-arm (1u gold/bronze filigree)
            Rectangle {
                y: parent.isBottom ? parent.height - parent.s : 0
                width: parent.width
                height: parent.s
                color: root.relicFrame
            }
            Rectangle {
                x: parent.isRight ? parent.width - parent.s : 0
                width: parent.s
                height: parent.height
                color: root.relicFrame
            }
            // Inner stepped bracket notch
            Rectangle {
                x: parent.isRight ? parent.s * 3 : parent.s
                y: parent.isBottom ? parent.s * 3 : parent.s
                width: parent.s * 2
                height: parent.s * 2
                color: Theme.relicDark ? Theme.edge : Theme.relicBronze
            }
            // Crimson enamel jewel + bright ivory highlight dot
            Rectangle {
                x: parent.isRight ? parent.width - parent.s * 3 : parent.s * 2
                y: parent.isBottom ? parent.height - parent.s * 3 : parent.s * 2
                width: parent.s
                height: parent.s
                color: Theme.relicCrimson
            }
            Rectangle {
                x: parent.isRight ? parent.width - parent.s * 2 : parent.s
                y: parent.isBottom ? parent.height - parent.s * 2 : parent.s
                width: parent.s
                height: parent.s
                color: Theme.relicDark ? "#ffe39e" : Theme.hi
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.inset
    }
}
