// Hallmark · component: chip tag · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · active
// contrast: pass (ink-on-paper, accent text 7:1+)
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property string text: ""
    property string colorKey: "neutral"
    property bool active: false
    signal clicked()

    implicitWidth: label.width + Theme.spacingHuge + dot.radius * 2 + Theme.spacingTiny
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

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingTiny

        Rectangle {
            id: dot
            width: root.height / 2
            height: root.height / 2
            radius: width / 2
            color: Theme.colorKeyToToken(root.colorKey)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: label
            text: root.text
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeCaption
            font.bold: true
            color: root.active ? Theme.colorBackground : Theme.colorText
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // Aturan DESIGN.md: Keys.* nempel di elemen yang punya activeFocusOnTab
    // (root), bukan di MouseArea — key event tidak pernah sampai ke situ.
    Keys.onPressed: {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
            root.clicked()
            event.accepted = true
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.text
}