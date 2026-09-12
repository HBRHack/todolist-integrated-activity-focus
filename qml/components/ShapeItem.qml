import QtQuick 2.15
import QtQuick.Shapes 1.15
import "../theme"

Item {
    id: root

    property int shapeId: -1
    property string shapeType: "rectangle"
    property var points: []
    property var style: ({})
    property bool linked: false
    property bool selected: false
    property bool interactive: false

    readonly property bool editable: root.interactive && !root.linked

    signal selectRequested()
    signal actionsRequested()
    signal geometryCommitted(real x, real y, real w, real h, real rotation)

    transformOrigin: Item.Center

    readonly property bool lineLike: root.shapeType === "line"
        || root.shapeType === "arrow" || root.shapeType === "freehand"
    readonly property int strokeWidth: Math.max(1, Math.round(root.style["strokeWidth"] || 2))

    readonly property color strokeColor: tokenColor(root.style["stroke"],
        root.lineLike ? "accent" : "border")
    readonly property color fillColor: tokenColor(root.style["fill"],
        root.lineLike ? "" : "surface")

    readonly property real drawW: Math.max(root.width, 1)
    readonly property real drawH: Math.max(root.height, 1)

    // Warna style bentuk: token khusus gaya (surface/border/text/muted)
    // diselesaikan lokal; color-key semantik (accent/danger/...) didelegasikan
    // ke Theme.colorKeyToToken sebagai satu sumber (DESIGN.md Color-key).
    function tokenColor(token, fallback) {
        switch (token) {
        case "surface": return Theme.colorSurface
        case "surfaceAlt": return Theme.colorSurfaceAlt
        case "border": return Theme.colorBorder
        case "text": return Theme.colorText
        case "muted": return Theme.colorMuted
        case "accent":
        case "danger":
        case "active":
        case "accentContent":
        case "neutral": return Theme.colorKeyToToken(token)
        default:
            return fallback ? tokenColor(fallback, "") : "transparent"
        }
    }

    function scaledPoints(w, h) {
        var out = []
        for (var i = 0; i < root.points.length; ++i) {
            var p = root.points[i]
            out.push(Qt.point(p[0] * w, p[1] * h))
        }
        return out
    }

    readonly property var scaledPts: root.points.length >= 2
        ? scaledPoints(root.drawW, root.drawH)
        : [Qt.point(0, 0), Qt.point(root.drawW, root.drawH)]

    readonly property var arrowHead: (function() {
        var a = root.scaledPts[0]
        var b = root.scaledPts[root.scaledPts.length - 1]
        var dx = b.x - a.x
        var dy = b.y - a.y
        var len = Math.hypot(dx, dy)
        if (len < 1)
            return null
        var headLen = Math.min(16, Math.max(12, root.strokeWidth * 6))
        var hw = headLen * 0.35
        var n = Qt.point(-dy / len, dx / len)
        var base = Qt.point(b.x - dx * headLen / len, b.y - dy * headLen / len)
        return {
            tip: b,
            baseL: Qt.point(base.x + n.x * hw, base.y + n.y * hw),
            baseR: Qt.point(base.x - n.x * hw, base.y - n.y * hw)
        }
    })()

    Rectangle {
        visible: root.shapeType === "rectangle"
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        color: root.fillColor
        border.color: root.strokeColor
        border.width: root.strokeWidth
    }

    Shape {
        visible: root.shapeType === "ellipse"
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        antialiasing: true

        ShapePath {
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            fillColor: root.fillColor
            startX: root.drawW / 2
            startY: 0

            PathArc {
                x: root.drawW / 2
                y: root.drawH
                radiusX: root.drawW / 2
                radiusY: root.drawH / 2
                direction: PathArc.Counterclockwise
            }
            PathArc {
                x: root.drawW / 2
                y: 0
                radiusX: root.drawW / 2
                radiusY: root.drawH / 2
                direction: PathArc.Counterclockwise
            }
        }
    }

    Shape {
        visible: root.shapeType === "triangle"
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        antialiasing: true

        ShapePath {
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            fillColor: root.fillColor
            joinStyle: ShapePath.MiterJoin
            startX: root.drawW / 2
            startY: 0

            PathLine { x: root.drawW; y: root.drawH }
            PathLine { x: 0; y: root.drawH }
        }
    }

    Shape {
        visible: root.shapeType === "line"
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        antialiasing: true

        ShapePath {
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.scaledPts[0].x
            startY: root.scaledPts[0].y

            PathLine { x: root.scaledPts[1].x; y: root.scaledPts[1].y }
        }
    }

    Shape {
        visible: root.shapeType === "arrow" && root.arrowHead !== null
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        antialiasing: true

        ShapePath {
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            fillColor: root.strokeColor
            startX: root.scaledPts[0].x
            startY: root.scaledPts[0].y

            PathLine { x: root.arrowHead.tip.x; y: root.arrowHead.tip.y }
            PathMove { x: root.arrowHead.baseL.x; y: root.arrowHead.baseL.y }
            PathLine { x: root.arrowHead.tip.x; y: root.arrowHead.tip.y }
            PathLine { x: root.arrowHead.baseR.x; y: root.arrowHead.baseR.y }
            PathLine { x: root.arrowHead.baseL.x; y: root.arrowHead.baseL.y }
        }
    }

    Shape {
        visible: root.shapeType === "freehand" && root.points.length > 1
        x: 0
        y: 0
        width: root.drawW
        height: root.drawH
        antialiasing: true

        ShapePath {
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: root.scaledPts[0].x
            startY: root.scaledPts[0].y

            PathPolyline { path: root.scaledPts.length > 1 ? root.scaledPts.slice(1) : [] }
        }
    }

    Rectangle {
        z: 10
        visible: root.selected && root.editable
        x: -3
        y: -3
        width: root.drawW + 6
        height: root.drawH + 6
        color: "transparent"
        border.color: Theme.colorAccent
        border.width: 3
    }

    Rectangle {
        z: 10
        visible: root.linked
        x: Theme.spacingTiny
        y: Theme.spacingTiny
        width: badgeLabel.implicitWidth + Theme.spacingSmall
        height: badgeLabel.implicitHeight + Theme.spacingTiny
        objectName: "shapeLinkedBadge_" + root.shapeId
        color: Theme.colorSlab
        border.color: Theme.colorBorder
        border.width: 1

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: qsTr("Item")
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeCaption
            font.bold: true
            color: Theme.colorSlabText
        }
    }

    MouseArea {
        id: shapePress
        anchors.fill: parent
        enabled: root.editable
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        property point pressPos: Qt.point(0, 0)
        property point startPos: Qt.point(0, 0)
        property bool moving: false

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.actionsRequested()
                return
            }
            root.selectRequested()
            pressPos = Qt.point(mouse.x, mouse.y)
            startPos = Qt.point(root.x, root.y)
            moving = false
        }

        onPositionChanged: (mouse) => {
            if (!pressed || mouse.button !== Qt.LeftButton)
                return
            if (!moving) {
                var dx = mouse.x - pressPos.x
                var dy = mouse.y - pressPos.y
                if (Math.abs(dx) <= Theme.dragThreshold && Math.abs(dy) <= Theme.dragThreshold)
                    return
                moving = true
            }
            root.x = startPos.x + (mouse.x - pressPos.x)
            root.y = startPos.y + (mouse.y - pressPos.y)
        }

        onReleased: (mouse) => {
            if (moving && mouse.button === Qt.LeftButton) {
                moving = false
                root.geometryCommitted(root.x, root.y, root.drawW, root.drawH, root.rotation)
            }
        }
    }

    Rectangle {
        id: resizeHandle
        z: 20
        visible: root.selected && root.editable
        x: root.width - 8
        y: root.height - 8
        width: 16
        height: 16
        objectName: "shapeResizeHandle_" + root.shapeId
        color: Theme.colorSurface
        border.color: Theme.colorAccent
        border.width: 2

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.SizeFDiagCursor

            property point pressLocal: Qt.point(0, 0)
            property real startW: 0
            property real startH: 0

            onPressed: (mouse) => {
                pressLocal = root.mapFromItem(resizeHandle, mouse.x, mouse.y)
                startW = root.width
                startH = root.height
            }

            onPositionChanged: (mouse) => {
                if (!pressed)
                    return
                var p = root.mapFromItem(resizeHandle, mouse.x, mouse.y)
                root.width = Math.max(Theme.dragThreshold, startW + p.x - pressLocal.x)
                root.height = Math.max(Theme.dragThreshold, startH + p.y - pressLocal.y)
            }

            onReleased: (mouse) => {
                root.geometryCommitted(root.x, root.y, root.width, root.height, root.rotation)
            }
        }
    }

    Rectangle {
        id: rotateStem
        z: 20
        visible: root.selected && root.editable
        x: root.width / 2 - 1
        y: -Theme.spacingLarge
        width: 2
        height: Theme.spacingLarge
        color: Theme.colorAccent
    }

    Rectangle {
        id: rotateHandle
        z: 20
        visible: root.selected && root.editable
        x: root.width / 2 - 8
        y: -Theme.spacingLarge - 16
        width: 16
        height: 16
        objectName: "shapeRotateHandle_" + root.shapeId
        color: Theme.colorSurface
        border.color: Theme.colorAccent
        border.width: 2

        MouseArea {
            id: rotateMouse
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            property real startRotation: 0
            property real startAngle: 0

            function worldPointerAngle() {
                var q = rotateMouse.mapToItem(root.parent, rotateMouse.mouseX, rotateMouse.mouseY)
                return Math.atan2(q.y - (root.y + root.height / 2),
                                  q.x - (root.x + root.width / 2)) * 180 / Math.PI
            }

            onPressed: (mouse) => {
                startRotation = root.rotation
                startAngle = rotateMouse.worldPointerAngle()
            }

            onPositionChanged: (mouse) => {
                if (!pressed)
                    return
                var r = startRotation + rotateMouse.worldPointerAngle() - startAngle
                if (mouse.modifiers & Qt.ShiftModifier)
                    r = Math.round(r / 15) * 15
                root.rotation = r
            }

            onReleased: (mouse) => {
                root.geometryCommitted(root.x, root.y, root.width, root.height, root.rotation)
            }
        }
    }
}