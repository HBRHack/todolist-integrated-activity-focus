import QtQuick 2.15
import "../theme"

// Pemilih warna strip kolom Kanban: 4 swatch dari token Theme preset aktif
// (accent/danger/active/accentContent). Warna tidak pernah di-hardcode —
// semua merujuk token, jadi ikut preset saat user ganti tema.
Item {
    id: picker

    property string selectedKey: "accent"
    signal picked(string key)

    readonly property var keys: ["accent", "danger", "active", "accentContent"]

    height: Theme.smallControlHeight
    implicitWidth: swatchRow.width

    readonly property int swatchW: 18

    Row {
        id: swatchRow
        anchors.centerIn: parent
        spacing: Theme.spacingSmall

        Repeater {
            model: picker.keys

            Rectangle {
                readonly property bool selected: picker.selectedKey === modelData
                width: picker.swatchW
                height: picker.swatchW
                radius: 0
                color: Theme.colorKeyToToken(modelData)
                border.color: selected ? Theme.colorText : Theme.colorBorder
                border.width: selected ? 3 : Theme.borderWidthThin

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: picker.picked(modelData)
                }
            }
        }
    }
}
