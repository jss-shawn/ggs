
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root

    width: parent.width
    height: parent.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property AppSettings appsettings: QGroundControl.settingsManager.appSettings
    property Vehicle vehicle: gises.vehicle
    property bool fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
    property string title: qsTr("Vehicle Setup")
    property var summaryOption: undefined
    property var curOption: summary

    onVehicleChanged: {
        showOption(summary, "/gises/panel/CCVehicleSummary.qml", null)
    }

    function reset(){
        if(visible)
            close.start()
    }
    function showOption(option, url, ptr){
        if(curOption !== option){
            curOption = option
            if(url.toString().length){
                setupLoader.sourcePtr = ptr
                setupLoader.source = url
            }
        }
    }

    Rectangle{
        id: bg
        width: parent.width
        height: parent.height
        color: cc.normalBg
        anchors.bottom: parent.bottom
    }
    Item{
        id: optionsArea
        width: ui.fontWidth * 20
        height: parent.height
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    spacing: ui.margin
                    CCButton{
                        id: summary
                        width: parent.width
                        height: ui.fontHeight * 2.5
                        checked: curOption === this
                        icon.source: "qrc:/icon/add.svg"
                        text: "Summary"
                        onClicked: showOption(this, "/gises/panel/CCVehicleSummary.qml", null)
                    }
                    CCButton{
                        id: firmware
                        width: parent.width
                        height: ui.fontHeight * 2.5
                        icon.source: "qrc:/icon/add.svg"
                        text: "Firmware"
                        checked: curOption === this
                        visible: !ui.isMobile && QGroundControl.corePlugin.options.showFirmwareUpgrade
                        onClicked: showOption(this, "/gises/panel/CCVehicleFirmware.qml", null)
                    }
                    CCButton{
                        id: imageTrans
                        width: parent.width
                        height: ui.fontHeight * 2.5
                        icon.source: "qrc:/icon/add.svg"
                        text: "Module"
                        checked: curOption === this
                        onClicked: showOption(this, "/gises/panel/CCModuleSettings.qml", null)
                    }
                    Repeater{
                        id: rep
                        model: fullParameterVehicleAvailable ? vehicle.autopilot.vehicleComponents : 0
                        CCButton{
                            width: parent.width
                            height: ui.fontHeight * 2.5
                            icon.source: "qrc:/icon/add.svg"
                            text: modelData.name
                            //textColor: modelData.setupComplete ? cc.enabled : cc.error
                            checked: curOption === this
                            onClicked: showOption(this, modelData.setupSource, modelData)
                        }
                    }
                    CCButton{
                        id: param
                        width: parent.width
                        height: ui.fontHeight * 2.5
                        icon.source: "qrc:/icon/add.svg"
                        text: "Parameter"
                        checked: curOption === this
                        onClicked: showOption(this, "/gises/panel/CCVehicleParameter.qml", null)
                        visible: vehicle
                    }
                }
            }
        }
    }

    Item{
        id: setupArea
        width: parent.width - optionsArea.width
        height: parent.height
        anchors.right: parent.right
        Loader{
            id: setupLoader
            anchors.fill: parent
            source: "/gises/panel/CCVehicleSummary.qml"
            property var sourcePtr: null
            onLoaded: {
                if(item.sourcePtr !== sourcePtr){
                    item.sourcePtr = sourcePtr
                }
            }
        }
    }
    PropertyAnimation{
        id: open
        target:         root
        property:       "opacity"
        from:           0
        to:             1
        duration:       100
        onStarted: actionProtect(duration)
    }
    PropertyAnimation{
        id: close
        target:         root
        property:       "opacity"
        from:           1
        to:             0
        duration:       100
        onStarted: actionProtect(duration)
        onStopped: root.visible = false
    }
    onVisibleChanged: {
        if(visible){
            open.start()
            if(summaryOption)
                showOption(summaryOption, "/gises/panel/CCVehicleSummary.qml", null)
        }
    }
}
