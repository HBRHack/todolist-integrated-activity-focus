// Hallmark · component: button · genre: editorial · theme: neo-brutalist (DESIGN.md)
// states: default · hover · focus · active · disabled
// contrast: pass (ink-on-paper 14:1+, accent-text 7:1+)
import QtQuick 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: lbl.text
    property bool highlighted: false
    property bool disabled: false
    signal clicked()

    implicitHeight: Theme.controlHeight
    implicitWidth: lbl.width + Theme.spacingHuge
    radius: Theme.radiusMedium
    color: "transparent"
    activeFocusOnTab: true

    // Hard shadow slab — tanpa blur (DropShadow = slop)
    Rectangle {
        id: shadowRect
        anchors.fill: face
        anchors.leftMargin: Theme.shadowOffset
        anchors.topMargin: Theme.shadowOffset
        color: Theme.colorShadow
        visible: !mouse.pressed && !root.disabled && face.visible
        z: -1
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: root.highlighted ? Theme.colorAccent
             : (mouse.hovered && !mouse.pressed) ? Theme.colorSurfaceAlt
             : mouse.pressed ? Theme.colorSurfaceAlt : Theme.colorSurface
        border.color: root.disabled ? Theme.colorMuted
                  : root.activeFocus ? Theme.colorAccent : Theme.colorBorder
        border.width: root.disabled ? Theme.borderWidthThin
                  : root.activeFocus ? Theme.borderWidth : Theme.borderWidth

        transform: Translate {
            x: mouse.pressed && !root.disabled ? 2 : 0
            y: mouse.pressed && !root.disabled ? 2 : 0
        }

        Text {
            id: lbl
            anchors.centerIn: parent
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.5
            color: root.disabled ? Theme.colorMuted
                 : root.highlighted ? Theme.colorAccentText : Theme.colorText
        }
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
