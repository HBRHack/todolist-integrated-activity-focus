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

    function openDetail(itemId) {
        detailPopup.show(itemId)
    }

    Connections {
        target: repo
        function onChanged() {
            root.reloadBoards()
            root.refreshOptions()
        }
    }

    Component.onCompleted: {
        reloadBoards()
        refreshOptions()
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

            Text {
                text: qsTr("Urutkan")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.capitalization: Font.AllUppercase
                color: Theme.colorMuted
                verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                id: sortModeBox
                objectName: "sortModeBox"
                Layout.preferredWidth: 200
                Layout.preferredHeight: Theme.smallControlHeight
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                model: [qsTr("Tanggal"), qsTr("Status")]
                onActivated: listProxy.sortMode = currentIndex === 0 ? "tanggal" : "status"
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurface
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
                contentItem: Text {
                    text: sortModeBox.displayText
                    font: sortModeBox.font
                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: Theme.spacingSmall
                    rightPadding: Theme.spacingHuge
                    elide: Text.ElideRight
                }
                indicator: Rectangle {
                    x: sortModeBox.width - width - 14
                    y: sortModeBox.height / 2 - height / 2
                    width: 8
                    height: 2
                    color: Theme.colorMuted
                }
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

        // Table-led rows — hairline rules, tanpa box kartu (ritme beda dari Inbox)
        ListView {
            id: listView
            objectName: "listView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
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

                    Text {
                        Layout.fillWidth: true
                        text: title
                        elide: Text.ElideRight
                        font.family: Theme.fontFamilyBody
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: Theme.colorText
                        verticalAlignment: Text.AlignVCenter
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
                        color: columnId === -1 ? Theme.colorMuted : Theme.colorAccent
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

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
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
