import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Rectangle {
    id: root
    color: Theme.colorBackground

    property var boardOptions: []
    property var boards: []
    property var tabsModel: []
    property int selectedBoardId: -1
    property bool perBoardMode: false

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
        rebuildTabs()
    }

    function rebuildTabs() {
        var out = [{ id: -1, label: qsTr("Semua") }]
        for (var i = 0; i < boards.length; ++i)
            out.push({ id: boards[i].id, label: boards[i].name })
        tabsModel = out
    }

    function selectBoard(id) {
        selectedBoardId = id
        applyMode()
    }

    function applyMode() {
        var per = typeof appSettings !== "undefined" && appSettings
            && appSettings.inboxMode === "perboard"
        perBoardMode = per
        inboxModel.perBoard = per
        inboxModel.boardId = per ? selectedBoardId : -1
    }

    function commitQuickAdd() {
        var text = quickAddField.text.trim()
        if (text.length === 0)
            return
        repo.quickAdd(text)
        quickAddField.text = ""
    }

    Connections {
        target: typeof repo !== "undefined" ? repo : null
        function onChanged() {
            root.refreshOptions()
            root.reloadBoards()
        }
    }

    Connections {
        target: typeof appSettings !== "undefined" ? appSettings : null
        function onInboxModeChanged() {
            root.applyMode()
        }
    }

    Component.onCompleted: {
        refreshOptions()
        reloadBoards()
        applyMode()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        Text {
            text: qsTr("Inbox")
            font.pixelSize: Theme.fontSizePageTitle
            font.bold: true
            color: Theme.colorText
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            TextField {
                id: quickAddField
                objectName: "quickAddField"
                Layout.fillWidth: true
                placeholderText: qsTr("Tulis Item — tanggal otomatis hari ini")
                color: Theme.colorText
                placeholderTextColor: Theme.colorMuted
                background: Rectangle {
                    radius: Theme.radiusMedium
                    color: Theme.colorSurface
                    border.color: Theme.colorBorder
                    border.width: 1
                }
                onAccepted: commitQuickAdd()
            }

            PrimaryButton {
                objectName: "quickAddButton"
                text: qsTr("Tambah")
                onClicked: commitQuickAdd()
            }
        }

        Row {
            id: tabsBar
            visible: root.perBoardMode
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: root.tabsModel
                Rectangle {
                    width: tabLabel.width + Theme.spacingHuge
                    height: Theme.smallControlHeight
                    radius: Theme.radiusSmall
                    color: root.selectedBoardId === modelData.id ? Theme.colorAccent : "transparent"

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Theme.fontSizeBody
                        font.bold: root.selectedBoardId === modelData.id
                        color: root.selectedBoardId === modelData.id ? Theme.colorAccentText : Theme.colorText
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingSmall
            model: inboxModel
            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle {
                width: listView.width
                height: Theme.sectionHeight
                color: "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: section === "baru" ? qsTr("Baru") : section === "lama" ? qsTr("Lama") : qsTr("Dikembalikan")
                    font.pixelSize: Theme.fontSizeBody
                    font.bold: true
                    color: Theme.colorMuted
                }
            }

            delegate: Item {
                width: listView.width
                height: Theme.itemHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusLarge
                    color: Theme.colorSurface
                    border.color: Theme.colorBorder
                    border.width: 1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingTiny

                    Text {
                        Layout.fillWidth: true
                        text: title
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeLarge
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

                        ComboBox {
                            id: moveBox
                            Layout.preferredWidth: 220
                            font.pixelSize: Theme.fontSizeSmall
                            displayText: currentIndex >= 0 ? currentText : qsTr("Pindah ke kolom…")
                            model: root.boardOptions
                            textRole: "label"
                            onActivated: {
                                if (index >= 0)
                                    repo.moveItem(itemId, root.boardOptions[index].columnId, 0)
                                currentIndex = -1
                            }
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: Theme.colorSurfaceAlt
                                border.color: Theme.colorBorder
                                border.width: 1
                            }
                            contentItem: Text {
                                text: moveBox.displayText
                                font: moveBox.font
                                color: Theme.colorText
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            indicator: Rectangle {
                                x: moveBox.width - width - 10
                                y: moveBox.height / 2 - height / 2
                                width: 10
                                height: 6
                                color: Theme.colorMuted
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: qsTr("Tidak ada Item di Inbox. Ketik di atas untuk menangkap Item.")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorMuted
            }
        }
    }
}