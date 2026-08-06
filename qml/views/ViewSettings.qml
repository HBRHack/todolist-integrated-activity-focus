import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Item {
    property var settings: typeof appSettings !== "undefined" ? appSettings : null

    Rectangle {
        anchors.fill: parent
        color: Theme.colorBackground
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingHuge
        spacing: Theme.spacingLarge

        Text {
            text: qsTr("Pengaturan")
            font.pixelSize: Theme.fontSizePageTitle
            font.bold: true
            color: Theme.colorText
        }

        Text {
            text: qsTr("Tema")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.colorText
        }

        Row {
            spacing: Theme.spacingMedium
            Repeater {
                model: Theme.presets
                PrimaryButton {
                    width: 110
                    text: modelData.label
                    highlighted: settings ? settings.theme === modelData.name : false
                    onClicked: {
                        Theme.apply(modelData.name)
                        if (settings)
                            settings.theme = modelData.name
                    }
                }
            }
        }

        Text {
            text: qsTr("Mode Inbox")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.colorText
        }

        Row {
            spacing: Theme.spacingMedium
            PrimaryButton {
                objectName: "inboxModeGlobalButton"
                width: 110
                text: qsTr("Global")
                highlighted: !settings || settings.inboxMode === "global"
                onClicked: {
                    if (settings)
                        settings.inboxMode = "global"
                }
            }
            PrimaryButton {
                objectName: "inboxModePerBoardButton"
                width: 110
                text: qsTr("Per-Board")
                highlighted: settings && settings.inboxMode === "perboard"
                onClicked: {
                    if (settings)
                        settings.inboxMode = "perboard"
                }
            }
        }

        Text {
            text: qsTr("Global = satu Inbox berisi semua Item belum dipetakan. Per-Board = Inbox terpecah per board.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        Text {
            text: qsTr("Bahasa")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.colorText
        }

        Row {
            spacing: Theme.spacingMedium
            PrimaryButton {
                objectName: "langAutoButton"
                width: 110
                text: qsTr("Auto (Sistem)")
                highlighted: !settings || settings.language === "auto"
                onClicked: {
                    if (settings)
                        settings.language = "auto"
                }
            }
            PrimaryButton {
                objectName: "langIdButton"
                width: 110
                text: "Indonesia"
                highlighted: settings && settings.language === "id"
                onClicked: {
                    if (settings)
                        settings.language = "id"
                }
            }
            PrimaryButton {
                objectName: "langEnButton"
                width: 110
                text: "English"
                highlighted: settings && settings.language === "en"
                onClicked: {
                    if (settings)
                        settings.language = "en"
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}