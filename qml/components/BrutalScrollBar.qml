import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

ScrollBar {
    id: root

    property color handleColor: Theme.colorText

    contentItem: Rectangle {
        implicitWidth: 8
        implicitHeight: 6
        radius: 0
        color: root.pressed || root.hovered ? Theme.colorAccentContent : root.handleColor
        opacity: root.size > 0 && root.interactive ? 1 : 0
    }

    background: Rectangle {
        implicitWidth: 8
        implicitHeight: 6
        color: "transparent"
    }
}