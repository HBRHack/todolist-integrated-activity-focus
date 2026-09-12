// Hallmark · genre: editorial · tone: neo-brutalist · design-system: DESIGN.md · designed-as-app
// Hallmark · pre-emit critique: P5 H5 E5 S5 R4 V4
// Sistem desain terkunci (DESIGN.md). Semua view WAJIB share token ini —
// tidak ada variasi tema antar view. Preset key "light"/"dark" dipertahankan
// karena dipakai test (tst_shell) dan settings lama.
pragma Singleton
import QtQuick 2.15

QtObject {
    id: theme

    // Warna — satu sumber (PRD §10). OKLCH tidak bisa diparse Qt 5.15 →
    // hex terkunci di sini (lihat DESIGN.md). Semua rasio kontras teks
    // diverifikasi WCAG ≥4.5 (accentContent/railMuted) dan ≥4.5 utk
    // teks di atas dangerFill.
    readonly property var presets: [
        { name: "light", label: qsTr("Terang"), background: "#F2F0E8", surface: "#FFFFFF", surfaceAlt: "#E6E4DA", text: "#141414", muted: "#63615A", accent: "#FF4D00", border: "#141414", danger: "#B3261E", active: "#141414", accentText: "#141414", accentContent: "#C73A00", shadow: "#141414", dangerFill: "#B3261E", dangerText: "#FFFFFF", railMuted: "#A6A59A" },
        { name: "dark", label: qsTr("Gelap"), background: "#141414", surface: "#232323", surfaceAlt: "#303030", text: "#F2F0E8", muted: "#9A9890", accent: "#7FB4FF", border: "#F2F0E8", danger: "#FF7B80", active: "#7FB4FF", accentText: "#10233F", accentContent: "#7FB4FF", shadow: "#000000", dangerFill: "#F44336", dangerText: "#141414", railMuted: "#63615A" },
        { name: "pirus", label: qsTr("Pirus"), background: "#EEF3F0", surface: "#FFFFFF", surfaceAlt: "#DDE6E1", text: "#10211B", muted: "#5D6E66", accent: "#00A88E", border: "#10211B", danger: "#B3261E", active: "#10211B", accentText: "#00705E", accentContent: "#00705E", shadow: "#10211B", dangerFill: "#B3261E", dangerText: "#FFFFFF", railMuted: "#859188" },
        { name: "elektrik", label: qsTr("Elektrik"), background: "#E3ECFA", surface: "#FFFFFF", surfaceAlt: "#D4E1F5", text: "#10233F", muted: "#5E7293", accent: "#2F6BFF", border: "#10233F", danger: "#B3261E", active: "#10233F", accentText: "#FFFFFF", accentContent: "#1D4ED8", shadow: "#10233F", dangerFill: "#B3261E", dangerText: "#FFFFFF", railMuted: "#8A93A5" },
        { name: "asam", label: qsTr("Asam"), background: "#EDF4E0", surface: "#FFFFFF", surfaceAlt: "#DFEAD0", text: "#1A2413", muted: "#66704F", accent: "#8FC900", border: "#1A2413", danger: "#B3261E", active: "#1A2413", accentText: "#141414", accentContent: "#1A2413", shadow: "#1A2413", dangerFill: "#B3261E", dangerText: "#FFFFFF", railMuted: "#849765" }
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
    property color colorAccentContent
    property color colorBorder
    property color colorDanger
    property color colorDangerText
    property color colorDangerFill
    property color colorActive
    property color colorRailMuted

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
    readonly property int cardHeight: 66
    readonly property int itemHeight: 58
    readonly property int sectionHeight: 28
    readonly property int columnWidth: 240
    readonly property int sidebarWidth: 180

    readonly property int nodeWidth: 200
    readonly property int nodeHeight: 72
    readonly property int dragThreshold: 8
    readonly property int moveToEnd: 99

    // SATU-SATUNYA tempat mapping color-key -> token (DESIGN.md
    // "Color-key system"). Semua komponen/view memanggil fungsi ini —
    // dilarang copy-paste switch-case di file lain. Fallback nilai tak
    // dikenal -> "accent" (konsisten dengan whitelist backend).
    function colorKeyToToken(key) {
        switch (key) {
        case "danger": return colorDanger
        case "active": return colorActive
        case "accentContent": return colorAccentContent
        case "neutral": return colorMuted
        case "accent":
        default: return colorAccent
        }
    }

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
        colorAccentContent = p.accentContent
        colorBorder = p.border
        colorDanger = p.danger
        colorDangerText = p.dangerText
        colorDangerFill = p.dangerFill
        colorActive = p.active
        colorRailMuted = p.railMuted
        colorShadow = p.shadow
    }

    Component.onCompleted: apply("light")
}
