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

        // Tab bar board — strip surface + rule bawah 2px
        Rectangle {
            Layout.fillWidth: true
            height: Theme.tabBarHeight
            color: Theme.colorSurface

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.colorBorder
            }

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingTiny
                spacing: Theme.spacingTiny

                Repeater {
                    model: boards
                    Chip {
                        text: modelData.name
                        active: selectedBoardId === modelData.id
                        onClicked: selectBoard(modelData.id)
                        onDoubleClicked: {
                            renameBoardId = modelData.id
                            renameBoardField.text = modelData.name
                            renameBoardVisible = true
                        }
                    }
                }

                // Tab "+"
                Rectangle {
                    width: Theme.smallControlHeight
                    height: Theme.smallControlHeight
                    radius: 0
                    color: addBoardMouse.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
                    border.color: addBoardMouse.containsMouse || activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: activeFocus ? 3 : Theme.borderWidth
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Tambah Board")

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.family: Theme.fontFamilyBody
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

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                            root.beginAddBoard()
                            event.accepted = true
                        }
                    }
                }

                // Inline add board
                Rectangle {
                    visible: newBoardVisible
                    width: newBoardField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: 0
                    border.color: Theme.colorAccent
                    border.width: Theme.borderWidth
                    color: Theme.colorSurface

                    TextInput {
                        id: newBoardField
                        objectName: "newBoardField"
                        anchors.centerIn: parent
                        width: 120
                        font.family: Theme.fontFamilyBody
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
                    radius: 0
                    border.color: Theme.colorAccent
                    border.width: Theme.borderWidth
                    color: Theme.colorSurface

                    TextInput {
                        id: renameBoardField
                        anchors.centerIn: parent
                        width: 120
                        font.family: Theme.fontFamilyBody
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

        // Column header row — tombol kotak kecil
        Rectangle {
            Layout.fillWidth: true
            height: Theme.headerHeight
            color: Theme.colorBackground

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.colorBorder
            }

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                spacing: Theme.spacingMedium

                Repeater {
                    model: columns
                    Rectangle {
                        width: Theme.columnWidth
                        height: Theme.smallControlHeight
                        radius: 0
                        color: "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingTiny
                            spacing: Theme.spacingSmall

                            SquareToolButton {
                                text: "\u2039"
                                objectName: "moveColLeft_" + modelData.id
                                onClicked: root.moveColumnLeft(modelData.id, index)
                            }

                            Text {
                                width: 132
                                text: modelData.name
                                font.family: Theme.fontFamilyBody
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                font.capitalization: Font.AllUppercase
                                color: Theme.colorText
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight

                                MouseArea {
                                    anchors.fill: parent
                                    onDoubleClicked: {
                                        renameColumnId = modelData.id
                                        renameColumnField.text = modelData.name
                                        renameColumnVisible = true
                                    }
                                }
                            }

                            SquareToolButton {
                                text: "\u203A"
                                objectName: "moveColRight_" + modelData.id
                                onClicked: root.moveColumnRight(modelData.id, index)
                            }

                            SquareToolButton {
                                text: "\u00D7"
                                objectName: "deleteColumn_" + modelData.id
                                danger: true
                                onClicked: deleteColumn(modelData.id)
                            }
                        }
                    }
                }

                // Add column button
                Rectangle {
                    width: addColumnBtn.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: 0
                    color: addColumnMouse.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
                    border.color: addColumnMouse.containsMouse || activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: activeFocus ? 3 : Theme.borderWidth
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Tambah Kolom")

                    Text {
                        id: addColumnBtn
                        anchors.centerIn: parent
                        text: qsTr("+ Kolom")
                        font.family: Theme.fontFamilyBody
                        font.pixelSize: Theme.fontSizeBody
                        font.bold: true
                        color: Theme.colorAccentContent
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

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                            newColumnVisible = true
                            newColumnField.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

                // Inline add column
                Rectangle {
                    visible: newColumnVisible
                    width: newColumnField.width + Theme.spacingLarge
                    height: Theme.smallControlHeight
                    radius: 0
                    border.color: Theme.colorAccent
                    border.width: Theme.borderWidth
                    color: Theme.colorSurface

                    TextInput {
                        id: newColumnField
                        objectName: "newColumnField"
                        anchors.centerIn: parent
                        width: 100
                        font.family: Theme.fontFamilyBody
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
                    radius: 0
                    border.color: Theme.colorAccent
                    border.width: Theme.borderWidth
                    color: Theme.colorSurface

                    TextInput {
                        id: renameColumnField
                        anchors.centerIn: parent
                        width: 120
                        font.family: Theme.fontFamilyBody
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

        // Columns area
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: columns.length * (Theme.columnWidth + Theme.spacingMedium) + Theme.spacingHuge
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            ScrollBar.horizontal: BrutalScrollBar {}

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
                            radius: 0
                            color: Theme.colorSurface
                            border.color: dropHighlight ? Theme.colorAccent : Theme.colorBorder
                            border.width: dropHighlight ? 3 : Theme.borderWidth

                            property bool dropHighlight: false

                            ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            // Column header — display + count mono
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSmall

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: Theme.fontFamilyBody
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.bold: true
                                    font.capitalization: Font.AllUppercase
                                    color: Theme.colorText
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: columnList.count < 10 ? "0" + columnList.count : "" + columnList.count
                                    font.family: Theme.fontFamilyMono
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.bold: true
                                    color: Theme.colorMuted
                                }
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
                                ScrollBar.vertical: BrutalScrollBar {}

                                delegate: Item {
                                    id: cardRoot
                                    objectName: "card_" + columnId + "_" + orderIndex
                                    width: ListView.view.width
                                    height: Theme.cardHeight

                                    // Hard shadow DI BELAKANG kartu
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.rightMargin: Theme.shadowOffset
                                        anchors.bottomMargin: Theme.shadowOffset
                                        color: Theme.colorShadow
                                        visible: !dragArea.dragActive
                                    }

                                    // Kartu — surface (terang/dark ikut theme)
                                    Rectangle {
                                        id: card
                                        anchors.fill: parent
                                        radius: 0
                                        color: dragArea.dragActive ? Theme.colorSurfaceAlt
                                             : dragArea.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
                                        border.color: Theme.colorBorder
                                        border.width: Theme.borderWidth

                                        // Accent bar kiri — kontras jelas vs surface
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 3
                                            color: Theme.colorAccent
                                        }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: Theme.spacingSmall
                                            spacing: Theme.spacingTiny

                                            Text {
                                                Layout.fillWidth: true
                                                text: title
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamilyBody
                                                font.pixelSize: Theme.fontSizeBody
                                                font.bold: true
                                                color: Theme.colorText
                                            }

                                            Text {
                                                text: Format.dueDateString(dueDate)
                                                font.family: Theme.fontFamilyMono
                                                font.pixelSize: Theme.fontSizeCaption
                                                color: Theme.colorMuted
                                            }
                                        }

                                        MouseArea {
                                            id: dragArea
                                            anchors.fill: parent
                                            hoverEnabled: true
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

                                    Drag.active: dragArea.dragActive
                                    Drag.source: card
                                    Drag.keys: ["kanbanItem"]
                                    Drag.hotSpot.x: card.width / 2
                                    Drag.hotSpot.y: card.height / 2

                                    opacity: dragArea.dragActive ? 0.4 : 1.0
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.count === 0
                                    text: qsTr("Belum ada Item")
                                    font.family: Theme.fontFamilyBody
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
        font.family: Theme.fontFamilyBody
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
                text: qsTr("Setup Awal — Mode Peta")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Pilih cara Peta menampilkan Board/Item. Pilihan tersimpan dan bisa diganti kapan saja lewat dropdown di area Peta.")
                font.family: Theme.fontFamilyBody
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
        radius: 0
        color: Theme.colorSurface

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: Theme.shadowOffset
            anchors.topMargin: Theme.shadowOffset
            color: Theme.colorShadow
        }

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Theme.colorSurface
            border.color: Theme.colorAccent
            border.width: Theme.borderWidth
        }

        Text {
            id: dragGhostTitle
            anchors.fill: parent
            anchors.margins: Theme.spacingSmall
            elide: Text.ElideRight
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeBody
            font.bold: true
            color: Theme.colorText
        }
    }
}
