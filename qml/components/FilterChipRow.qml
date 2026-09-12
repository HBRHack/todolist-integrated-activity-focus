// Hallmark · component: filter-chip-row · genre: editorial · theme: neo-brutalist (DESIGN.md)
// Baris chip filter: Prioritas (multi toggle, Tinggi/Sedang/Rendah) + Tag (multi toggle AND).
// View pemakai memegang state daftar (activePriorities/activeTagIds) dan handle toggle.
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    id: root

    property var tags: []
    property var activePriorities: []
    property var activeTagIds: []
    signal priorityToggled(int value)
    signal tagToggled(int tagId)

    Layout.fillWidth: true
    spacing: Theme.spacingTiny

    readonly property var priorityModel: [
        { value: 1, label: qsTr("Rendah") },
        { value: 2, label: qsTr("Sedang") },
        { value: 3, label: qsTr("Tinggi") }
    ]

    Text {
        text: qsTr("Prioritas")
        font.family: Theme.fontFamilyMono
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        font.capitalization: Font.AllUppercase
        color: Theme.colorMuted
        verticalAlignment: Text.AlignVCenter
    }

    Repeater {
        model: root.priorityModel
        Chip {
            text: modelData.label
            active: root.activePriorities.indexOf(modelData.value) !== -1
            onClicked: root.priorityToggled(modelData.value)
        }
    }

    Text {
        visible: root.tags.length > 0
        Layout.leftMargin: Theme.spacingMedium
        text: qsTr("Tag")
        font.family: Theme.fontFamilyMono
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        font.capitalization: Font.AllUppercase
        color: Theme.colorMuted
        verticalAlignment: Text.AlignVCenter
    }

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.smallControlHeight + 2
        visible: root.tags.length > 0
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: tagRow.width
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.horizontal: BrutalScrollBar {}

        Row {
            id: tagRow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: Theme.spacingTiny

            Repeater {
                model: root.tags
                TagChip {
                    text: modelData.name
                    colorKey: modelData.colorKey
                    active: root.activeTagIds.indexOf(modelData.id) !== -1
                    onClicked: root.tagToggled(modelData.id)
                }
            }
        }
    }
}