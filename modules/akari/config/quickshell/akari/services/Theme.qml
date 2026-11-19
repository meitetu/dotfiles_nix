pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // ========================================================================
    // Material 3 Tonal Palette — Akari Hoshizaki (#FF4D79 · HCT scheme-fidelity)
    // Prefixed with m3* so QML never confuses "onSurface" with a signal slot!
    // ========================================================================
    property bool darkMode: true

    function toggleDarkMode() {
        darkMode = !darkMode
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface",
            "color-scheme", darkMode ? "prefer-dark" : "prefer-light"
        ])
    }

    // Primary
    readonly property color m3Primary:              darkMode ? "#FFB2BD" : "#B60B47"
    readonly property color m3OnPrimary:            darkMode ? "#670024" : "#FFFFFF"
    readonly property color m3PrimaryContainer:     darkMode ? "#FF4E7A" : "#D92F5F"
    readonly property color m3OnPrimaryContainer:   darkMode ? "#000000" : "#FFFFFF"

    // Secondary
    readonly property color m3Secondary:            darkMode ? "#FFB2BD" : "#9D3E52"
    readonly property color m3OnSecondary:          darkMode ? "#610F26" : "#FFFFFF"
    readonly property color m3SecondaryContainer:   darkMode ? "#7F273B" : "#FF8B9F"
    readonly property color m3OnSecondaryContainer: darkMode ? "#FFD6DA" : "#4E0019"

    // Tertiary (Akari Emerald Eye Accent)
    readonly property color m3Tertiary:             darkMode ? "#59E077" : "#006E2C"
    readonly property color m3OnTertiary:           darkMode ? "#003913" : "#FFFFFF"
    readonly property color m3TertiaryContainer:    darkMode ? "#00531F" : "#59E077"
    readonly property color m3OnTertiaryContainer:  darkMode ? "#78FD90" : "#002108"

    // Error
    readonly property color m3Error:                darkMode ? "#FFB4AB" : "#BA1A1A"
    readonly property color m3OnError:              darkMode ? "#690005" : "#FFFFFF"
    readonly property color m3ErrorContainer:       darkMode ? "#93000A" : "#FFDAD6"
    readonly property color m3OnErrorContainer:     darkMode ? "#FFDAD6" : "#410002"

    // Surfaces & Tonal Elevation (No blur, no shadow, no gradient)
    readonly property color m3SurfaceDim:              darkMode ? "#1D0F12" : "#EFD3D6"
    readonly property color m3Surface:                 darkMode ? "#1D0F12" : "#FFF8F7"
    readonly property color m3SurfaceContainerLowest:  darkMode ? "#180A0C" : "#FFFFFF"
    readonly property color m3SurfaceContainerLow:     darkMode ? "#26181A" : "#FFF0F1"
    readonly property color m3SurfaceContainer:        darkMode ? "#2B1B1E" : "#FFE9EA"
    readonly property color m3SurfaceContainerHigh:    darkMode ? "#362628" : "#FEE2E4"
    readonly property color m3SurfaceContainerHighest: darkMode ? "#423032" : "#F8DCDE"

    // Content & Outlines
    readonly property color m3OnSurface:            darkMode ? "#F8DCDE" : "#26181A"
    readonly property color m3OnSurfaceVariant:     darkMode ? "#E2BEC1" : "#5A4043"
    readonly property color m3Outline:              darkMode ? "#A9898C" : "#8E6F73"
    readonly property color m3OutlineVariant:       darkMode ? "#5A4043" : "#E2BEC1"

    // Typography (English/ASCII/Numbers: JetBrains Mono -> Japanese fallback: Noto Sans CJK JP)
    readonly property string fontUi:                "JetBrains Mono"
    readonly property string fontMono:              "JetBrains Mono"
    readonly property string fontIcon:              "Material Symbols Outlined"

    readonly property int typeLabelSmall:           11
    readonly property int typeLabelMedium:          12
    readonly property int typeLabelLarge:           14
    readonly property int typeBodySmall:            12
    readonly property int typeBodyMedium:           14
    readonly property int typeTitleSmall:           14
    readonly property int typeTitleMedium:          16
    readonly property int typeHeadlineSmall:        24
    readonly property int typeDisplayLarge:         57

    // M3 Shape Tokens (0 / 4 / 8 / 12 / 16 / 28 — Bar & Panels <= 12)
    readonly property int shapeNone:                0
    readonly property int shapeXs:                  4
    readonly property int shapeSm:                  8
    readonly property int shapeMd:                  12
    readonly property int shapeLg:                  16
    readonly property int shapeXl:                  28

    // 4dp / 8dp Grid Metrics
    readonly property int barHeight:                40
    readonly property int barMarginTop:             8
    readonly property int barMarginSide:            12
    readonly property int barRadius:                12
    readonly property int space4:                   4
    readonly property int space8:                   8
    readonly property int space12:                  12
    readonly property int space16:                  16
    readonly property int space20:                  20
    readonly property int space24:                  24
}
