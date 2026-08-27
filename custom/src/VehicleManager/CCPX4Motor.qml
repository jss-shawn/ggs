
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Motor")

    readonly property int timeoutSec: 3

    FactPanelController {
        id: ctrl
    }
    Column{
        anchors.fill: contentArea
        anchors.margins: ui.margin
        CCText{
            width: ui.fontWidth * 40
            text: qsTr("Warning: Unable to determine motor count")
            visible: ctrl.vehicle.motorCount === -1
        }
        CCSwitchEditor{
            id: safe
            width: ui.fontWidth * 40
            title: qsTr("Moving the sliders will causes the motors to spin. Make sure you remove all props.")
            //title: qsTr("Careful: Motor sliders are enabled") : qsTr("Propellers are removed - Enable motor sliders")
            stateOn: false
            color: cc.error
            onStateChanged: {
                if (stateOn) {
                    for (var sliderIndex=0; sliderIndex<rep.count; sliderIndex++) {
                        rep.itemAt(sliderIndex).value = 0
                    }
                }
                stateOn = !stateOn
            }
        }
        Repeater{
            id: rep
            model: ctrl.vehicle.motorCount === -1 ? 8 : ctrl.vehicle.motorCount
            CCSliderEditor{
                id: sld
                width: ui.fontWidth * 40
                title: index + 1
                from: 0
                to: 100
                stepSize: 1
                value: 0
                enabled: safe.stateOn
                onUpdateValue:
                    (val)=>{
                        ctrl.vehicle.motorTest(index + 1, val, val === 0 ? 0 : timeoutSec, true)
                        if (value != 0) {
                            motorTimer.restart()
                        }
                    }
                Timer {
                    id: motorTimer
                    interval: timeoutSec * 1000
                    repeat: false
                    running: false
                    onTriggered: {
                        parent.value = 0
                    }
                }
            }
        }
        Row{
            height: ui.fontHeight + ui.margin * 4
            spacing: ui.fontWidth * 4
            CCButton{
                width: ui.fontWidth * 8
                text: qsTr("All-")
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    for (var sliderIndex=0; sliderIndex<rep.count; sliderIndex++) {
                        rep.itemAt(sliderIndex).value -= 1
                    }
                }
            }
            CCButton{
                width: ui.fontWidth * 8
                text: qsTr("All+")
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    for (var sliderIndex=0; sliderIndex<rep.count; sliderIndex++) {
                        rep.itemAt(sliderIndex).value += 1
                    }
                }
            }
        }
    }
}
