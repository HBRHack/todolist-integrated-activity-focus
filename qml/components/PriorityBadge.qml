// Hallmark · component: badge prioritas · genre: editorial · theme: neo-brutalist (DESIGN.md)
// Skala prioritas (CONTEXT.md): 1 = Rendah, 2 = Sedang, 3 = Tinggi.
// Visual per spec issue 18 §4:
//   3 (Tinggi) → kotak badge isi colorDangerFill + teks colorDangerText "TINGGI" (mono ≤ 11px)
//   2 (Sedang) → elemen kecil colorAccent (kotak 8px, non-teks)
//   1 (Rendah) → tanpa badge
import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Item {
    id: root

    property int priority: 1

    readonly property string textValue: root.priority >= 3 ? qsTr("Tinggi")
                                       : root.priority === 2 ? qsTr("Sedang")
                                       : qsTr("Rendah")

    implicitWidth: root.priority === 3 ? badgeLabel.width + Theme.spacingLarge
                  : root.priority === 2 ? 10 : 0
    implicitHeight: root.priority === 3 ? badgeLabel.height + 8
                    : root.priority === 2 ? 8 : 0

    ToolTip.visible: hover.hovered
    ToolTip.text: qsTr("Prioritas %1").arg(textValue)
    ToolTip.delay: 400

    HoverHandler {
        id: hover
    }

    // Tinggi — kotak badge dengan label mono
    Rectangle {
        id: highBadge
        visible: root.priority === 3
        anchors.centerIn: parent
        implicitWidth: badgeLabel.width + 10
        implicitHeight: badgeLabel.height + 6
        color: Theme.colorDangerFill
        border.color: Theme.colorDangerText
        border.width: Theme.borderWidthThin
        radius: 0

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: qsTr("TINGGI")
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeCaption
            font.bold: true
            color: Theme.colorDangerText
        }
    }

    // Sedang = elemen kecil non-teks
    Rectangle {
        visible: root.priority === 2
        anchors.centerIn: parent
        width: 8
        height: 8
        color: Theme.colorAccent
        radius: 0
    }
}