
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Vehicle

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Remote Support")
    Column{
        anchors.fill: contentArea
        anchors.margins: ui.margin
        spacing: ui.margin
        CCTextEditor{
            id: host
            width: ui.fontWidth * 36
            title: qsTr("Host Name")
            fact: QGroundControl.settingsManager.appSettings.forwardMavlinkAPMSupportHostName
            near: true
        }
        CCButton{
            width: ui.fontWidth * 10
            text: qsTr("Connect")
        }
        CCText{
            text: qsTr("Forwarding traffic: Mavlink traffic will keep being forwarded until application restarts")
            visible: QGroundControl.linkManager.mavlinkSupportForwardingEnabled
        }
    }
}
