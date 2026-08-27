
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls

import Gises.Widget

CCMouseArea{
    id: root
    width: ui.fontWidth * 50
    height: head.height + col.height

    property Ui ui: Ui
    property string title: qsTr("Link Settings")
    property var linkManager: QGroundControl.linkManager
    property var autoConnect: QGroundControl.settingsManager.autoConnectSettings
    property var typeNames: [ qsTr("Pixhawk"), qsTr("SiK Radio"), qsTr("LibrePilot"), qsTr("UDP"), qsTr("RTK") ]
    property int autoCount: 0
    property bool showConfigPage: false
    property LinkConfiguration sourceConfig: null
    property LinkConfiguration editingConfig: null
    property int linkIndex: -1

    function reset(){
        showConfigPage = false
        typeLoader.sourceComponent = undefined
        if(editingConfig){
            linkManager.cancelConfigurationEditing(editingConfig)
        }
        sourceConfig = null
        editingConfig = null
    }
    function changeComponent(){
        if(editingConfig === null){
            typeLoader.sourceComponent = undefined
            return
        }
        switch(editingConfig.linkType){
        case LinkConfiguration.TypeSerial:
            typeLoader.sourceComponent = serial
            break;
        case LinkConfiguration.TypeUdp:
            typeLoader.sourceComponent = udp
            break;
        case LinkConfiguration.TypeTcp:
            typeLoader.sourceComponent = tcp
            break;
        case LinkConfiguration.TypeBluetooth:
            typeLoader.sourceComponent = blueTooth
            break;
        case LinkConfiguration.TypeMock:
            typeLoader.sourceComponent = mock
            break;
        case LinkConfiguration.TypeLogReplay:
            typeLoader.sourceComponent = logReplay
            break;
        default:
            break;
        }
    }

    function updateAutoCount(){
        autoCount = 0
        if(autoConnect.autoConnectPixhawk.userVisible){
            autoCount += 1
        }
        if(autoConnect.autoConnectSiKRadio.userVisible){
            autoCount += 1
        }
        if(autoConnect.autoConnectLibrePilot.userVisible){
            autoCount += 1
        }
        if(autoConnect.autoConnectUDP.userVisible){
            autoCount += 1
        }
        if(autoConnect.autoConnectRTKGPS.userVisible){
            autoCount += 1
        }
    }
    Component.onCompleted: {
        updateAutoCount()
    }
    CCText{
        id: head
        width: parent.width
        text: title
        alignMid: true
        font.pointSize: ui.llFontSize
    }
    Column{
        id: col
        width: parent.width
        anchors.top: head.bottom
        visible: !showConfigPage
        CCText{
            height: contentHeight + ui.x2margin
            text: qsTr("AutoConnect")
            font.pointSize: ui.lFontSize
        }
        Repeater{
            id: rep
            visible: autoConnect.userVisible
            model: [
                autoConnect.autoConnectPixhawk,
                autoConnect.autoConnectSiKRadio,
                autoConnect.autoConnectLibrePilot,
                autoConnect.autoConnectUDP,
                autoConnect.autoConnectRTKGPS,
            ]
            LabelSwitchButton{
                title: typeNames[index]
                stateOn: modelData.rawValue
                visible: modelData.userVisible
                onSwitched: {
                    modelData.rawValue ? modelData.rawValue = 0 : modelData.rawValue = 1
                }
            }
        }
        CCText{
            id: linksTitle
            height: contentHeight + ui.x2margin
            width: parent.width
            text: qsTr("Links")
            font.pointSize: ui.lFontSize
            CCButton{
                width: parent.height
                height: width
                icon.source: "/icon/add.svg"
                anchors.right: parent.right
                onClicked: {
                    showConfigPage = true
                    editingConfig = linkManager.createConfiguration(
                                ui.isSerialAvailable ? LinkConfiguration.TypeSerial :
                                                       LinkConfiguration.TypeUdp, "")
                    changeComponent()
                }
            }
        }
        Repeater{
            id: linklist
            model: linkManager.linkConfigurations
            CCMouseArea{
                id: link
                width: parent.width
                height: name.height
                CCText{
                    id: name
                    height: contentHeight + ui.x2margin
                    text: object.name
                }
                CCButton{
                    id: con
                    width: parent.height
                    height: width
                    checkable: true
                    checked: false//object.link
                    icon.source: "/icon/link_state.svg"
                    anchors.right: del.left
                    onClicked:{
                        // if(selected){
                        //     if(object.link){
                        //         object.link.disconnect()
                        //         object.linkChanged()
                        //     }else{
                        //         linkManager.createConnectedLink(object)
                        //     }
                        // }
                        // selected = !selected
                        if (object.link) {
                            object.link.disconnect()
                            object.linkChanged()
                            checked = false
                        } else {
                            linkManager.createConnectedLink(object)
                            checked = true
                        }
                    }
                }
                CCButton{
                    id: del
                    width: parent.height
                    height: width
                    icon.source: "/res/TrashDelete.svg"
                    anchors.right: parent.right
                    onClicked: {
                        linkManager.removeConfiguration(object)
                    }
                }
                onClicked: {
                    sourceConfig = object
                    editingConfig = linkManager.startConfigurationEditing(sourceConfig)
                    changeComponent()
                    showConfigPage = true
                }
            }
        }
    }
    Column{
        id: addLinkConfig
        width: parent.width
        anchors.top: head.bottom
        visible: showConfigPage
        LabelTextField{
            id: linkName
            title: qsTr("Link Name")
            text: editingConfig ? editingConfig.name : ""
            onValueChanged:
                (value)=>{
                    if(editingConfig){
                        editingConfig.name = value
                    }
                }
        }
        LabelSwitchButton{
            id: autoConnectOnStart
            title: qsTr("Automatically Connect on Start")
            stateOn: editingConfig ? editingConfig.autoConnect : false
            onSwitched: {
                if(editingConfig)
                    editingConfig.autoConnect ? editingConfig.autoConnect = 0 : editingConfig.autoConnect = 1
            }
        }
        LabelSwitchButton{
            id: heightLatency
            title: qsTr("Height Latency")
            stateOn: editingConfig ? editingConfig.highLatency : false
            onSwitched: {
                if(editingConfig)
                    editingConfig.highLatency ? editingConfig.highLatency = 0 : editingConfig.highLatency = 1
            }
        }
        LabelComboBox{
            id: type
            title: qsTr("Type")
            model: linkManager.linkTypeStrings
            currentIndex: editingConfig ? editingConfig.linkType : 0
            onUpdateResult:
                (index)=>{
                    if(editingConfig && index !== editingConfig.linkType){
                        typeLoader.sourceComponent = undefined
                        linkManager.cancelConfigurationEditing(editingConfig)
                        var name = "new link"
                        if(sourceConfig){
                            name = sourceConfig.name
                        }
                        editingConfig =  linkManager.createConfiguration(index, name)
                        changeComponent()
                    }
                }
        }
        Loader{
            id: typeLoader
            width: parent.width
        }
        Item{
            id: saveOrCancel
            width: parent.width
            height: ui.fontHeight * 2 + ui.x2margin
            CCButton{
                id: save
                width: ui.fontWidth * 8
                height: ui.fontHeight * 2
                text: qsTr("Save")
                anchors.right: cancel.left
                anchors.rightMargin: ui.margin
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if(editingConfig.name.length <= 0){
                        return
                    }
                    if(typeLoader.sourceComponent === mock){
                        typeLoader.item.saveSettings()
                    }
                    typeLoader.sourceComponent = undefined
                    if(sourceConfig){
                        linkManager.endConfigurationEditing(sourceConfig, editingConfig)
                    }else{
                        editingConfig.dynamic = false
                        linkManager.endCreateConfiguration(editingConfig)
                    }
                    editingConfig = null
                    sourceConfig = null
                    showConfigPage = false
                }
            }
            CCButton{
                id: cancel
                width: ui.fontWidth * 8
                height: ui.fontHeight * 2
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Cancel")
                onClicked: {
                    typeLoader.sourceComponent = undefined
                    linkManager.cancelConfigurationEditing(editingConfig)
                    sourceConfig = null
                    editingConfig = null
                    showConfigPage = false
                }
            }
        }
    }

    Component{
        id: serial
        Column{
            LabelComboBox{
                title: qsTr("Serial Port")
                model: linkManager.serialPortStrings
                currentIndex: 0//editingConfig.linkType
                onUpdateResult:
                    (index)=>{
                        editingConfig.portName = linkManager.serialPorts[index]
                    }
            }
            LabelComboBox{
                title: qsTr("Baud Rate")
                model: linkManager.serialBaudRates
                currentIndex: 0
                onUpdateResult:
                    (index)=>{
                        editingConfig.baud = parseInt(linkManager.serialBaudRates[index])
                    }
            }
            LabelSwitchButton{
                id: advance
                title: qsTr("Advanced Settings")
                stateOn: false
                onSwitched: {
                    stateOn = !stateOn
                }
            }
            LabelComboBox{
                title: qsTr("Party")
                model: [qsTr("None"), qsTr("Even"), qsTr("Odd")]
                currentIndex: editingConfig.parity === 0 ? editingConfig.parity : editingConfig.parity-1
                visible: advance.stateOn
                onUpdateResult:
                    (index)=>{
                        if(0 === index){
                            editingConfig.parity = 0
                        }else{
                            editingConfig.parity = index+1
                        }
                    }
            }
            LabelComboBox{
                title: qsTr("Data Bits")
                model: ["5", "6", "7", "8"]
                currentIndex: editingConfig.dataBits - 5 > 3 ? 3 : editingConfig.dataBits - 5 < 0 ? 0 : editingConfig.dataBits - 5
                visible: advance.stateOn
                onUpdateResult:
                    (index)=>{
                        editingConfig.dataBits = index+5
                    }
            }
            LabelComboBox{
                title: qsTr("Stop Bits")
                model: ["1", "2"]
                currentIndex: editingConfig.stopBits-1 > 1 ? 1 : editingConfig.stopBits-1 < 0 ? 0 : editingConfig.stopBits-1
                visible: advance.stateOn
                onUpdateResult:
                    (index)=>{
                        editingConfig.stopBits = index + 1
                    }
            }
        }
    }
    Component{
        id: udp
        Column{
            LabelTextField{
                title: qsTr("Port")
                text: editingConfig.localPort.toString()
                onlyNumber: true
                onValueChanged:
                    (value)=>{
                        editingConfig.localPort = value
                    }
            }
            CCText{
                text: qsTr("Server Address(optional)")
            }
            Repeater{
                model: editingConfig.hostList
                CCText{
                    height: remove.height + ui.x2margin
                    width: parent.width
                    text: modelData
                    CCButton{
                        id: remove
                        width: ui.fontWidth * 8
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Remove")
                        onClicked: {
                            editingConfig.removeHost(modelData)
                        }
                    }
                }
            }
            Item{
                width: parent.width
                height: hostInput.height + ui.x2margin
                CCTextField{
                    id: hostInput
                    width: ui.fontWidth * 20
                    radius: ui.radius
                    placeholderText: qsTr("Example:127.0.0.1:14550")
                    placeholderTextColor: clcfg.disabled
                    anchors.verticalCenter: parent.verticalCenter
                }
                CCButton{
                    width: ui.fontWidth * 12
                    text: qsTr("Add Server")
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        editingConfig.addHost(hostInput.text)
                    }
                }
            }
            CCSeparator{
                width: parent.width
            }
        }
    }
    Component{
        id: tcp
        Column{
            LabelTextField{
                title: qsTr("Server Address")
                text: editingConfig.host
                onValueChanged:
                    (value)=>{
                        editingConfig.host = value
                    }
            }
            LabelTextField{
                title: qsTr("Port")
                text: editingConfig.port
                onlyNumber: true
                onValueChanged:
                    (value)=>{
                        editingConfig.port = value
                    }
            }
        }
    }
    Component{
        id: blueTooth
        Column{
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("Device:") + editingConfig.devName
            }
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("Address:") + editingConfig.address
            }
            Item{
                width: parent.width
                height: allDevices.height
                CCText{
                    id: allDevices
                    height: contentHeight + ui.x2margin
                    text: qsTr("Bluetooth Devices:")
                }
                CCButton{
                    text: qsTr("Scan")
                    enabled: !editingConfig.scanning
                    anchors.right: stopScan.left
                    anchors.rightMargin: ui.x2margin
                    anchors.verticalCenter: allDevices.verticalCenter
                    onClicked: {
                        editingConfig.startScan()
                    }
                }
                CCButton{
                    id: stopScan
                    text: qsTr("Stop")
                    enabled: editingConfig.scanning
                    anchors.right: parent.right
                    anchors.verticalCenter: allDevices.verticalCenter
                    onClicked: {
                        editingConfig.stopScan()
                    }
                }
            }
            Item{
                width: parent.width * 0.7
                height: (deviceRep.count > 5 ? 5.5 : deviceRep.count) * allDevices.height
                CCFlickable{
                    anchors.fill: parent
                    anchors.margins: ui.margin
                    fixedWidth: true
                    Column{
                        width: parent.width
                        Repeater{
                            id: deviceRep
                            model: editingConfig.nameList
                            CCButton{
                                width: parent.width
                                text: modelData
                                //border.color: index === linkIndex ? clcfg.selected : clcfg.border
                                enabled: !editingConfig.scanning
                                onClicked: {
                                    if(linkIndex !== index && modelData.length){
                                        editingConfig.devName = modelData
                                        linkIndex = index
                                    }
                                }
                            }
                        }
                    }
                }
            }

            CCSeparator{
                width: parent.width
            }
        }
    }
    Component{
        id: mock
        Column{
            readonly property int _MAV_AUTOPILOT_GENERIC:       0
            readonly property int _MAV_AUTOPILOT_PX4:           12
            readonly property int _MAV_AUTOPILOT_ARDUPILOTMEGA: 3
            readonly property int _MAV_TYPE_FIXED_WING:         1
            readonly property int _MAV_TYPE_QUADROTOR:          2

            function saveSettings() {
                switch (firmware.currentIndex) {
                case 0:
                    editingConfig.firmware = _MAV_AUTOPILOT_PX4
                    break
                case 1:
                    editingConfig.firmware = _MAV_AUTOPILOT_ARDUPILOTMEGA
                    if (vehicle.currentIndex === 1) {          // Hardcoded _MAV_TYPE_FIXED_WING
                        editingConfig.vehicle = _MAV_TYPE_FIXED_WING
                    } else {
                        editingConfig.vehicle = _MAV_TYPE_QUADROTOR
                    }
                    break
                default:
                    editingConfig.firmware = _MAV_AUTOPILOT_GENERIC
                    break
                }
            }

            Component.onCompleted: {
                switch (editingConfig.firmware) {
                case _MAV_AUTOPILOT_PX4:
                    firmware.currentIndex = 0
                    break
                case _MAV_AUTOPILOT_ARDUPILOTMEGA:
                    firmware.currentIndex = 1
                    break
                default:
                    firmware.currentIndex = 2
                    break
                }
                if (editingConfig.vehicle === _MAV_TYPE_FIXED_WING) {          // Hardcoded _MAV_TYPE_FIXED_WING
                    vehicle.currentIndex = 1
                } else {
                    vehicle.currentIndex = 0
                }
            }
            LabelSwitchButton{
                id: sendStatus
                title: qsTr("Send Status Text And Voice")
                stateOn: editingConfig.sendStatus
                onSwitched: {
                    if(editingConfig)
                        editingConfig.sendStatus ? editingConfig.sendStatus = 0 : editingConfig.sendStatus = 1
                }
            }
            LabelSwitchButton{
                id: incrementId
                title: qsTr("Increment Vehicle ID")
                stateOn: editingConfig.incrementVehicleId
                onSwitched: {
                    if(editingConfig)
                        editingConfig.incrementVehicleId ? editingConfig.incrementVehicleId = 0 : editingConfig.incrementVehicleId = 1
                }
            }
            LabelComboBox{
                id: firmware
                title: qsTr("Firmware")
                model: [ qsTr("PX4 Pro"), qsTr("ArduPilot"), qsTr("Generic MAVLink") ]
            }
            LabelComboBox{
                id: vehicle
                title: qsTr("Vehicle Type")
                model: [ qsTr("ArduCopter"), qsTr("ArduPlane") ]
                visible: firmware.currentIndex === 1
            }
        }
    }
    Component{
        id: logReplay
        Item{
            height: file.height
            LabelTextField{
                id: file
                width: parent.width - dlgBtn.width - ui.margin
                title: qsTr("Log File:")
                text: editingConfig.fileName
            }
            CCButton{
                id: dlgBtn
                width: ui.fontWidth * 8
                text: qsTr("Browse")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    logDlg.open()
                }
            }
            CCSeparator{
                width: parent.width
                anchors.bottom: parent.bottom
            }
            FileDialog{
                id: logDlg

                property string logFileExtension: QGroundControl.settingsManager.appSettings.telemetryFileExtension

                title: qsTr("Select Telemetery Log")
                nameFilters: [ qsTr("Telemetry Logs (*.%1)").arg(logFileExtension), qsTr("All Files (*)") ]
                currentFolder: "file:///" + QGroundControl.settingsManager.appSettings.telemetrySavePath
                onAccepted: {
                    if (fileMode == FileDialog.OpenFile) {
                        console.log("select file:",selectedFile)
                    } else {
                    }
                    close()
                }
            }
        }
    }
}
