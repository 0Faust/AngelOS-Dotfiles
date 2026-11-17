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
    // A small trough or key cannot give up five pixels of padding on each side.
    readonly property int relicInset: Math.min(5, Math.max(1, Math.floor(Math.min(width, height) / (Theme.u * 4)))) * Theme.u
    readonly property int inset: relic ? (outline ? relicInset : Theme.u) : ob + (flat ? 0 : bevel)
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
    Rectangle {
        visible: root.relic && !root.outline
        anchors.fill: parent
        color: root.color
    }
    Rectangle {
        visible: !root.flat && !root.relic
        x: root.ob
        y: root.ob
        width: root.width - 2 * root.ob
        height: root.bevel
        color: root.sunken ? root.loColor : root.hiColor
    }
    Rectangle {
        visible: !root.flat && !root.relic
        x: root.ob
        y: root.ob
        width: root.bevel
        height: root.height - 2 * root.ob
        color: root.sunken ? root.loColor : root.hiColor
    }
    Rectangle {
        visible: !root.flat && !root.relic
        x: root.ob + root.bevel
        y: root.height - root.ob - root.bevel
        width: root.width - 2 * root.ob - root.bevel
        height: root.bevel
        color: root.sunken ? root.hiColor : root.loColor
    }
    Rectangle {
        visible: !root.flat && !root.relic
        x: root.width - root.ob - root.bevel
        y: root.ob + root.bevel
        width: root.bevel
        height: root.height - 2 * root.ob - root.bevel
        color: root.sunken ? root.hiColor : root.loColor
    }

    // Three nested, stepped silhouettes: dark wrought-iron cut, gilt thread, bronze bevel.
    // All geometry sits on Theme.u and stays still when the desktop is idle.
    RelicShape {
        visible: root.relic && root.outline
        anchors.fill: parent
        fill: root.edgeColor
    }
    RelicShape {
        visible: root.relic && root.outline
        x: Theme.u
        y: Theme.u
        width: Math.max(0, root.width - 2 * Theme.u)
        height: Math.max(0, root.height - 2 * Theme.u)
        fill: Theme.relicGold
    }
    RelicShape {
        visible: root.relic && root.outline
        x: Theme.u * 2
        y: Theme.u * 2
        width: Math.max(0, root.width - 4 * Theme.u)
        height: Math.max(0, root.height - 4 * Theme.u)
        fill: root.sunken ? root.loColor : root.hiColor
    }
    RelicShape {
        visible: root.relic && root.outline
        x: Theme.u * 3
        y: Theme.u * 3
        width: Math.max(0, root.width - 6 * Theme.u)
        height: Math.max(0, root.height - 6 * Theme.u)
        fill: root.color
    }
    Repeater {
        model: root.relic && root.outline && root.width >= Theme.u * 24 && root.height >= Theme.u * 20 ? 4 : 0
        Item {
            required property int index
            readonly property int s: Theme.u
            x: index % 2 ? root.width - s * 5 : s * 2
            y: index >= 2 ? root.height - s * 5 : s * 2
            width: s * 3
            height: s * 3
            Rectangle { x: Theme.u; width: Theme.u; height: parent.height; color: Theme.relicGold }
            Rectangle { y: Theme.u; width: parent.width; height: Theme.u; color: Theme.relicGold }
            Rectangle { x: Theme.u; y: Theme.u; width: Theme.u; height: Theme.u; color: Theme.relicDark ? "#efe4d4" : "#3a2622" }
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
