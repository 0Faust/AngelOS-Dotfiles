import QtQuick
import qs.config

// Cached pixel-only sunburst, concentric red reliquary and central gilded cross.
// Painted once per palette/scale change into an offscreen Canvas image (0% idle CPU).
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
    readonly property color interior: Theme.relicDark ? "#31131d" : "#e9d5b8"

    onSChanged: sealCanvas.requestPaint()
    onBronzeChanged: sealCanvas.requestPaint()
    onGoldChanged: sealCanvas.requestPaint()
    onCrimsonChanged: sealCanvas.requestPaint()
    onInteriorChanged: sealCanvas.requestPaint()

    Canvas {
        id: sealCanvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        antialiasing: false
        smooth: false
        onPaint: {
            const ctx = getContext("2d");
            const s = root.s;
            ctx.clearRect(0, 0, width, height);

            // Cardinal and diagonal sunburst spikes
            ctx.fillStyle = root.gold.toString();
            ctx.fillRect(34 * s, 0, 2 * s, 9 * s);
            ctx.fillRect(34 * s, 61 * s, 2 * s, 9 * s);
            ctx.fillRect(0, 34 * s, 9 * s, 2 * s);
            ctx.fillRect(61 * s, 34 * s, 9 * s, 2 * s);
            for (let q = 0; q < 4; q++) {
                const dx = q % 2 === 0 ? -1 : 1;
                const dy = q < 2 ? -1 : 1;
                for (let i = 0; i < 5; i++) {
                    const rx = (35 + dx * (21 + i) - (dx < 0 ? 2 : 0)) * s;
                    const ry = (35 + dy * (21 + i) - (dy < 0 ? 2 : 0)) * s;
                    ctx.fillRect(rx, ry, 2 * s, 2 * s);
                }
            }

            // Concentric rings (bronze outer, gold inner, crimson seal)
            for (let i = 0; i < 54; i++) {
                const xx = i - 27;
                const x = (i + 8) * s;
                const dyOuter = Math.floor(Math.sqrt(Math.max(0, 27 * 27 - xx * xx)));
                const dyInner = Math.floor(Math.sqrt(Math.max(0, 24 * 24 - xx * xx)));
                const dyRed = Math.floor(Math.sqrt(Math.max(0, 21 * 21 - xx * xx)));

                ctx.fillStyle = root.bronze.toString();
                ctx.fillRect(x, (35 - dyOuter) * s, s, 2 * s);
                ctx.fillRect(x, (35 + dyOuter - 2) * s, s, 2 * s);

                ctx.fillStyle = root.gold.toString();
                ctx.fillRect(x, (35 - dyInner) * s, s, 2 * s);
                ctx.fillRect(x, (35 + dyInner - 2) * s, s, 2 * s);

                ctx.fillStyle = root.crimson.toString();
                ctx.fillRect(x, (35 - dyRed) * s, s, 2 * s);
                ctx.fillRect(x, (35 + dyRed - 2) * s, s, 2 * s);
            }

            // Interior disc
            ctx.fillStyle = root.interior.toString();
            for (let i = 0; i < 36; i++) {
                const dy = i - 18;
                const dx = Math.floor(Math.sqrt(Math.max(0, 18 * 18 - dy * dy)));
                ctx.fillRect((35 - dx) * s, (17 + i) * s, Math.max(s, 2 * dx * s), s);
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
