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
    property bool flat: !relic && (settingsSkin === "windose" || p5 || (Theme.zine && !hell))
    property bool shadow: false
    property int shadowSize: Theme.u * 2
    property color shadowColor: Qt.alpha(Theme.shadow, Theme.shadowAlpha)
    property color hiColor: hell ? Theme.hellHi : settingsSkin === "windose" ? Theme.windoseLine : Theme.hi
    property color loColor: hell ? Theme.hellLo : settingsSkin === "windose" ? Theme.windoseLine : Theme.lo
    property color edgeColor: hell ? Theme.hellEdge : settingsSkin === "windose" ? Theme.windoseLine : p5 ? Theme.p5Black : Theme.edge
    readonly property int ob: outline ? bevel : 0
    // Engraved dark-gold-dark border + 3u inset for corner caps on larger panels; 1u on thin bars.
    readonly property int relicInset: outline ? (width >= Theme.u * 20 && height >= Theme.u * 16 ? Theme.u * 3 : Theme.u) : Theme.u
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
    // Relic / Sanctum: engraved dark-gold-dark channel + bold corner caps.
    Rectangle {
        visible: root.relic
        anchors.fill: parent
        color: root.color
        border.width: root.outline ? Theme.u : 0
        border.color: root.edgeColor
        Rectangle {
            visible: root.outline && root.width >= Theme.u * 6 && root.height >= Theme.u * 6
            anchors.fill: parent
            anchors.margins: Theme.u
            color: "transparent"
            border.width: Theme.u
            border.color: root.sunken ? root.loColor : Theme.relicGold
            Rectangle {
                visible: root.width >= Theme.u * 12 && root.height >= Theme.u * 12
                anchors.fill: parent
                anchors.margins: Theme.u
                color: "transparent"
                border.width: Theme.u
                border.color: root.edgeColor
            }
        }
    }
    Repeater {
        model: root.relic && root.outline && root.width >= Theme.u * 20 && root.height >= Theme.u * 16 ? 4 : 0
        Item {
            required property int index
            readonly property int s: Theme.u
            readonly property bool isRight: index % 2 === 1
            readonly property bool isBottom: index >= 2
            x: isRight ? root.width - s * 6 : s
            y: isBottom ? root.height - s * 6 : s
            width: s * 5
            height: s * 5
            Rectangle {
                y: parent.isBottom ? parent.height - parent.s * 2 : 0
                width: parent.width
                height: parent.s * 2
                color: Theme.relicGold
            }
            Rectangle {
                x: parent.isRight ? parent.width - parent.s * 2 : 0
                width: parent.s * 2
                height: parent.height
                color: Theme.relicGold
            }
            Rectangle {
                x: parent.isRight ? parent.width - parent.s : 0
                y: parent.isBottom ? parent.height - parent.s : 0
                width: parent.s
                height: parent.s
                color: Theme.relicDark ? "#f4e6cf" : "#3a2622"
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.inset
    }

    component RelicShape: Item {
        id: shape
        property color fill: "transparent"
        readonly property int s: Theme.u
        readonly property int cut: width >= s * 8 && height >= s * 8 ? s * 2 : s
        Rectangle {
            x: shape.cut
            width: Math.max(0, shape.width - 2 * shape.cut)
            height: shape.s
            color: shape.fill
        }
        Rectangle {
            x: shape.s
            y: shape.s
            width: Math.max(0, shape.width - 2 * shape.s)
            height: shape.s
            color: shape.fill
        }
        Rectangle {
            y: shape.cut
            width: shape.width
            height: Math.max(0, shape.height - 2 * shape.cut)
            color: shape.fill
        }
        Rectangle {
            x: shape.s
            y: shape.height - 2 * shape.s
            width: Math.max(0, shape.width - 2 * shape.s)
            height: shape.s
            color: shape.fill
        }
        Rectangle {
            x: shape.cut
            y: shape.height - shape.s
            width: Math.max(0, shape.width - 2 * shape.cut)
            height: shape.s
            color: shape.fill
        }
    }
}
