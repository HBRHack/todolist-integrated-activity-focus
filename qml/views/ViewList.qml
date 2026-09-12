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
    property var boardOptions: []
    property int selectedBoardId: -1

    function reloadBoards() {
        boards = repo.boardList()
        var exists = selectedBoardId === -1
        for (var i = 0; i < boards.length; ++i) {
            if (boards[i].id === selectedBoardId) {
                exists = true
                break
            }
        }
        if (!exists)
            selectedBoardId = boards.length > 0 ? boards[0].id : -1
    }

    function selectBoard(id) {
        selectedBoardId = id
        listProxy.boardId = id
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

    property var tagList: []

    function reloadTags() {
        tagList = repo.tagList()
    }

    property string filterQuery: ""
    property var filterPriorities: []
    property var filterTagIds: []
    property bool hasActiveFilter: filterQuery.length > 0
        || filterPriorities.length > 0 || filterTagIds.length > 0

    function applyQuery(query) {
        filterQuery = query
        listProxy.filterText = query
    }

    function togglePriorityFilter(value) {
        var out = []
        for (var i = 0; i < filterPriorities.length; ++i) {
            if (filterPriorities[i] !== value)
                out.push(filterPriorities[i])
        }
        if (out.length === filterPriorities.length)
            out.push(value)
        filterPriorities = out
        listProxy.filterPriorities = filterPriorities
    }

    function toggleTagFilter(tagId) {
        var out = []
        for (var i = 0; i < filterTagIds.length; ++i) {
            if (filterTagIds[i] !== tagId)
                out.push(filterTagIds[i])
        }
        if (out.length === filterTagIds.length)
            out.push(tagId)
        filterTagIds = out
        listProxy.filterTagIds = filterTagIds
    }

    function clearFilters() {
        searchField.text = ""
        filterQuery = ""
        filterPriorities = []
        filterTagIds = []
        listProxy.filterText = ""
        listProxy.filterPriorities = []
        listProxy.filterTagIds = []
    }

    function onListMode(index) {
        listProxy.sortMode = index === 0 ? "tanggal" : index === 1 ? "status" : "prioritas"
    }

    function openDetail(itemId) {
        detailPopup.show(itemId)
    }

    Connections {
        target: repo
        function onChanged() {
            root.reloadBoards()
            root.refreshOptions()
            root.reloadTags()
        }
    }

    Component.onCompleted: {
        reloadBoards()
        refreshOptions()
        reloadTags()
        listProxy.setItemModel(itemModel)
        listProxy.boardId = selectedBoardId
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // Header — display besar + kontrol sort di kanan
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("List")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            Item { Layout.fillWidth: true }

            SearchField {
                id: searchField
                objectName: "searchField"
                Layout.preferredWidth: 240
                placeholder: qsTr("Cari…")
                onSearchRequested: root.applyQuery(query)
            }

            Text {
                text: qsTr("Urutkan")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.capitalization: Font.AllUppercase
                color: Theme.colorMuted
                verticalAlignment: Text.AlignVCenter
            }

            SelectBox {
                id: sortModeBox
                objectName: "sortModeBox"
                Layout.preferredWidth: 200
                Layout.preferredHeight: Theme.smallControlHeight
                model: [qsTr("Tanggal"), qsTr("Status"), qsTr("Prioritas")]
                onActivated: root.onListMode(currentIndex)
            }
        }

        // Chip board — kotak
        Row {
            spacing: Theme.spacingTiny

            Chip {
                text: qsTr("Semua")
                active: root.selectedBoardId === -1
                onClicked: root.selectBoard(-1)
            }

            Repeater {
                model: root.boards
                Chip {
                    text: modelData.name
                    active: root.selectedBoardId === modelData.id
                    onClicked: root.selectBoard(modelData.id)
                }
            }
        }

        // Bar filter Prioritas + Tag — chip multi-toggle lintas view
        FilterChipRow {
            Layout.fillWidth: true
            tags: root.tagList
            activePriorities: root.filterPriorities
            activeTagIds: root.filterTagIds
            onPriorityToggled: root.togglePriorityFilter(value)
            onTagToggled: root.toggleTagFilter(tagId)
        }

        // Table-led rows — hairline rules, tanpa box kartu (ritme beda dari Inbox)
        ListView {
            id: listView
            objectName: "listView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            ScrollBar.vertical: BrutalScrollBar {}
            model: ListProxyModel {
                id: listProxy
                objectName: "listProxy"
            }

            delegate: Item {
                width: listView.width
                height: 44

                Rectangle {
                    anchors.fill: parent
                    color: mouse.containsMouse ? Theme.colorSurfaceAlt : "transparent"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.borderWidthThin
                    color: Theme.colorBorder
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSmall
                    anchors.rightMargin: Theme.spacingSmall
                    spacing: Theme.spacingMedium

                    Text {
                        text: index + 1 < 10 ? "0" + (index + 1) : "" + (index + 1)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.colorMuted
                        verticalAlignment: Text.AlignVCenter
                    }

                    PriorityBadge {
                        objectName: "prioCell_" + itemId
                        priority: model.priority
                    }

                    RowLayout {
                        id: tagRow
                        property var rowTags: model.tags
                        Layout.fillWidth: true
                        spacing: Theme.spacingTiny

                        Text {
                            Layout.fillWidth: true
                            text: model.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.family: Theme.fontFamilyBody
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            color: Theme.colorText
                            verticalAlignment: Text.AlignVCenter
                        }

                        InlineTagRow {
                            tags: tagRow.rowTags
                            maxChips: 2
                        }
                    }

                    Text {
                        text: Format.dueDateString(dueDate)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.colorMuted
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        objectName: "listStatus_" + itemId
                        text: root.statusLabel(columnId, boardName, columnName)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: columnId !== -1
                        color: columnId === -1 ? Theme.colorMuted : Theme.colorAccentContent
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openDetail(itemId)
                }
            }

            Column {
                anchors.centerIn: parent
                visible: root.hasActiveFilter && listView.count === 0
                spacing: Theme.spacingMedium

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Tidak ada hasil")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: Theme.colorMuted
                }

                PrimaryButton {
                    objectName: "clearFilter"
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Bersihkan filter")
                    onClicked: root.clearFilters()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasActiveFilter && listView.count === 0
                text: qsTr("Belum ada Item.")
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorMuted
            }
        }
    }

    ItemDetailPopup {
        id: detailPopup
        parent: root
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        boardOptions: root.boardOptions
    }
}
