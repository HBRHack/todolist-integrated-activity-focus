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
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizePageTitle
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        // ===== Tema — 5 swatch kotak =====
        Text {
            text: qsTr("Tema")
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.borderWidth
            color: Theme.colorBorder
        }

        Row {
            spacing: Theme.spacingMedium

            Repeater {
                model: Theme.presets

                Rectangle {
                    width: 120
                    height: 74
                    radius: 0
                    color: Theme.colorSurface
                    border.color: swatchMouse.containsMouse ? Theme.colorAccent
                         : (settings && settings.theme === modelData.name) ? Theme.colorActive : Theme.colorBorder
                    border.width: (settings && settings.theme === modelData.name) ? 3 : Theme.borderWidth

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall
                        spacing: Theme.spacingSmall

                        Row {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                width: 24
                                height: 18
                                radius: 0
                                color: modelData.background
                                border.color: Theme.colorBorder
                                border.width: 1
                            }

                            Rectangle {
                                width: 24
                                height: 18
                                radius: 0
                                color: modelData.accent
                                border.color: Theme.colorBorder
                                border.width: 1
                            }

                            Rectangle {
                                width: 24
                                height: 18
                                radius: 0
                                color: modelData.text
                                border.color: Theme.colorBorder
                                border.width: 1
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.family: Theme.fontFamilyBody
                            font.pixelSize: Theme.fontSizeBody
                            font.bold: true
                            color: Theme.colorText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: swatchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Theme.apply(modelData.name)
                            if (settings)
                                settings.theme = modelData.name
                        }
                    }
                }
            }
        }

        // ===== Mode Inbox =====
        Text {
            text: qsTr("Mode Inbox")
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.borderWidth
            color: Theme.colorBorder
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
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        // ===== Bahasa =====
        Text {
            text: qsTr("Bahasa")
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.borderWidth
            color: Theme.colorBorder
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

        Text {
            objectName: "appVersionLabel"
            text: qsTr("Versi %1").arg(typeof appVersion !== "undefined" ? appVersion : "")
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }
    }
}