import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "theme"
import "views"
import "components"

ApplicationWindow {
    id: win
    width: 1100
    height: 700
    visible: true
    title: qsTr("Peta Ide")

    property int currentIndex: 0
    property var navModel: [
        { label: qsTr("Inbox"), index: 0 },
        { label: qsTr("List"), index: 1 },
        { label: qsTr("Kanban"), index: 2 },
        { label: qsTr("Kalender"), index: 3 },
        { label: qsTr("Peta"), index: 4 },
        { label: qsTr("Pengaturan"), index: 5 }
    ]

    Component.onCompleted: Theme.apply(appSettings.theme)

    Rectangle {
        anchors.fill: parent
        color: Theme.colorBackground

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: Theme.sidebarWidth
                Layout.fillHeight: true
                color: Theme.colorSurface

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingSmall

                    Text {
                        text: qsTr("Peta Ide")
                        font.pixelSize: Theme.fontSizeTitle
                        font.bold: true
                        color: Theme.colorAccent
                    }

                    Item { height: Theme.spacingTiny }

                    Repeater {
                        model: win.navModel
                        PrimaryButton {
                            Layout.fillWidth: true
                            text: modelData.label
                            highlighted: win.currentIndex === modelData.index
                            onClicked: win.currentIndex = modelData.index
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    anchors.fill: parent
                    currentIndex: win.currentIndex
                    ViewInbox {}
                    ViewList {}
                    ViewKanban {}
                    ViewCalendar {}
                    ViewMap {}
                    ViewSettings {}
                }
            }
        }
    }
}