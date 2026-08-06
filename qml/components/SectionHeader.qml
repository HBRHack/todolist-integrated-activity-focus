// Hallmark · component: section-header · genre: editorial · theme: neo-brutalist (DESIGN.md)
// Slab ink-fill bar — label mono uppercase. Kebalikan dari label-abu biasa.
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text

    implicitWidth: lbl.width + Theme.spacingHuge
    implicitHeight: Theme.sectionHeight
    radius: 0
    color: Theme.colorSlab

    Text {
        id: lbl
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        font.family: Theme.fontFamilyMono
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
        color: Theme.colorSlabText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
