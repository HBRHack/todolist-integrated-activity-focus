import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "."

Popup {
    id: root
    objectName: "detailPopup"
    modal: true
    width: 440
    padding: 0

    property int itemId: -1
    property var boardOptions: []

    function show(id) {
        itemId = id
        root.open()
    }

    function statusLabel(columnId, boardName, columnName) {
        if (columnId === -1)
            return qsTr("Inbox")
        return boardName + " · " + columnName
    }

    function moveToColumn(columnId) {
        if (root.itemId !== -1)
            repo.moveItem(root.itemId, columnId, Theme.moveToEnd)
        root.close()
    }

    function applyDate() {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateField.text)
        if (!m || root.itemId === -1)
            return
        repo.rescheduleItem(root.itemId, new Date(+m[1], +m[2] - 1, +m[3]))
        dateField.focus = false
    }

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
            id: detailTitle
            Layout.fillWidth: true
            text: ""
            elide: Text.ElideRight
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Text {
            id: detailInfo
            Layout.fillWidth: true
            text: ""
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.borderWidth
            color: Theme.colorBorder
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            TextField {
                id: dateField
                objectName: "detailDateField"
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlHeight
                verticalAlignment: Text.AlignVCenter
                padding: 8
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorText
                selectByMouse: true
                placeholderText: qsTr("yyyy-MM-dd")
                placeholderTextColor: Theme.colorMuted
                validator: RegExpValidator { regExp: /^\d{4}-\d{2}-\d{2}$/ }
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurfaceAlt
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
            }

            PrimaryButton {
                objectName: "detailDateApply"
                Layout.preferredWidth: Theme.controlHeight * 2
                text: qsTr("Simpan")
                onClicked: root.applyDate()
            }
        }

        SelectBox {
            id: detailMoveBox
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            placeholderText: qsTr("Pindah ke kolom…")
            model: root.boardOptions
            textRole: "label"
            onActivated: {
                if (index >= 0)
                    root.moveToColumn(root.boardOptions[index].columnId)
                currentIndex = -1
            }
        }

        PrimaryButton {
            Layout.fillWidth: true
            text: qsTr("Tutup")
            highlighted: true
            onClicked: root.close()
        }
    }

    onOpened: {
        var info = repo.itemInfo(root.itemId)
        detailTitle.text = info.title
        var date = info.dueDate ? Format.dueDateString(info.dueDate) : ""
        detailInfo.text = statusLabel(info.columnId, info.boardName, info.columnName)
            + (date.length > 0 ? " · " + date : "")
        dateField.text = info.dueDate ? info.dueDate : ""
        detailMoveBox.currentIndex = -1
    }
}