// Hallmark · component: chip · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · pressed
// contrast: pass (ink-on-paper, accent text 7:1+)
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool active: false
    signal clicked()
    signal doubleClicked()

    implicitWidth: lbl.width + Theme.spacingHuge
    implicitHeight: Theme.smallControlHeight
    radius: Theme.radiusSmall
    color: root.active ? Theme.colorActive
         : mouse.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
    border.color: root.activeFocus ? Theme.colorAccent : Theme.colorText
    border.width: root.activeFocus ? 3 : Theme.borderWidth
    activeFocusOnTab: true

    transform: Translate {
        x: mouse.pressed ? 2 : 0
        y: mouse.pressed ? 2 : 0
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        font.family: Theme.fontFamilyBody
        font.pixelSize: Theme.fontSizeBody
        font.bold: true
        color: root.active ? Theme.colorBackground : Theme.colorText
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
            root.clicked()
            event.accepted = true
        }
    }
}
