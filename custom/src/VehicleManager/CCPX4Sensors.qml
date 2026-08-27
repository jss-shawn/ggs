
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Sensor")

    property var coreOpts: QGroundControl.corePlugin.options
    property var gcsPosition: QGroundControl.qgcPositionManger.gcsPosition
    property var mapPosition: QGroundControl.flightMapPosition
    property bool hasMag: ctrl.parameterExists(-1, "SYS_HAS_MAG") ? ctrl.getParameterFact(-1, "SYS_HAS_MAG").value : false
    property bool showReboot: false
    property bool showWaitting: ctrl.waitingForCancel
    property bool showOriBtn: checkShowOriBtn()
    property bool showBoardOrientation: true
    property bool fixedOri: coreOpts.sensorsHaveFixedOrientation
    property bool boardOrientationChangeAllowed: !fixedOri && showBoardOrientation
    property Fact cal_mag0_id: ctrl.getParameterFact(-1, "CAL_MAG0_ID")
    property Fact cal_acc0_id: ctrl.getParameterFact(-1, "CAL_ACC0_ID")
    property Fact cal_gyro0_id: ctrl.getParameterFact(-1, "CAL_GYRO0_ID")
    property Fact sens_board_rot: ctrl.getParameterFact(-1, "SENS_BOARD_ROT")
    property Fact sens_dpres_off: ctrl.getParameterFact(-1, "SENS_DPRES_OFF")
    property string calMagIdParamFormat: "CAL_MAG#_ID"
    property string calMagRotParamFormat: "CAL_MAG#_ROT"
    property string sensorParamInfo
    property int arbitrarilyLargeMaxMagIndex: 50
    property int partIndex: 0

    property var partInfos:[
        {
            name: qsTr("Orientations"),
            color: cc.enabled,
            visible: showOriBtn,
            desc: qsTr("Adjust orientations as needed.")},
        {
            name: qsTr("Compass"),
            color: cal_mag0_id.value ? cc.enabled : cc.error,
            visible: hasMag && coreOpts.showSensorCalibrationCompass,
            desc: qsTr("For Compass calibration you will need to rotate your vehicle through a number of positions.")},
        {
            name: qsTr("Accelerometer"),
            color: cal_acc0_id.value ? cc.enabled : cc.error,
            visible: coreOpts.showSensorCalibrationAccel,
            desc: qsTr("For Accelerometer calibration you will need to place your vehicle on all six sides on a perfectly level surface and hold it still in each orientation for a few seconds.")},
        {
            name: qsTr("Gyroscope"),
            color: cal_gyro0_id.value ? cc.enabled : cc.error,
            visible: coreOpts.showSensorCalibrationGyro,
            desc: qsTr("For Gyroscope calibration you will need to place your vehicle on a surface and leave it still.")},
        {
            name: qsTr("Level Horizon"),
            color: cc.enabled,
            visible: coreOpts.showSensorCalibrationLevel,
            desc: qsTr("To level the horizon you need to place the vehicle in its level flight position and leave still.")},
        {
            name: qsTr("Airspeed"),
            color: sens_dpres_off.value ? cc.enabled : cc.error,
            visible: coreOpts.showSensorCalibrationAirspeed && sourcePtr.airspeedCalSupported,
            desc: qsTr("For Airspeed calibration you will need to keep your airspeed sensor out of any wind and then blow across the sensor. Do not touch the sensor or obstruct any holes during the calibration.")},
    ]
    property var imgSource: [
        {
            done: ctrl.orientationCalDownSideDone,
            inProgress: ctrl.orientationCalDownSideInProgress,
            rotation: ctrl.orientationCalDownSideRotate,
            source:"qrc:///qmlimages/VehicleDown.png",
            rotSource:"qrc:///qmlimages/VehicleDownRotate.png"},
        {
            done: ctrl.orientationCalLeftSideDone,
            inProgress: ctrl.orientationCalLeftSideInProgress,
            rotation: ctrl.orientationCalLeftSideRotate,
            source: "/qmlimages/VehicleLeft.png",
            rotSource: "/qmlimages/VehicleLeftRotate.png"},
        {
            done: ctrl.orientationCalRightSideDone,
            inProgress: ctrl.orientationCalRightSideInProgress,
            rotation: ctrl.orientationCalRightSideRotate,
            source:"/qmlimages/VehicleRight.png",
            rotSource:"/qmlimages/VehicleRightRotate.png"},
        {
            done: ctrl.orientationCalNoseDownSideDone,
            inProgress: ctrl.orientationCalNoseDownSideInProgress,
            rotation: ctrl.orientationCalNoseDownSideRotate,
            source:"/qmlimages/VehicleNoseDown.png",
            rotSource:"/qmlimages/VehicleNoseDownRotate.png"},
        {
            done: ctrl.orientationCalTailDownSideDone,
            inProgress: ctrl.orientationCalTailDownSideInProgress,
            rotation: ctrl.orientationCalTailDownSideRotate,
            source:"/qmlimages/VehicleTailDown.png",
            rotSource:"/qmlimages/VehicleTailDownRotate.png"},
        {
            done: ctrl.orientationCalUpsideDownSideDone,
            inProgress: ctrl.orientationCalUpsideDownSideInProgress,
            rotation: ctrl.orientationCalUpsideDownSideRotate,
            source:"/qmlimages/VehicleUpsideDown.png",
            rotSource:"/qmlimages/VehicleUpsideDownRotate.png"},
    ]
    function currentExternalMagCount() {
        if (!hasMag) {
            return 0
        } else {
            var externalMagCount = 0
            for (var index=0; index<arbitrarilyLargeMaxMagIndex; index++) {
                var magIdParam = calMagIdParamFormat.replace("#", index)
                if (ctrl.parameterExists(-1, magIdParam)) {
                    var calMagIdFact = ctrl.getParameterFact(-1, magIdParam)
                    var calMagRotFact = ctrl.getParameterFact(-1, calMagRotParamFormat.replace("#", index))
                    if (calMagIdFact.value > 0 && calMagRotFact.value >= 0) {
                        externalMagCount++
                    }
                } else {
                    return externalMagCount
                }
            }
            return 0
        }
    }
    function currentMagParamCount() {
        if(!hasMag){
            return 0
        }else{
            for(var index=0; index<arbitrarilyLargeMaxMagIndex; index++){
                var magIdParam = calMagIdParamFormat.replace("#", index)
                if(!ctrl.parameterExists(-1, magIdParam)){
                    return index
                }
            }
            return -1
        }
    }
    function checkShowOriBtn() {
        if (fixedOri) {
            return false
        } else if (boardOrientationChangeAllowed) {
            return true
        } else if (!fixedOri && hasMag)  {
            for (var index=0; index<arbitrarilyLargeMaxMagIndex; index++) {
                var magIdParam = calMagIdParamFormat.replace("#", index)
                if (ctrl.parameterExists(-1, magIdParam)) {
                    var calMagIdFact = ctrl.parameterExists(-1, magIdParam)
                    var calMagRotFact = ctrl.parameterExists(-1, calMagRotParamFormat.replace("#", index))
                    if (calMagIdFact.value > 0 && calMagRotFact.value >= 0) {
                        // Only external compasses can set orientation
                        return true
                    }
                }
            }
            return false
        } else {
            return false
        }
    }
    SensorsComponentController {
        id: ctrl
        statusLog: logText
        progressBar: bar
        compassButton: setupFlow.children[1]
        accelButton: setupFlow.children[2]
        gyroButton: setupFlow.children[3]
        levelButton: setupFlow.children[4]
        airspeedButton: setupFlow.children[5]
        cancelButton: cancel
        setOrientationsButton: setupFlow.children[0]
        orientationCalAreaHelpText: tip

        onResetStatusTextArea: statusLog.text = qsTr("Start the individual calibration steps by clicking one of the buttons to the left.")

        onMagCalComplete: {
            setOrientationsButton.visible = checkShowOriBtn()
            showBoardOrientation = false
            showReboot = true
            partIndex = 0
        }
        onSensorParamUpdated: {
            if(cal_mag0_id){
                sensorParamInfo += "New:\n"
                sensorParamInfo += ("off_x:" + ctrl.getParameterFact(-1, "CAL_MAG0_XOFF").rawValue.toFixed(3))
                sensorParamInfo += (" off_y:" + ctrl.getParameterFact(-1, "CAL_MAG0_YOFF").rawValue.toFixed(3))
                sensorParamInfo += (" off_z:" + ctrl.getParameterFact(-1, "CAL_MAG0_ZOFF").rawValue.toFixed(3))
                dlg.visible = true
            }
        }
    }
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
                        id: partRep
                        model: partInfos
                        CCButton{
                            width: ui.fontWidth * 15
                            text: modelData.name
                            textColor: modelData.color
                            selected: partIndex === index
                            visible: modelData.visible
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
                    height: parent.height - setupFlow.height - ui.x2margin
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
                            CCText{
                                width: parent.width
                                text: qsTr("Reboot the vehicle prior to flight.")
                                visible: !partIndex && showReboot
                            }
                            CCButton{
                                text: qsTr("Reboot Vehicle")
                                visible: !partIndex && showReboot
                                onClicked: {
                                    vehicle.rebootVehicle()
                                }
                            }

                            CCText{
                                id: boardRotationHelp
                                text: qsTr("Set autopilot orientation before calibrating.")
                                wrapMode: Text.WordWrap
                                visible: !fixedOri && (1 === partIndex || 2 === partIndex)
                            }
                            CCComboBoxEditor{
                                title: qsTr("Autopilot Orientation:")
                                fact: sens_board_rot
                                visible: !fixedOri && partIndex < 3
                            }
                            CCText{
                                text: qsTr("ROTATION_NONE indicates component points in direction of flight.")
                                wrapMode: Text.WordWrap
                                visible: !fixedOri && partIndex < 3
                            }
                            Repeater {
                                model: (!fixedOri && partIndex === 0) ? currentMagParamCount() : 0
                                Column {
                                    // id > = signals compass available, rot < 0 signals internal compass
                                    visible: calMagIdFact.value > 0 && calMagRotFact.value >= 0

                                    property Fact calMagIdFact: ctrl.getParameterFact(-1, calMagIdParamFormat.replace("#", index))
                                    property Fact calMagRotFact: ctrl.getParameterFact(-1, calMagRotParamFormat.replace("#", index))

                                    CCComboBoxEditor{
                                        title: qsTr("Mag %1 Orientation").arg(index)
                                        fact: parent.calMagRotFact
                                    }
                                }
                            }
                            Row{
                                anchors.right: parent.right
                                spacing: ui.margin
                                CCButton{
                                    id: cancel
                                    width: ui.fontWidth * 12
                                    text: qsTr("Cancel")
                                    enabled: false
                                    onClicked: ctrl.cancelCalibration()
                                }
                                CCButton{
                                    width: ui.fontWidth * 12
                                    text: qsTr("Calibration")
                                    onClicked: {
                                        if(0 === partIndex){
                                        }else if(1 === partIndex){
                                            ctrl.calibrateCompass()
                                            sensorParamInfo = "Old:\n"
                                            if(cal_mag0_id){
                                                sensorParamInfo += ("off_x:" + ctrl.getParameterFact(-1, "CAL_MAG0_XOFF").rawValue.toFixed(3))
                                                sensorParamInfo += (" off_y:" + ctrl.getParameterFact(-1, "CAL_MAG0_YOFF").rawValue.toFixed(3))
                                                sensorParamInfo += (" off_z:" + ctrl.getParameterFact(-1, "CAL_MAG0_ZOFF").rawValue.toFixed(3))
                                            }
                                            sensorParamInfo += "\n"
                                        }else if(2 === partIndex){
                                            ctrl.calibrateAccel()
                                        }else if(3 === partIndex){
                                            ctrl.calibrateGyro()
                                        }else if(4 === partIndex){
                                            ctrl.calibrateLevel()
                                        }else if(4 === partIndex){
                                            ctrl.calibrateAirspeed()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Rectangle{
                id:log
                width: parent.width - setup.width - ui.margin
                height: parent.height
                color: cc.none
                border.color: cc.border
                anchors.right: parent.right
                CCFlickable{
                    id: rFlk
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
                                    source: modelData.rotation ? modelData.rotSource : modelData.source
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
    CCMouseArea{
        anchors.fill: parent
        visible: showWaitting
        Rectangle{
            width: ui.fontWidth * 30
            height: ui.fontHeight * 6
            color: cc.normalBg
            border.color: cc.border
            anchors.centerIn: parent
            visible: showWaitting
            CCText{
                text: qsTr("Waiting for Vehicle to response to Cancel...")
                anchors.centerIn: parent
            }
        }
    }
    CCMouseArea{
        id: dlg
        anchors.fill: parent
        visible: false
        Rectangle{
            width: ui.fontWidth * 30
            height: ui.fontHeight * 6
            color: cc.normalBg
            border.color: cc.border
            anchors.centerIn: parent
            CCText{
                text: sensorParamInfo
                anchors.centerIn: parent
            }
        }
        onClicked: {
            visible = false
        }
    }
}
