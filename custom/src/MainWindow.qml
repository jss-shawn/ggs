import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

import Gises.Fly
import Gises.Panel
import Gises.Plan
import Gises.Widget

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:         mainWindow
    visible:    true
    // The special casing for android prevents white bars from showing up on the edges of the screen with newer android versions
    flags:      Qt.Window | (ScreenTools.isAndroid ? Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint : 0)

    // Qt 6.9+ auto-sets ApplicationWindow padding to the display safe-area insets on mobile,
    // which insets our full-bleed content and leaves a blank strip along the screen edge.
    // QGC draws edge-to-edge and manages its own insets, so zero the padding.
    topPadding:    0
    bottomPadding: 0
    leftPadding:   0
    rightPadding:  0

    property bool _forceClose: false
    property GisesManager gises: QGroundControl.corePlugin.gises
    property Ui ui: Ui
    property var flyMap: null
    property var planMap: null
    property bool showMap: bg.showMap
    property bool showPlanView: false

    Component.onCompleted: {
    }
    onClosing:
        (close)=>{
            if(!_forceClose){
                closeApp()
            }
        }

    function closeApp(){
        _forceClose = true
        //firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo();
        mainWindow.close()
    }

    WindowState{
        window: mainWindow
    }

    AppLayerBackground{
        id: bg
    }

    AppLayerMainUi{
        id: mainUi
    }

    AppLayerVideo{
        id: vid
        bgLayer: bg
    }

    AppLayerNotice{
        id: notice
    }


}