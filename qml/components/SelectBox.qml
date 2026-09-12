import QtQuick 2.15
import QtQuick.Controls 2.15
import "../theme"

ComboBox {
    id: root

    property string placeholderText: ""
    // Test seam: role opsional di model yang memuat objectName per baris
    // (misal opsi "moveToInboxOption" di detailMoveBox).
    property string delegateObjectNameRole: ""

    font.family: Theme.fontFamilyBody
    font.pixelSize: Theme.fontSizeSmall

    displayText: root.currentIndex >= 0 ? root.currentText : root.placeholderText

    background: Rectangle {
        radius: 0
        color: root.enabled ? (root.hovered ? Theme.colorSurfaceAlt : Theme.colorSurface)
             : Theme.colorSurfaceAlt
        border.color: root.activeFocus ? Theme.colorAccent : Theme.colorBorder
        border.width: root.activeFocus ? 3 : Theme.borderWidth
    }

    contentItem: Text {
        text: root.displayText
        font: root.font
        color: Theme.colorText
        verticalAlignment: Text.AlignVCenter
        leftPadding: Theme.spacingSmall
        rightPadding: root.indicator ? root.indicator.width + 12 : Theme.spacingHuge
        elide: Text.ElideRight
    }

    indicator: Rectangle {
        id: marker
        width: 8
        height: 2
        x: root.width - width - 12
        y: root.height / 2 - height / 2
        color: Theme.colorMuted
    }

    delegate: ItemDelegate {
        width: root.width
        height: Theme.smallControlHeight
        padding: 0
        objectName: root.delegateObjectNameRole.length > 0
                    && typeof modelData === "object" && modelData[root.delegateObjectNameRole]
                    ? modelData[root.delegateObjectNameRole] : ""

        background: Rectangle {
            radius: 0
            color: parent.highlighted ? Theme.colorAccent
                 : parent.hovered ? Theme.colorSurfaceAlt : Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidthThin
        }

        contentItem: Text {
            text: root.textRole.length > 0 ? modelData[root.textRole]
                                         : (typeof modelData === "object" ? "" : modelData)
            font: root.font
            color: parent.highlighted ? Theme.colorBackground : Theme.colorText
            verticalAlignment: Text.AlignVCenter
            leftPadding: Theme.spacingSmall
            rightPadding: Theme.spacingSmall
            elide: Text.ElideRight
        }

        highlighted: root.highlightedIndex === index
    }

    popup: Popup {
        id: comboPopup
        y: root.height + 2
        width: root.width
        implicitHeight: Math.min(listView.implicitHeight, 240)
        padding: 1
        leftMargin: 0
        rightMargin: 0

        background: Rectangle {
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidth
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
            ScrollBar.vertical: BrutalScrollBar {}
        }
    }
}