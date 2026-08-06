// Hallmark · component: chip · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · pressed · disabled
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool active: false
    property bool disabled: false
    signal clicked()
    signal doubleClicked()

    implicitWidth: lbl.width + Theme.spacingHuge
    implicitHeight: Theme.smallControlHeight
    radius: Theme.radiusSmall
    color: root.disabled ? Theme.colorSurface
         : root.active ? Theme.colorActive
         : mouse.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
    border.color: root.disabled ? Theme.colorMuted
                : root.activeFocus ? Theme.colorAccent : Theme.colorText
    border.width: root.disabled ? Theme.borderWidthThin
                : root.activeFocus ? Theme.borderWidth : Theme.borderWidth
    activeFocusOnTab: true
    opacity: root.disabled ? 0.5 : 1.0

    transform: Translate {
        x: mouse.pressed && !root.disabled ? 2 : 0
        y: mouse.pressed && !root.disabled ? 2 : 0
    }

    Text {
        id: lbl
        anchors.centerIn: parent
        font.family: Theme.fontFamilyBody
        font.pixelSize: Theme.fontSizeBody
        font.bold: true
        color: root.disabled ? Theme.colorMuted
             : root.active ? Theme.colorBackground : Theme.colorText
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: !root.disabled
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.disabled)
                root.clicked()
        }
        onDoubleClicked: {
            if (!root.disabled)
                root.doubleClicked()
        }
    }

    Keys.onPressed: {
        if (!root.disabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return)) {
            root.clicked()
            event.accepted = true
        }
    }

    states: [
        State {
            name: "disabled"
            when: root.disabled
            PropertyChanges { target: root; opacity: 0.5 }
        }
    ]
}
