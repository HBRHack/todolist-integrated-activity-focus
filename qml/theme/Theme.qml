// Hallmark · genre: editorial · tone: neo-brutalist · design-system: DESIGN.md · designed-as-app
// Hallmark · pre-emit critique: P5 H5 E5 S5 R4 V4
// Sistem desain terkunci (DESIGN.md). Semua view WAJIB share token ini —
// tidak ada variasi tema antar view. Preset key "light"/"dark" dipertahankan
// karena dipakai test (tst_shell) dan settings lama.
pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    readonly property var presets: [
        { name: "light", label: qsTr("Terang"), background: "#F2F0E8", surface: "#FFFFFF", surfaceAlt: "#E6E4DA", text: "#141414", muted: "#63615A", accent: "#FF4D00", border: "#141414", danger: "#E53131", active: "#141414", accentText: "#141414", shadow: "#141414" },
        { name: "dark", label: qsTr("Gelap"), background: "#141414", surface: "#232323", surfaceAlt: "#303030", text: "#F2F0E8", muted: "#9A9890", accent: "#7FB4FF", border: "#F2F0E8", danger: "#FF5252", active: "#7FB4FF", accentText: "#10233F", shadow: "#000000" },
        { name: "pirus", label: qsTr("Pirus"), background: "#EEF3F0", surface: "#FFFFFF", surfaceAlt: "#DDE6E1", text: "#10211B", muted: "#5D6E66", accent: "#00A88E", border: "#10211B", danger: "#E53131", active: "#10211B", accentText: "#141414", shadow: "#10211B" },
        { name: "elektrik", label: qsTr("Elektrik"), background: "#E3ECFA", surface: "#FFFFFF", surfaceAlt: "#D4E1F5", text: "#10233F", muted: "#5E7293", accent: "#2F6BFF", border: "#10233F", danger: "#E53131", active: "#10233F", accentText: "#141414", shadow: "#10233F" },
        { name: "asam", label: qsTr("Asam"), background: "#EDF4E0", surface: "#FFFFFF", surfaceAlt: "#DFEAD0", text: "#1A2413", muted: "#66704F", accent: "#8FC900", border: "#1A2413", danger: "#E53131", active: "#1A2413", accentText: "#141414", shadow: "#1A2413" }
    ]

    // Warna — satu sumber (PRD §10). OKLCH tidak bisa diparse Qt 5.15 →
    // hex terkunci di sini (lihat DESIGN.md).
    property color colorBackground
    property color colorSurface
    property color colorSurfaceAlt
    property color colorText
    property color colorMuted
    property color colorAccent
    property color colorAccentText
    property color colorBorder
    property color colorDanger
    property color colorDangerText: "#FFFFFF"
    property color colorActive

    // Turunan (dihitung dari preset, bukan di-hardcode per preset)
    property color colorShadow: colorText
    property color colorRail: colorText
    property color colorRailText: colorBackground
    property color colorSlab: colorText
    property color colorSlabText: colorBackground

    // Geometri brutal: semua radius 0, border tebal, hard shadow offset
    readonly property int radiusSmall: 0
    readonly property int radiusMedium: 0
    readonly property int radiusLarge: 0
    readonly property int borderWidth: 2
    readonly property int borderWidthThin: 1
    readonly property int shadowOffset: 3

    // Font — sistem (tanpa bundle): display = Noto Sans Bold uppercase,
    // mono = DejaVu Sans Mono untuk tanggal/angka/index. Qt fallback otomatis.
    readonly property string fontFamilyDisplay: "Noto Sans"
    readonly property string fontFamilyBody: "Noto Sans"
    readonly property string fontFamilyMono: "DejaVu Sans Mono"
    readonly property int letterSpacingDisplay: 1

    // Spacing (skala 4pt)
    readonly property int spacingTiny: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingHuge: 24

    // Font scale
    readonly property int fontSizeCaption: 11
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeBody: 13
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
    readonly property int fontSizePageTitle: 26
    readonly property int fontSizeHero: 32

    // Ukuran komponen
    readonly property int controlHeight: 34
    readonly property int smallControlHeight: 28
    readonly property int tabBarHeight: 40
    readonly property int headerHeight: 40
    readonly property int cardHeight: 52
    readonly property int itemHeight: 58
    readonly property int sectionHeight: 28
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
        colorAccentText = p.accentText
        colorBorder = p.border
        colorDanger = p.danger
        colorActive = p.active
        colorShadow = p.shadow
    }

    Component.onCompleted: apply("light")
}
