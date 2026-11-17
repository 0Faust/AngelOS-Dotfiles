import QtQuick
import qs.config

// The Relic's resting Halo: a reliquary plaque, not a pill. Its ends are stepped points
// (a banner's tips) drawn column by column in whole art pixels; a second gilded hairline
// and a rivet at each corner keep the double frame of the Sanctum reference. Decoration
// only: no timers, no input, nothing that the Halo's own gestures could collide with.
Item {
    id: root

    property color color: Theme.faceAlt
    property color edge: Theme.relicGold
    property color hairline: Qt.alpha(Theme.relicGold, 0.55)
    // how far each tip reaches from the straight body, in screen pixels
    property int tip: Theme.u * 7
    readonly property int u: Theme.u

    readonly property int rows: Math.max(1, Math.ceil(height / u))
    readonly property real bodyX: Math.min(tip, Math.max(0, width / 2 - u))
    readonly property real bodyW: Math.max(0, width - bodyX * 2)
    // inlay of the gilded frame: the edge's own thickness
    readonly property real inlay: Math.min(u, Math.max(1, Math.round(bodyW / 2)))

    // the silhouette: rows widen toward mid-height, so both ends come to a point
    Repeater {
        model: root.rows
        Item {
            id: row
            required property int index
            readonly property real y0: index * root.u
            readonly property real h: Math.min(root.u, Math.max(0, root.height - y0))
            // 0 at the top and bottom, the full tip at mid-height
            readonly property real ext: {
                if (root.height <= 0)
                    return 0;
                const mid = root.height / 2;
                const d = Math.abs(y0 + h / 2 - mid) / mid;
                return Math.max(0, Math.round(root.tip * (1 - d) / root.u) * root.u);
            }
            readonly property real x0: Math.max(0, root.bodyX - ext)
            readonly property real w: Math.min(root.width - x0, root.bodyW + ext * 2)
            Rectangle {
                x: row.x0
                y: row.y0
                width: row.w
                height: row.h
                color: root.edge
            }
            // the face, one art pixel inside the frame
            Rectangle {
                visible: row.index > 0 && row.index < root.rows - 1
                x: row.x0 + root.inlay
                y: row.y0
                width: Math.max(0, row.w - root.inlay * 2)
                height: row.h
                color: root.color
            }
        }
    }

    // the second gilding: a hairline inside the body
    Item {
        visible: root.width > root.u * 12 && root.height > root.u * 10
        Rectangle {
            x: root.bodyX + root.u * 2
            y: root.u * 2
            width: Math.max(0, root.bodyW - root.u * 4)
            height: root.u
            color: root.hairline
        }
        Rectangle {
            x: root.bodyX + root.u * 2
            y: root.height - root.u * 3
            width: Math.max(0, root.bodyW - root.u * 4)
            height: root.u
            color: root.hairline
        }
        Rectangle {
            x: root.bodyX + root.u * 2
            y: root.u * 2
            width: root.u
            height: Math.max(0, root.height - root.u * 5)
            color: root.hairline
        }
        Rectangle {
            x: root.bodyX + root.bodyW - root.u * 3
            y: root.u * 2
            width: root.u
            height: Math.max(0, root.height - root.u * 5)
            color: root.hairline
        }
    }

    // a rivet at each corner of the hairline
    component Rivet: Item {
        width: root.u * 3
        height: root.u * 3
        Rectangle {
            anchors.fill: parent
            color: root.edge
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.u
            height: root.u
            color: Theme.relicCrimson
        }
    }
    Rivet {
        x: root.bodyX + root.u
        y: root.u
    }
    Rivet {
        x: root.bodyX + root.bodyW - root.u * 4
        y: root.u
    }
    Rivet {
        x: root.bodyX + root.u
        y: root.height - root.u * 4
    }
    Rivet {
        x: root.bodyX + root.bodyW - root.u * 4
        y: root.height - root.u * 4
    }
}
