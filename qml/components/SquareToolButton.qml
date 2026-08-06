// Hallmark · component: square-tool-button · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · disabled
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool danger: false
    property bool disabled: false
    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: 0
    color: root.disabled ? "transparent"
         : mouse.containsMouse && !mouse.pressed ? Theme.colorSurfaceAlt
         : mouse.pressed ? Theme.colorSurfaceAlt : "transparent"
    border.color: root.disabled ? Theme.colorMuted
                : root.activeFocus ? Theme.colorAccent : "transparent"
    border.width: root.disabled ? Theme.borderWidthThin
                : root.activeFocus ? Theme.borderWidth : 0
    activeFocusOnTab: true
    opacity: root.disabled ? 0.5 : 1.0

    Text {
        id: lbl
        anchors.centerIn: parent
        font.family: Theme.fontFamilyBody
        font.pixelSize: Theme.fontSizeMedium
        font.bold: true
        color: root.disabled ? Theme.colorMuted
             : root.danger ? Theme.colorDanger : Theme.colorText
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
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