import QtQuick
import qs.config

// NGO-style window: bevelled frame, gradient title bar, pixel buttons.
// `hell` (Theme.realm, desktop widgets): the circle's dark frame, a blackletter title, and
// on its edges what the circle did to them (HellEdge: burnt, rimed, rusted…), still — now
// and then one slow thing happens there (HellAmbient).
Item {
    id: root
    Accessible.role: Accessible.Pane
    Accessible.name: title

    property bool hell: false
    // the settings skins (Config.settingsUi.skin): "" / classic, windose (a candy NGO window:
    // pink rim, ink outline, white buttons) or stream (a broadcast panel with a LIVE pill)
    property string skin: Config.settingsUi.skin === "windose" ? "windose" : ""
    readonly property bool windose: skin === "windose" && !hell
    readonly property bool streamSkin: skin === "stream" && !hell
    readonly property bool relic: Theme.relic && !hell && !windose && !streamSkin
    readonly property string settingsSkin: windose ? "windose" : streamSkin ? "stream" : "classic"
    // the window by day: the title a solid plate, a rule of the outline's colour under it
    readonly property bool zine: Theme.zine && !hell && !windose && !streamSkin
    property bool flamesLive: true         // (kept for plugins: hell's rim is still now, HellAmbient moves it)
    property bool trim: true               // hell's rim (a copy drawn over its twin leaves it to it)
    // the desktop widgets' gilded plate in the Relic skin: the host opts in, so the shell's other
    // windows (Settings included) keep their own chrome
    property bool relicPlate: false
    readonly property bool gilded: root.relic && root.relicPlate

    property string title: ""
    property string icon: "heart"
    property bool closable: true
    property bool minimizable: false
    property bool maximizable: false
    property bool translucent: true
    property bool compact: false
    property bool decor: true
    property bool titleRow: true           // false: the bar is bare, the host draws its own (the Halo)
    property bool active: true
    property bool shadow: Config.appearance.shadows
    property url relicFrameSource: ""
    property color bodyColor: translucent ? Theme.panel : Theme.face
    property int bodyPadding: Theme.pad
    readonly property int titleHeight: hell ? Theme.hellPx(Theme.fs) + Theme.u * 3 : compact ? Theme.sizeBody + Theme.u * 5 : Theme.sizeTitle + Theme.u * 5
    readonly property int chrome: frame.inset + Theme.u + ornatePad
    readonly property int ornatePad: ornateFrame.visible ? Theme.u * 8 : 0
    property alias titleBar: bar
    property alias titleMouse: titleMouse
    property alias bodyItem: body          // where the content goes (a host may put it there itself)
    default property alias content: body.data

    signal closeClicked
    signal minimizeClicked
    signal maximizeClicked
    signal titlePressed(var mouse)

    PxBox {
        id: frame
        visible: !widgetFrame9Slice.visible
        anchors.fill: parent
        prominent: root.active && !root.compact
        outline: !ornateFrame.visible
        hell: root.hell
        color: root.windose ? Theme.windosePaper : root.streamSkin ? Theme.streamBg : root.hell && root.bodyColor.a > 0 ? Theme.hellPanel : root.bodyColor
        edgeColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellEdge : Theme.edge
        hiColor: root.windose ? Theme.mix(Theme.windosePaper, Theme.text, 0.15) : root.hell ? Theme.hellHi : Theme.hi
        loColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellLo : Theme.lo
        shadow: root.shadow
        shadowColor: root.hell ? Qt.alpha(Theme.shadow, Theme.shadowAlpha) : Theme.popShadow
    }
    // Relic / Sanctum 2.0: forged 9-slice frame for compact widgets & HaloWindow
    BorderImage {
        id: widgetFrame9Slice
        visible: root.relic && root.compact && !ornateFrame.visible
        anchors.fill: parent
        source: visible ? (root.relicFrameSource.toString() !== "" ? root.relicFrameSource : Qt.resolvedUrl("../assets/relic/widget_frame_9slice_96x96.png")) : ""
        border { left: 32; right: 32; top: 32; bottom: 32 }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: false
        asynchronous: true
    }
    // Relic: ornate 9-slice forged frame on large windows (Settings, etc.) around inset bar & body
    BorderImage {
        id: ornateFrame
        visible: root.relic && !root.compact && root.width >= Theme.u * 200
        anchors.fill: parent
        z: 3
        source: visible ? Qt.resolvedUrl("../assets/relic/sanctum-frame.png") : ""
        border { left: 32; right: 32; top: 32; bottom: 32 }
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        smooth: false
        asynchronous: true
    }

    Rectangle {
        id: bar
        x: frame.inset + Theme.u * (root.gilded ? 4 : 1) + root.ornatePad
        y: frame.inset + Theme.u * (root.gilded ? 4 : 1) + root.ornatePad
        width: root.width - 2 * x
        height: root.titleHeight
        color: widgetFrame9Slice.visible ? "transparent" : root.windose ? Theme.windoseRose : root.streamSkin ? Theme.streamPanel : root.hell ? (root.active ? Theme.mix(Theme.hellFaceAlt, Theme.hellRim, 0.25) : Theme.hellFace) : root.relic ? (root.active ? (Theme.relicDark ? Theme.mix(Theme.faceAlt, Theme.relicCrimson, 0.22) : Theme.mix(Theme.faceAlt, Theme.relicGold, 0.22)) : Theme.face) : root.active ? (root.zine ? Theme.title1 : Theme.menuHeader) : Theme.faceAlt
        // Windose: the candy gradient from pink to lilac
        gradient: root.windose ? candy : null
        Gradient {
            id: candy
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: Theme.windoseRose
            }
            GradientStop {
                position: 1
                color: Theme.windoseLavender
            }
        }

        MouseArea {
            id: titleMouse
            anchors.fill: parent
            onPressed: m => root.titlePressed(m)
        }

        Row {
            visible: root.titleRow
            anchors.left: parent.left
            anchors.leftMargin: Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3

            PxIcon {
                visible: !root.relic
                name: root.icon
                anchors.verticalCenter: parent.verticalCenter
                ink: root.hell ? Theme.hellEdge : root.windose ? Theme.windoseInk : Theme.edge
                fill: root.hell ? Theme.hellTextDim : root.windose ? Theme.windoseSticker : "#ffffff"
                light: root.hell ? Theme.hellText : root.windose ? Theme.windoseLavender : Theme.accent3
                fill2: root.hell ? Theme.hellRim : root.windose ? Theme.windoseRose : "#ffffff"
                body: root.hell ? Theme.hellFace : root.windose ? Theme.windoseSticker : "#ffffff"
                bad: root.hell ? Theme.hellAccent : Theme.danger
            }
            // Relic / Sanctum 2.0: forged gothic cross in every window and widget header.
            Image {
                visible: root.relic
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 18
                source: visible ? Qt.resolvedUrl("../assets/relic/sanctum_header_cross_16x18.png") : ""
                smooth: false
                mipmap: false
                fillMode: Image.Pad
            }
            // stream: the red LIVE pill before the title
            Rectangle {
                visible: root.streamSkin
                anchors.verticalCenter: parent.verticalCenter
                width: liveLabel.implicitWidth + Theme.u * 6
                height: liveLabel.implicitHeight + Theme.u
                radius: height / 2
                color: Theme.streamLive
                PxText {
                    id: liveLabel
                    anchors.centerIn: parent
                    text: "● LIVE"
                    kind: "tiny"
                    font.bold: true
                    color: Theme.selectText
                }
            }
            PxText {
                text: root.title
                kind: root.compact ? "body" : "title"
                readonly property bool relicTitle: root.gilded && Theme.hellCovers(root.title)
                readonly property bool gothic: (root.hell || relicTitle) && Theme.latin(root.title)
                font.family: gothic ? Theme.fontHell : root.compact ? Theme.fontBody : Theme.fontTitle
                font.pixelSize: gothic ? Theme.hellPx(Theme.fs) : root.compact ? Theme.sizeBody : Theme.sizeTitle
                font.bold: root.windose
                antialiasing: relicTitle ? false : !(fractional && !script && !mac)
                renderType: relicTitle ? Text.NativeRendering : script || mac || zoomed ? Text.QtRendering : Text.NativeRendering
                color: root.windose ? Theme.text : root.streamSkin ? Theme.streamText : root.hell ? Theme.hellText : root.zine && root.active ? Theme.titleText : Theme.text
                style: Text.Normal
                styleColor: Qt.alpha(Theme.edge, 0.55)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, bar.width - buttons.width - Theme.u * 30)
                elide: Text.ElideRight
            }
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2

            Row {
                visible: root.decor && !root.compact && !root.relic
                spacing: Theme.u
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: Theme.u * 3
                PxIcon {
                    name: "heartSmall"
                    fill: "#ffffff"
                    ink: Qt.alpha(Theme.edge, 0.7)
                    anchors.verticalCenter: parent.verticalCenter
                }
                PxIcon {
                    name: "sparkle"
                    fill: "#ffffff"
                    light: Theme.accent3
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Repeater {
                model: [
                    {
                        id: "min",
                        icon: "minimize",
                        show: root.minimizable
                    },
                    {
                        id: "max",
                        icon: "maximize",
                        show: root.maximizable
                    },
                    {
                        id: "close",
                        icon: "close",
                        show: root.closable
                    }
                ]
                delegate: Item {
                    id: tb
                    required property var modelData
                    visible: modelData.show
                    width: root.titleHeight - Theme.u * 4
                    height: width
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    PxBox {
                        anchors.fill: parent
                        sunken: tbMouse.pressed
                        hell: root.hell
                        edgeColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellEdge : root.relic && (tb.modelData.id === "close" || tbMouse.containsMouse) ? Theme.relicGold : Theme.edge
                        color: root.relic && tb.modelData.id === "close" ? (tbMouse.containsMouse ? Qt.lighter(Theme.relicCrimson, 1.15) : Theme.relicCrimson) : tbMouse.containsMouse && tb.modelData.id === "close" ? (root.hell ? Theme.hellBlood : Theme.danger) : root.windose ? Theme.windoseSticker : root.streamSkin ? Theme.streamBg : root.hell ? Theme.hellFace : Theme.face
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: tbMouse.pressed ? Theme.u : 0
                        name: tb.modelData.icon
                        pixel: Math.max(1, Math.floor(Theme.u * (root.compact ? 0.5 : 1)))
                        ink: (root.relic && tb.modelData.id === "close") || (tbMouse.containsMouse && tb.modelData.id === "close") ? "#ffffff" : root.windose ? Theme.windoseInk : root.streamSkin ? Theme.streamText : root.hell ? Theme.hellText : (Theme.dark ? Theme.text : Theme.edge)
                    }
                    MouseArea {
                        id: tbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tb.modelData.id === "close")
                                root.closeClicked();
                            else if (tb.modelData.id === "min")
                                root.minimizeClicked();
                            else
                                root.maximizeClicked();
                        }
                    }
                }
            }
        }
    }

    // A single gilded rule below the title, with a carmine reliquary seal at its centre.
    Item {
        visible: root.relic && root.titleRow && root.width >= Theme.u * 48
        x: bar.x + Theme.u * 3
        y: bar.y + bar.height - Theme.u
        width: bar.width - Theme.u * 6
        height: Theme.u
        Rectangle { anchors.fill: parent; color: Theme.relicGold }
        Rectangle {
            anchors.centerIn: parent
            width: Theme.u * 5
            height: Theme.u
            color: Theme.relicCrimson
        }
    }

    // the Relic's second gilding: a hairline inside the frame, a rivet at each corner, and the
    // title's closing cross — the reference's plate. Decoration only: no input, no geometry.
    Item {
        id: relicTrim
        visible: root.gilded && !widgetFrame9Slice.visible
        anchors.fill: parent
        z: 2
        readonly property int u: Theme.u
        readonly property color ink: Qt.alpha(Theme.relicGold, 0.75)
        Rectangle {
            x: relicTrim.u * 2
            y: relicTrim.u * 2
            width: Math.max(0, root.width - relicTrim.u * 4)
            height: relicTrim.u
            color: relicTrim.ink
        }
        Rectangle {
            x: relicTrim.u * 2
            y: Math.max(0, root.height - relicTrim.u * 3)
            width: Math.max(0, root.width - relicTrim.u * 4)
            height: relicTrim.u
            color: relicTrim.ink
        }
        Rectangle {
            x: relicTrim.u * 2
            y: relicTrim.u * 2
            width: relicTrim.u
            height: Math.max(0, root.height - relicTrim.u * 4)
            color: relicTrim.ink
        }
        Rectangle {
            x: Math.max(0, root.width - relicTrim.u * 3)
            y: relicTrim.u * 2
            width: relicTrim.u
            height: Math.max(0, root.height - relicTrim.u * 4)
            color: relicTrim.ink
        }
        component TrimRivet: Item {
            width: relicTrim.u * 3
            height: relicTrim.u * 3
            Rectangle {
                anchors.fill: parent
                color: Theme.relicGold
            }
            Rectangle {
                anchors.centerIn: parent
                width: relicTrim.u
                height: relicTrim.u
                color: Theme.relicCrimson
            }
        }
        TrimRivet {
            x: relicTrim.u * 2
            y: relicTrim.u * 2
        }
        TrimRivet {
            x: Math.max(0, root.width - relicTrim.u * 5)
            y: relicTrim.u * 2
        }
        TrimRivet {
            x: relicTrim.u * 2
            y: Math.max(0, root.height - relicTrim.u * 5)
        }
        TrimRivet {
            x: Math.max(0, root.width - relicTrim.u * 5)
            y: Math.max(0, root.height - relicTrim.u * 5)
        }
    }

    // Relic: flourish closes the title bar's right end when not closable
    Image {
        visible: root.relic && root.titleRow && !root.closable
        z: 2
        width: 18
        height: 18
        x: bar.x + bar.width - width - Theme.u * 3
        y: bar.y + Math.round((bar.height - height) / 2)
        source: visible ? Qt.resolvedUrl("../assets/relic/sanctum_header_flourish_18x18.png") : ""
        smooth: false
        mipmap: false
        fillMode: Image.Pad
    }

    Rectangle {
        visible: root.zine
        x: frame.inset
        y: bar.y + bar.height + Theme.u
        width: root.width - 2 * x
        height: Theme.u
        color: Theme.edge
    }

    // Relic: subtle gothic damask texture inside compact widget windows
    Image {
        visible: root.relic && !ornateFrame.visible && root.width >= Theme.u * 40 && root.height >= Theme.u * 30
        x: frame.inset + Theme.u
        y: bar.y + bar.height
        width: Math.max(0, root.width - (frame.inset + Theme.u) * 2)
        height: Math.max(0, root.height - y - frame.inset - Theme.u)
        source: visible ? Qt.resolvedUrl("../assets/relic/sanctum_damask_64x64.png") : ""
        fillMode: Image.Tile
        opacity: Theme.relicDark ? 0.55 : 0.08
        smooth: false
        asynchronous: true
    }

    Item {
        id: body
        anchors {
            top: bar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: root.bodyPadding
            leftMargin: frame.inset + root.bodyPadding + root.ornatePad
            rightMargin: frame.inset + root.bodyPadding + root.ornatePad
            bottomMargin: frame.inset + root.bodyPadding + root.ornatePad
        }
    }

    WindoseDecor {
        visible: root.windose && !root.compact && root.width >= Theme.u * 180 && root.height >= Theme.u * 110
        x: bar.x + Theme.u
        y: bar.y + bar.height + Theme.u
        width: bar.width - Theme.u * 2
        height: root.height - y - frame.inset - Theme.u
        z: 2
    }

    // ---- hell's rim: over the frame and the title, no input ----
    HellEdge {
        visible: root.hell && root.trim
        anchors.fill: parent
        z: 3
        seed: (root.title.length * 7 + root.title.charCodeAt(0)) || 1
    }
}
