import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"
import PetaIde 1.0

Rectangle {
    id: root
    color: Theme.colorBackground

    property real zoom: 1.0
    property int selectedBoardId: -1
    property var boards: []
    property var chipsModel: []
    property bool perBoardMode: false
    property var boardOptions: []
    property var edges: []
    property int edgeDragItemId: -1
    property var edgeDragStart: Qt.point(0, 0)
    property var edgeDragEnd: Qt.point(0, 0)
    property int edgeTargetId: -1
    property int edgePopupId: -1
    property bool prevPerBoardMode: false

    readonly property int canvasWidth: 3000
    readonly property int canvasHeight: 3000

    function clampZoom(z) {
        return Math.min(2.0, Math.max(0.5, z))
    }

    function boardExists(id) {
        for (var i = 0; i < root.boards.length; ++i) {
            if (root.boards[i].id === id)
                return true
        }
        return false
    }

    function rebuildChips() {
        var switchingToGlobal = appSettings.mapMode !== "perboard" && root.prevPerBoardMode
        root.perBoardMode = appSettings.mapMode === "perboard"
        if (root.perBoardMode) {
            if (!root.boardExists(root.selectedBoardId))
                root.selectedBoardId = root.boards.length > 0 ? root.boards[0].id : -1
        } else if (switchingToGlobal) {
            root.selectedBoardId = -1
        } else if (!root.boardExists(root.selectedBoardId)) {
            root.selectedBoardId = -1
        }
        root.prevPerBoardMode = root.perBoardMode

        var out = []
        if (!root.perBoardMode)
            out.push({ id: -1, label: qsTr("Semua") })
        for (var i = 0; i < root.boards.length; ++i)
            out.push({ id: root.boards[i].id, label: root.boards[i].name })
        chipsModel = out
        root.applyFilter()
    }

    function loadBoards() {
        root.boards = repo.boardList()
        rebuildChips()
    }

    function applyFilter() {
        mapProxy.boardId = root.selectedBoardId
        root.refreshEdges()
    }

    function refreshEdges() {
        root.edges = repo.edgeList()
    }

    function nodeItemById(itemId) {
        for (var i = 0; i < nodesRepeater.count; ++i) {
            var n = nodesRepeater.itemAt(i)
            if (n.nodeId === itemId)
                return n
        }
        return null
    }

    function nodeAt(px, py) {
        for (var i = 0; i < nodesRepeater.count; ++i) {
            var n = nodesRepeater.itemAt(i)
            if (px >= n.x && px <= n.x + n.width && py >= n.y && py <= n.y + n.height)
                return n.nodeId
        }
        return -1
    }

    function openEdgeDetail(edgeId) {
        root.edgePopupId = edgeId
        edgePopup.open()
    }

    function selectBoard(id) {
        root.selectedBoardId = id
        applyFilter()
    }

    function setMapMode(mode) {
        appSettings.mapMode = mode
    }

    function susunRapi() {
        repo.layoutMap(root.selectedBoardId)
        for (var i = 0; i < nodesRepeater.count; ++i) {
            var node = nodesRepeater.itemAt(i)
            var p = root.nodePosition(node.nodeId)
            node.x = p.x
            node.y = p.y
        }
    }

    function nodePosition(itemId) {
        if (repo.hasNodePosition(itemId)) {
            var p = repo.nodePosition(itemId)
            return Qt.point(p.x, p.y)
        }
        return Qt.point(root.canvasWidth / 2 + ((itemId * 97) % 600) - 300,
                        root.canvasHeight / 2 + ((itemId * 53) % 400) - 200)
    }

    function saveNodePosition(itemId, pos) {
        repo.setNodePosition(itemId, Qt.point(pos.x, pos.y))
    }

    function refreshOptions() {
        var raw = repo.boardColumnOptions()
        var out = []
        for (var i = 0; i < raw.length; ++i)
            out.push({
                label: raw[i].boardName + " · " + raw[i].columnName,
                columnId: raw[i].columnId
            })
        boardOptions = out
    }

    function statusLabel(columnId, boardName, columnName) {
        if (columnId === -1)
            return qsTr("Inbox")
        return boardName + " · " + columnName
    }

    function openDetail(itemId) {
        detailPopup.show(itemId)
    }

    Connections {
        target: repo
        function onChanged() {
            root.loadBoards()
            root.refreshOptions()
            root.refreshEdges()
        }
    }

    Connections {
        target: appSettings
        function onMapModeChanged() {
            root.rebuildChips()
        }
    }

    Component.onCompleted: {
        mapProxy.setItemModel(itemModel)
        refreshOptions()
        loadBoards()
        refreshEdges()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // Toolbar — slab kontrol kotak
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("Peta")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Gulir roda untuk zoom · seret area kosong untuk geser")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorMuted
                verticalAlignment: Text.AlignVCenter
            }

            PrimaryButton {
                id: susunRapiBtn
                objectName: "susunRapiButton"
                text: qsTr("Susun rapi")
                onClicked: root.susunRapi()
            }

            SelectBox {
                id: mapModeDropdown
                objectName: "mapModeDropdown"
                width: 200
                height: Theme.smallControlHeight
                model: [qsTr("Satu Papan Global"), qsTr("Multiple Papan")]
                currentIndex: appSettings.mapMode === "perboard" ? 1 : 0
                onActivated: root.setMapMode(index === 0 ? "global" : "perboard")
            }

            SquareToolButton {
                Layout.preferredWidth: Theme.smallControlHeight
                Layout.preferredHeight: Theme.smallControlHeight
                text: "\u2212"
                onClicked: root.zoom = root.clampZoom(root.zoom * 0.85)
            }

            SquareToolButton {
                Layout.preferredWidth: Theme.smallControlHeight
                Layout.preferredHeight: Theme.smallControlHeight
                text: "+"
                onClicked: root.zoom = root.clampZoom(root.zoom * 1.15)
            }

            Text {
                text: Math.round(root.zoom * 100) + "%"
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.colorMuted
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Chips board — kotak
        Row {
            id: chipsBar
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: root.chipsModel

                Chip {
                    id: chip
                    objectName: "boardChip_" + modelData.id
                    text: modelData.label
                    active: root.selectedBoardId === modelData.id
                    onClicked: root.selectBoard(modelData.id)
                }
            }
        }

        // Canvas peta
        Flickable {
            id: canvas
            objectName: "mapCanvas"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: canvasContent.width * root.zoom
            contentHeight: canvasContent.height * root.zoom
            boundsBehavior: Flickable.DragAndOvershootBounds
            ScrollBar.vertical: BrutalScrollBar {}
            ScrollBar.horizontal: BrutalScrollBar {}

            WheelHandler {
                id: wheelZoom
                target: canvas
                onActiveChanged: {
                    if (wheelZoom.active)
                        root.zoom = root.clampZoom(root.zoom * (wheelZoom.point.rotation > 0 ? 1.15 : 0.85))
                }
            }

            Item {
                id: canvasContent
                width: root.canvasWidth
                height: root.canvasHeight

                transform: Scale {
                    xScale: root.zoom
                    yScale: root.zoom
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Theme.colorBorder
                    border.width: Theme.borderWidth
                }

                Repeater {
                    id: edgesRepeater
                    model: root.edges

                    Item {
                        id: edgeRoot
                        objectName: "edge_" + modelData.id

                        property Item childNode: null
                        property Item parentNode: null

                        readonly property real cx: childNode !== null ? childNode.x + childNode.width / 2 : 0
                        readonly property real cy: childNode !== null ? childNode.y + childNode.height / 2 : 0
                        readonly property real px: parentNode !== null ? parentNode.x + parentNode.width / 2 : 0
                        readonly property real py: parentNode !== null ? parentNode.y + parentNode.height / 2 : 0
                        readonly property real dx: px - cx
                        readonly property real dy: py - cy

                        visible: childNode !== null && parentNode !== null

                        Component.onCompleted: {
                            childNode = root.nodeItemById(modelData.itemId)
                            parentNode = root.nodeItemById(modelData.parentItemId)
                        }

                        Rectangle {
                            width: Math.hypot(edgeRoot.dx, edgeRoot.dy)
                            height: 3
                            x: edgeRoot.cx
                            y: edgeRoot.cy - 1.5
                            rotation: Math.atan2(edgeRoot.dy, edgeRoot.dx) * 180 / Math.PI
                            transformOrigin: Item.TopLeft
                            color: Theme.colorText

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -7
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openEdgeDetail(modelData.id)
                            }
                        }
                    }
                }

                Repeater {
                    id: nodesRepeater
                    model: mapProxy

                    Item {
                        id: nodeRoot
                        property int nodeId: itemId
                        objectName: "node_" + itemId
                        width: Theme.nodeWidth
                        height: Theme.nodeHeight
                        x: root.nodePosition(itemId).x
                        y: root.nodePosition(itemId).y
                        z: nodeMouse.dragActive || nodeMouse.edgeDrag ? 10 : 1

                        // Hard shadow slab
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.shadowOffset
                            anchors.topMargin: Theme.shadowOffset
                            color: Theme.colorShadow
                            visible: !nodeMouse.dragActive
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 0
                            color: Theme.colorSurface
                            border.color: nodeMouse.dragActive || nodeMouse.edgeDrag || root.edgeTargetId === itemId ? Theme.colorAccent : Theme.colorBorder
                            border.width: nodeMouse.dragActive || nodeMouse.edgeDrag || root.edgeTargetId === itemId ? 3 : Theme.borderWidth
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: title
                                elide: Text.ElideRight
                                font.family: Theme.fontFamilyBody
                                font.pixelSize: Theme.fontSizeBody
                                font.bold: true
                                color: Theme.colorText
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingTiny

                                Text {
                                    text: Format.dueDateString(dueDate)
                                    font.family: Theme.fontFamilyMono
                                    font.pixelSize: Theme.fontSizeCaption
                                    color: Theme.colorMuted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: boardName.length > 0
                                    text: boardName
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamilyMono
                                    font.pixelSize: Theme.fontSizeCaption
                                    font.bold: true
                                    color: Theme.colorAccentContent
                                }
                            }
                        }

                        MouseArea {
                            id: nodeMouse
                            anchors.fill: parent
                            preventStealing: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            property bool dragActive: false
                            property bool edgeDrag: false
                            property point pressPos: Qt.point(0, 0)
                            property point nodeStart: Qt.point(0, 0)

                            onPressed: (mouse) => {
                                pressPos = Qt.point(mouse.x, mouse.y)
                                nodeStart = Qt.point(nodeRoot.x, nodeRoot.y)
                                dragActive = false
                                edgeDrag = (mouse.button === Qt.RightButton)
                                if (edgeDrag) {
                                    root.edgeDragItemId = itemId
                                    root.edgeDragStart = Qt.point(nodeRoot.x + nodeRoot.width / 2,
                                                                  nodeRoot.y + nodeRoot.height / 2)
                                    root.edgeDragEnd = Qt.point(root.edgeDragStart.x, root.edgeDragStart.y)
                                    root.edgeTargetId = -1
                                }
                            }

                            onPositionChanged: (mouse) => {
                                if (!pressed)
                                    return
                                if (edgeDrag) {
                                    var p = nodeRoot.mapToItem(canvasContent, mouse.x, mouse.y)
                                    root.edgeDragEnd = Qt.point(p.x, p.y)
                                    root.edgeTargetId = root.nodeAt(p.x, p.y)
                                    return
                                }
                                if (!dragActive) {
                                    var dx = mouse.x - pressPos.x
                                    var dy = mouse.y - pressPos.y
                                    if (Math.abs(dx) <= Theme.dragThreshold && Math.abs(dy) <= Theme.dragThreshold)
                                        return
                                    dragActive = true
                                }
                                nodeRoot.x = nodeStart.x + (mouse.x - pressPos.x)
                                nodeRoot.y = nodeStart.y + (mouse.y - pressPos.y)
                            }

                            onReleased: (mouse) => {
                                if (edgeDrag) {
                                    var rp = nodeRoot.mapToItem(canvasContent, mouse.x, mouse.y)
                                    var target = root.nodeAt(rp.x, rp.y)
                                    if (target > 0 && target !== itemId)
                                        repo.addEdge(itemId, target)
                                    edgeDrag = false
                                    root.edgeDragItemId = -1
                                    root.edgeTargetId = -1
                                    return
                                }
                                if (dragActive) {
                                    var p = nodeRoot.mapToItem(canvasContent, 0, 0)
                                    root.saveNodePosition(itemId, p)
                                }
                                dragActive = false
                            }

                            onClicked: (mouse) => {
                                if (!dragActive && !edgeDrag && mouse.button === Qt.LeftButton)
                                    root.openDetail(itemId)
                            }
                        }
                    }
                }

                Rectangle {
                    id: edgeTempLine
                    objectName: "edgeTempLine"
                    visible: root.edgeDragItemId !== -1
                    x: root.edgeDragStart.x
                    y: root.edgeDragStart.y - 1.5
                    width: Math.max(2, Math.hypot(root.edgeDragEnd.x - root.edgeDragStart.x,
                                                  root.edgeDragEnd.y - root.edgeDragStart.y))
                    height: 3
                    rotation: Math.atan2(root.edgeDragEnd.y - root.edgeDragStart.y,
                                         root.edgeDragEnd.x - root.edgeDragStart.x) * 180 / Math.PI
                    transformOrigin: Item.TopLeft
                    color: Theme.colorAccent
                }

                Text {
                    anchors.centerIn: parent
                    visible: mapProxy.count === 0
                    text: qsTr("Belum ada Item di peta. Tambahkan Item dari Inbox atau view lain.")
                    font.family: Theme.fontFamilyBody
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.colorMuted
                }
            }
        }
    }

    MapProxyModel {
        id: mapProxy
        objectName: "mapProxy"
    }

    ItemDetailPopup {
        id: detailPopup
        parent: root
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        boardOptions: root.boardOptions
    }

    Popup {
        id: edgePopup
        parent: root
        modal: true
        width: 420
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        padding: 0

        background: Rectangle {
            radius: 0
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidth
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: qsTr("Hapus koneksi")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            Text {
                id: edgePopupInfo
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorMuted
            }

            PrimaryButton {
                id: edgeDeleteBtn
                objectName: "edgeDeleteBtn"
                Layout.fillWidth: true
                text: qsTr("Hapus koneksi")
                highlighted: true
                onClicked: {
                    repo.deleteEdge(root.edgePopupId)
                    edgePopup.close()
                }
            }

            PrimaryButton {
                Layout.fillWidth: true
                text: qsTr("Batal")
                onClicked: edgePopup.close()
            }
        }

        onOpened: {
            var e = null
            for (var i = 0; i < root.edges.length; ++i) {
                if (root.edges[i].id === root.edgePopupId) {
                    e = root.edges[i]
                    break
                }
            }
            if (e === null)
                return
            var child = repo.itemInfo(e.itemId)
            var parent = repo.itemInfo(e.parentItemId)
            edgePopupInfo.text = qsTr("%1 → %2").arg(child.title).arg(parent.title)
        }
    }
}