pragma Singleton
import QtQuick

QtObject {
    readonly property color barBg:           Qt.rgba(0, 0, 0, 0.45)
    readonly property color buttonHover:     Qt.rgba(0, 0, 0, 0.35)

    readonly property color surfaceBg:       Qt.rgba(0, 0, 0, 0.45)
    readonly property color surfaceInner:    Qt.rgba(0, 0, 0, 0.25)
    readonly property color surfaceStrong:   Qt.rgba(0, 0, 0, 0.30)
    readonly property color surfaceActive:   Qt.rgba(0, 0, 0, 0.50)
    readonly property color surfaceSubtle:   Qt.rgba(0, 0, 0, 0.20)

    readonly property color text:          "#ffffff"
    readonly property color textDim:       Qt.rgba(1, 1, 1, 0.70)
    readonly property color iconPrimary:   "#ffffff"
    readonly property color iconDim:       Qt.rgba(1, 1, 1, 0.40)

    readonly property color workspaceActive: Qt.rgba(0, 0, 0, 0.55)
    readonly property color workspaceHover:  Qt.rgba(0, 0, 0, 0.35)

    property color accent:                 "#89b4fa"
    readonly property color accentSoft:    Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property color accentGlow:    Qt.rgba(accent.r, accent.g, accent.b, 0.35)

    readonly property color hairline:      Qt.rgba(1, 1, 1, 0.10)
    readonly property color hairlineTop:   Qt.rgba(1, 1, 1, 0.22)

    readonly property color accentDanger:  "#e04040"
    readonly property color toggleGreen:   Qt.rgba(0.4, 0.8, 0.4, 0.8)
    readonly property color graphCpu:      Qt.rgba(0.4, 0.8, 0.4, 0.90)
    readonly property color graphRam:      Qt.rgba(1, 1, 1, 0.70)

    readonly property string fontMono:  "JetBrains Mono"
    readonly property string codeStyle: "chroma-dark.xml"

    readonly property int fontCaption: 10
    readonly property int fontLabel:   11
    readonly property int fontBody:    12
    readonly property int fontTitle:   13

    readonly property int animFast:  150
    readonly property int animPopup: 180
}
