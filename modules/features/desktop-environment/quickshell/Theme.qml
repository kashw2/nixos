pragma Singleton
import QtQuick

QtObject {
    id: root

    enum Mode { Auto, Dark, Light }

    property int mode: Theme.Auto
    property int dayStartHour: 7
    property int dayEndHour: 19

    property int currentHour: new Date().getHours()

    readonly property bool isDark: {
        if (mode === Theme.Dark) return true;
        if (mode === Theme.Light) return false;
        return currentHour < dayStartHour || currentHour >= dayEndHour;
    }

    readonly property color barBg:           isDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(1, 1, 1, 0.30)
    readonly property color buttonHover:     isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.30)

    readonly property color surfaceBg:       isDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(1, 1, 1, 0.30)
    readonly property color surfaceInner:    isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, 0.15)
    readonly property color surfaceStrong:   isDark ? Qt.rgba(0, 0, 0, 0.30) : Qt.rgba(1, 1, 1, 0.20)
    readonly property color surfaceActive:   isDark ? Qt.rgba(0, 0, 0, 0.50) : Qt.rgba(1, 1, 1, 0.35)
    readonly property color surfaceSubtle:   isDark ? Qt.rgba(0, 0, 0, 0.20) : Qt.rgba(1, 1, 1, 0.10)

    readonly property color text:          "#ffffff"
    readonly property color textDim:       Qt.rgba(1, 1, 1, 0.70)
    readonly property color iconPrimary:   "#ffffff"
    readonly property color iconDim:       Qt.rgba(1, 1, 1, 0.40)

    readonly property color workspaceActive: isDark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.50)
    readonly property color workspaceHover:  isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.30)

    readonly property color accentDanger:  "#e04040"
    readonly property color toggleGreen:   Qt.rgba(0.4, 0.8, 0.4, 0.8)
    readonly property color graphCpu:      Qt.rgba(0.4, 0.8, 0.4, 0.90)
    readonly property color graphRam:      Qt.rgba(1, 1, 1, 0.70)

    property Timer _hourTimer: Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentHour = new Date().getHours()
    }
}
