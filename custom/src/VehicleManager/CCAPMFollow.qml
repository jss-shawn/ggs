
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.Vehicle


import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: "Vehicle Follow Me"

    property Fact followEnabled: ctrl.getParameterFact(-1, "FOLL_ENABLE")
    property bool followParamsAvailable: ctrl.parameterExists(-1, "FOLL_SYSID")
    property Fact followDistanceMax: ctrl.getParameterFact(-1, "FOLL_DIST_MAX", false /* reportMissing */)
    property Fact followSysId: ctrl.getParameterFact(-1, "FOLL_SYSID", false /* reportMissing */)
    property Fact followOffsetX: ctrl.getParameterFact(-1, "FOLL_OFS_X", false /* reportMissing */)
    property Fact followOffsetY: ctrl.getParameterFact(-1, "FOLL_OFS_Y", false /* reportMissing */)
    property Fact followOffsetZ: ctrl.getParameterFact(-1, "FOLL_OFS_Z", false /* reportMissing */)
    property Fact followOffsetType: ctrl.getParameterFact(-1, "FOLL_OFS_TYPE", false /* reportMissing */)
    property Fact followAltitudeType: ctrl.getParameterFact(-1, "FOLL_ALT_TYPE", false /* reportMissing */)
    property Fact followYawBehavior: ctrl.getParameterFact(-1, "FOLL_YAW_BEHAVE", false /* reportMissing */)
    property bool roverFirmware: ctrl.roverFirmware
    property bool showMainSetup: followEnabled.rawValue === 1 && supportedSetup
    property bool followMaintain: followPositionCombo.currentIndex === followComboMaintainIndex
    property bool supportedSetup: true
    property bool showOffsetsSetup: showMainSetup && !followMaintain

    property int followComboMaintainIndex: 0
    property int followComboSpecifyIndex: 1
    readonly property int followYawBehaviorNone: 0
    readonly property int followYawBehaviorFace: 1
    readonly property int followYawBehaviorSame: 2
    readonly property int followYawBehaviorFlight: 3
    readonly property int followAltitudeTypeAbsolute: 0
    readonly property int followAltitudeTypeRelative: 1
    readonly property int followOffsetTypeRelative: 1

    function validateSupportedParamSetup() {
        var followSysIdOk = followSysId.rawValue === QGroundControl.mavlinkSystemID
        var followOffsetOk = followOffsetType.rawValue === followOffsetTypeRelative
        var followAltOk = true
        var followYawOk = true
        if (!roverFirmware) {
            followAltOk = followAltitudeType.rawValue === followAltitudeTypeRelative
            followYawOk = followYawBehavior.rawValue === followYawBehaviorNone || followYawBehavior.rawValue === followYawBehaviorFace || followYawBehavior.rawValue === followYawBehaviorFlight
        }
        supportedSetup = followOffsetOk && followAltOk && followYawOk && followSysIdOk
        return supportedSetup
    }
    function setUIFromParams() {
        if (!followParamsAvailable || !validateSupportedParamSetup()) {
            return
        }
        if (followOffsetX.rawValue || followOffsetY.rawValue || followOffsetZ.rawValue) {
            followPositionCombo.currentIndex = followComboSpecifyIndex
            var angleRadians = Math.atan2(followOffsetX.rawValue, followOffsetY.rawValue)
            if (angleRadians == 0) {
                ctrl.distance.rawValue = followOffsetY.rawValue
            } else {
                ctrl.distance.rawValue = followOffsetX.rawValue / Math.sin(angleRadians)
            }
            ctrl.angle.rawValue = radiansToHeading(angleRadians)
        }else{
            followPositionCombo.currentIndex = followComboMaintainIndex
            ctrl.distance.rawValue = 0
            ctrl.angle.rawValue = 0
            ctrl.height.rawValue = 0
        }

        ctrl.height.rawValue = -followOffsetZ.rawValue
        if (!roverFirmware) {
            var comboIndex = -1
            for (var i=0; i<pointVehicleCombo.rgValues.length; i++) {
                if (pointVehicleCombo.rgValues[i] === followYawBehavior.rawValue) {
                    comboIndex = i
                    break
                }
            }
            pointVehicleCombo.currentIndex = comboIndex
        }
    }
    function setFollowMeParamDefaults() {
        followSysId.rawValue = QGroundControl.mavlinkSystemID
        followOffsetType.rawValue = followOffsetTypeRelative
        if (!roverFirmware) {
            followAltitudeType.rawValue = followAltitudeTypeRelative
            followYawBehavior.rawValue = followYawBehaviorFace
        }

        ctrl.distance.value = ctrl.distance.defaultValue
        ctrl.angle.value = ctrl.angle.defaultValue
        ctrl.height.value = ctrl.height.defaultValue

        setXYOffsetByAngleAndDistance(ctrl.angle.rawValue, ctrl.distance.rawValue)
        followOffsetZ.rawValue = -ctrl.height.rawValue
        setUIFromParams()
    }
    function setXYOffsetByAngleAndDistance(headingAngleDegrees, distance) {
        if(distance){
            var angleRadians = headingToRadians(headingAngleDegrees)
            if(angleRadians){
                followOffsetX.rawValue = Math.sin(angleRadians) * distance
                followOffsetY.rawValue = Math.cos(angleRadians) * distance
                if (Math.abs(followOffsetX.rawValue) < 0.0001) {
                    followOffsetX.rawValue = 0
                }
                if (Math.abs(followOffsetY.rawValue) < 0.0001) {
                    followOffsetY.rawValue = 0
                }
            }else{
                followOffsetX.rawValue = 0
                followOffsetY.rawValue = distance
            }
        }else{
            followOffsetX.rawValue = followOffsetY.rawValue = 0
        }
    }
    function radiansToHeading(radians) {
        var geometricAngle = QGroundControl.unitsConversion.radiansToDegrees(radians)
        var headingAngle = 90 - geometricAngle
        if (headingAngle < 0) {
            headingAngle += 360
        } else if (headingAngle > 360) {
            headingAngle -= 360
        }
        return headingAngle
    }
    function headingToRadians(heading) {
        var geometricAngle = -(heading - 90)
        return QGroundControl.unitsConversion.degreesToRadians(geometricAngle)
    }

    APMFollowComponentController {
        id: ctrl

        onMissingParametersAvailable: {
            followDistanceMax = ctrl.getParameterFact(-1, "FOLL_DIST_MAX")
            followSysId = ctrl.getParameterFact(-1, "FOLL_SYSID")
            followOffsetX = ctrl.getParameterFact(-1, "FOLL_OFS_X")
            followOffsetY = ctrl.getParameterFact(-1, "FOLL_OFS_Y")
            followOffsetZ = ctrl.getParameterFact(-1, "FOLL_OFS_Z")
            followOffsetType = ctrl.getParameterFact(-1, "FOLL_OFS_TYPE")
            if(!roverFirmware){
                followAltitudeType = ctrl.getParameterFact(-1, "FOLL_ALT_TYPE")
                followYawBehavior = ctrl.getParameterFact(-1, "FOLL_YAW_BEHAVE")
            }
            followParamsAvailable = true
            //vehicleParamRefreshLabel.visible = false
            validateSupportedParamSetup()
        }
    }
    CCFlickable{
        anchors.fill: contentArea
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea{
            width: parent.width
            height: children[0].height
            Column{
                width: parent.width
                CCSwitchEditor{
                    id: followCheck
                    width: ui.fontWidth * 28
                    title: qsTr("Enable Follow Me")
                    fact: followEnabled
                    onStateChanged: {
                        if(stateOn){
                            var missingParameters = [ "FOLL_DIST_MAX", "FOLL_SYSID", "FOLL_OFS_X", "FOLL_OFS_Y", "FOLL_OFS_Z", "FOLL_OFS_TYPE"  ]
                            if(!roverFirmware){
                                missingParameters.push("FOLL_ALT_TYPE", "FOLL_YAW_BEHAVE")
                            }
                            ctrl.getMissingParameters(missingParameters)
                            //vehicleParamRefreshLabel.visible = true
                        }
                    }
                }
                CCText{
                    width: parent.width
                    text: qsTr("The vehicle parameters required for follow me are currently set in a way which is not supported. Using follow with this setup may lead to unpredictable/hazardous results.")
                    wrapMode: Text.WordWrap
                    visible: !supportedSetup
                }
                CCButton{
                    width: ui.fontWidth * 24
                    text: qsTr("Reset To Supported Settings")
                    visible: !supportedSetup
                    onClicked: setFollowMeParamDefaults()
                }
                Column{
                    width: ui.fontWidth * 60
                    visible: showMainSetup
                    CCComboBoxEditor{
                        id: followPositionCombo
                        title: qsTr("Vehicle Position")
                        model: [ qsTr("Maintain Current Offsets"), qsTr("Specify Offsets")]
                        onUpdateResult:
                            (index)=>{
                                if(index){
                                    setFollowMeParamDefaults()
                                }else{
                                    followOffsetX.rawValue = followOffsetY.rawValue = followOffsetZ.rawValue = 0
                                    setUIFromParams()
                                }
                            }
                    }
                    CCComboBoxEditor{
                        id: pointVehicleCombo
                        title: qsTr("Point Vehicle")
                        model: rgText
                        visible: !roverFirmware
                        property var rgText: [ qsTr("Maintain current vehicle orientation"), qsTr("Point at ground station location"), qsTr("Same direction as ground station movement") ]
                        property var rgValues: [ followYawBehaviorNone, followYawBehaviorFace, followYawBehaviorFlight ]
                        onUpdateResult:
                            (index)=>{
                                followYawBehavior.rawValue = rgValues[index]
                            }
                    }
                    Column{
                        width: parent.width
                        visible: followMaintain
                        CCText{
                            height: contentHeight + ui.x2margin
                            text: qsTr("Vehicle Offsets")
                            font.pointSize: ui.lFontSize
                        }
                        CCTextEditor{
                            title: qsTr("Angle")
                            fact: ctrl.angle
                            onValueChanged:
                                (value)=>{
                                    setXYOffsetByAngleAndDistance(ctrl.angle.rawValue, ctrl.distance.rawValue)
                                }
                        }
                        CCTextEditor{
                            title: qsTr("Distance")
                            fact: ctrl.distance
                            onValueChanged:
                                (value)=>{
                                    setXYOffsetByAngleAndDistance(ctrl.angle.rawValue, ctrl.distance.rawValue)
                                }
                        }
                        CCTextEditor{
                            id: heightLabel
                            title: qsTr("Height")
                            fact: ctrl.height
                            visible: !roverFirmware && !followMaintain
                            onValueChanged:
                                (value)=>{
                                    followOffsetZ.rawValue = -ctrl.height.rawValue
                                }
                        }
                    }
                }
                Row{
                    visible: showOffsetsSetup
                    Item{
                        height: ui.fontWidth * 50
                        width:  height
                        Rectangle{
                            width: 2
                            height: parent.height
                            color: cc.dark
                            anchors.centerIn: parent
                        }
                        Rectangle{
                            width: parent.width
                            height: 2
                            color: cc.dark
                            anchors.centerIn: parent
                        }
                        CCText{
                            anchors.top: parent.top
                            anchors.topMargin: parent.height * 0.2
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Click in the graphic to change angle")
                            opacity: 0.5
                        }
                        CCImage{
                            id: gcsIcon
                            height: ui.fontWidth * 5
                            source: "/res/QGCLogoArrow"
                            anchors.centerIn:   parent
                            mipmap: true
                            antialiasing: true
                            fillMode: Image.PreserveAspectFit
                        }
                        Item{
                            id: vehicleHolder
                            anchors.fill:   parent
                            transform: Rotation {
                                origin.x: vehicleHolder.width  / 2
                                origin.y: vehicleHolder.height / 2
                                angle: ctrl.angle.rawValue
                            }
                            CCImage{
                                id: vehicleIcon
                                height: ui.fontWidth * 5
                                source: ctrl.vehicle.vehicleImageOpaque
                                mipmap: true
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                                transform: Rotation {
                                    origin.x: vehicleIcon.width  / 2
                                    origin.y: vehicleIcon.height / 2
                                    angle: roverFirmware ? 0 : (followYawBehavior.rawValue === followYawBehaviorNone ?
                                                            0 : (followYawBehavior.rawValue === followYawBehaviorFace ?
                                                            180 : -ctrl.angle.rawValue))
                                }
                            }
                            Rectangle {
                                id: distanceLine
                                x: parent.width / 2
                                y: vehicleIcon.height
                                width: 2
                                height: (parent.height / 2) - (vehicleIcon.height + (gcsIcon.height / 2))
                                color: cc.enabled
                                opacity: 0.4
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: ui.fontWidth * 2
                                    height: 2
                                    color: cc.enabled
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: ui.fontWidth * 2
                                    height: 2
                                    color: cc.enabled
                                }
                            }
                            CCText{
                                id: distanceLabel
                                anchors.centerIn: distanceLine
                                text: ctrl.distance.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                                transform: Rotation {
                                    origin.x: distanceLabel.width  / 2
                                    origin.y: distanceLabel.height / 2
                                    angle: -ctrl.angle.rawValue
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked:
                                (mouse)=>{
                                    // Translate x,y to centered
                                    var x = mouse.x - (width / 2)
                                    var y = (height - mouse.y) - (height / 2)
                                    ctrl.angle.rawValue = radiansToHeading(Math.atan2(y, x))
                                    setXYOffsetByAngleAndDistance(ctrl.angle.rawValue, ctrl.distance.rawValue)
                                }
                        }
                    }

                    Column{
                        height: parent.height
                        spacing: 0
                        visible: !roverFirmware
                        Image {
                            id: vehicleIconHeight
                            source: ctrl.vehicle.vehicleImageOpaque
                            mipmap: true
                            height: ui.fontWidth * 5
                            fillMode: Image.PreserveAspectFit
                            transform: Rotation {
                                origin.x: vehicleIconHeight.width  / 2
                                origin.y: vehicleIconHeight.height / 2
                                angle: 65
                                axis { x: 1; y: 0; z: 0 }
                            }
                        }
                        Item {
                            width: Math.max(ui.fontWidth * 2, heightValueLabel.width)
                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            Rectangle {
                                id: heightLine
                                width: 2
                                height: parent.height
                                color: cc.enabled
                                opacity: 0.4
                                anchors.horizontalCenter: parent.horizontalCenter
                                Rectangle {
                                    width: ui.fontWidth * 2
                                    height: 2
                                    color: cc.enabled
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Rectangle {
                                    width: ui.fontWidth * 2
                                    height: 2
                                    color: cc.enabled
                                    anchors.bottom:             parent.bottom
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                }
                            }

                            CCText{
                                id: heightValueLabel
                                text: ctrl.height.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                                anchors.centerIn: parent
                            }
                        }

                        Rectangle{
                            id: launchIconHeight
                            width: ui.fontWidth * 2
                            height: width
                            radius: width / 2
                            color: cc.warnning
                            antialiasing: true
                            anchors.horizontalCenter: parent.horizontalCenter

                            transform: [
                                Scale {
                                    origin.x:       launchIconHeight.width  / 2
                                    origin.y:       launchIconHeight.height / 2
                                    xScale:         1.5
                                    yScale:         2.5

                                },
                                Rotation {
                                    origin.x:       launchIconHeight.width  / 2
                                    origin.y:       launchIconHeight.height / 2
                                    angle:          75
                                    axis { x: 1; y: 0; z: 0 }
                                } ]
                            CCText{
                                anchors.fill: parent
                                text: qsTr("L")
                                alignMid: true
                                color: cc.normalBg
                            }
                        }
                    }
                }
            }
        }
    }
}
