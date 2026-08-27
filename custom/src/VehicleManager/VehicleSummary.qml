
import QtQuick
import QtQuick.Controls
import QtCharts

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Summary")
    description: qsTr("Vehicle Parts Summary Page")

    Timer{
        id: timer
        interval: 1000
        onTriggered: {
            l1.remove(0)
        }
    }
    Flow{
        id: flow
        anchors.fill: contentArea
        anchors.margins: ui.margin
        Rectangle{
            width: ui.fontWidth * 40
            height: ui.fontHeight * 15
            color: cc.none
            border.color: cc.border
        }
    }
}
