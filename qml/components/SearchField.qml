// Hallmark · component: search · genre: editorial · theme: neo-brutalist (DESIGN.md)
// Debounce 150 ms + tombol ✕ — query hanya dikirim setelah jeda ketik.
import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

Rectangle {
    id: root

    property alias text: field.text
    property alias placeholder: field.placeholderText
    property int debounceMs: 150
    signal searchRequested(string query)

    implicitWidth: 240
    implicitHeight: Theme.controlHeight
    objectName: "searchField"
    radius: Theme.radiusSmall
    border.color: field.activeFocus ? Theme.colorAccent : Theme.colorBorder
    border.width: field.activeFocus ? 3 : Theme.borderWidth
    color: Theme.colorBackground

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        text: "\u2315"
        font.family: Theme.fontFamilyMono
        font.pixelSize: Theme.fontSizeBody
        color: Theme.colorMuted
    }

    SquareToolButton {
        id: clearBtn
        objectName: "searchClearButton"
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        visible: field.text.length > 0
        implicitWidth: Theme.smallControlHeight
        implicitHeight: Theme.smallControlHeight
        text: "\u2715"
        onClicked: {
            field.text = ""
            debounce.stop()
            root.searchRequested("")
        }
    }

    TextField {
        id: field
        objectName: "searchFieldInput"
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.right: clearBtn.visible ? clearBtn.left : parent.right
        anchors.rightMargin: clearBtn.visible ? 2 : Theme.spacingSmall
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        padding: 0
        color: Theme.colorText
        placeholderTextColor: Theme.colorMuted
        font.family: Theme.fontFamilyBody
        font.pixelSize: Theme.fontSizeBody
        background: Item {}
        selectByMouse: true
        onTextChanged: debounce.restart()
    }

    Timer {
        id: debounce
        interval: root.debounceMs
        onTriggered: root.searchRequested(root.text)
    }
}