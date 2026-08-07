// Hallmark · component: nav-item · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active · focus · pressed
// contrast: pass (ink-on-paper ≥ 14:1)
import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property int index: 0
    property bool active: false
    signal clicked()

    implicitHeight: 42
    radius: 0
    color: root.active ? Theme.colorActive
         : mouse.containsMouse ? Theme.colorSurfaceAlt : "transparent"
    activeFocusOnTab: true

    Rectangle {
        id: accentBar
        width: 4
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: 0
        color: Theme.colorAccent
        visible: root.active
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingLarge
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            text: root.index < 10 ? "0" + root.index : "" + root.index
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: root.active ? Theme.colorBackground : Theme.colorMuted
        }

        Text {
            id: lbl
            Layout.fillWidth: true
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeMedium
            font.bold: root.active
            font.capitalization: Font.AllUppercase
            color: root.active ? Theme.colorBackground : Theme.colorText
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.activeFocus ? 3 : 1
        color: root.activeFocus ? Theme.colorAccent : Theme.colorBorder
        visible: root.activeFocus || !root.active
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