import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "."

Popup {
    id: root
    objectName: "promoteDialog"
    modal: true
    width: 460
    padding: 0

    property int itemId: -1
    property var optionEntries: []
    property var boardEntries: []
    readonly property bool perBoardMode: typeof appSettings !== "undefined" && appSettings
        && appSettings.mapMode === "perboard"

    function refreshEntries() {
        var raw = repo.boardColumnOptions()
        var opts = []
        for (var i = 0; i < raw.length; ++i)
            opts.push({
                label: raw[i].boardName + " · " + raw[i].columnName,
                columnId: raw[i].columnId,
                boardId: raw[i].boardId
            })
        root.optionEntries = opts

        var bs = repo.boardList()
        var entries = []
        for (var j = 0; j < bs.length; ++j)
            entries.push({ label: bs[j].name, id: bs[j].id })
        root.boardEntries = entries
    }

    function show(id) {
        root.itemId = id
        refreshEntries()
        boardCheck.checked = true
        petaCheck.checked = false
        boardBox.currentIndex = -1
        petaTargetBox.currentIndex = root.boardEntries.length > 0 ? 0 : -1
        errorHint.visible = false
        root.x = Math.round((parent.width - width) / 2)
        root.y = Math.round((parent.height - height) / 2)
        root.open()
    }

    function commit() {
        var any = boardCheck.checked || petaCheck.checked
        if (!any) {
            errorHint.text = qsTr("Pilih minimal satu tujuan (Board/Kolom dan/atau Peta).")
            errorHint.visible = true
            return
        }
        if (boardCheck.checked && boardBox.currentIndex < 0) {
            errorHint.text = qsTr("Pilih kolom tujuan.")
            errorHint.visible = true
            return
        }
        var targetBoardId = -1
        if (petaCheck.checked && root.perBoardMode) {
            if (petaTargetBox.currentIndex < 0) {
                errorHint.text = qsTr("Pilih papan target.")
                errorHint.visible = true
                return
            }
            targetBoardId = root.boardEntries[petaTargetBox.currentIndex].id
        }
        if (boardCheck.checked)
            repo.moveItem(root.itemId, root.optionEntries[boardBox.currentIndex].columnId,
                          Theme.moveToEnd)
        if (petaCheck.checked)
            // Tanpa posisi eksplisit: C++ memakai posisi terekam bila ada,
            // else fallback formula (QPointF() default = isNull).
            repo.mapItemToMap(root.itemId, targetBoardId)
        root.close()
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
            Layout.fillWidth: true
            text: qsTr("Petakan")
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Pilih satu atau lebih tujuan — tidak saling eksklusif.")
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        CheckBox {
            id: boardCheck
            objectName: "promoteBoardCheck"
            Layout.fillWidth: true
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeMedium
            text: qsTr("Board/Kolom")

            indicator: Rectangle {
                width: 18
                height: 18
                color: boardCheck.checked ? Theme.colorAccent : Theme.colorSurface
                border.color: boardCheck.checked ? Theme.colorAccent : Theme.colorBorder
                border.width: Theme.borderWidth
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: boardCheck.checked
                    color: Theme.colorBackground
                }
            }

            contentItem: Text {
                text: boardCheck.text
                font: boardCheck.font
                color: Theme.colorText
                leftPadding: boardCheck.indicator.width + 8
                verticalAlignment: Text.AlignVCenter
            }
        }

        SelectBox {
            id: boardBox
            objectName: "promoteBoardBox"
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            enabled: boardCheck.checked
            placeholderText: qsTr("Board · Kolom")
            model: root.optionEntries
            textRole: "label"
            onActivated: errorHint.visible = false
        }

        CheckBox {
            id: petaCheck
            objectName: "promotePetaCheck"
            Layout.fillWidth: true
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeMedium
            text: qsTr("Peta")

            indicator: Rectangle {
                width: 18
                height: 18
                color: petaCheck.checked ? Theme.colorAccent : Theme.colorSurface
                border.color: petaCheck.checked ? Theme.colorAccent : Theme.colorBorder
                border.width: Theme.borderWidth
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: petaCheck.checked
                    color: Theme.colorBackground
                }
            }

            contentItem: Text {
                text: petaCheck.text
                font: petaCheck.font
                color: Theme.colorText
                leftPadding: petaCheck.indicator.width + 8
                verticalAlignment: Text.AlignVCenter
            }
        }

        SelectBox {
            id: petaTargetBox
            objectName: "promoteBoardTargetBox"
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            visible: petaCheck.checked && root.perBoardMode
            placeholderText: qsTr("Papan target")
            model: root.boardEntries
            textRole: "label"
            onActivated: errorHint.visible = false
        }

        Text {
            id: globalHint
            Layout.fillWidth: true
            visible: petaCheck.checked && !root.perBoardMode
            wrapMode: Text.WordWrap
            text: qsTr("Mode Satu Papan Global — item otomatis menjadi node di kanvas global.")
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        Text {
            id: errorHint
            objectName: "promoteError"
            Layout.fillWidth: true
            visible: false
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: Theme.colorDanger
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Item { Layout.fillWidth: true }

            PrimaryButton {
                text: qsTr("Batal")
                onClicked: root.close()
            }

            PrimaryButton {
                objectName: "promoteBtn"
                text: qsTr("Petakan")
                highlighted: true
                onClicked: root.commit()
            }
        }
    }
}
