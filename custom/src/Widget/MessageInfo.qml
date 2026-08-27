
import QtQuick
import QtQuick.Controls

import QGroundControl

Rectangle{
    id: root

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property Ui ui: Ui

    width: mainWindow.width * 0.5
    height: mainWindow.height * 0.5
    radius: ui.radius
    color: clcfg.normalBg
    border.color: clcfg.border
    function formatMessage(message) {
        message = message.replace(new RegExp("<#E>", "g"), "color: " + clcfg.error + "; font: " + ui.sFontSize + "pt;")//" monospace;")
        message = message.replace(new RegExp("<#I>", "g"), "color: " + clcfg.warnning + "; font: " + ui.sFontSize + "pt;")//" monospace;")
        message = message.replace(new RegExp("<#N>", "g"), "color: " + clcfg.normal + "; font: " + ui.sFontSize + "pt;")//" monospace;")
        return message;
    }
    CCFlickable{
        anchors.fill: parent
        anchors.margins: ui.margin
        fixedWidth: true
        TextArea{
            id: log
            width: parent.width
            text: formatMessage(vehicle ? vehicle.formattedMessages : "")
            readOnly: true
            wrapMode: Text.WordWrap
            textFormat: TextEdit.RichText
            font.family: ui.fontFamily
            placeholderText: qsTr("No Messages")
            placeholderTextColor: clcfg.disabled
            color: clcfg.enabled
        }
    }
    Connections{
        target: vehicle
        onNewFormattedMessage:
        (message)=>{
                log.insert(0, formatMessage(message))
        }
    }
}
