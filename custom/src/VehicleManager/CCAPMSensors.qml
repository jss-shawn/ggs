
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.Vehicle

import MAVLink

import qgc
import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Sensor")

    property var gcsPosition: QGroundControl.qgcPositionManger.gcsPosition
    property var mapPosition: QGroundControl.flightMapPosition
    property var partInfos:[
        {
            name: qsTr("Sensor Settings"),
            color: cc.enabled,
            desc: qsTr("If mounted in the direction of flight, select None.")},
        {
            name: qsTr("Compass"),
            color: ctrl.compassSetupNeeded ? cc.error : cc.enabled,
            desc: qsTr("Before calibrating make sure rotation settings are correct.") +
                  qsTr(" If mounted in the direction of flight, select None.")},
        {
            name: qsTr("Compass Motor"),
            color: cc.enabled,
            desc: qsTr("This is recommended for vehicles that have only an internal compass and on vehicles where there is significant interference on the compass from the motors, power wires, etc.") +
                  qsTr(" CompassMot only works well if you have a battery current monitor because the magnetic interference is linear with current drawn.") +
                  qsTr(" It is technically possible to set-up CompassMot using throttle but this is not recommended.")+
                  qsTr("\n\nDisconnect your props, flip them over and rotate them one position around the frame.") +
                  qsTr(" In this configuration they should push the copter down into the ground when the throttle is raised.")+
                  qsTr("\n\nSecure the copter (perhaps with tape) so that it does not move.")+
                  qsTr("\n\nTurn on your transmitter and keep throttle at zero.")},
        {
            name: qsTr("Accelerometer"),
            color: ctrl.accelSetupNeeded ? cc.error : cc.enabled,
            desc: qsTr("Before calibrating make sure rotation settings are correct.") +
                  qsTr(" If mounted in the direction of flight, select None.")},
        {
            name: qsTr("Level Horizon"),
            color: cc.enabled,
            desc: (ctrl.accelSetupNeeded ? qsTr("Accelerometer must be calibrated prior to Level Horizon.") :
                                           qsTr("To level the horizon you need to place the vehicle in its level flight position and press Calibration."))},
        {
            name: qsTr("Gyro"),
            color: cc.enabled,
            desc: qsTr("For Gyroscope calibration you will need to place your vehicle on a surface and leave it still.")},
        {
            name: vehicle.fixedWing ? qsTr("Baro/Airspeed") : qsTr("Pressure"),
            color: cc.enabled,
            desc: (vehicle.sub ? qsTr("Pressure calibration will set the depth to zero at the current pressure reading.") :
                                 qsTr("Pressure calibration will set the altitude to zero at the current pressure reading.")) +
                  (vehicle.fixedWing ? qsTr("To calibrate the airspeed sensor shield it from the wind. Do not touch the sensor or obstruct any holes during the calibration.") :
                                       "")}
    ]
    property int partIndex: 0
    property var imgSource: [
        {
            done: ctrl.orientationCalDownSideDone,
            inProgress: ctrl.orientationCalDownSideInProgress,
            rotation: ctrl.orientationCalDownSideRotate,
            source:"qrc:///qmlimages/VehicleDown.png"},
        {
            done: ctrl.orientationCalLeftSideDone,
            inProgress: ctrl.orientationCalLeftSideInProgress,
            rotation: ctrl.orientationCalLeftSideRotate,
            source: "/qmlimages/VehicleLeft.png"},
        {
            done: ctrl.orientationCalRightSideDone,
            inProgress: ctrl.orientationCalRightSideInProgress,
            rotation: ctrl.orientationCalRightSideRotate,
            source:"/qmlimages/VehicleRight.png"},
        {
            done: ctrl.orientationCalNoseDownSideDone,
            inProgress: ctrl.orientationCalNoseDownSideInProgress,
            rotation: ctrl.orientationCalNoseDownSideRotate,
            source:"/qmlimages/VehicleNoseDown.png"},
        {
            done: ctrl.orientationCalTailDownSideDone,
            inProgress: ctrl.orientationCalTailDownSideInProgress,
            rotation: ctrl.orientationCalTailDownSideRotate,
            source:"/qmlimages/VehicleTailDown.png"},
        {
            done: ctrl.orientationCalUpsideDownSideDone,
            inProgress: ctrl.orientationCalUpsideDownSideInProgress,
            rotation: ctrl.orientationCalUpsideDownSideRotate,
            source:"/qmlimages/VehicleUpsideDown.png"},
    ]
    function compassMask () {
        var mask = 0
        mask |=  (0 + (params.rgCompassPrio[0].rawValue !== 0)) << 0
        mask |=  (0 + (params.rgCompassPrio[1].rawValue !== 0)) << 1
        mask |=  (0 + (params.rgCompassPrio[2].rawValue !== 0)) << 2
        return mask
    }
    APMSensorParams{
        id: params
        factPanelController: ctrl
    }
    APMSensorsComponentController {
        id: ctrl
        statusLog: logText
        progressBar: bar
        nextButton: next
        cancelButton: cancel
        orientationCalAreaHelpText: tip

        property var rgCompassCalFitness: [ ctrl.compass1CalFitness, ctrl.compass2CalFitness, ctrl.compass3CalFitness ]
        readonly property string statusTextAreaDefaultText: qsTr("Start the individual calibration steps by clicking one of the buttons to the left.")

        onResetStatusTextArea: logText.text = statusTextAreaDefaultText

        // onWaitingForCancelChanged: {
        //     if (ctrl.waitingForCancel) {
        //         waitForCancelDialogComponent.createObject(mainWindow).open()
        //     }
        // }

        onCalibrationComplete:
            (calType)=>{
                switch (calType) {
                    case MAVLink.CalibrationAccel:
                    case MAVLink.CalibrationMag:
                    // postOnboardCompassCalibrationComponent.createObject(mainWindow).open()
                    allCompass.showFitness = true
                    break
                    default:
                    allCompass.showFitness = false
                }
            }
    }
    property Fact boardRot: ctrl.getParameterFact(-1, "AHRS_ORIENTATION")
    property Fact autoDecFact: ctrl.getParameterFact(-1, "COMPASS_AUTODEC")
    Column{
        anchors.fill: contentArea
        anchors.margins: ui.margin
        spacing: ui.margin
    ProgressBar{
        id: bar
        width: parent.width
        height: ui.fontHeight
    }
    Item{
        id: cont
        width: parent.width
        height: parent.height - bar.height - ui.margin
        Rectangle{
            id:setup
            width: ui.isMobile ? (parent.width - ui.margin) / 2 : ui.fontWidth * 50
            height: parent.height
            color: cc.none
            border.color: cc.border
            Flow{
                id: setupFlow
                y: ui.margin
                width: parent.width - ui.x2margin
                spacing: ui.margin
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater{
                    model: partInfos
                    CCButton{
                        width: ui.fontWidth * 15
                        text: modelData.name
                        textColor: modelData.color
                        selected: partIndex === index
                        onClicked: {
                            if(partIndex !== index){
                                partIndex = index
                            }
                        }
                    }
                }
            }
            Item{
                id: setupArea
                width: parent.width
                height: parent.height - setupFlow.height - ui.margin
                anchors.bottom: parent.bottom
            }
            CCFlickable{
                anchors.fill: setupArea
                anchors.margins: ui.margin
                fixedWidth: true
                CCMouseArea{
                    width: parent.width
                    height: children[0].height
                    Column{
                        width: parent.width
                        spacing: ui.margin
                        CCText{
                            id: desText
                            width: parent.width
                            text: partInfos[partIndex].desc
                            wrapMode: Text.WordWrap
                        }
                        CCComboBoxEditor{
                            title: qsTr("Autopilot Rotation:")
                            fact: boardRot
                            visible: partIndex < 2 || 3 === partIndex
                        }
                        Column{
                            id: compassCol
                            width: parent.width
                            visible: partIndex < 2
                            CCAPMCompass{
                                id: allCompass
                            }
                            CCText{
                                id: declination
                                height: contentHeight + ui.x2margin
                                text: qsTr("Magnetic Declination")
                                visible: vehicle.sub
                            }
                            CCSwitchEditor{
                                id: mmd
                                title: qsTr("Manual Magnetic Declination")
                                fact: autoDecFact
                                visible: declination.visible
                            }
                            CCComboBoxEditor{
                                fact: params.declinationFact
                                visible: mmd.visible && mmd.stateOn
                            }
                            CCText{
                                id: northCal
                                width: parent.width
                                height: contentHeight + ui.x2margin
                                text: qsTr("Fast compass calibration given vehicle position and yaw. ") +
                                      qsTr("This results in zero diagonal and off-diagonal elements, ") +
                                      qsTr("so is only suitable for vehicles where the field is close to spherical. ") +
                                      qsTr("It is useful for large vehicles where moving the vehicle to calibrate itis difficult. ") +
                                      qsTr("Point the vehicle North before using it.")
                                wrapMode: Text.WordWrap
                            }
                            CCSwitchEditor{
                                id: cal
                                title: qsTr("Fast Calibration")
                                stateOn: false
                                visible: northCal.visible
                                onStateChanged: {
                                    stateOn = !stateOn
                                }
                            }
                            CCText{
                                id: pos
                                height: contentHeight + ui.x2margin
                                text: qsTr("Vehicle has no Valid positon, please provide it")
                                visible: cal.stateOn && !vehicle.coordinate.isValid
                            }
                            CCSwitchEditor{
                                id: useGcsPosition
                                title: qsTr("Use GCS position instead")
                                stateOn: gcsPosition.isValid
                                visible: pos.visible && gcsPosition.isValid
                            }
                            CCSwitchEditor{
                                id: useMapPosition
                                title: qsTr("Use current map position instead")
                                stateOn: mapPosition.isValid
                                visible: pos.visible && !gcsPosition.isValid
                            }
                            CCText{
                                height: contentHeight + ui.x2margin
                                text: qsTr(`Lat: ${mapPosition.latitude.toFixed(4)} Lon: ${mapPosition.longitude.toFixed(4)}`)
                                visible: useMapPosition.stateOn
                            }
                            CCTextField{
                                id: northCalLat
                                text: "0.00"
                                //textColor:  isNaN(parseFloat(text)) ? cc.error : cc.enabled
                                enabled: !useGcsPosition.stateOn
                                visible: !useGcsPosition.stateOn && !useMapPosition.stateOn && cal.stateOn
                            }
                            CCTextField{
                                id: northCalLon
                                text: "0.00"
                                //textColor:  isNaN(parseFloat(text)) ? qgcPal.warningText: qgcPal.textFieldText
                                enabled: !useGcsPosition.stateOn
                                visible: !useGcsPosition.stateOn && !useMapPosition.stateOn && cal.stateOn
                            }
                        }
                        Column{
                            id: accelerometer
                            width: parent.width
                            visible: 3 === partIndex
                            CCText{
                                width: parent.width
                                text: qsTr("Simple accelerometer calibration is less precise but allows calibrating without rotating the vehicle. Check this if you have a large/heavy vehicle.")
                                wrapMode: Text.WordWrap
                            }
                            CCSwitchEditor{
                                id: accSimple
                                title: qsTr("Simple Accelerometer Calibration")
                                stateOn: false
                                onStateChanged: {
                                    stateOn = !stateOn
                                }
                            }
                        }
                        Row{
                            anchors.right: parent.right
                            spacing: ui.margin
                            visible: partIndex
                            CCButton{
                                id: cancel
                                width: ui.fontWidth * 12
                                text: qsTr("Cancel")
                                enabled: false
                                onClicked: ctrl.cancelCalibration()
                            }
                            CCButton{
                                id: next
                                width: ui.fontWidth * 12
                                text: qsTr("Next")
                                enabled: false
                                onClicked: ctrl.nextClicked()
                            }
                            CCButton{
                                width: ui.fontWidth * 12
                                text: qsTr("Calibration")
                                onClicked: {
                                    if(1 === partIndex){
                                        if (!cal.checked) {
                                            ctrl.calibrateCompass()
                                        } else {
                                            var lat = parseFloat(northCalLat.text)
                                            var lon = parseFloat(northCalLon.text)
                                            if (useMapPosition.checked) {
                                                lat = mapPosition.latitude
                                                lon = mapPosition.longitude
                                            }
                                            if (useGcsPosition.checked) {
                                                lat = gcsPosition.latitude
                                                lon = gcsPosition.longitude
                                            }
                                            if (isNaN(lat) || isNaN(lon)) {
                                                return
                                            }
                                            ctrl.calibrateCompassNorth(lat, lon, compassMask())
                                        }
                                    }else if(2 === partIndex){
                                        ctrl.calibrateMotorInterference()
                                    }else if(3 === partIndex){
                                        ctrl.calibrateAccel(accSimple.stateOn)
                                    }else if(4 === partIndex){
                                        ctrl.levelHorizon()
                                    }else if(5 === partIndex){
                                        ctrl.calibrateGyro()
                                    }else if(6 === partIndex){
                                        ctrl.calibratePressure()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // CCFlickable{
            //     id: resultFlk
            //     anchors.fill: setupArea
            //     anchors.margins: ui.margin
            //     fixedWidth: true
            //     CCMouseArea{
            //         width: parent.width
            //         height: children[0].height
            //         Column{

            //         }
            //     }
            // }
        }
        Rectangle{
            id:log
            width: parent.width - setup.width
            height: parent.height
            color: cc.none
            border.color: cc.border
            anchors.right: parent.right
            CCFlickable{
                anchors.fill: parent
                anchors.margins: ui.margin
                fixedWidth: true
                CCMouseArea{
                    width: parent.width
                    height: flow.visible ? flow.height : logText.height
                    TextArea{
                        id: logText
                        width: parent.width
                        font.family: ui.fontFamily
                    }
                    Flow{
                        id: flow
                        width: parent.width
                        spacing: ui.margin
                        visible: ctrl.showOrientationCalArea
                        CCText{
                            id: tip
                            width: parent.width
                            height: contentHeight + ui.x2margin
                        }
                        Repeater{
                            model: imgSource
                            CCImage{
                                width: (parent.width - ui.x2margin) / 3
                                height: width
                                source: modelData.source
                                CCText{
                                    width: contentWidth + ui.x2margin
                                    height: contentHeight + ui.x2margin
                                    text: modelData.done ? qsTr("Complete") :
                                                           modelData.inProgress ? modelData.rotation ?
                                                                                      qsTr("Rotation") : qsTr("Hold Still") : qsTr("Waitting")
                                    alignRight: true
                                    color: modelData.done ? cc.good : modelData.inProgress ?
                                                                cc.warnning : cc.error
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
