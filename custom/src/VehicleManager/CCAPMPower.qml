
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Vehicle

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Power")

    property Fact batt1Monitor: ctrl.getParameterFact(-1, "BATT_MONITOR")
    property Fact batt2Monitor: ctrl.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
    property bool batt2MonitorAvailable: ctrl.parameterExists(-1, "BATT2_MONITOR")
    property bool batt1MonitorEnabled: batt1Monitor.rawValue !== 0
    property bool batt2MonitorEnabled: batt2MonitorAvailable && batt2Monitor.rawValue !== 0
    property bool batt1ParamsAvailable: ctrl.parameterExists(-1, "BATT_CAPACITY")
    property bool batt2ParamsAvailable: ctrl.parameterExists(-1, "BATT2_CAPACITY")
    property bool showBatt1Reboot: batt1MonitorEnabled && !batt1ParamsAvailable
    property bool showBatt2Reboot: batt2MonitorEnabled && !batt2ParamsAvailable
    property bool escCalibrationAvailable: ctrl.parameterExists(-1, "ESC_CALIBRATION")
    property Fact escCalibration: ctrl.getParameterFact(-1, "ESC_CALIBRATION", false /* reportMissing */)
    property var sensors:[
        qsTr("Power Module 90A"),
        qsTr("Power Module HV"),
        qsTr("3DR Iris"),
        qsTr("Blue Robotics Power Sense Module"),
        qsTr("Navigator w/ Blue Robotics Power Sense Module"),
        qsTr("Other")
    ]

    FactPanelController { id: ctrl }

    ListModel {
        id: sensorModel

        ListElement {
            text:       qsTr("Power Module 90A")
            voltPin:    2
            currPin:    3
            voltMult:   10.1
            ampPerVolt: 17.0
            ampOffset:  0
        }
        ListElement {
            text:       qsTr("Power Module HV")
            voltPin:    2
            currPin:    3
            voltMult:   12.02
            ampPerVolt: 39.877
            ampOffset:  0
        }
        ListElement {
            text:       qsTr("3DR Iris")
            voltPin:    2
            currPin:    3
            voltMult:   12.02
            ampPerVolt: 17.0
            ampOffset:  0
        }
        ListElement {
            text:       qsTr("Blue Robotics Power Sense Module")
            voltPin:    2
            currPin:    3
            voltMult:   11.000
            ampPerVolt: 37.8788
            ampOffset:  0.330
        }
        ListElement {
            text:       qsTr("Navigator w/ Blue Robotics Power Sense Module")
            voltPin:    5
            currPin:    4
            voltMult:   11.000
            ampPerVolt: 37.8788
            ampOffset:  0.330
        }
    }
    CCFlickable{
        anchors.fill: contentArea
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea{
            width: parent.width
            height: children[0].height
            Flow{
                width: parent.width
                spacing: ui.margin
                Rectangle{
                    id: bat1
                    width: ui.fontWidth * 40
                    height: col1.height
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: col1
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            id: b1
                            height: contentHeight + ui.x2margin
                            text: qsTr("Battery - 1")
                            font.pointSize: ui.llFontSize
                        }
                        Column{
                            width: parent.width
                            visible: !batt1MonitorEnabled || !batt1ParamsAvailable
                            CCComboBoxEditor{
                                id: cmon1
                                title: qsTr("Battery monitor")
                                fact: full1.battMonitor
                            }
                            CCButton{
                                width: ui.fontWidth * 12
                                height: cmon1.height
                                text: qsTr("Reboot Vehicle")
                                anchors.right: parent.right
                                visible: showBatt1Reboot
                            }
                        }
                        Loader{
                            id: full1
                            width:parent.width
                            sourceComponent: visible ? battery : undefined
                            visible: batt1MonitorEnabled && batt1ParamsAvailable

                            property Fact armVoltMin: ctrl.getParameterFact(-1, "r.BATT_ARM_VOLT", false /* reportMissing */)
                            property Fact battAmpPerVolt: ctrl.getParameterFact(-1, "r.BATT_AMP_PERVLT", false /* reportMissing */)
                            property Fact battAmpOffset: ctrl.getParameterFact(-1, "BATT_AMP_OFFSET", false /* reportMissing */)
                            property Fact battCapacity: ctrl.getParameterFact(-1, "BATT_CAPACITY", false /* reportMissing */)
                            property Fact battCurrPin: ctrl.getParameterFact(-1, "BATT_CURR_PIN", false /* reportMissing */)
                            property Fact battMonitor: ctrl.getParameterFact(-1, "BATT_MONITOR", false /* reportMissing */)
                            property Fact battVoltMult: ctrl.getParameterFact(-1, "BATT_VOLT_MULT", false /* reportMissing */)
                            property Fact battVoltPin: ctrl.getParameterFact(-1, "BATT_VOLT_PIN", false /* reportMissing */)
                            property FactGroup batteryFactGroup:  full1.visible ? ctrl.vehicle.getFactGroup("battery0") : null
                            property Fact vehicleVoltage: batteryFactGroup ? batteryFactGroup.voltage : null
                            property Fact vehicleCurrent: batteryFactGroup ? batteryFactGroup.current : null
                        }
                    }
                }
                Rectangle{
                    id: bat2
                    width: ui.fontWidth * 40
                    height: col2.height
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: col2
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            id: b2
                            height: contentHeight + ui.x2margin
                            text: qsTr("Battery - 2")
                            x: ui.margin
                            font.pointSize: ui.llFontSize
                        }
                        Column{
                            width: parent.width
                            visible: !batt2MonitorEnabled || !batt2ParamsAvailable
                            CCComboBoxEditor{
                                id: cmon2
                                title: qsTr("Battery monitor")
                                fact: full2.battMonitor
                            }
                            CCButton{
                                width: ui.fontWidth * 12
                                height: cmon2.height
                                text: qsTr("Reboot Vehicle")
                                anchors.right: parent.right
                                visible: showBatt2Reboot
                            }
                        }
                        Loader{
                            id: full2
                            width:parent.width
                            sourceComponent: visible ? battery : undefined
                            visible: batt2MonitorEnabled && batt2ParamsAvailable

                            property Fact armVoltMin: ctrl.getParameterFact(-1, "r.BATT2_ARM_VOLT", false /* reportMissing */)
                            property Fact battAmpPerVolt: ctrl.getParameterFact(-1, "r.BATT2_AMP_PERVLT", false /* reportMissing */)
                            property Fact battAmpOffset: ctrl.getParameterFact(-1, "BATT2_AMP_OFFSET", false /* reportMissing */)
                            property Fact battCapacity: ctrl.getParameterFact(-1, "BATT2_CAPACITY", false /* reportMissing */)
                            property Fact battCurrPin: ctrl.getParameterFact(-1, "BATT2_CURR_PIN", false /* reportMissing */)
                            property Fact battMonitor: ctrl.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
                            property Fact battVoltMult: ctrl.getParameterFact(-1, "BATT2_VOLT_MULT", false /* reportMissing */)
                            property Fact battVoltPin: ctrl.getParameterFact(-1, "BATT2_VOLT_PIN", false /* reportMissing */)
                            property FactGroup batteryFactGroup:  full2.visible ? ctrl.vehicle.getFactGroup("battery1") : null
                            property Fact vehicleVoltage: batteryFactGroup ? batteryFactGroup.voltage : null
                            property Fact vehicleCurrent: batteryFactGroup ? batteryFactGroup.current : null
                        }
                    }
                }
                Rectangle{
                    id: cali
                    width: Math.min(ui.fontWidth * 50, root.width)
                    height: calicol.height + ui.x2margin
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: calicol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            id: calitext
                            width: parent.width
                            text: qsTr("ESC Calibration")
                            font.pointSize: ui.llFontSize
                            CCButton{
                                id: calibration
                                width: ui.fontWidth *10
                                text: qsTr("Calibration")
                                anchors.right: parent.right
                            }
                        }
                        CCText{
                            id: caliwar
                            text: qsTr("WARNING: Remove props prior to calibration!")
                            font.pointSize: ui.lFontSize
                            color: cc.error
                        }
                        CCText{
                            width: parent.width
                            text: escCalibration ? (escCalibration.rawValue === 3 ? qsTr("Now perform these steps:") : qsTr("Click Calibrate to start, then:")) : ""
                            color: cc.disabled
                            wrapMode: Text.WordWrap
                        }
                        Repeater{
                            id: calirep
                            model: [
                                qsTr("- Disconnect USB and battery so flight controller powers down")
                                , qsTr("- Connect the battery")
                                , qsTr("- The arming tone will be played (if the vehicle has a buzzer attached)")
                                , qsTr("- If using a flight controller with a safety button press it until it displays solid red")
                                , qsTr("- You will hear a musical tone then two beeps")
                                , qsTr("- A few seconds later you should hear a number of beeps (one for each battery cell you're using)")
                                , qsTr("- And finally a single long beep indicating the end points have been set and the ESC is calibrated")
                                , qsTr("- Disconnect the battery and power up again normally")
                            ]
                            CCText{
                                width: parent.width
                                text: modelData
                                color: cc.disabled
                                wrapMode: Text.WordWrap
                            }
                        }

                    }
                }
            }
        }
    }
    Component{
        id: battery
        Column{
            id: full
            property bool show: sen.currentIndex === (sensors.length-1)
            Component.onCompleted: {
                for (var i=0; i<sensorModel.count - 1; i++) {
                    if (sensorModel.get(i).voltPin === battVoltPin.value &&
                            sensorModel.get(i).currPin === battCurrPin.value &&
                            Math.abs(sensorModel.get(i).voltMult - battVoltMult.value) < 0.001 &&
                            Math.abs(sensorModel.get(i).ampPerVolt - battAmpPerVolt.value) < 0.0001 &&
                            Math.abs(sensorModel.get(i).ampOffset - battAmpOffset.value) < 0.0001) {
                        sen.currentIndex = i
                        return
                    }
                }
                sen.currentIndex = sensorModel.count - 1
            }
            CCComboBoxEditor{
                id: fmon
                title: qsTr("Battery monitor")
                fact: battMonitor
            }
            CCTextEditor{
                id: cap
                title: qsTr("Battery capacity")
                fact: battCapacity
            }
            CCTextEditor{
                id: arm
                title: qsTr("Minimum arming voltage")
                fact: armVoltMin
            }
            CCComboBoxEditor{
                id: sen
                title: qsTr("Power sensor")
                model: sensors
                singleLine: false
                onUpdateResult:
                    (index)=>{
                        if(index < sensors.length-1){
                            battVoltPin.value = sensorModel.get(index).voltPin
                            battCurrPin.value = sensorModel.get(index).currPin
                            battVoltMult.value = sensorModel.get(index).voltMult
                            battAmpPerVolt.value = sensorModel.get(index).ampPerVolt
                            battAmpOffset.value = sensorModel.get(index).ampOffset
                        }
                    }
            }
            CCComboBoxEditor{
                id: cur
                title: qsTr("Current pin")
                fact: battCurrPin
                singleLine: false
                visible: full.show
            }
            CCComboBoxEditor{
                id: vol
                title: qsTr("Voltage pin")
                fact: battVoltPin
                singleLine: false
                visible: full.show
            }
            Item{
                id: mul
                width: parent.width
                height: av.height * 2
                CCTextEditor{
                    id: vm
                    width: parent.width * 0.7
                    title: qsTr("Voltage multiplier")
                    fact: battVoltMult
                }
                CCButton{
                    width: ui.fontWidth * 6
                    text: qsTr("calc")
                    anchors.right: parent.right
                    anchors.verticalCenter: vm.verticalCenter
                }
                CCText{
                    text: qsTr("Vehicle voltage: ") + (vehicleVoltage ? (vehicleVoltage.valueString + vehicleVoltage.units) : "")
                    anchors.bottom: parent.bottom
                }
                CCText{
                    text: qsTr("Voltage multiplier: ") + (battVoltMult ? (battVoltMult.valueString + battVoltMult.units) : "")
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                }
                visible: full.show
            }
            Item{
                id: apv
                width: parent.width
                height: av.height * 2
                CCTextEditor{
                    id: av
                    width: parent.width * 0.7
                    title: qsTr("Amps per volt")
                    fact: battAmpPerVolt
                }
                CCButton{
                    width: ui.fontWidth * 6
                    text: qsTr("calc")
                    anchors.right: parent.right
                    anchors.verticalCenter: av.verticalCenter
                }
                CCText{
                    text: qsTr("Vehicle current: ") + (vehicleCurrent ? (vehicleCurrent.valueString + vehicleCurrent.units) : "")
                    anchors.bottom: parent.bottom
                }
                CCText{
                    text: qsTr("Amps per volt: ") + (battAmpPerVolt ? (battAmpPerVolt.valueString + battAmpPerVolt.units) : "")
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
                visible: full.show
            }
            CCTextEditor{
                id: offset
                title: qsTr("Amps Offset: ")
                fact: battAmpOffset
                visible: full.show
            }
        }
    }
}
