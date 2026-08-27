
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactControls

Rectangle{
    width: leftArea.width + rightArea.width
    height: ui.fontHeight * 18
    color: clcfg.normalBg
    border.color: clcfg.border

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property int batteryIndex: 0
    property int batteryCount: vehicle ? vehicle.batteries.count : 0
    property var battery: batteryCount ? vehicle.batteries.get(batteryIndex) : undefined
    property real green: battery === undefined ? 0 : (battery.percentRemaining.rawValue>50 ? 50 : battery.percentRemaining.rawValue)
    property real red: battery === undefined ? 50 : (battery.percentRemaining.rawValue>50 ? 100-battery.percentRemaining.rawValue : 50)
    property color batColor: Qt.rgba(red/50.0, green/50.0, 0, 1)

    Item{
        id: leftArea
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
                    Repeater{
                        id: repeat
                        model: vehicle ? vehicle.batteries : []
                        Rectangle{
                            height: batteryid.height + grid.height
                            width: parent.width
                            radius: ui.radius
                            color: clcfg.none
                            border.color: clcfg.border

                            property var battery: object
                            property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
                            property bool showFunction:              functionAvailable && battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_ALL
                            property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue)
                            property bool currentAvailable:          !isNaN(battery.current.rawValue)
                            property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)
                            property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)
                            property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue)
                            property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED

                            CCText{
                                id: batteryid
                                text: qsTr("Battery") + (batteryCount > 1 ? " " + (index + 1) : "")
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Grid{
                                id: grid
                                height: children.length * batteryid.height / 2
                                width: parent.width - ui.x2margin
                                columns: 2
                                anchors.top: batteryid.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                CCText{
                                    width: parent.width/2
                                    text:  qsTr("Charge State")
                                    visible: parent.parent.chargeStateAvailable
                                }
                                CCText{
                                    width: parent.width/2
                                    text:  object.chargeState.enumStringValue
                                    alignRight: true
                                    visible: parent.parent.chargeStateAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:      qsTr("Remaining")
                                    visible: parent.parent.timeRemainingAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:  object.timeRemainingStr.value
                                    alignRight: true
                                    visible: parent.parent.timeRemainingAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:      qsTr("Remaining")
                                    visible: parent.parent.percentRemainingAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                                    alignRight: true
                                    visible: parent.parent.percentRemainingAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:      qsTr("Voltage")
                                }
                                CCText {
                                    width: parent.width/2
                                    text:  object.voltage.valueString + " " + object.voltage.units
                                    alignRight: true
                                }
                                CCText {
                                    width: parent.width/2
                                    text:      qsTr("Consumed")
                                    visible: parent.parent.mahConsumedAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                                    alignRight: true
                                    visible: parent.parent.mahConsumedAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:      qsTr("Temperature")
                                    visible: parent.parent.temperatureAvailable
                                }
                                CCText {
                                    width: parent.width/2
                                    text:  object.temperature.valueString + " " + object.temperature.units
                                    alignRight: true
                                    visible: parent.parent.temperatureAvailable
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item{
        id: rightArea
        width: ui.fontWidth * 30
        height: parent.height
        anchors.right: parent.right
        CCSeparator{
            height: parent.height - ui.x2margin
            anchors.verticalCenter: parent.verticalCenter
        }
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Loader{
                    width: parent.width
                    sourceComponent: vehicle ? (vehicle.px4Firmware ? px4 : (vehicle.apmFirmware ? apm : null)) : null
                }
            }
        }
    }
    // Rectangle{
    //     anchors.fill: parent
    //     color: clcfg.none
    //     border.color: clcfg.border
    // }
    Component{
        id: px4
        Column{
            id: px4Col
            FactPanelController { id: px4Ctrl }
            LabelSlider{
                title: qsTr("Warning Level")
                fact: px4Ctrl.getParameterFact(-1, "BAT_LOW_THR")
                enabled: fact
            }

            LabelSlider{
                title: qsTr("Failsafe Level")
                fact: px4Ctrl.getParameterFact(-1, "BAT_CRIT_THR")
                enabled: fact
            }

            LabelSlider{
                title: qsTr("Emergency Level")
                fact: px4Ctrl.getParameterFact(-1, "BAT_EMERGEN_THR")
                enabled: fact
            }

            LabelComboBox{
                title: qsTr("Failsafe Action")
                fact: px4Ctrl.getParameterFact(-1, "COM_LOW_BAT_ACT")
            }
        }
    }
    Component{
        id: apm
        Column{
            id: apmCol
            FactPanelController { id: apmCtrl }
            visible: batt1Monitor.rawValue
            property Fact batt1Monitor: apmCtrl.getParameterFact(-1, "BATT_MONITOR")
            CCText{
                width: parent.width
                height: contentHeight + ui.x2margin
                text: qsTr("Low Voltage Failsafe")
                font.pointSize: ui.lFontSize
            }
            LabelComboBox{
                title: qsTr("Action")
                fact: apmCtrl.getParameterFact(-1, "BATT_FS_LOW_ACT")
            }
            LabelTextField{
                title: qsTr("Voltage Trigger")
                fact: apmCtrl.getParameterFact(-1, "BATT_LOW_VOLT")
            }
            LabelTextField{
                title: qsTr("mAh Trigger")
                fact: apmCtrl.getParameterFact(-1, "BATT_LOW_MAH")
            }
            CCText{
                width: parent.width
                height: contentHeight + ui.x2margin
                text: qsTr("Critical Voltage Failsafe")
            }
            LabelComboBox {
                title: qsTr("Action")
                fact: apmCtrl.getParameterFact(-1, "BATT_FS_CRT_ACT")
            }
            LabelTextField {
                title: qsTr("Voltage Trigger")
                fact: apmCtrl.getParameterFact(-1, "BATT_CRT_VOLT")
            }

            LabelTextField {
                title: qsTr("mAh Trigger")
                fact: apmCtrl.getParameterFact(-1, "BATT_CRT_MAH")
            }
        }
    }
}
