import QtQuick
import qs.config

// All strokes are whole art pixels. Used by the Relic launcher, windows and Settings.
// It is purely decorative: the host owns mouse and accessibility actions.
Item {
    id: root
    property int pixel: Math.max(1, Theme.u)
    property color gilt: Theme.relicGold
    property color glow: Theme.relicDark ? "#ffe1a0" : "#f5dfaa"
    property color shade: Theme.relicCrimson
    property bool animated: false
    property real pulse: 0
    readonly property int s: Math.max(1, pixel)
    implicitWidth: s * 20
    implicitHeight: s * 20
    width: implicitWidth
    height: implicitHeight

    // Stepped ~5.5 Hz pixel-art breathing (avoids 60fps scene-graph churn & Theme.mix allocations).
    Timer {
        id: pulseTimer
        property int step: 0
        readonly property var curve: [0.0, 0.15, 0.38, 0.68, 0.9, 1.0, 0.9, 0.68, 0.38, 0.15]
        interval: 180
        repeat: true
        running: root.animated && root.visible && !Motion.still
        onTriggered: {
            step = (step + 1) % curve.length;
            root.pulse = curve[step];
        }
        onRunningChanged: if (!running) {
            step = 0;
            root.pulse = 0;
        }
    }

    Rectangle { x: root.s * 8; y: root.s * 2; width: root.s * 4; height: root.s * 16; color: root.shade }
    Rectangle { x: root.s * 3; y: root.s * 7; width: root.s * 14; height: root.s * 4; color: root.shade }
    Rectangle { x: root.s * 9; y: 0; width: root.s * 2; height: root.s * 19; color: root.gilt }
    Rectangle { x: root.s; y: root.s * 8; width: root.s * 18; height: root.s * 2; color: root.gilt }
    Rectangle { x: root.s * 8; y: root.s * 2; width: root.s * 4; height: root.s; color: root.glow }
    Rectangle { x: root.s * 7; y: root.s * 5; width: root.s * 6; height: root.s; color: root.gilt }
    Rectangle { x: root.s * 8; y: root.s * 14; width: root.s * 4; height: root.s; color: root.gilt }
    Rectangle { x: root.s * 3; y: root.s * 7; width: root.s; height: root.s * 4; color: root.gilt }
    Rectangle { x: root.s * 16; y: root.s * 7; width: root.s; height: root.s * 4; color: root.gilt }
    // Sacred core gem at the cross intersection
    Rectangle {
        visible: root.animated
        x: root.s * 9
        y: root.s * 8
        width: root.s * 2
        height: root.s * 2
        color: root.glow
        opacity: 0.45 + root.pulse * 0.55
    }
    // Four stepped corner sparks, visible on the 40–60px launcher but still crisp at 20px.
    Repeater {
        model: 4
        Rectangle {
            required property int index
            x: (index % 2 ? 15 : 3) * root.s
            y: (index >= 2 ? 15 : 3) * root.s
            width: root.s
            height: root.s
            color: root.glow
            opacity: root.animated ? 0.55 + root.pulse * 0.45 : 1
        }
    }
}
