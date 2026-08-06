pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    readonly property var presets: [
        { name: "light", label: qsTr("Terang"), background: "#F6F7FB", surface: "#FFFFFF", surfaceAlt: "#EEF0F6", text: "#1F2430", muted: "#8A93A6", accent: "#4F6BFF", border: "#E2E5EE", danger: "#E5484D" },
        { name: "dark", label: qsTr("Gelap"), background: "#14161C", surface: "#1C1F27", surfaceAlt: "#262A34", text: "#E8EAF0", muted: "#7C8494", accent: "#6C8CFF", border: "#2E3340", danger: "#E5484D" },
        { name: "biru", label: qsTr("Aksen Pirus"), background: "#F4F8FB", surface: "#FFFFFF", surfaceAlt: "#EAF1F7", text: "#14243A", muted: "#7A8CA0", accent: "#0FA3B1", border: "#DCE7EF", danger: "#E5484D" }
    ]

    // Warna — satu sumber (PRD §10)
    property color colorBackground
    property color colorSurface
    property color colorSurfaceAlt
    property color colorText
    property color colorMuted
    property color colorAccent
    property color colorAccentText
    property color colorBorder
    property color colorDanger

    // Spacing
    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingHuge: 24

    // Font
    readonly property int fontSizeCaption: 11
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeBody: 13
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
    readonly property int fontSizePageTitle: 24
    readonly property int fontSizeHero: 28

    // Ukuran komponen
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 6
    readonly property int radiusLarge: 8
    readonly property int controlHeight: 34
    readonly property int smallControlHeight: 28
    readonly property int tabBarHeight: 40
    readonly property int headerHeight: 40
    readonly property int cardHeight: 52
    readonly property int itemHeight: 58
    readonly property int sectionHeight: 26
    readonly property int columnWidth: 240
    readonly property int sidebarWidth: 180

    readonly property int nodeWidth: 200
    readonly property int nodeHeight: 60
    readonly property int dragThreshold: 8
    readonly property int moveToEnd: 99

    function apply(name) {
        var p = presets[0]
        for (var i = 0; i < presets.length; ++i) {
            if (presets[i].name === name) {
                p = presets[i]
                break
            }
        }
        colorBackground = p.background
        colorSurface = p.surface
        colorSurfaceAlt = p.surfaceAlt
        colorText = p.text
        colorMuted = p.muted
        colorAccent = p.accent
        colorAccentText = "#FFFFFF"
        colorBorder = p.border
        colorDanger = p.danger
    }

    Component.onCompleted: apply("light")
}
