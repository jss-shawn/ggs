import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtCore

import QGroundControl
import QGroundControl.Controls

Item {
    property Window window

    property bool _enabled: !ScreenTools.isMobile && !ScreenTools.isFakeMobile && QGroundControl.corePlugin.options.enableSaveMainWindowPosition

    Settings {
        id:         set
        category:   "MainWindowState"

        property int x
        property int y
        property int width
        property int height
        property int visibility
    }

    function _setDefaultDesktopWindowSize() {
        //window.width = Math.min(250 * Screen.pixelDensity, Screen.width);
        //window.height = Math.min(150 * Screen.pixelDensity, Screen.height);
        window.width = Screen.width * 0.6
        window.height = Screen.height * 0.6
        window.x = Screen.virtualX + (Screen.width - window.width) / 2;
        window.y = Screen.virtualY + (Screen.height - window.height) / 2;
    }

    Component.onCompleted: {
        if (ScreenTools.isFakeMobile) {
            window.width = ScreenTools.screenWidth
            window.height = ScreenTools.screenHeight
        } else if (ScreenTools.isMobile) {
            window.showFullScreen();
        } else if (QGroundControl.corePlugin.options.enableSaveMainWindowPosition) {
            window.minimumWidth = Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
            window.minimumHeight = Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
            if (set.width && set.height) {
                window.x = set.x;
                window.y = set.y;
                window.width = set.width;
                window.height = set.height;
                window.visibility = set.visibility;
            } else {
                _setDefaultDesktopWindowSize()
            }
        } else {
            _setDefaultDesktopWindowSize()
        }
    }

    Connections {
        target:                         window
        function onXChanged()           { if(_enabled) saveSettingsTimer.restart() }
        function onYChanged()           { if(_enabled) saveSettingsTimer.restart() }
        function onWidthChanged()       { if(_enabled) saveSettingsTimer.restart() }
        function onHeightChanged()      { if(_enabled) saveSettingsTimer.restart() }
        function onVisibilityChanged()  { if(_enabled) saveSettingsTimer.restart() }
    }

    Timer {
        id:             saveSettingsTimer
        interval:       500
        repeat:         false
        onTriggered:    saveSettings()
    }

    function saveSettings() {
        if (_enabled) {
            switch(window.visibility) {
            case ApplicationWindow.Windowed:
                set.x = window.x;
                set.y = window.y;
                set.width = window.width;
                set.height = window.height;
                set.visibility = window.visibility;
                break;
            case ApplicationWindow.FullScreen:
                set.visibility = window.visibility;
                break;
            case ApplicationWindow.Maximized:
                set.visibility = window.visibility;
                break;
            }
        }
    }
}
