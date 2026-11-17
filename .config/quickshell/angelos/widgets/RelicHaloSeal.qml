import QtQuick
import qs.config

// Static pixel-only sunburst, concentric red reliquary and central gilded cross.
// No timers, Canvas, smoothing or mouse handlers: Halo retains its original actions.
Item {
    id: root
    property int pixel: Math.max(1, Theme.u)
    readonly property int s: Math.max(1, pixel)
    implicitWidth: 70 * s
    implicitHeight: 70 * s
    width: implicitWidth
    height: implicitHeight
    readonly property color bronze: Theme.relicDark ? "#b67a30" : "#86601e"
    readonly property color gold: Theme.relicGold
    readonly property color crimson: Theme.relicCrimson
    readonly property real p: sealCross.pulse
    readonly property color liveGold: Theme.mix(gold, Theme.relicDark ? "#ffe39e" : "#d99d30", p * 0.6)
    readonly property color liveBronze: Theme.mix(bronze, gold, p * 0.45)
    readonly property color liveCrimson: Theme.mix(crimson, Theme.relicDark ? "#df4959" : "#c93848", p * 0.45)

    // Pure pixel-aligned cardinal and diagonal sunburst spikes (no rotation anti-aliasing).
    Rectangle { x: 34 * root.s; y: 0; width: 2 * root.s; height: 9 * root.s; color: root.liveGold }
    Rectangle { x: 34 * root.s; y: 61 * root.s; width: 2 * root.s; height: 9 * root.s; color: root.liveGold }
    Rectangle { x: 0; y: 34 * root.s; width: 9 * root.s; height: 2 * root.s; color: root.liveGold }
    Rectangle { x: 61 * root.s; y: 34 * root.s; width: 9 * root.s; height: 2 * root.s; color: root.liveGold }
    Repeater {
        model: 4
        Item {
            required property int index
            readonly property int dx: index % 2 === 0 ? -1 : 1
            readonly property int dy: index < 2 ? -1 : 1
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    x: (35 + parent.dx * (21 + index) - (parent.dx < 0 ? 2 : 0)) * root.s
                    y: (35 + parent.dy * (21 + index) - (parent.dy < 0 ? 2 : 0)) * root.s
                    width: 2 * root.s
                    height: 2 * root.s
                    color: root.liveGold
                }
            }
        }
    }
    // The circles are drawn column-by-column with integer square-root steps.
    // Two separate rings make a dark seam between red and gold.
    Repeater {
        model: 54
        Item {
            required property int index
            readonly property int xx: index - 27
            readonly property int dyOuter: Math.floor(Math.sqrt(Math.max(0, 27 * 27 - xx * xx)))
            readonly property int dyInner: Math.floor(Math.sqrt(Math.max(0, 24 * 24 - xx * xx)))
            readonly property int dyRed: Math.floor(Math.sqrt(Math.max(0, 21 * 21 - xx * xx)))
            x: (index + 8) * root.s
            Rectangle {
                y: (35 - dyOuter) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveBronze
            }
            Rectangle {
                y: (35 + dyOuter - 2) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveBronze
            }
            Rectangle {
                y: (35 - dyInner) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveGold
            }
            Rectangle {
                y: (35 + dyInner - 2) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveGold
            }
            Rectangle {
                y: (35 - dyRed) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveCrimson
            }
            Rectangle {
                y: (35 + dyRed - 2) * root.s
                width: root.s
                height: root.s * 2
                color: root.liveCrimson
            }
        }
    }
    Repeater {
        model: 36
        Item {
            required property int index
            readonly property int dy: index - 18
            readonly property int dx: Math.floor(Math.sqrt(Math.max(0, 18 * 18 - dy * dy)))
            x: (35 - dx) * root.s
            y: (17 + index) * root.s
            Rectangle {
                width: Math.max(root.s, 2 * dx * root.s)
                height: root.s
                color: Theme.relicDark ? "#31131d" : "#e9d5b8"
            }
        }
    }
    RelicCross {
        id: sealCross
        anchors.centerIn: parent
        pixel: root.s
        animated: true
        gilt: Theme.relicDark ? "#f4e6cf" : "#3a2622"
        glow: Theme.relicDark ? "#fff8ef" : "#b07a22"
    }
}
