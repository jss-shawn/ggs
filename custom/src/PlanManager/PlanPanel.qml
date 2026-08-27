
import QtQuick
import QtQuick.Controls

import Gises.Widget

CCMouseArea{
    id: root
    property ColorConfig cc: gises.colorConfig
    property GisesPlan plan: gises.planManager
    property GCSRoute baseRoute: manager.route
    property bool showLib: true

    Component.onCompleted: {
        //gcsManager.state = GCSManager.Planning
        showLib = baseRoute.isEmpty()
    }
    Component.onDestruction: {
        gcsManager.state = GCSManager.Normal
    }
    onShowLibChanged: {
        showLib ? gcsManager.state = GCSManager.Normal : gcsManager.state = GCSManager.Planning
    }
    // Rectangle{
    //     anchors.fill: parent
    //     color: cc.normalBg
    // }
    Loader{
        id: loader
        width: parent.width
        height: parent.height
        source: showLib ? "" : baseRoute.configPanel
        //visible: !showLib
    }
    RouteLibrary{
        id: lib
        visible: showLib
    }
}
