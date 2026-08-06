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

        // Header — display besar + counter mono
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("Inbox")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            Text {
                text: listView.count < 10 ? "0" + listView.count : "" + listView.count
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.colorMuted
                verticalAlignment: Text.AlignBottom
            }

            Item { Layout.fillWidth: true }
        }

        // Quick add — input kotak 2px + tombol ink
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            TextField {
                id: quickAddField
                objectName: "quickAddField"
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlHeight
                placeholderText: qsTr("Tulis Item — tanggal otomatis hari ini")
                color: Theme.colorText
                placeholderTextColor: Theme.colorMuted
                padding: Theme.spacingMedium
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeBody
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurface
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
                onAccepted: commitQuickAdd()
            }

            PrimaryButton {
                objectName: "quickAddButton"
                text: qsTr("Tambah")
                highlighted: true
                onClicked: commitQuickAdd()
            }
        }

        // Tabs board (mode per-board) — chip kotak
        Row {
            id: tabsBar
            visible: root.perBoardMode
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: root.tabsModel
                Chip {
                    text: modelData.label
                    active: root.selectedBoardId === modelData.id
                    onClicked: root.selectBoard(modelData.id)
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
            section.delegate: SectionHeader {
                width: listView.width
                text: section === "baru" ? qsTr("Baru") : section === "lama" ? qsTr("Lama") : qsTr("Dikembalikan")
            }

            delegate: Item {
                width: listView.width
                height: Theme.itemHeight

                // Hard shadow slab
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
                    border.color: Theme.colorBorder
                    border.width: Theme.borderWidth
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingTiny

                    Text {
                        Layout.fillWidth: true
                        text: title
                        elide: Text.ElideRight
                        font.family: Theme.fontFamilyBody
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.colorText
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Text {
                            text: Format.dueDateString(dueDate)
                            font.family: Theme.fontFamilyMono
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.colorMuted
                        }

                        Item { Layout.fillWidth: true }

                        ComboBox {
                            id: moveBox
                            Layout.preferredWidth: 220
                            Layout.preferredHeight: Theme.smallControlHeight
                            font.family: Theme.fontFamilyBody
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
                                radius: 0
                                color: Theme.colorSurfaceAlt
                                border.color: Theme.colorBorder
                                border.width: Theme.borderWidth
                            }
                            contentItem: Text {
                                text: moveBox.displayText
                                font: moveBox.font
                                color: Theme.colorText
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: Theme.spacingSmall
                                rightPadding: Theme.spacingHuge
                                elide: Text.ElideRight
                            }
                            indicator: Rectangle {
                                x: moveBox.width - width - 14
                                y: moveBox.height / 2 - height / 2
                                width: 8
                                height: 2
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
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorMuted
            }
        }
    }
}
