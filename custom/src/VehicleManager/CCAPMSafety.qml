
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.Vehicle

import qgc
import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Safety")

    property Fact batt1Monitor: ctrl.getParameterFact(-1, "BATT_MONITOR")
    property Fact batt2Monitor: ctrl.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
    property bool batt2MonitorAvailable: ctrl.parameterExists(-1, "BATT2_MONITOR")
    property bool batt1MonitorEnabled: batt1Monitor.rawValue !== 0
    property bool batt2MonitorEnabled: batt2MonitorAvailable ? batt2Monitor.rawValue !== 0 : false
    property bool batt1ParamsAvailable: ctrl.parameterExists(-1, "BATT_CAPACITY")
    property bool batt2ParamsAvailable: ctrl.parameterExists(-1, "BATT2_CAPACITY")

    property Fact failsafeBatt1LowAct: ctrl.getParameterFact(-1, "BATT_FS_LOW_ACT", false /* reportMissing */)
    property Fact failsafeBatt2LowAct: ctrl.getParameterFact(-1, "BATT2_FS_LOW_ACT", false /* reportMissing */)
    property Fact failsafeBatt1CritAct: ctrl.getParameterFact(-1, "BATT_FS_CRT_ACT", false /* reportMissing */)
    property Fact failsafeBatt2CritAct: ctrl.getParameterFact(-1, "BATT2_FS_CRT_ACT", false /* reportMissing */)
    property Fact failsafeBatt1LowMah: ctrl.getParameterFact(-1, "BATT_LOW_MAH", false /* reportMissing */)
    property Fact failsafeBatt2LowMah: ctrl.getParameterFact(-1, "BATT2_LOW_MAH", false /* reportMissing */)
    property Fact failsafeBatt1CritMah: ctrl.getParameterFact(-1, "BATT_CRT_MAH", false /* reportMissing */)
    property Fact failsafeBatt2CritMah: ctrl.getParameterFact(-1, "BATT2_CRT_MAH", false /* reportMissing */)
    property Fact failsafeBatt1LowVoltage: ctrl.getParameterFact(-1, "BATT_LOW_VOLT", false /* reportMissing */)
    property Fact failsafeBatt2LowVoltage: ctrl.getParameterFact(-1, "BATT2_LOW_VOLT", false /* reportMissing */)
    property Fact failsafeBatt1CritVoltage: ctrl.getParameterFact(-1, "BATT_CRT_VOLT", false /* reportMissing */)
    property Fact failsafeBatt2CritVoltage: ctrl.getParameterFact(-1, "BATT2_CRT_VOLT", false /* reportMissing */)
    property Fact armingCheck: ctrl.getParameterFact(-1, "ARMING_CHECK")
    property bool roverFirmware: ctrl.parameterExists(-1, "MODE1") // This catches all usage of ArduRover firmware vehicle types: Rover, Boat...

    FactPanelController { id: ctrl; }

    CCFlickable{
        id: flk
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
                    id: batfs
                    width: ui.fontWidth * 40
                    height: b1col.height
                    color: cc.none
                    border.color: cc.border
                    visible: batt1MonitorEnabled
                    Column{
                        id: b1col
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            height: contentHeight + ui.x2margin
                            text: qsTr("Battery1 Failsafe Triggers")
                            font.pointSize: ui.lFontSize
                        }
                        CCButton{
                            width: ui.fontWidth * 16
                            height: ui.fontHeight * 2
                            text: qsTr("Reboot Vehicle")
                            visible: !batt1ParamsAvailable
                        }
                        Column{
                            width: parent.width
                            visible: batt1ParamsAvailable
                            CCComboBoxEditor{
                                title: qsTr("Low action")
                                fact: failsafeBatt1LowAct
                            }
                            CCComboBoxEditor{
                                title: qsTr("Critical action")
                                fact: failsafeBatt1CritAct
                            }
                            CCTextEditor{
                                title: qsTr("Low voltage threshold")
                                fact: failsafeBatt1LowVoltage
                            }
                            CCTextEditor{
                                title: qsTr("Critical voltage threshold")
                                fact: failsafeBatt1CritVoltage
                            }
                            CCTextEditor{
                                title: qsTr("Low mAh threshold")
                                fact: failsafeBatt1LowMah
                            }
                            CCTextEditor{
                                title: qsTr("Critical mAh threshold")
                                fact: failsafeBatt1CritMah
                            }
                        }
                    }
                }
                Rectangle{
                    id: bat2fs
                    width: ui.fontWidth * 40
                    height: b2col.height
                    color: cc.none
                    border.color: cc.border
                    visible: batt2MonitorEnabled
                    Column{
                        id: b2col
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            height: contentHeight + ui.x2margin
                            text: qsTr("Battery2 Failsafe Triggers")
                            font.pointSize: ui.lFontSize
                        }
                        CCButton{
                            width: ui.fontWidth * 16
                            height: ui.fontHeight * 2
                            text: qsTr("Reboot Vehicle")
                            visible: !batt2ParamsAvailable
                        }
                        Column{
                            width: parent.width
                            visible: batt2ParamsAvailable
                            CCComboBoxEditor{
                                title: qsTr("Low action")
                                fact: failsafeBatt2LowAct
                            }
                            CCComboBoxEditor{
                                title: qsTr("Critical action")
                                fact: failsafeBatt2CritAct
                            }
                            CCTextEditor{
                                title: qsTr("Low voltage threshold")
                                fact: failsafeBatt2LowVoltage
                            }
                            CCTextEditor{
                                title: qsTr("Critical voltage threshold")
                                fact: failsafeBatt2CritVoltage
                            }
                            CCTextEditor{
                                title: qsTr("Low mAh threshold")
                                fact: failsafeBatt2LowMah
                            }
                            CCTextEditor{
                                title: qsTr("Critical mAh threshold")
                                fact: failsafeBatt2CritMah
                            }
                        }
                    }
                }
                Loader {
                    sourceComponent: ctrl.vehicle.fixedWing ? planeFs : undefined
                    //sourceComponent: planeFs
                }
                Loader {
                    sourceComponent: roverFirmware ? planeFs : undefined
                    //sourceComponent: roverFs
                }
                Loader {
                    sourceComponent: ctrl.vehicle.multiRotor ? copterFs : undefined
                    //sourceComponent: copterFs
                }
                Loader {
                    sourceComponent: ctrl.vehicle.multiRotor ? fence : undefined
                    //sourceComponent: fence
                }
                Loader {
                    sourceComponent: ctrl.vehicle.multiRotor ? copterRtl : undefined
                    //sourceComponent: copterRtl
                }
                Loader {
                    sourceComponent: ctrl.vehicle.fixedWing ? planeRtl : undefined
                    //sourceComponent: planeRtl
                }
                Rectangle{
                    id: arm
                    width: parent.width
                    height: armcol.height
                    color: cc.none
                    border.color: cc.border

                    property var all
                    property var cur

                    Column{
                        id: armcol
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            height: contentHeight + ui.x2margin
                            text: qsTr("Arming Checks")
                            font.pointSize: ui.lFontSize
                        }
                        CCText{
                            id: armingCheckWarning
                            width: parent.width
                            text: qsTr("Warning: Turning off arming checks can lead to loss of Vehicle control.")
                            color: cc.error
                            wrapMode: Text.WordWrap
                            visible: armingCheck.value !== 1
                        }
                        Flow{
                            width: parent.width
                            Repeater{
                                model: armingCheck.bitmaskStrings
                                CCSwitchEditor{
                                    width: ui.fontWidth * 15
                                    title: modelData
                                    stateOn: armingCheck.value & armingCheck.bitmaskValues[index]
                                    enabled: (index && armingCheck.value === 1) ? false : true
                                    onStateChanged: {
                                        if(stateOn){
                                            armingCheck.value &= ~armingCheck.bitmaskValues[index]
                                        }else{
                                            if(index === 0){
                                                armingCheck.value = 1
                                            }else{
                                                armingCheck.value |= armingCheck.bitmaskValues[index]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Component{
        id: planeFs
        Rectangle{
            id:plane
            width: ui.fontWidth * 30
            height: planecol.height
            color: cc.none
            border.color: cc.border

            property Fact failsafeThrEnable: ctrl.getParameterFact(-1, "THR_FAILSAFE")
            property Fact failsafeThrValue: ctrl.getParameterFact(-1, "THR_FS_VALUE")
            property Fact failsafeGCSEnable: ctrl.getParameterFact(-1, "FS_GCS_ENABL")

            Column{
                id: planecol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("Failsafe Triggers")
                    font.pointSize: ui.lFontSize
                }
                CCSwitchEditor{
                    title: qsTr("Throttle PWM")
                    stateOn: plane.failsafeThrEnable.value
                    onStateChanged: {
                        plane.failsafeThrEnable.value = !plane.failsafeThrEnable.value
                    }
                }
                CCTextEditor{
                    title: qsTr("Threshold")
                    fact: plane.failsafeThrValue
                    enabled: plane.failsafeThrEnable.value
                }
                CCSwitchEditor{
                    title: qsTr("GCS failsafe")
                    stateOn: plane.failsafeGCSEnable !== 0
                    onStateChanged: {
                        plane.failsafeGCSEnable.value = !plane.failsafeGCSEnable.value
                    }
                }
            }
        }
    }
    Component{
        id: roverFs
        Rectangle{
            id: rover
            width: ui.fontWidth * 40
            height: rovercol.height
            color: cc.none
            border.color: cc.border

            property Fact failsafeGCSEnable: ctrl.getParameterFact(-1, "FS_GCS_ENABLE")
            property Fact failsafeThrEnable: ctrl.getParameterFact(-1, "FS_THR_ENABLE")
            property Fact failsafeThrValue: ctrl.getParameterFact(-1, "FS_THR_VALUE")
            property Fact failsafeAction: ctrl.getParameterFact(-1, "FS_ACTION")
            property Fact failsafeCrashCheck: ctrl.getParameterFact(-1, "FS_CRASH_CHECK")

            Column{
                id: rovercol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter

                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("Failsafe Triggers")
                    font.pointSize: ui.lFontSize
                }
                CCComboBoxEditor{
                    title: qsTr("Ground Station failsafe:")
                    fact: rover.failsafeGCSEnable
                }
                CCComboBoxEditor{
                    title: qsTr("Throttle failsafe:")
                    fact: rover.failsafeThrEnable
                }
                CCTextEditor{
                    title: qsTr("PWM threshold:")
                    fact: rover.failsafeThrValue
                }
                CCComboBoxEditor{
                    title: qsTr("Failsafe Crash Check:")
                    fact: rover.failsafeCrashCheck
                }
            }
        }
    }
    Component{
        id: copterFs
        Rectangle{
            id: copter
            width: ui.fontWidth * 40
            height: coptercol.height
            color: cc.none
            border.color: cc.border
            property Fact failsafeGCSEnable: ctrl.getParameterFact(-1, "FS_GCS_ENABLE")
            property Fact failsafeBattLowAct: ctrl.getParameterFact(-1, "r.BATT_FS_LOW_ACT", false /* reportMissing */)
            property Fact failsafeBattMah: ctrl.getParameterFact(-1, "r.BATT_LOW_MAH", false /* reportMissing */)
            property Fact failsafeBattVoltage: ctrl.getParameterFact(-1, "r.BATT_LOW_VOLT", false /* reportMissing */)
            property Fact failsafeThrEnable: ctrl.getParameterFact(-1, "FS_THR_ENABLE")
            property Fact failsafeThrValue: ctrl.getParameterFact(-1, "FS_THR_VALUE")

            Column{
                id: coptercol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("General Failsafe Triggers")
                    font.pointSize: ui.lFontSize
                }
                CCComboBoxEditor{
                    title: qsTr("Ground Station failsafe:")
                    fact: copter.failsafeGCSEnable
                }
                CCComboBoxEditor{
                    title: qsTr("Throttle failsafe:")
                    model: [
                        qsTr("Disabled"), qsTr("Always RTL"),
                        qsTr("Continue with Mission in Auto Mode"), qsTr("Always Land")]
                    currentIndex: copter.failsafeThrEnable.value
                    onUpdateResult:
                        (index) => {
                            copter.failsafeThrEnable.value = index
                        }
                }
                CCTextEditor{
                    title: qsTr("PWM threshold:")
                    fact: copter.failsafeThrValue
                }
            }
        }
    }
    Component{
        id: fence
        Rectangle{
            id: fen
            width: ui.fontWidth * 40
            height: fencol.height
            color: cc.none
            border.color: cc.border
            property Fact fenceAction: ctrl.getParameterFact(-1, "FENCE_ACTION")
            property Fact fenceAltMax: ctrl.getParameterFact(-1, "FENCE_ALT_MAX")
            property Fact fenceEnable: ctrl.getParameterFact(-1, "FENCE_ENABLE")
            property Fact fenceMargin: ctrl.getParameterFact(-1, "FENCE_MARGIN")
            property Fact fenceRadius: ctrl.getParameterFact(-1, "FENCE_RADIUS")
            property Fact fenceType: ctrl.getParameterFact(-1, "FENCE_TYPE")

            readonly property int maxAltitudeFenceBitMask: 1
            readonly property int circleFenceBitMask:      2
            readonly property int polygonFenceBitMask:     4

            Column{
                id: fencol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("GeoFence")
                    font.pointSize: ui.lFontSize
                }
                CCSwitchEditor{
                    title: qsTr("Enabled")
                    fact: fen.fenceEnable
                }
                CCSwitchEditor{
                    id: maxen
                    title: qsTr("Maximum Altitude")
                    stateOn: fen.fenceType.rawValue & fen.maxAltitudeFenceBitMask
                    enabled: fen.fenceEnable.value
                    onStateChanged: {
                        if (stateOn) {
                            fen.fenceType.rawValue |= fen.maxAltitudeFenceBitMask
                        } else {
                            fen.fenceType.value &= ~fen.maxAltitudeFenceBitMask
                        }
                    }
                }
                CCTextEditor{
                    title: ""
                    fact: fen.fenceAltMax
                    enabled: maxen.stateOn && fen.fenceEnable.value
                }
                CCSwitchEditor{
                    id: cir
                    title: qsTr("Circle centered on Home")
                    stateOn: fen.fenceType.rawValue & fen.circleFenceBitMask
                    enabled: fen.fenceEnable.value
                    onStateChanged: {
                        if (stateOn) {
                            fen.fenceType.rawValue |= fen.circleFenceBitMask
                        } else {
                            fen.fenceType.value &= ~fen.circleFenceBitMask
                        }
                    }
                }
                CCTextEditor{
                    title: ""
                    fact: fen.fenceRadius
                    enabled: cir.stateOn && fen.fenceEnable.value
                }
                CCSwitchEditor{
                    id: poly
                    title: qsTr("Inclusion/Exclusion Circles+Polygons")
                    stateOn: fen.fenceType.rawValue & fen.polygonFenceBitMask
                    enabled: fen.fenceEnable.value
                    onStateChanged: {
                        if (stateOn) {
                            fen.fenceType.rawValue |= fen.polygonFenceBitMask
                        } else {
                            fen.fenceType.value &= ~fen.polygonFenceBitMask
                        }
                    }
                }
                CCComboBoxEditor{
                    title: qsTr("Breach action")
                    fact: fen.fenceAction
                    enabled: fen.fenceEnable.value
                }
                CCComboBoxEditor{
                    title: qsTr("Fence margin")
                    fact: fen.fenceMargin
                    enabled: fen.fenceEnable.value
                }
            }
        }
    }
    Component{
        id: copterRtl
        Rectangle{
            id: rtl
            width: img.width + rtlFlow.width + ui.x2margin
            height: rtlFlow.height
            color: cc.none
            border.color: cc.border

            property Fact landSpeedFact:   ctrl.getParameterFact(-1, "LAND_SPEED")
            property Fact rtlAltFact:      ctrl.getParameterFact(-1, "RTL_ALT")
            property Fact rtlLoitTimeFact: ctrl.getParameterFact(-1, "RTL_LOIT_TIME")
            property Fact rtlAltFinalFact: ctrl.getParameterFact(-1, "RTL_ALT_FINAL")
            property int opt: 0

            CCImage{
                id: img
                //width: ui.isTinyScreen ? 0 : ui.fontWidth * 20
                width: ui.fontWidth * 20
                height: width
            }

            Flow{
                id: rtlFlow
                width: ui.fontWidth * 42
                anchors.left: img.right
                anchors.leftMargin: ui.margin
                CCText{
                    height: contentHeight + ui.x2margin
                    text: qsTr("Return To Launch")
                    font.pointSize: ui.lFontSize
                }
                CCText{
                    id: cur
                    width: parent.width
                    leftPadding: ui.fontHeight + ui.margin
                    text: qsTr("Return at current altitude")
                    Rectangle{
                        width: ui.fontHeight
                        height: width
                        radius: width / 2
                        color: (rtl.opt === 0 ? cc.selected : cc.normal)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Row{
                    height: spec.height
                    spacing: ui.margin
                    Rectangle{
                        width: ui.fontHeight
                        height: width
                        radius: width / 2
                        color: (rtl.opt === 1 ? cc.selected : cc.normal)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    CCTextEditor{
                        id: spec
                        width: rtlFlow.width - ui.fontHeight - ui.margin
                        title: qsTr("Return at specified altitude")
                        fact: rtl.rtlAltFact
                    }
                }
                CCSwitchEditor{
                    id: loiter
                    title: qsTr("Loiter above Home")
                    stateOn: rtl.rtlLoitTimeFact.value > 0
                    onStateChanged: {
                        if(rtl.rtlLoitTimeFact.value === 0){
                            rtl.rtlLoitTimeFact.value = 60
                        }else{
                            rtl.rtlLoitTimeFact.value = 0
                        }
                    }
                }
                CCTextEditor{
                    title: "Time"
                    fact: rtl.rtlLoitTimeFact
                    enabled: loiter.stateOn
                }
                CCTextEditor{
                    title: qsTr("Final land stage altitude")
                    fact: rtl.rtlAltFinalFact
                }
                CCTextEditor{
                    title: qsTr("Final land stage descent speed")
                    fact: rtl.landSpeedFact
                }
            }
        }
    }
    Component{
        id: planeRtl
        Rectangle{
            id: prtl
            width: ui.fontWidth * 40
            height: prtlcol.height
            color: cc.none
            border.color: cc.border

            property Fact rtlAltFact: ctrl.getParameterFact(-1, "ALT_HOLD_RTL")
            property int opt: 0

            Flow{
                id: prtlcol
                width: parent.width - ui.x2margin
                anchors.horizontalCenter: parent.horizontalCenter
                CCText{
                    width: parent.width
                    height: contentHeight + ui.x2margin
                    text: qsTr("Return To Launch")
                    font.pointSize: ui.lFontSize
                }
                CCText{
                    id: cur
                    width: parent.width
                    leftPadding: ui.fontHeight + ui.margin
                    text: qsTr("Return at current altitude")
                    Rectangle{
                        width: ui.fontHeight
                        height: width
                        radius: width / 2
                        color: (prtl.opt === 0 ? cc.selected : cc.normal)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Row{
                    height: spec.height
                    spacing: ui.margin
                    Rectangle{
                        width: ui.fontHeight
                        height: width
                        radius: width / 2
                        color: (prtl.opt === 1 ? cc.selected : cc.normal)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    CCTextEditor{
                        id: spec
                        width: prtlcol.width - ui.fontHeight - ui.margin
                        title: qsTr("Return at specified altitude")
                        fact: prtl.rtlAltFact
                    }
                }
            }
        }
    }
}
