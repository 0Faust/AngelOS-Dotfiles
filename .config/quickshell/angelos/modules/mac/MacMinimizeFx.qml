pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Minimizing as macOS does it, Genie or Scale (Config.mac.minimizeEffect): the window's snapshot
// (services/Minimize took it with grim) bends and pours into its place in the Dock (shaders/genie.vert)
// or shrinks into it; a click in the Dock plays it backwards, out to where the window goes.
// A layer over everything on the window's screen, taking no input,
// up only while something flies (Minimize.flights). The Dock writes where its items are
// (Minimize.dockSlots); the place is read each frame, so the item that appears in the Dock a
// moment after the window has gone is where the snapshot lands.
// The pixel skins use it too (Background.qml, Minimize.effect "pixel"): Scale into the taskbar's
// button (Tasks.qml writes dockSlots), on the art-pixel grid — the snapshot coarsens into a mosaic
// of art pixels as it goes (averaged down, drawn nearest: no shimmer) and steps over the grid.
// (The genie there shimmered — a whole window sampled nearest into a funnel; the owner, 28.10.)
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name
    readonly property var mine: Minimize.flights.filter(f => f.output === screenName)

    // a model that keeps its delegates: a JS array given to the Repeater makes all of them again
    // whenever a flight starts or lands, and the ones still flying start over (#130)
    onMineChanged: syncFlights()
    Component.onCompleted: syncFlights()
    function syncFlights() {
        const wanted = mine.map(f => f.key);
        for (let i = flightModel.count - 1; i >= 0; --i)
            if (!wanted.includes(flightModel.get(i).flight.key))
                flightModel.remove(i);
        const have = [];
        for (let i = 0; i < flightModel.count; ++i)
            have.push(flightModel.get(i).flight.key);
        for (const f of mine)
            if (!have.includes(f.key))
                flightModel.append({
                    "flight": f
                });
    }
    ListModel {
        id: flightModel
        dynamicRoles: true
    }

    screen: modelData
    visible: mine.length > 0
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "angelos-minimize"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Repeater {
        model: flightModel

        Item {
            id: fx
            required property var flight
            readonly property bool pixel: Minimize.effect === "pixel"
            readonly property bool genie: Minimize.effect === "genie"
            width: win.width
            height: win.height
            // where the window is, in this screen's coordinates
            readonly property var home: [flight.rect[0] - win.modelData.x, flight.rect[1] - win.modelData.y, flight.rect[2], flight.rect[3]]
            property real t: 0                 // 0 at the window .. 1 in the Dock
            property var dock: [win.width / 2, win.height - GoldenGate.px(40), GoldenGate.px(48)]
            property bool armed: false
            property bool started: false
            readonly property Image activeShot: genie ? shot : scaleShot

            // no slot (no task button there): the middle of the bar's edge
            function fallback() {
                if (pixel)
                    return [win.width / 2, Config.bar.edge === "top" ? Theme.u * 10 : win.height - Theme.u * 10, Theme.u * 16];
                return [win.width / 2, win.height - GoldenGate.px(40), GoldenGate.px(48)];
            }
            function place() {
                // Golden Gate's Dock magnifies under the pointer, so re-read its slot without
                // broadcasting slotsWanted on every frame; pixel taskbar stays put during flight
                if (GoldenGate.on)
                    dock = Minimize.slotOf(win.screenName, flight.id, false) || dock;
                if (genie)
                    return;
                const h = home, d = dock;
                // the snapshot keeps its proportions, fitted into the Dock's square at the end
                const k = Math.min(d[2] * 0.82 / h[2], d[2] * 0.82 / h[3]);
                const e = t;
                const sc = 1 + (k - 1) * e;
                const w = h[2] * sc;
                const ht = h[3] * sc;
                const x = h[0] + h[2] / 2 + (d[0] - h[0] - h[2] / 2) * e - w / 2;
                // a curve on the way, like the Dock's: it sinks faster than it moves sideways
                const ey = 1 - Math.pow(1 - e, 1.5);
                const y = h[1] + h[3] / 2 + (d[1] - h[1] - h[3] / 2) * ey - ht / 2;
                scaled.scale = sc;
                scaled.x = x;
                scaled.y = y;
            }
            function armFlight() {
                if (armed || started)
                    return;
                if (activeShot.status === Image.Error) {
                    started = true;
                    if (!flight.back)
                        Minimize.flightReady(flight.id);
                    Minimize.landed(flight.key);
                    return;
                }
                if (activeShot.status !== Image.Ready)
                    return;
                dock = Minimize.slotOf(win.screenName, flight.id, true) || fallback();
                t = flight.back ? 1 : 0;
                place();
                armed = true;
                frameFallback.restart();
            }
            function launch() {
                if (started)
                    return;
                armed = false;
                started = true;
                frameFallback.stop();
                if (!flight.back)
                    Minimize.flightReady(flight.id);
                run.from = t;
                run.to = flight.back ? 0 : 1;
                run.start();
            }
            onTChanged: if (started)
                place()
            Component.onCompleted: armFlight()

            Connections {
                target: fx.activeShot
                function onStatusChanged() {
                    fx.armFlight();
                }
            }
            // wait until the overlay surface + texture have presented their first frame so the
            // animation never skips its opening frames during Wayland surface / GPU upload
            Connections {
                target: win
                enabled: fx.armed && !fx.started
                function onFrameSwapped() {
                    fx.launch();
                }
            }
            Timer {
                id: frameFallback
                interval: 80
                onTriggered: fx.launch()
            }

            Image {
                id: shot
                source: fx.genie ? (fx.flight.shot || "") : ""
                visible: false
                asynchronous: true
                sourceSize: Qt.size(Math.min(Math.max(1, fx.home[2]), 960), Math.min(Math.max(1, fx.home[3]), 540))
                smooth: !fx.pixel
                mipmap: false
                cache: false
            }

            // Scale: the snapshot shrinks into the Dock / taskbar via pure GPU transform
            Item {
                id: scaled
                visible: !fx.genie && scaleShot.status === Image.Ready
                width: fx.home[2]
                height: fx.home[3]
                transformOrigin: Item.TopLeft
                Image {
                    id: scaleShot
                    anchors.fill: parent
                    source: fx.genie ? "" : (fx.flight.shot || "")
                    asynchronous: true
                    sourceSize: Qt.size(Math.min(Math.max(1, fx.home[2]), 960), Math.min(Math.max(1, fx.home[3]), 540))
                    fillMode: Image.Stretch
                    smooth: true
                    mipmap: false
                    cache: false
                    // gentle fade only as it lands into the taskbar button
                    opacity: fx.t > 0.75 ? Math.max(0.15, 1 - (fx.t - 0.75) * 3.4) : 1
                }
            }

            // Genie: the snapshot on a mesh bent into the Dock's icon (shaders/genie.vert)
            ShaderEffect {
                visible: fx.genie && shot.status === Image.Ready
                anchors.fill: parent
                mesh: GridMesh {
                    resolution: fx.pixel ? Qt.size(4, 20) : Qt.size(4, 64)
                }
                property variant source: shot
                property real progress: fx.t
                property vector4d win: Qt.vector4d(fx.home[0], fx.home[1], fx.home[2], fx.home[3])
                // the item's middle, its top, its size (the Dock writes centres)
                property vector4d tgt: Qt.vector4d(fx.dock[0], fx.dock[1] - fx.dock[2] / 2, fx.dock[2] * 0.82, fx.dock[2] * 0.82)
                // a target above the window's middle (a bar at the top): the funnel goes up
                property real flip: fx.pixel && fx.dock[1] < fx.home[1] + fx.home[3] / 2 ? 1 : 0
                property real screenH: win.height
                // the shell's art pixel: the funnel's edges step on the skins' own grid
                property real snap: fx.pixel ? Theme.u : 0
                vertexShader: Qt.resolvedUrl("../../shaders/genie.vert.qsb")
                fragmentShader: Qt.resolvedUrl("../../shaders/genie.frag.qsb")
            }

            NumberAnimation {
                id: run
                target: fx
                property: "t"
                duration: Minimize.flightMs
                // Genie: even, as macOS pours it; Scale: instant response, smooth settle
                easing.type: fx.genie ? Easing.InOutSine : Easing.OutCubic
                onFinished: Minimize.landed(fx.flight.key)
            }
        }
    }

    RightClickGuard {}
}
