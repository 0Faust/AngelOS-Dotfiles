pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

// One level of a pixel menu (PxMenu's own, a PxMenuSub's): the frame (services/MenuLook), an
// optional title, the everyday actions as signed icons in a row (`quick`, the menu's own level
// only), the rows of `items`, room for a menu's own parts on top (`header`) and below (`footer`)
// the rows, and the keyboard — the same in every menu: ↑↓ go round (↑ from the first row into
// the icons, ←→ along them), → opens a submenu (the tray's), ← goes back, ←→ on a row of
// choices picks one, Enter/Space choose, Esc closes this level, a letter jumps to the next entry
// starting with it. Rows taller than `maxHeight` scroll.
Item {
    id: list

    property var menu: null                 // the PxMenu it belongs to
    property int level: 0                   // 0: the menu itself, 1… its submenus
    property var items: []                  // see PxMenu for the entry schema
    property var quick: []                  // the row of icons over the list (same schema)
    property real tileScale: 1              // their size (Settings → Right-click menu → Size)
    property int qcurrent: -1               // the keyboard's icon in that row (-1: on the rows)
    property string title: ""
    property string look: "classic"
    // what PxMenuItems inside take their colours from (MenuLook.tokensFor), plugins' rows too
    readonly property var menuTokens: MenuLook.tokens(look)
    readonly property var t: menuTokens
    // serp-skin: the rows' PxText in the skin's font and sizes (its mac branch); as before otherwise
    readonly property string settingsSkin: Serp.on ? "goldengate" : Theme.settingsSkinFor(list.parent)
    property int minWidth: MenuLook.minWidth
    property int maxWidth: MenuLook.maxWidth
    property int maxHeight: 0               // the level's height at most (0: no limit): its rows scroll
    property bool icons: true
    property int current: -1                // the lit entry: the keyboard's, or the one under the pointer
    property alias header: headCol.data
    property alias footer: footCol.data
    readonly property alias frame: frame

    width: frame.width
    height: frame.height
    focus: true
    // entries swapped while open (a menu whose entries come late, the tray's): the lit one stays lit
    property var shown: []
    onItemsChanged: {
        const was = current >= 0 ? shown[current] : null;
        shown = items;
        current = was ? find(was) : -1;
    }
    // where entry `e` is now: the same object, else the first with its label (-1: gone)
    function find(e) {
        const n = items ? items.length : 0;
        for (let i = 0; i < n; i++)
            if (items[i] === e)
                return i;
        const l = e && !e.separator ? String(e.label || "") : "";
        for (let i = 0; l !== "" && i < n; i++)
            if (!items[i].separator && String(items[i].label || "") === l)
                return i;
        return -1;
    }
    // the keyboard's entry scrolled into view
    function select(i) {
        current = i;
        const r = rows.itemAt(i), f = scroll.flick;
        if (!r || !scroll.overflows)
            return;
        if (r.y < f.contentY)
            f.contentY = r.y;
        else if (r.y + r.height > f.contentY + f.height)
            f.contentY = r.y + r.height - f.height;
    }

    function need(c) {
        return c.visible === false ? 0 : c.implicitWidth || 0;
    }
    function rowAt(i) {
        return rows.itemAt(i);
    }
    function usable(i) {
        const it = items[i], r = rows.itemAt(i);
        return !!it && !it.separator && MenuLook.on(it.enabled, true) && !!r && r.visible;
    }
    // the next usable entry from `current` (none: from the top or the bottom), round
    function step(dir) {
        const n = items.length;
        let i = current < 0 ? (dir > 0 ? -1 : n) : current;
        for (let k = 0; k < n; k++) {
            i = ((i + dir) % n + n) % n;
            if (usable(i))
                return i;
        }
        return current;
    }
    function jump(ch) {
        const n = items.length, c = String(ch).toLowerCase();
        for (let k = 1; k <= n; k++) {
            const i = ((current + k) % n + n) % n;
            if (usable(i) && String(items[i].label || "").trim().toLowerCase().startsWith(c))
                return i;
        }
        return -1;
    }

    // the first usable row: ↑ from it goes up into the icons
    function first() {
        for (let i = 0; i < items.length; i++)
            if (usable(i))
                return i;
        return -1;
    }
    function choicesAt(i) {
        const it = items[i];
        return it && it.choices ? Array.from(it.choices) : [];
    }
    Keys.onPressed: e => {
        if (!menu)
            return;
        const k = e.key;
        e.accepted = true;
        // in the row of icons
        if (qcurrent >= 0) {
            if (k === Qt.Key_Left || k === Qt.Key_Right)
                qcurrent = (qcurrent + (k === Qt.Key_Right ? 1 : -1) + quick.length) % quick.length;
            else if (k === Qt.Key_Down) {
                const r = quickRow.rowOf(qcurrent);
                if (r + 1 < quickRow.rowCount) {
                    const c = quickRow.colOf(qcurrent);
                    const nextCols = quickRow.colsInRow(r + 1);
                    qcurrent = quickRow.rowStart(r + 1) + Math.min(c, nextCols - 1);
                } else {
                    qcurrent = -1;
                    select(step(1));
                }
            } else if (k === Qt.Key_Up) {
                const r = quickRow.rowOf(qcurrent);
                if (r > 0) {
                    const c = quickRow.colOf(qcurrent);
                    const prevCols = quickRow.colsInRow(r - 1);
                    qcurrent = quickRow.rowStart(r - 1) + Math.min(c, prevCols - 1);
                } else {
                    qcurrent = -1;
                    select(step(-1));
                }
            } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
                menu.activateQuick(list, qcurrent, -1);
            else if (k === Qt.Key_Escape)
                menu.close();
            else
                e.accepted = false;
            return;
        }
        const ch = current >= 0 ? choicesAt(current) : [];
        if (k === Qt.Key_Up && quick.length > 0 && (current < 0 || current === first())) {
            current = -1;
            qcurrent = quick.length - 1;
        } else if (k === Qt.Key_Down || k === Qt.Key_Up)
            select(step(k === Qt.Key_Down ? 1 : -1));
        else if ((k === Qt.Key_Right || k === Qt.Key_Left) && ch.length > 0) {
            const r = rows.itemAt(current);
            if (r)
                r.choice = (r.choice + (k === Qt.Key_Right ? 1 : -1) + ch.length) % ch.length;
        } else if (k === Qt.Key_Right) {
            if (current >= 0 && MenuLook.hasKids(items[current]))
                menu.activate(list, current, true);
        } else if (k === Qt.Key_Left) {
            if (level > 0)
                menu.collapse(level);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (current >= 0 && ch.length > 0)
                menu.runChoice(list, current, rows.itemAt(current) ? rows.itemAt(current).choice : 0);
            else if (current >= 0)
                menu.activate(list, current, true);
        } else if (k === Qt.Key_Escape) {
            if (level > 0)
                menu.collapse(level);
            else
                menu.close();
        } else if (e.text.length === 1 && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            const i = jump(e.text);
            if (i >= 0)
                select(i);
        } else {
            e.accepted = false;
        }
    }

    // a little pop as it opens (the desktop's: Settings → Right-click menu → Animation)
    function popNow() {
        popAnim.restart();
    }
    transformOrigin: Item.TopLeft
    scale: popAnim.running ? popAnim.v : 1
    NumberAnimation {
        id: popAnim
        property real v: 1
        target: popAnim
        property: "v"
        from: 0.92
        to: 1
        duration: Motion.ms(120)
        easing.type: Easing.OutCubic
    }

    // serp-skin: the skin's flat rounded plate under the rows (the pixel frame draws nothing then)
    Rectangle {
        visible: !!list.t.serp
        width: frame.width
        height: frame.height
        radius: Serp.radius
        color: list.t.plate || "transparent"
        border.width: 1
        border.color: Serp.line
    }
    PxBox {
        id: frame
        readonly property real natural: Math.max(list.minWidth, titleNeed, quickRow.visible ? quickRow.implicitWidth + Theme.u * 4 : 0, ...rowCol.children.map(list.need), ...headCol.children.map(list.need), ...footCol.children.map(list.need))
        readonly property real titleNeed: list.title === "" ? 0 : plainText.implicitWidth + Theme.u * 16
        readonly property bool useRelicFrame: Theme.relic && !list.t.hellBox
        readonly property int relicPad: useRelicFrame ? Theme.u * 3 : 0
        // the frame's own inset, computed here: PxBox.relicInset reads width and height, and the
        // width is what this binding sets — asking `inset` made a binding loop (relic skin)
        readonly property int pad: useRelicFrame ? Theme.u * 3 : ob + (flat ? 0 : bevel)
        // the scroll bar's room on top of the widest row
        width: Math.min(list.maxWidth, Math.ceil(natural)) + (pad + relicPad) * 2 + (scroll.barVisible ? Theme.u * 11 : 0)
        height: col.implicitHeight + (pad + relicPad) * 2
        // everything but the rows: what a limited height leaves them
        readonly property real chrome: (plainText.visible ? plainText.height : 0) + (quickRow.visible ? quickRow.height + quickLine.height : 0) + headCol.height + footCol.height + (pad + relicPad) * 2
        hell: list.t.hellBox
        color: useRelicFrame ? "transparent" : list.t.face
        outline: !useRelicFrame && list.t.outline
        flat: useRelicFrame || list.t.flat
        hiColor: list.t.hi
        loColor: list.t.lo
        edgeColor: Theme.relic && !list.t.hellBox ? Theme.relicBronze : list.t.edge
        shadow: Config.appearance.shadows && list.t.shadow
        shadowColor: list.t.shadowColor
        shadowSize: Theme.u * list.t.shadowU
        BorderImage {
            visible: frame.useRelicFrame && width >= 48 && height >= 48
            anchors.fill: parent
            z: -1
            source: visible ? Qt.resolvedUrl("../assets/relic/pkm_frame_9slice_64x64.png") : ""
            border { left: 16; right: 16; top: 16; bottom: 16 }
            horizontalTileMode: BorderImage.Stretch
            verticalTileMode: BorderImage.Stretch
            smooth: false
            asynchronous: true
        }
        Image {
            visible: frame.useRelicFrame && width >= 48 && height >= 48
            anchors.fill: parent
            anchors.margins: Theme.u * 2
            z: -1
            source: visible ? Qt.resolvedUrl("../assets/relic/sanctum_damask_64x64.png") : ""
            fillMode: Image.Tile
            opacity: Theme.relicDark ? 0.35 : 0.06
            smooth: false
            asynchronous: true
        }

        Column {
            id: col
            x: frame.relicPad
            width: parent.width - frame.relicPad * 2
            topPadding: list.t.serp ? Serp.px(5) : frame.relicPad  // serp-skin: rows clear of the round corners
            bottomPadding: list.t.serp ? Serp.px(5) : frame.relicPad  // serp-skin

            // the title: small and dim (with Relic cross & rule in Sanctum)
            Item {
                visible: list.title !== ""
                width: col.width
                height: plainText.height + (Theme.relic && !list.t.hellBox ? Theme.u * 2 : 0)
                Image {
                    visible: Theme.relic && !list.t.hellBox
                    x: Theme.u * 4
                    anchors.verticalCenter: plainText.verticalCenter
                    width: Theme.u * 7
                    height: Theme.u * 8
                    source: visible ? Qt.resolvedUrl("../assets/relic/sanctum_header_cross_16x18.png") : ""
                    smooth: false
                    mipmap: false
                    fillMode: Image.Stretch
                }
                PxText {
                    id: plainText
                    visible: list.title !== ""
                    x: Theme.relic && !list.t.hellBox ? Theme.u * 13 : Theme.u * 4
                    topPadding: Theme.u * 2
                    bottomPadding: Theme.u
                    width: col.width - x - Theme.u * 4
                    elide: Text.ElideRight
                    kind: "tiny"
                    dim: !(Theme.relic && !list.t.hellBox)
                    color: Theme.relic && !list.t.hellBox ? Theme.text : list.t.headText
                    text: list.title
                }
                Rectangle {
                    visible: Theme.relic && !list.t.hellBox
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.u
                    x: Theme.u * 4
                    width: parent.width - Theme.u * 8
                    height: 1
                    color: Theme.relicGold
                    opacity: 0.75
                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.u * 4
                        height: 1
                        color: Theme.relicCrimson
                    }
                }
            }
            // the menu's own parts on top (a task's window and its name)
            Column {
                id: headCol
                width: parent.width
            }
            // the everyday actions: balanced bento grid adapting cleanly to any count
            Item {
                id: quickRow
                visible: list.quick.length > 0
                x: Theme.u * 3
                width: Math.max(0, parent.width - Theme.u * 6)
                height: implicitHeight
                readonly property int n: list.quick.length
                readonly property int maxC: (n === 5 || n === 6 || n === 9) ? 3 : 4
                readonly property int rowCount: n > 0 ? Math.ceil(n / maxC) : 0
                readonly property int gap: Theme.u * 2
                readonly property int padV: Theme.u * 2
                function colsInRow(r) {
                    if (rowCount <= 0)
                        return 0;
                    return Math.floor(n / rowCount) + (r < (n % rowCount) ? 1 : 0);
                }
                function rowStart(r) {
                    let s = 0;
                    for (let i = 0; i < r; i++)
                        s += colsInRow(i);
                    return s;
                }
                function rowOf(idx) {
                    let s = 0;
                    for (let r = 0; r < rowCount; r++) {
                        const c = colsInRow(r);
                        if (idx < s + c)
                            return r;
                        s += c;
                    }
                    return 0;
                }
                function colOf(idx) {
                    const r = rowOf(idx);
                    return idx - rowStart(r);
                }
                readonly property int tileH: {
                    let m = Math.round(Theme.u * 24 * list.tileScale);
                    for (let i = 0; i < quickRep.count; i++) {
                        const it = quickRep.itemAt(i);
                        if (it && it.naturalH > m)
                            m = it.naturalH;
                    }
                    return m;
                }
                readonly property real maxTileW: {
                    let m = Theme.u * 36 * list.tileScale;
                    for (let i = 0; i < quickRep.count; i++) {
                        const it = quickRep.itemAt(i);
                        if (it && it.naturalW > m)
                            m = it.naturalW;
                    }
                    return m;
                }
                implicitWidth: rowCount > 0 ? Math.max(Theme.u * 130, colsInRow(0) * maxTileW + Math.max(0, colsInRow(0) - 1) * gap) + Theme.u * 6 : 0
                implicitHeight: rowCount > 0 ? padV * 2 + rowCount * tileH + Math.max(0, rowCount - 1) * gap : 0
                Repeater {
                    id: quickRep
                    model: list.quick
                    PxMenuTile {
                        required property var modelData
                        required property int index
                        readonly property int rIdx: quickRow.rowOf(index)
                        readonly property int cIdx: quickRow.colOf(index)
                        readonly property int rCols: quickRow.colsInRow(rIdx)
                        cellWidth: Math.max(1, Math.floor((quickRow.width - Math.max(0, rCols - 1) * quickRow.gap) / Math.max(1, rCols)))
                        cellHeight: quickRow.tileH
                        x: cIdx * (cellWidth + quickRow.gap)
                        y: quickRow.padV + rIdx * (quickRow.tileH + quickRow.gap)
                        entry: modelData
                        scale_: list.tileScale
                        highlighted: list.qcurrent === index
                        onTriggered: if (list.menu)
                            list.menu.activateQuick(list, index, -1)
                        onChoiceTriggered: j => {
                            if (list.menu)
                                list.menu.activateQuick(list, index, j);
                        }
                    }
                }
            }
            PxMenuItem {
                id: quickLine
                visible: quickRow.visible && list.items.length > 0
                separator: true
            }

            PxScroll {
                id: scroll
                width: parent.width
                height: list.maxHeight > 0 ? Math.min(rowCol.implicitHeight, Math.max(Theme.u * 24, list.maxHeight - Math.ceil(frame.chrome))) : rowCol.implicitHeight
                contentHeight: rowCol.implicitHeight
                trackColor: list.t.face
                handleColor: list.t.dim
                // a submenu hangs where its entry was: it closes when the rows move
                Connections {
                    target: scroll.flick
                    function onContentYChanged() {
                        if (list.menu)
                            list.menu.collapse(list.level + 1);
                    }
                }

                Column {
                    id: rowCol
                    width: scroll.flick.width
                    Repeater {
                        id: rows
                        model: list.items
                        PxMenuItem {
                            required property var modelData
                            required property int index
                            separator: !!modelData.separator
                            choices: modelData.choices ? Array.from(modelData.choices) : []
                            onChoiceTriggered: j => {
                                if (list.menu)
                                    list.menu.runChoice(list, index, j);
                            }
                            text: modelData.label || ""
                            icon: list.icons ? (modelData.icon || "") : ""
                            hint: modelData.hint || ""
                            keys: modelData.keys || ""
                            submenu: MenuLook.hasKids(modelData)
                            checkable: !!modelData.checkable
                            // a function is read live: the tick follows the setting while open (issue #5)
                            checked: typeof modelData.checked === "function" ? !!modelData.checked() : !!modelData.checked
                            enabled: MenuLook.on(modelData.enabled, true)
                            hoverLights: false
                            highlighted: list.current === index
                            onHoveredChanged: if (hovered && list.menu) {
                                list.qcurrent = -1;
                                list.menu.rowHovered(list, index);
                            }
                            onTriggered: if (list.menu)
                                list.menu.activate(list, index, false)
                        }
                    }
                }
            }
            // …and under them (plugins' QML entries)
            Column {
                id: footCol
                width: parent.width
            }
        }
    }
}
