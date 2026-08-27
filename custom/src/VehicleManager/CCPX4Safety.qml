
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Safety")

    readonly property string hitlParam: "SYS_HITL"

    property Fact enableLogging:       ctrl.getParameterFact(-1, "SDLOG_MODE")
    property Fact fenceAction:         ctrl.getParameterFact(-1, "GF_ACTION")
    property Fact fenceRadius:         ctrl.getParameterFact(-1, "GF_MAX_HOR_DIST")
    property Fact fenceAlt:            ctrl.getParameterFact(-1, "GF_MAX_VER_DIST")
    property Fact rtlLandDelay:        ctrl.getParameterFact(-1, "RTL_LAND_DELAY")
    property Fact lowBattAction:       ctrl.getParameterFact(-1, "COM_LOW_BAT_ACT")
    property Fact rcLossAction:        ctrl.getParameterFact(-1, "NAV_RCL_ACT")
    property Fact dlLossAction:        ctrl.getParameterFact(-1, "NAV_DLL_ACT")
    property Fact disarmLandDelay:     ctrl.getParameterFact(-1, "COM_DISARM_LAND")
    property Fact collisionPrevention: ctrl.getParameterFact(-1, "CP_DIST")
    property Fact objectAvoidance:     ctrl.getParameterFact(-1, "COM_OBS_AVOID")
    property Fact landSpeedMC:         ctrl.getParameterFact(-1, "MPC_LAND_SPEED", false)
    property bool hitlAvailable:       ctrl.parameterExists(-1, hitlParam)
    property Fact hitlEnabled:         ctrl.getParameterFact(-1, hitlParam, false)

    FactPanelController {
        id: ctrl
    }

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
                    width: ui.fontWidth * 50
                    height: lowBatteryCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: lowBatteryCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Low Battery Failsafe Trigger")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: lowBatteryImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                Image{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/LowBatteryLight.svg" : "/qmlimages/LowBattery.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - lowBatteryImg.width
                                CCComboBoxEditor{
                                    title: qsTr("Failsafe Action")
                                    fact: lowBattAction
                                }
                                CCTextEditor{
                                    title: qsTr("Battery Warn Level")
                                    fact: ctrl.getParameterFact(-1, "BAT_LOW_THR")
                                }
                                CCTextEditor{
                                    title: qsTr("Battery Failsafe Level")
                                    fact: ctrl.getParameterFact(-1, "BAT_CRIT_THR")
                                }
                                CCTextEditor{
                                    title: qsTr("Battery Emergency Level")
                                    fact: ctrl.getParameterFact(-1, "BAT_EMERGEN_THR")
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: collisionCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: collisionCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Object Detection")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: collisionImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: "/qmlimages/ObjectAvoidance.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - collisionImg.width
                                CCComboBoxEditor{
                                    title: qsTr("Collision Prevention")
                                    model: [qsTr("Disabled"), qsTr("Enabled")]
                                    enabled: collisionPrevention
                                    currentIndex: collisionPrevention ? (collisionPrevention.rawValue > 0 ? 1 : 0) : 0
                                    onUpdateResult:
                                        (index)=>{
                                            if(collisionPrevention) {
                                                collisionPrevention.value = index > 0 ? 5 : -1
                                                console.log('Collision prevention enabled: ' + collisionPrevention.value)
                                                showObstacleDistanceOverlayCheckBox.checked = collisionPrevention.value > 0
                                            }
                                        }
                                }
                                CCComboBoxEditor{
                                    title: qsTr("Obstacle Avoidance")
                                    model: [qsTr("Disabled"), qsTr("Enabled")]
                                    enabled: objectAvoidance && collisionPrevention.rawValue > 0
                                    currentIndex: objectAvoidance ? (objectAvoidance.value === 0 ? 0 : 1) : 0
                                    onUpdateResult:
                                        (index)=>{
                                            if(objectAvoidance) {
                                                objectAvoidance.value = index > 0 ? 1 : 0
                                            }
                                        }
                                }
                                CCSliderEditor{
                                    title: qsTr("Minimum Distance: (") + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString + ")"
                                    enabled: collisionPrevention && collisionPrevention.rawValue > 0
                                    from: QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(1)
                                    to: QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(15)
                                    stepSize: 1
                                    realTime: false
                                    simple: true
                                    value: {
                                        if (collisionPrevention && collisionPrevention.rawValue > 0) {
                                            return QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(collisionPrevention.rawValue)
                                        } else {
                                            return 1;
                                        }
                                    }
                                    onUpdateValue: {
                                        if(collisionPrevention) {
                                            //-- Negative means disabled
                                            if(collisionPrevention.rawValue >= 0) {
                                                collisionPrevention.rawValue = QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsToMeters(value)
                                            }
                                        }
                                    }
                                }
                                CCSwitchEditor{
                                    id: showObstacleDistanceOverlayCheckBox
                                    title: qsTr("Show obstacle distance overlay")
                                    fact: showObstacleDistanceOverlay
                                    visible: showObstacleDistanceOverlay.visible
                                    property Fact showObstacleDistanceOverlay: QGroundControl.settingsManager.flyViewSettings.showObstacleDistanceOverlay
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: rcLossCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: rcLossCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("RC Loss Failsafe Trigger")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: rcLossImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/RCLossLight.svg" : "/qmlimages/RCLoss.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - rcLossImg.width
                                CCComboBoxEditor{
                                    title: qsTr("Failsafe Action")
                                    fact: rcLossAction
                                }
                                CCTextEditor{
                                    title: qsTr("RC Loss Timeout")
                                    fact: ctrl.getParameterFact(-1, "COM_RC_LOSS_T")
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: dataLinkLossCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: dataLinkLossCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Data Link Loss Failsafe Trigger")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: dataLinkLossImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/DatalinkLossLight.svg" : "/qmlimages/DatalinkLoss.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - dataLinkLossImg.width
                                CCComboBoxEditor{
                                    title: qsTr("Failsafe Action")
                                    fact: dlLossAction
                                }
                                CCTextEditor{
                                    title: qsTr("Data Link Loss Timeout")
                                    fact: ctrl.getParameterFact(-1, "COM_DL_LOSS_T")
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: fenceCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: fenceCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Geofence Failsafe Trigger")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width - ui.x2margin
                            Item{
                                id: fenceImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/GeoFenceLight.svg" : "/qmlimages/GeoFence.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - fenceImg.width
                                CCComboBoxEditor{
                                    title: qsTr("Action on breach")
                                    fact: fenceAction
                                }
                                CCSwitchEditor{
                                    id: swRadius
                                    title: qsTr("Enable Radius")
                                    stateOn: fenceRadius.value > 0
                                    onStateChanged: {
                                        if(fenceRadius.value){
                                            fenceRadius.value = 0
                                        }else{
                                            fenceRadius.value = 100
                                        }
                                    }
                                }
                                CCTextEditor{
                                    title: qsTr("Max Radius")
                                    fact: fenceRadius
                                    enabled: swRadius.stateOn
                                }
                                CCSwitchEditor{
                                    id: swAlt
                                    title: qsTr("Enable Altitude")
                                    stateOn: fenceAlt ? fenceAlt.value > 0 : false
                                    onStateChanged: {
                                        if(fenceAlt.value){
                                            fenceAlt.value = 0
                                        }else{
                                            fenceAlt.value = 100
                                        }
                                    }
                                }
                                CCTextEditor{
                                    title: qsTr("Max Altitude")
                                    fact: fenceAlt
                                    enabled: swAlt.stateOn
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: rtlCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: rtlCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Return To Launch Settings")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: rtlImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/ReturnToHomeAltitude.svg" : "/qmlimages/ReturnToHomeAltitudeCopter.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - rtlImg.width
                                CCTextEditor{
                                    title: qsTr("Climb to altitude of")
                                    fact: ctrl.getParameterFact(-1, "RTL_RETURN_ALT")
                                }
                                CCText{
                                    text: qsTr("Return to launch Action")
                                    font.pointSize: ui.lFontSize
                                }
                                CCSwitchEditor{
                                    title: qsTr("Land immediately")
                                    stateOn: rtlLandDelay && rtlLandDelay.value === 0
                                    onStateChanged: {
                                        if(rtlLandDelay){
                                            rtlLandDelay.value = 0
                                        }
                                    }
                                }
                                CCSwitchEditor{
                                    title: qsTr("Loiter and do not land")
                                    stateOn: rtlLandDelay && rtlLandDelay.value < 0
                                    onStateChanged: {
                                        if(rtlLandDelay){
                                            rtlLandDelay.value = -1
                                        }
                                    }
                                }
                                CCSwitchEditor{
                                    title: qsTr("Loiter and land after specified time")
                                    stateOn: rtlLandDelay && rtlLandDelay.value > 0
                                    onStateChanged: {
                                        if(rtlLandDelay){
                                            rtlLandDelay.value = 60
                                        }
                                    }
                                }
                                CCTextEditor{
                                    title: qsTr("Loiter Time")
                                    fact: ctrl.getParameterFact(-1, "RTL_LAND_DELAY")
                                    enabled: rtlLandDelay && rtlLandDelay.value === -1
                                }
                                CCTextEditor{
                                    title: qsTr("Loiter Altitude")
                                    fact: ctrl.getParameterFact(-1, "RTL_DESCEND_ALT")
                                    enabled: rtlLandDelay && rtlLandDelay.value
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: landCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: landCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Land Mode Settings")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            Item{
                                id: landImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/LandMode.svg" : "/qmlimages/LandModeCopter.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            Column{
                                width: parent.width - landImg.width
                                CCTextEditor{
                                    title: qsTr("Landing Descent Rate")
                                    fact: landSpeedMC
                                    visible: vehicle && !vehicle.fixedWing
                                }
                                CCSwitchEditor{
                                    id: autoLand
                                    title: qsTr("Auto Land")
                                    stateOn: disarmLandDelay.value > 0
                                    onStateChanged: {
                                        if(disarmLandDelay.value){
                                            disarmLandDelay.value = 0
                                        }else{
                                            disarmLandDelay.value = 2
                                        }
                                    }
                                }
                                CCTextEditor{
                                    title: qsTr("Disarm After")
                                    fact: disarmLandDelay
                                    enabled: autoLand.stateOn
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: logCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: logCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Vehicle Telemetry Logging")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            height: logBox.height * 1.5
                            Item{
                                id: logImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: cc.theme === cc.Light ? "/qmlimages/no-logging-light.svg" : "/qmlimages/no-logging.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            CCComboBoxEditor{
                                id: logBox
                                width: parent.width - logImg.width
                                title: qsTr("Telemetry logging to vehicle storage")
                                model: [qsTr("Disabled"), qsTr("Enabled")]
                                currentIndex: enableLogging ? (enableLogging.value >= 0 ? 1 : 0) : 0
                                enabled: enableLogging
                                anchors.verticalCenter: parent.verticalCenter
                                //Component.onCompleted: {
                                //    currentIndex = enableLogging ? (enableLogging.value >= 0 ? 1 : 0) : 0
                                //}
                                onUpdateResult:
                                    (index)=>{
                                        if(enableLogging) {
                                            enableLogging.value = index > 0 ? 0 : -1
                                        }
                                    }
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 50
                    height: hitlCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    visible: hitlAvailable
                    Column{
                        id: hitlCol
                        width: parent.width - ui.x2margin
                        anchors.centerIn: parent
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Hardware in the Loop Simulation")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        Row{
                            width: parent.width
                            height: hitlBox.height * 1.5
                            Item{
                                id: hitlImg
                                width: ui.fontWidth * 13
                                height: parent.height
                                CCImage{
                                    width: ui.fontWidth * 12
                                    height: width / 2
                                    source: "/qmlimages/HITL.svg"
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    anchors.centerIn: parent
                                }
                            }
                            CCComboBoxEditor{
                                id: hitlBox
                                width: parent.width - hitlImg.width
                                title: qsTr("HITL Enabled")
                                fact: hitlEnabled
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
