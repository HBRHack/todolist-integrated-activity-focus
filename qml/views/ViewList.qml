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

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("List")
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                color: Theme.colorText
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Urutkan")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorMuted
                verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                id: sortModeBox
                objectName: "sortModeBox"
                Layout.preferredWidth: 200
                font.pixelSize: Theme.fontSizeSmall
                model: [qsTr("Tanggal"), qsTr("Status")]
                onActivated: listProxy.sortMode = currentIndex === 0 ? "tanggal" : "status"
                background: Rectangle {
                    radius: Theme.radiusMedium
                    color: Theme.colorSurface
                    border.color: Theme.colorBorder
                    border.width: 1
                }
                contentItem: Text {
                    text: sortModeBox.displayText
                    font: sortModeBox.font
                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                indicator: Rectangle {
                    x: sortModeBox.width - width - 10
                    y: sortModeBox.height / 2 - height / 2
                    width: 10
                    height: 6
                    color: Theme.colorMuted
                }
            }
        }

        Row {
            spacing: Theme.spacingTiny

            Rectangle {
                width: allChipLabel.width + Theme.spacingLarge
                height: Theme.smallControlHeight
                radius: Theme.radiusSmall
                color: selectedBoardId === -1 ? Theme.colorAccent : "transparent"

                Text {
                    id: allChipLabel
                    anchors.centerIn: parent
                    text: qsTr("Semua")
                    font.pixelSize: Theme.fontSizeBody
                    font.bold: selectedBoardId === -1
                    color: selectedBoardId === -1 ? Theme.colorAccentText : Theme.colorText
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectBoard(-1)
                }
            }

            Repeater {
                model: root.boards
                Rectangle {
                    width: chipLabel.width + Theme.spacingHuge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    color: selectedBoardId === modelData.id ? Theme.colorAccent : "transparent"

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: modelData.name
                        font.pixelSize: Theme.fontSizeBody
                        font.bold: selectedBoardId === modelData.id
                        color: selectedBoardId === modelData.id ? Theme.colorAccentText : Theme.colorText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectBoard(modelData.id)
                    }
                }
            }
        }

        ListView {
            id: listView
            objectName: "listView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingSmall
            model: ListProxyModel {
                id: listProxy
                objectName: "listProxy"
            }

            delegate: Rectangle {
                width: listView.width
                height: Theme.itemHeight
                radius: Theme.radiusLarge
                color: Theme.colorSurface
                border.color: Theme.colorBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingTiny

                    Text {
                        Layout.fillWidth: true
                        text: title
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.colorText
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Text {
                            text: Format.dueDateString(dueDate)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.colorMuted
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            objectName: "listStatus_" + itemId
                            text: root.statusLabel(columnId, boardName, columnName)
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: columnId !== -1
                            color: columnId === -1 ? Theme.colorMuted : Theme.colorAccent
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openDetail(itemId)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: qsTr("Belum ada Item.")
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