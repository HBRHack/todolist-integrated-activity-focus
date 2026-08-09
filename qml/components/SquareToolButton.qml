// Hallmark · component: square-tool-button · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · disabled
import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool danger: false
    property bool active: false
    property bool disabled: false
    property string tooltip: ""
    property int glyphSize: Theme.fontSizeMedium
    property bool hovered: mouse.containsMouse
    signal clicked()

    implicitWidth: 24
    implicitHeight: 24
    radius: 0
    color: root.disabled ? "transparent"
         : root.active ? Theme.colorSurfaceAlt
         : mouse.containsMouse && !mouse.pressed ? Theme.colorSurfaceAlt
         : mouse.pressed ? Theme.colorSurfaceAlt : "transparent"
    border.color: root.disabled ? "transparent"
         : root.active ? Theme.colorAccent
         : root.activeFocus ? Theme.colorAccent : "transparent"
    border.width: root.active || root.activeFocus ? 2 : 0
    activeFocusOnTab: true
    opacity: root.disabled ? 0.35 : 1.0

    Text {
        id: lbl
        anchors.centerIn: parent
        font.family: Theme.fontFamilyBody
        font.pixelSize: root.glyphSize
        font.bold: true
        color: root.danger ? Theme.colorDanger : Theme.colorMuted
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    ToolTip {
        id: tip
        visible: root.tooltip.length > 0 && root.hovered
        text: root.tooltip
        delay: 600
        y: parent.height + 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Keys.onPressed: {
        if (!root.disabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return)) {
            root.clicked()
            event.accepted = true
        }
    }
}