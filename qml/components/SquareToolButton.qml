// Hallmark · component: square-tool-button · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · disabled
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool danger: false
    property bool active: false
    property bool hovered: mouse.containsMouse
    signal clicked()

    implicitWidth: 24
    implicitHeight: 24
    radius: 0
    color: root.active ? Theme.colorSurfaceAlt
         : mouse.containsMouse && !mouse.pressed ? Theme.colorSurfaceAlt
         : mouse.pressed ? Theme.colorSurfaceAlt : "transparent"
    border.color: root.active ? Theme.colorAccent
         : root.activeFocus ? Theme.colorAccent : "transparent"
    border.width: root.active || root.activeFocus ? 2 : 0
    activeFocusOnTab: true

    Text {
        id: lbl
        anchors.centerIn: parent
        font.family: Theme.fontFamilyBody
        font.pixelSize: Theme.fontSizeMedium
        font.bold: true
        color: root.danger ? Theme.colorDanger : Theme.colorMuted
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
            root.clicked()
            event.accepted = true
        }
    }
}