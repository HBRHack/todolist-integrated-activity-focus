import QtQuick 2.15
import "../theme"

Rectangle {
    id: root
    property alias text: lbl.text
    property bool highlighted: false
    signal clicked()

    implicitHeight: Theme.controlHeight
    radius: Theme.radiusMedium
    color: highlighted ? Theme.colorAccent : Theme.colorSurface
    border.color: Theme.colorBorder
    border.width: 1

    Text {
        id: lbl
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeMedium
        font.bold: root.highlighted
        color: highlighted ? Theme.colorAccentText : Theme.colorText
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}