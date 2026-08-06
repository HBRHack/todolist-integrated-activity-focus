import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"
import PetaIde 1.0

Rectangle {
    id: root
    color: Theme.colorBackground

    property var boards: []
    property int selectedBoardId: -1
    property var columns: []

    property var dragState: null
    property bool newBoardVisible: false
    property bool renameBoardVisible: false
    property int renameBoardId: -1
    property bool newColumnVisible: false
    property bool renameColumnVisible: false
    property int renameColumnId: -1

    function reloadBoards() {
        boards = repo.boardList()
        var exists = false
        for (var i = 0; i < boards.length; ++i) {
            if (boards[i].id === selectedBoardId) {
                exists = true
                break
            }
        }
        if (!exists)
            selectedBoardId = boards.length > 0 ? boards[0].id : -1
        reloadColumns()
    }

    function reloadColumns() {
        if (selectedBoardId === -1) {
            columns = []
            return
        }
        columns = repo.columnList(selectedBoardId)
    }

    function selectBoard(id) {
        selectedBoardId = id
        reloadColumns()
    }

    // Compute posisi final (0-based) di kolom target untuk repo.moveItem().
    // Berbasis geometri: kotak = cardHeight + spacing, dikoreksi scroll vertikal
    // dan slot item yang sedang diseret (khusus kolom yang sama).
    function commitDrop(targetColumnId, dropY, list) {
        if (!dragState)
            return
        var viewportY = dropY + list.contentY
        var cellH = Theme.cardHeight + list.spacing
        var row = Math.floor(viewportY / cellH)
        var count = list.count
        var idx = row >= count ? count : row
        var sameCol = dragState.sourceColumnId === targetColumnId
        if (sameCol && dragState.sourceRow < idx)
            idx -= 1
        var maxFinal = sameCol ? count - 1 : count
        idx = Math.max(0, Math.min(idx, maxFinal))
        repo.moveItem(dragState.itemId, targetColumnId, idx)
        dragState = null
    }

    function ghostShow(title) {
        dragGhostTitle.text = title
        dragGhost.visible = true
    }

    function ghostMove(pos) {
        dragGhost.x = pos.x - dragGhost.width / 2
        dragGhost.y = pos.y - dragGhost.height / 2
    }

    function ghostHide() {
        dragGhost.visible = false
    }

    function addBoard() {
        var name = newBoardField.text.trim()
        if (name.length === 0) return
        var id = repo.addBoard(name)
        newBoardField.text = ""
        newBoardVisible = false
        reloadBoards()
        selectBoard(id)
    }

    // Alur tambah Board: board/Idea pertama memunculkan dialog Setup Awal (ADR-0009);
    // setelah mode terkunci, langsung ke input nama.
    function beginAddBoard() {
        if (!appSettings.mapModeChosen) {
            mapModeSetupDialog.open()
            return
        }
        showNewBoardInput()
    }

    function showNewBoardInput() {
        newBoardVisible = true
        newBoardField.forceActiveFocus()
    }

    function deleteBoard(id) {
        repo.deleteBoard(id)
        reloadBoards()
    }

    function addColumn() {
        var name = newColumnField.text.trim()
        if (name.length === 0 || selectedBoardId === -1) return
        repo.addColumn(selectedBoardId, name)
        newColumnField.text = ""
        newColumnVisible = false
        reloadColumns()
    }

    function deleteColumn(id) {
        repo.deleteColumn(id)
        reloadColumns()
    }

    function moveColumnLeft(columnId, index) {
        if (selectedBoardId === -1) return
        repo.moveColumn(selectedBoardId, columnId, index - 1)
        reloadColumns()
    }

    function moveColumnRight(columnId, index) {
        if (selectedBoardId === -1) return
        repo.moveColumn(selectedBoardId, columnId, index + 1)
        reloadColumns()
    }

    Component.onCompleted: reloadBoards()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tab bar board
        Rectangle {
            Layout.fillWidth: true
            height: Theme.tabBarHeight
            color: Theme.colorSurface

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingTiny
                spacing: Theme.spacingTiny

                Repeater {
                    model: boards
                    Rectangle {
                        width: tabLabel.width + Theme.spacingHuge
                        height: Theme.smallControlHeight
                        radius: Theme.radiusSmall
                        color: selectedBoardId === modelData.id ? Theme.colorAccent : "transparent"

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeBody
                            font.bold: selectedBoardId === modelData.id
                            color: selectedBoardId === modelData.id ? Theme.colorAccentText : Theme.colorText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selectBoard(modelData.id)
                            onDoubleClicked: {
                                renameBoardId = modelData.id
                                renameBoardField.text = modelData.name
                                renameBoardVisible = true
                            }
                        }
                    }
                }

                // Tab "+"
                Rectangle {
                    width: Theme.smallControlHeight
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    color: addBoardMouse.containsMouse ? Theme.colorSurfaceAlt : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: Theme.fontSizeTitle
                        font.bold: true
                        color: Theme.colorAccent
                    }

                    MouseArea {
                        id: addBoardMouse
                        objectName: "addBoardTab"
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.beginAddBoard()
                    }
                }

                // Inline add board
                Rectangle {
                    visible: newBoardVisible
                    width: newBoardField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    border.color: Theme.colorAccent
                    border.width: 1
                    color: Theme.colorSurface

                    TextInput {
                        id: newBoardField
                        objectName: "newBoardField"
                        anchors.centerIn: parent
                        width: 120
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.colorText
                        clip: true
                        visible: true

                        Keys.onReturnPressed: addBoard()
                        Keys.onEscapePressed: {
                            newBoardVisible = false
                            newBoardField.text = ""
                        }
                    }
                }

                // Inline rename board
                Rectangle {
                    visible: renameBoardVisible
                    width: renameBoardField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    border.color: Theme.colorAccent
                    border.width: 1
                    color: Theme.colorSurface

                    TextInput {
                        id: renameBoardField
                        anchors.centerIn: parent
                        width: 120
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.colorText
                        clip: true

                        Keys.onReturnPressed: {
                            var name = renameBoardField.text.trim()
                            if (name.length > 0 && renameBoardId !== -1) {
                                repo.renameBoard(renameBoardId, name)
                                reloadBoards()
                            }
                            renameBoardVisible = false
                            renameBoardId = -1
                        }
                        Keys.onEscapePressed: {
                            renameBoardVisible = false
                            renameBoardId = -1
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colorBorder
        }

        // Column header row
        Rectangle {
            Layout.fillWidth: true
            height: Theme.headerHeight
            color: Theme.colorBackground

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: Theme.spacingMedium

                Repeater {
                    model: columns
                    Rectangle {
                        width: Theme.columnWidth
                        height: Theme.smallControlHeight
                        radius: Theme.radiusSmall
                        color: "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingTiny
                            spacing: Theme.spacingSmall

                            Text {
                                text: "‹"
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                color: Theme.colorMuted
                                verticalAlignment: Text.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.moveColumnLeft(modelData.id, index)
                                }
                            }

                            Text {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                color: Theme.colorText
                                verticalAlignment: Text.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    onDoubleClicked: {
                                        renameColumnId = modelData.id
                                        renameColumnField.text = modelData.name
                                        renameColumnVisible = true
                                    }
                                }
                            }

                            Text {
                                text: "›"
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                color: Theme.colorMuted
                                verticalAlignment: Text.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.moveColumnRight(modelData.id, index)
                                }
                            }

                            Text {
                                text: "×"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.colorDanger
                                verticalAlignment: Text.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    objectName: "deleteColumn_" + modelData.id
                                    onClicked: deleteColumn(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Add column button
                Rectangle {
                    width: addColumnBtn.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    color: addColumnMouse.containsMouse ? Theme.colorSurfaceAlt : "transparent"

                    Text {
                        id: addColumnBtn
                        anchors.centerIn: parent
                        text: qsTr("+ Kolom")
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.colorAccent
                    }

                    MouseArea {
                        id: addColumnMouse
                        objectName: "addColumnButton"
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            newColumnVisible = true
                            newColumnField.forceActiveFocus()
                        }
                    }
                }

                // Inline add column
                Rectangle {
                    visible: newColumnVisible
                    width: newColumnField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    border.color: Theme.colorAccent
                    border.width: 1
                    color: Theme.colorSurface

                    TextInput {
                        id: newColumnField
                        objectName: "newColumnField"
                        anchors.centerIn: parent
                        width: 100
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.colorText
                        clip: true

                        Keys.onReturnPressed: addColumn()
                        Keys.onEscapePressed: {
                            newColumnVisible = false
                            newColumnField.text = ""
                        }
                    }
                }

                // Inline rename column
                Rectangle {
                    visible: renameColumnVisible
                    width: renameColumnField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    border.color: Theme.colorAccent
                    border.width: 1
                    color: Theme.colorSurface

                    TextInput {
                        id: renameColumnField
                        anchors.centerIn: parent
                        width: 120
                        font.pixelSize: Theme.fontSizeBody
                        color: Theme.colorText
                        clip: true

                        Keys.onReturnPressed: {
                            var name = renameColumnField.text.trim()
                            if (name.length > 0 && renameColumnId !== -1) {
                                repo.renameColumn(renameColumnId, name)
                                reloadColumns()
                            }
                            renameColumnVisible = false
                            renameColumnId = -1
                        }
                        Keys.onEscapePressed: {
                            renameColumnVisible = false
                            renameColumnId = -1
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colorBorder
        }

        // Columns area
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: columns.length * (Theme.columnWidth + Theme.spacingMedium) + Theme.spacingHuge
            clip: true
            flickableDirection: Flickable.HorizontalFlick

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Repeater {
                    model: columns

                    Rectangle {
                            id: columnRect
                            width: Theme.columnWidth
                            height: parent ? parent.height - Theme.spacingHuge : 0
                            radius: Theme.radiusLarge
                            color: Theme.colorSurface
                            border.color: dropHighlight ? Theme.colorAccent : Theme.colorBorder
                            border.width: dropHighlight ? 2 : 1

                            property bool dropHighlight: false

                            ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            // Column header
                            Text {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: Theme.colorText
                            }

                            // Item list
                            ListView {
                                id: columnList
                                objectName: "colList_" + modelData.id
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: Theme.spacingTiny
                                model: ColumnProxyModel {
                                    id: proxyModel
                                    columnId: modelData.id
                                    Component.onCompleted: setItemModel(itemModel)
                                }
                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                }

                                delegate: Rectangle {
                                    id: card
                                    objectName: "card_" + columnId + "_" + orderIndex
                                    width: ListView.view.width
                                    height: Theme.cardHeight
                                    radius: Theme.radiusMedium
                                    color: Theme.colorSurfaceAlt
                                    border.color: Theme.colorBorder
                                    border.width: 1

                                    Drag.active: dragArea.dragActive
                                    Drag.source: card
                                    Drag.keys: ["kanbanItem"]
                                    Drag.hotSpot.x: card.width / 2
                                    Drag.hotSpot.y: card.height / 2

                                    opacity: dragArea.dragActive ? 0.4 : 1.0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingSmall
                                        spacing: Theme.spacingTiny

                                        Text {
                                            Layout.fillWidth: true
                                            text: title
                                            elide: Text.ElideRight
                                            font.pixelSize: Theme.fontSizeBody
                                            font.bold: true
                                            color: Theme.colorText
                                        }

                                        Text {
                                            text: Format.dueDateString(dueDate)
                                            font.pixelSize: Theme.fontSizeCaption
                                            color: Theme.colorMuted
                                        }
                                    }

                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        property bool dragActive: false
                                        property point pressPos: Qt.point(0, 0)

                                        onPressed: (mouse) => {
                                            pressPos = Qt.point(mouse.x, mouse.y)
                                            root.dragState = {
                                                itemId: itemId,
                                                sourceColumnId: columnId,
                                                sourceRow: index,
                                                title: title
                                            }
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (dragActive) {
                                                root.ghostMove(card.mapToItem(root, mouse.x, mouse.y))
                                                return
                                            }
                                            if (!pressed)
                                                return
                                            var dx = mouse.x - pressPos.x
                                            var dy = mouse.y - pressPos.y
                                            if (Math.abs(dx) <= Theme.dragThreshold && Math.abs(dy) <= Theme.dragThreshold)
                                                return
                                            dragActive = true
                                            root.ghostShow(title)
                                        }
                                        onReleased: {
                                            if (dragActive) {
                                                card.Drag.drop()
                                                root.ghostHide()
                                            }
                                            dragActive = false
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.count === 0
                                    text: qsTr("Belum ada Item")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.colorMuted
                                }

                                DropArea {
                                    anchors.fill: parent
                                    keys: ["kanbanItem"]
                                    onEntered: columnRect.dropHighlight = true
                                    onExited: columnRect.dropHighlight = false
                                    onDropped: {
                                        columnRect.dropHighlight = false
                                        root.commitDrop(modelData.id, drop.y, columnList)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        anchors.centerIn: parent
        visible: boards.length === 0
        text: qsTr("Belum ada Board. Klik '+' untuk membuat Board baru.")
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorMuted
    }

    // Dialog Setup Awal — pilihan Mode Peta saat Board/Idea pertama dibuat (ADR-0009)
    Popup {
        id: mapModeSetupDialog
        objectName: "mapModeSetupDialog"
        parent: root
        modal: true
        width: 480
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        padding: 0

        background: Rectangle {
            radius: Theme.radiusLarge
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: qsTr("Setup Awal — Mode Peta")
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.colorText
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Pilih cara Peta menampilkan Board/Item. Pilihan tersimpan dan bisa diganti kapan saja lewat dropdown di area Peta.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorMuted
            }

            PrimaryButton {
                objectName: "mapModeGlobalButton"
                Layout.fillWidth: true
                text: qsTr("Satu Papan Global")
                highlighted: true
                onClicked: {
                    appSettings.mapMode = "global"
                    mapModeSetupDialog.close()
                    root.showNewBoardInput()
                }
            }

            PrimaryButton {
                objectName: "mapModePerBoardButton"
                Layout.fillWidth: true
                text: qsTr("Multiple Papan")
                onClicked: {
                    appSettings.mapMode = "perboard"
                    mapModeSetupDialog.close()
                    root.showNewBoardInput()
                }
            }
        }
    }

    // Ghost kartu yang mengikuti kursor saat drag
    Rectangle {
        id: dragGhost
        visible: false
        z: 100
        width: Theme.columnWidth - Theme.spacingLarge
        height: Theme.cardHeight
        radius: Theme.radiusMedium
        color: Theme.colorSurfaceAlt
        border.color: Theme.colorAccent
        border.width: 2
        opacity: 0.9

        Text {
            id: dragGhostTitle
            anchors.fill: parent
            anchors.margins: Theme.spacingSmall
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeBody
            font.bold: true
            color: Theme.colorText
        }
    }
}
