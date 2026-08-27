
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.FactSystem

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Firmware")
    description: qsTr("You can upgrade vehicle firmware on this page")

    readonly property string highlightPrefix: "<font color=\"" + cc.warnning + "\">"
    readonly property string highlightSuffix: "</font>"
    readonly property string plugInText: "<big>" + highlightPrefix + qsTr("Plug in your device") + highlightSuffix + qsTr(" via USB to ") + highlightPrefix + qsTr("start") + highlightSuffix + qsTr(" firmware upgrade.") + "</big>"
    readonly property string welcomeText: qsTr("%1 can upgrade the firmware on Pixhawk devices and SiK Radios.").arg(QGroundControl.appName)
    readonly property string welcomeTextSingle: qsTr("Update the autopilot firmware to the latest version")
    readonly property string flashFailText: qsTr("If upgrade failed, make sure to connect ") + highlightPrefix + qsTr("directly") + highlightSuffix + qsTr(" to a powered USB port on your computer, not through a USB hub. ") +
                                            qsTr("Also make sure you are only powered via USB ") + highlightPrefix + qsTr("not battery") + highlightSuffix + "."
    readonly property string qgcUnplugText1: qsTr("All %1 connections to vehicles must be ").arg(QGroundControl.appName) + highlightPrefix + qsTr(" disconnected ") + highlightSuffix + qsTr("prior to firmware upgrade.")
    readonly property string qgcUnplugText2: highlightPrefix + "<big>" + qsTr("Please unplug your Pixhawk and/or Radio from USB.") + "</big>" + highlightSuffix

    property var firmwareUpgradeSettings: QGroundControl.settingsManager.firmwareUpgradeSettings
    property var defaultFirmwareFact: firmwareUpgradeSettings.defaultFirmwareType
    property bool defaultFirmwareIsPX4: true
    property bool initialBoardSearch: true
    property bool showFirmSelect: false
    property bool adv: false
    property bool px4Stable: ctrl.selectedFirmwareBuildType === FirmwareUpgradeController.StableFirmware
    property bool singleFirmwareMode: QGroundControl.corePlugin.options.firmwareUpgradeSingleURL.length != 0   ///< true: running in special single firmware download mode

    property string px4Version: adv && !px4Stable ? ctrl.px4BetaVersion : ctrl.px4StableVersion
    property string px4Firmware: "PX4 Pro " + px4Version
    property string apmFirmware: "ArduPilot"
    property bool selectApm: false
    property var singleTypeName: [
        qsTr("Standard Version (stable)"),
        qsTr("Custom firmware file...")]
    property var singltTypeValue:[
        FirmwareUpgradeController.StableFirmware,
        FirmwareUpgradeController.CustomFirmware]
    property var typeName: [
        qsTr("Standard Version (stable)"),
        qsTr("Beta Testing (beta)"),
        qsTr("Developer Build (master)"),
        qsTr("Custom firmware file...")]
    property var typeValue:[
        FirmwareUpgradeController.StableFirmware,
        FirmwareUpgradeController.BetaFirmware,
        FirmwareUpgradeController.DeveloperFirmware,
        FirmwareUpgradeController.CustomFirmware]
    property var fmType

    Component.onCompleted: {
        ctrl.startBoardSearch()
    }

    Flow{
        id: flow
        anchors.fill: contentArea
        anchors.margins: ui.margin
        spacing: ui.margin
        ProgressBar{
            id: bar
            width: parent.width
            height: ui.fontHeight
        }
        Rectangle{
            id: opt
            width: ui.fontWidth * 36
            height: parent.height - bar.height - ui.x2margin
            color: cc.none
            border.color: cc.border
            CCText{
                id: tipText
                width: parent.width
                height: contentHeight + ui.x2margin
                text: showFirmSelect ? qsTr("Detected") : qsTr("No board was detected")
                alignMid: true
                wrapMode: Text.WordWrap
                font.pointSize: ui.lFontSize
            }
            Column{
                width: parent.width - ui.x2margin
                anchors.top: tipText.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: ui.margin
                visible: showFirmSelect
                CCSwitchEditor{
                    id: advSwitch
                    width: parent.width
                    title: qsTr("Advanced Settings")
                    stateOn: false
                    onStateChanged: {
                        stateOn = !stateOn
                    }
                }
                CCButton{
                    width: parent.width
                    text: px4Firmware
                    selected: !selectApm
                    onClicked: selectApm = false
                }
                CCButton{
                    width: parent.width
                    text: apmFirmware
                    selected: selectApm
                    onClicked: selectApm = true
                }
                Column{
                    id: apmCol
                    width: parent.width
                    visible: selectApm
                    CCComboBoxEditor{
                        width: parent.width
                        title: qsTr("chi")
                        fact: firmwareUpgradeSettings.apmChibiOS
                    }
                    CCComboBoxEditor{
                        id: vtCombo
                        width: parent.width
                        title: qsTr("Vehicle Type")
                        fact: firmwareUpgradeSettings.apmVehicleType
                    }
                    CCComboBoxEditor{
                        id: fnCombo
                        width: parent.width
                        title: qsTr("Firmware Name")
                        model: ctrl.apmFirmwareNames
                        onModelChanged: currentIndex = ctrl.apmFirmwareNamesBestIndex
                    }
                }
                CCComboBoxEditor{
                    width: parent.width
                    title: qsTr("Version") + "   "
                    model: singleFirmwareMode ? singleTypeName : typeName
                    near: true
                    visible: advSwitch.stateOn
                    onUpdateResult:
                        (index)=>{
                            if(singleFirmwareMode){
                                fmType = singltTypeValue[index]
                            }else{
                                fmType = typeValue[index]
                            }
                        }
                }
                CCButton{
                    width: ui.fontWidth * 10
                    height: ui.fontHeight * 2
                    text: qsTr("Upgrade")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if(singleFirmwareMode){
                            ctrl.flashSingleFirmwareMode(ctrl.selectedFirmwareBuildType)
                        }else{
                            var vehicleType = FirmwareUpgradeController.DefaultVehicleFirmware
                            var stack = selectApm ? FirmwareUpgradeController.AutoPilotStackAPM : FirmwareUpgradeController.AutoPilotStackPX4
                            if(selectApm){
                                if(fmType === FirmwareUpgradeController.CustomFirmware){
                                    vehicleType = vtCombo.currentIndex
                                } else {
                                    if(ctrl.apmFirmwareNames.length === 0){
                                        // Not ready yet, or no firmware available
                                        //mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("Either firmware list is still downloading, or no firmware is available for current selection."))
                                        msg.title = qsTr("Either firmware list is still downloading, or no firmware is available for current selection.")
                                        return
                                    }
                                    if(fnCombo.currentIndex === -1){
                                        //mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("You must choose a board type."))
                                        msg.title = qsTr("You must choose a board type.")
                                        return
                                    }
                                    var firmwareUrl = ctrl.apmFirmwareUrls[fnCombo.currentIndex]
                                    if(firmwareUrl === ""){
                                        //mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("No firmware was found for the current selection."))
                                        msg.title = qsTr("No firmware was found for the current selection.")
                                        return
                                    }
                                    ctrl.flashFirmwareUrl(ctrl.apmFirmwareUrls[fnCombo.currentIndex])
                                    return
                                }
                            }
                            //-- If custom, get file path
                            if(fmType === FirmwareUpgradeController.CustomFirmware){
                                customFirmwareDialog.openForLoad()
                            }else{
                                ctrl.flash(stack, fmType, vehicleType)
                            }
                        }
                        showFirmSelect = false
                    }
                }
            }
        }
        Rectangle{
            width: parent.width - opt.width - ui.margin
            height: parent.height - bar.height - ui.x2margin
            color: cc.none
            border.color: cc.border
            CCFlickable{
                anchors.fill: parent
                anchors.margins: ui.margin
                fixedWidth: true
                CCMouseArea{
                    width: parent.width
                    height: children[0].height
                    FirmwareUpgradeController{
                        id: ctrl
                        progressBar: bar
                        statusLog: area

                        property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

                        onActiveVehicleChanged: {
                            if (!activeVehicle) {
                                area.append(plugInText)
                            }
                        }
                        onNoBoardFound: {
                            initialBoardSearch = false
                            if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) {
                                area.append(plugInText)
                            }
                        }
                        onBoardGone: {
                            initialBoardSearch = false
                            if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) {
                                area.append(plugInText)
                            }
                        }
                        onBoardFound: {
                            if (initialBoardSearch) {
                                // Board was found right away, so something is already plugged in before we've started upgrade
                                area.append(qgcUnplugText1)
                                area.append(qgcUnplugText2)

                                var availableDevices = ctrl.availableBoardsName()
                                if (availableDevices.length > 1) {
                                    area.append(highlightPrefix + qsTr("Multiple devices detected! Remove all detected devices to perform the firmware upgrade."))
                                    area.append(qsTr("Detected [%1]: ").arg(availableDevices.length) + availableDevices.join(", "))
                                }
                                if (activeVehicle) {
                                    QGroundControl.multiVehicleManager.activeVehicle.vehicleLinkManager.autoDisconnect = true
                                }
                            } else {
                                // We end up here when we detect a board plugged in after we've started upgrade
                                area.append(highlightPrefix + qsTr("Found device") + highlightSuffix + ": " + ctrl.boardType)
                            }
                        }

                        onShowFirmwareSelectDlg: showFirmSelect = true
                        onError: area.append(flashFailText)
                    }
                    Column{
                        width: parent.width
                        CCText{
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: qsTr("Status Log")
                            alignMid: true
                            font.pointSize: ui.lFontSize
                        }
                        TextArea{
                            id: area
                            width: parent.width
                            readOnly: true
                            textFormat: TextEdit.RichText
                            font.family: ui.fontFamily
                            color: cc.enabled
                        }
                    }
                }
            }
        }
    }
    CCConfirmDialog{
        id: msg
    }
}
