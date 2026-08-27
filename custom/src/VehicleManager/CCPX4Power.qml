
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Radio")

    readonly property string highlightPrefix: "<font color=\"" + cc.warnning + "\">"
    readonly property string highlightSuffix: "</font>"
    readonly property string batNCellsIndexedParamName: "BAT#_N_CELLS"

    property Fact uavcanEnable: ctrl.getParameterFact(-1, "UAVCAN_ENABLE", false)
    property bool indexedBatteryParamsAvailable: ctrl.parameterExists(-1, batNCellsIndexedParamName.replace("#", 1))
    property int  indexedBatteryParamCount: getIndexedBatteryParamCount()
    property string dlgTitle: ""
    property string dlgContent: ""


    function getIndexedBatteryParamCount() {
        var batteryIndex = 1
        do {
            if (!ctrl.parameterExists(-1, batNCellsIndexedParamName.replace("#", batteryIndex))) {
                return batteryIndex - 1
            }
            batteryIndex++
        } while (true)
    }

    PowerComponentController {
        id: ctrl
        onOldFirmware:{
            dlgTitle = qsTr("ESC Calibration")
            dlgContent = (QGroundControl.appName) + qsTr(" cannot perform ESC Calibration with this version of firmware. You will need to upgrade to a newer firmware.")
            dlg.visible = true
        }
        onNewerFirmware:{
            dlgTitle = qsTr("ESC Calibration")
            dlgContent = QGroundControl.appName + qsTr(" cannot perform ESC Calibration with this version of firmware. You will need to upgrade ") + QGroundControl.appName + "."
            dlg.visible = true
        }
        onDisconnectBattery:{
            dlgTitle = qsTr("ESC Calibration failed")
            dlgContent = qsTr("You must disconnect the battery prior to performing ESC Calibration. Disconnect your battery and try again.")
            dlg.visible = true
        }
        onConnectBattery: escCalibrationDlgComponent.createObject(mainWindow).open()
    }
    CCFlickable{
        id: flk
        anchors.fill: contentArea
        anchors.margins: ui.margin
        fixedWidth: true
        CCMouseArea{
            width: parent.width
            height: children[0].height
            Column{
                width: ui.fontWidth * 60
                spacing: ui.margin
                Repeater{
                    id: batteayRep
                    model: indexedBatteryParamsAvailable ? indexedBatteryParamCount : 1
                    Rectangle{
                        id: frame
                        width: parent.width
                        height: batCol.height + ui.margin
                        radius: ui.radius
                        color: cc.none
                        border.color: cc.border
                        property int batteryIndex: index + 1
                        property bool showBatteryIndex: batteayRep.count > 1
                        property bool useIndexedParamNames: indexedBatteryParamsAvailable
                        QtObject {
                            id: batParams
                            property int batIndex: frame.batteryIndex
                            property bool multibleBat: indexedBatteryParamsAvailable
                            property Fact battSource: ctrl.getParameterFact(-1, "BAT#_SOURCE".replace("#", multibleBat ? batIndex : ""))
                            property Fact battNumCells: ctrl.getParameterFact(-1, "BAT#_N_CELLS".replace("#", multibleBat ? batIndex : ""))
                            property Fact battHighVolt: ctrl.getParameterFact(-1, "BAT#_V_CHARGED".replace("#", multibleBat ? batIndex : ""))
                            property Fact battLowVolt: ctrl.getParameterFact(-1, "BAT#_V_EMPTY".replace("#", multibleBat ? batIndex : ""))
                            property Fact battVoltLoadDrop: ctrl.getParameterFact(-1, "BAT#_V_LOAD_DROP".replace("#", multibleBat ? batIndex : ""), false)
                            property Fact battVoltageDivider: ctrl.getParameterFact(-1, "BAT#_V_DIV".replace("#", multibleBat ? batIndex : ""), false)
                            property Fact battAmpsPerVolt: ctrl.getParameterFact(-1, "BAT#_A_PER_V".replace("#", multibleBat ? batIndex : ""), false)
                            property FactGroup batteryFactGroup:  ctrl.vehicle.getFactGroup("battery" + (batIndex))

                            property bool battVoltLoadDropAvailable: ctrl.parameterExists(-1, "BAT#_V_LOAD_DROP".replace("#", multibleBat ? batIndex : ""))
                            property bool battVoltageDividerAvailable: ctrl.parameterExists(-1, "BAT#_V_DIV".replace("#", multibleBat ? batIndex : ""))
                            property bool battAmpsPerVoltAvailable: ctrl.parameterExists(-1, "BAT#_A_PER_V".replace("#", multibleBat ? batIndex : ""))

                            property string batNCellsIndexedParamName: "BAT#_N_CELLS"
                            property bool indexedBatteryParamsAvailable: ctrl.parameterExists(-1, batNCellsIndexedParamName.replace("#", 1))
                            property int indexedBatteryParamCount: getIndexedBatteryParamCount()

                            Component.onCompleted: {
                                if (batIndex > 1 && !indexedBatteryParamsAvailable) {
                                    console.warn("Internal Error: BatteryParams.qml batteryIndex > 1 while indexed params are not available", batteryIndex)
                                }
                            }

                            function getIndexedBatteryParamCount() {
                                var batteryIndex = 1
                                do {
                                    if (!ctrl.parameterExists(-1, batNCellsIndexedParamName.replace("#", batteryIndex))) {
                                        return batteryIndex - 1
                                    }
                                    batteryIndex++
                                } while (true)
                            }
                        }
                        Column{
                            id: batCol
                            width: parent.width - ui.x2margin
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: ui.margin
                            CCText{
                                width: parent.width
                                height: contentHeight + ui.x2margin
                                text: qsTr("Battery ") + (parent.showBatteryIndex ? parent.batteryIndex : "")
                                alignMid: true
                                font.pointSize: ui.lFontSize
                            }
                            CCComboBoxEditor{
                                width: ui.fontWidth * 30
                                title: qsTr("Source")
                                fact: batParams.battSource
                            }
                            Row{
                                spacing: ui.margin
                                Column{
                                    width: ui.fontWidth * 40
                                    visible: batParams.battSource.rawValue !== -1
                                    CCTextEditor{
                                        id: numCells
                                        title: qsTr("Number of Cells (in Series)")
                                        fact: batParams.battNumCells
                                    }
                                    CCTextEditor{
                                        id: fullVolt
                                        title: qsTr("Full Voltage (per cell)")
                                        fact: batParams.battHighVolt
                                    }
                                    CCTextEditor{
                                        id: emptyVolt
                                        title: qsTr("Empty Voltage (per cell)")
                                        fact: batParams.battLowVolt
                                    }
                                }
                                CCImage{
                                    width: ui.fontWidth * 8
                                    height: width * 1.3
                                    sourceSize.height: height
                                    fillMode: Image.PreserveAspectFit
                                    smooth:  true
                                    cache: false
                                    source: "/qmlimages/PowerComponentBattery_0" +
                                            (batParams.battNumCells.rawValue > 1 ? batParams.battNumCells.rawValue : 1) +
                                            "cell.svg"
                                    anchors.verticalCenter: parent.verticalCenter
                                    CCText{
                                        x: parent.width + ui.margin
                                        text: qsTr("Max: ") + (batParams.battNumCells.rawValue * batParams.battHighVolt.rawValue).toFixed(2) + " V"
                                    }
                                    CCText{
                                        x: parent.width + ui.margin
                                        text: qsTr("Min: ") + (batParams.battNumCells.rawValue * batParams.battLowVolt.rawValue).toFixed(2) + " V"
                                        anchors.bottom: parent.bottom
                                    }
                                }
                            }
                            Column{
                                width: ui.fontWidth * 30
                                CCTextEditor{
                                    title: qsTr("Voltage divider")
                                    fact: batParams.battVoltageDivider
                                }
                                CCText{
                                    width: batCol.width
                                    text: qsTr("If the battery voltage reported by the vehicle is largely different than the voltage read externally using a voltmeter you can adjust the voltage multiplier value to correct this. Click the Calculate button for help with calculating a new value.")
                                    font.pointSize: ui.sFontSize
                                    wrapMode: Text.WordWrap
                                }
                                CCSwitchEditor{
                                    id: calcDivider
                                    title: qsTr("Calculate")
                                    stateOn: false
                                    onStateChanged: {
                                        stateOn = !stateOn
                                    }
                                }
                                CCTextEditor{
                                    id: measuredVolt
                                    width: parent.width
                                    title: qsTr("Measured voltage")
                                    enabled: calcDivider.stateOn
                                    CCButton{
                                        width: ui.fontWidth * 10
                                        text: qsTr("Calculate")
                                        anchors.top: parent.bottom
                                        anchors.topMargin: ui.margin
                                        anchors.right: parent.right
                                        onClicked: {
                                            var measuredVoltageValue = parseFloat(measuredVolt.text)
                                            if (measuredVoltageValue === 0 || isNaN(measuredVoltageValue)) {
                                                return
                                            }
                                            var newVoltageDivider = (measuredVoltageValue * batParams.battVoltageDivider.value) / batParams.batteryFactGroup.voltage.value
                                            if (newVoltageDivider > 0) {
                                                batParams.battVoltageDivider.value = newVoltageDivider
                                            }
                                        }
                                    }
                                }
                                CCText{
                                    text: qsTr("Vehicle voltage: ") + (batParams.batteryFactGroup ? batParams.batteryFactGroup.voltage.valueString : "")
                                    enabled: calcDivider.stateOn
                                }
                                CCText{
                                    text: qsTr("Voltage divider: ") + batParams.battVoltageDivider.rawValue.toFixed(2)
                                    enabled: calcDivider.stateOn
                                }
                            }
                            Column{
                                width: ui.fontWidth * 30
                                visible: batParams.battAmpsPerVoltAvailable
                                CCTextEditor{
                                    title: qsTr("Amps per volt")
                                    fact: batParams.battAmpsPerVolt
                                }
                                CCText{
                                    width: batCol.width
                                    text: qsTr("If the current draw reported by the vehicle is largely different than the current read externally using a current meter you can adjust the amps per volt value to correct this. Click the Calculate button for help with calculating a new value.")
                                    font.pointSize: ui.sFontSize
                                    wrapMode: Text.WordWrap
                                }
                                CCSwitchEditor{
                                    id: calcAmps
                                    title: qsTr("Calculate")
                                    stateOn: false
                                    onStateChanged: {
                                        stateOn = !stateOn
                                    }
                                }
                                CCTextEditor{
                                    id: measuredAmps
                                    width: parent.width
                                    title: qsTr("Measured current")
                                    enabled: calcAmps.stateOn
                                    CCButton{
                                        width: ui.fontWidth * 10
                                        text: qsTr("Calculate")
                                        anchors.top: parent.bottom
                                        anchors.topMargin: ui.margin
                                        anchors.right: parent.right
                                        onClicked:  {
                                            var measuredCurrentValue = parseFloat(measuredAmps.text)
                                            if (measuredCurrentValue === 0 || isNaN(measuredCurrentValue)) {
                                                return
                                            }
                                            var newAmpsPerVolt = (measuredCurrentValue * batParams.battAmpsPerVolt.value) / batParams.batteryFactGroup.current.value
                                            if (newAmpsPerVolt != 0) {
                                                batParams.battAmpsPerVolt.value = newAmpsPerVolt
                                            }
                                        }
                                    }
                                }
                                CCText{
                                    text: qsTr("Vehicle current: ") + (batParams.batteryFactGroup ? batParams.batteryFactGroup.current.valueString : "")
                                    enabled: calcAmps.stateOn
                                }
                                CCText{
                                    text: qsTr("Amps per volt: ") + batParams.battAmpsPerVolt.rawValue.toFixed(2)
                                    enabled: calcAmps.stateOn
                                }
                            }
                            CCSwitchEditor{
                                id: advancedSettings
                                width: ui.fontWidth * 30
                                title: qsTr("Show Advanced Settings")
                                stateOn: false
                                onStateChanged: {
                                    stateOn = !stateOn
                                }
                            }
                            Column{
                                width: ui.fontWidth * 35
                                visible: advancedSettings.stateOn
                                CCTextEditor{
                                    title: qsTr("Voltage Drop on Full Load (per cell)")
                                    fact: batParams.battVoltLoadDrop
                                }
                                CCText{
                                    width: batCol.width
                                    text: qsTr("Batteries show less voltage at high throttle. Enter the difference in Volts between idle throttle and full throttle, divided by the number of battery cells. Leave at the default if unsure.")
                                    font.pointSize: ui.sFontSize
                                    wrapMode: Text.WordWrap
                                }
                                CCText{
                                    width: batCol.width
                                    text: qsTr("If this value is set too high, the battery might be deep discharged and damaged.")
                                    color: cc.warnning
                                    font.pointSize: ui.sFontSize
                                    wrapMode: Text.WordWrap
                                }
                                CCText{
                                    text: qsTr("Compensated Minimum Voltage: ") + ((batParams.battNumCells.value * batParams.battLowVolt.value) - (batParams.battNumCells.value * batParams.battVoltLoadDrop.value)).toFixed(2) + qsTr(" V")
                                    font.pointSize: ui.lFontSize
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    id: pwmCal
                    width: parent.width
                    height: pwnCalCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    Column{
                        id: pwnCalCol
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: ui.margin
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("ESC PWM Minimum and Maximum Calibration")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        CCText{
                            width: parent.width
                            text: qsTr("WARNING: Propellers must be removed from vehicle prior to performing ESC calibration.")
                            color: cc.warnning
                            wrapMode: Text.WordWrap
                        }
                        CCText{
                            text: qsTr("You must use USB connection for this operation.")
                        }
                        CCButton {
                            width: ui.fontWidth * 10
                            text: qsTr("Calibrate")
                            onClicked: ctrl.calibrateEsc()
                        }
                    }
                }
                CCSwitchEditor{
                    id: showUAVCAN
                    title: qsTr("Show UAVCAN Settings")
                    stateOn: uavcanEnable ? uavcanEnable.rawValue !== 0 : false
                    visible: uavcanEnable
                    onStateChanged: {
                        stateOn = !stateOn
                    }
                }
                Rectangle{
                    id: uavcanBus
                    width: parent.width
                    height: uavcanBusCol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    visible: showUAVCAN.stateOn
                    Column{
                        id: uavcanBusCol
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: ui.margin
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("UAVCAN Bus Configuration")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        CCComboBox{
                            width: ui.fontWidth * 20
                            model: uavcanEnable ? uavcanEnable.enumStrings : [0]
                            currentIndex: uavcanEnable ? uavcanEnable.enumIndex : 0
                            onActivated: {
                                if(uavcanEnable){
                                    uavcanEnable.enumIndex = currentIndex
                                }
                            }
                        }
                        CCText{
                            width: parent.width
                            text: qsTr("Change required restart")
                            color: cc.warnning
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle{
                    id: uavcanMotor
                    width: parent.width
                    height: uavcanMotorol.height + ui.x2margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    visible: showUAVCAN.stateOn
                    Column{
                        id: uavcanMotorol
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: ui.margin
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("UAVCAN Motor Index and Direction Assignment")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        CCText{
                            width: parent.width
                            text: qsTr("WARNING: Propellers must be removed from vehicle prior to performing UAVCAN ESC configuration.")
                            color: cc.warnning
                            wrapMode: Text.WordWrap
                        }
                        CCText{
                            width: parent.width
                            text: qsTr("ESC parameters will only be accessible in the editor after assignment.")
                            wrapMode: Text.WordWrap
                        }
                        CCText{
                            width: parent.width
                            text: qsTr("Start the process, then turn each motor into its turn direction, in the order of their motor indices.")
                            wrapMode: Text.WordWrap
                        }
                        CCButton{
                            width: ui.fontWidth * 20
                            text: qsTr("Start Assignment")
                            onClicked: ctrl.startBusConfigureActuators()
                        }
                        CCButton{
                            width: ui.fontWidth * 20
                            text: qsTr("Stop Assignment")
                            onClicked: ctrl.stopBusConfigureActuators()
                        }
                    }
                }
            }
        }
    }
    MouseArea{
        id: dlg
        anchors.fill: parent
        visible: false
        onClicked: {
            visible = false
        }

        Rectangle{
            width: parent.width * 0.4
            height: parent.height * 0.4
            radius: ui.radius
            color: cc.normalBg
            border.color: cc.border
            anchors.centerIn: parent
            CCText{
                width: parent.width
                text: dlgTitle
                alignMid: true
            }
            CCText{
                width: parent.width
                text: dlgContent
                alignMid: true
                wrapMode: Text.WordWrap
                anchors.centerIn: parent
            }
        }
    }
}
