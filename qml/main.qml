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

            // Rail navigasi — slab dengan rule kanan 2px, item aktif = ink fill
            Rectangle {
                Layout.preferredWidth: Theme.sidebarWidth
                Layout.fillHeight: true
                color: Theme.colorSurface

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: Theme.borderWidth
                    color: Theme.colorBorder
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingTiny

                    // Logotype block — slab ink
                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        color: Theme.colorRail

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingMedium
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Peta Ide")
                                font.family: Theme.fontFamilyDisplay
                                font.pixelSize: Theme.fontSizeTitle
                                font.bold: true
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: Theme.letterSpacingDisplay
                                color: Theme.colorRailText
                            }

                            Text {
                                text: qsTr("Versi %1").arg(typeof appVersion !== "undefined" ? appVersion : "")
                                font.family: Theme.fontFamilyMono
                                font.pixelSize: Theme.fontSizeCaption
                                color: Theme.colorRailMuted
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.colorBorder
                    }

                    Repeater {
                        model: win.navModel
                        NavItem {
                            Layout.fillWidth: true
                            index: modelData.index + 1
                            text: modelData.label
                            active: win.currentIndex === modelData.index
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
