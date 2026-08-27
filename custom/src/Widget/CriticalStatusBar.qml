
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Window
import QtQuick.Shapes

import QGroundControl
import QGroundControl.Controls

CCMouseArea{
    id: root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property int panelIndex: 0
    property var panelList: ["",
                            "/qml/Gises/Widget/MessageInfo.qml",
                            "/qml/Gises/Widget/ForwardInfo.qml",
                            "/qml/Gises/Widget/RemoteIDInfo.qml",
                            "/qml/Gises/Widget/GimbalInfo.qml",
                            "/qml/Gises/Widget/LinkInfo.qml",
                            "/qml/Gises/Widget/BatteryInfo.qml",
                            "/qml/Gises/Widget/TelemeteryRSSIInfo.qml",
                            "/qml/Gises/Widget/GpsInfo.qml",
                            "/qml/Gises/Widget/RCInfo.qml"]

    property Vehicle vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool lost: vehicle && vehicle.vehicleLinkManager.communicationLost
    property bool healthSupported: vehicle && vehicle.healthAndArmingCheckReport.supported

    readonly property string commLostText: qsTr("Communication Lost")
    readonly property string readyToFlyText: qsTr("Ready To Fly")
    readonly property string notReadyToFlyText: qsTr("Not Ready")
    readonly property string disconnectedText: qsTr("Disconnected")
    readonly property string armedText: qsTr("Armed")
    readonly property string flyingText: qsTr("Flying")
    readonly property string landingText: qsTr("Landing")

    // onDoubleClicked: {
    //     if(mainWindow.visibility === Window.Windowed){
    //         mainWindow.showFullScreen()
    //     }
    //     else if(mainWindow.visibility === Window.FullScreen){
    //         mainWindow.showNormal()
    //     }
    // }

    function linkStatusText() {
        if (vehicle) {
            if (lost) {
                linkStatus.color = cc.error
                return commLostText
            }
            if (vehicle.armed) {
                linkStatus.color = cc.good
                if (healthSupported) {
                    if (vehicle.healthAndArmingCheckReport.canArm) {
                        if (vehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                            linkStatus.color = cc.warnning
                        }
                    } else {
                        linkStatus.color = cc.error
                    }
                }
                if (vehicle.flying) {
                    return flyingText
                } else if (vehicle.landing) {
                    return landingText
                } else {
                    return armedText
                }
            } else {
                if (healthSupported) {
                    if (vehicle.healthAndArmingCheckReport.canArm) {
                        if (vehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                            linkStatus.color = cc.warnning
                        } else {
                            linkStatus.color = cc.good
                        }
                        return readyToFlyText
                    } else {
                        linkStatus.color = cc.error
                        return notReadyToFlyText
                    }
                } else if (vehicle.readyToFlyAvailable) {
                    if (vehicle.readyToFly) {
                        linkStatus.color = cc.good
                        return readyToFlyText
                    } else {
                        linkStatus.color = cc.warnning
                        return notReadyToFlyText
                    }
                } else {
                    if (vehicle.allSensorsHealthy
                            && vehicle.autopilot.setupComplete) {
                        linkStatus.color = cc.good
                        return readyToFlyText
                    } else {
                        linkStatus.color = cc.warnning
                        return notReadyToFlyText
                    }
                }
            }
        } else {
            linkStatus.color = cc.border
            return disconnectedText
        }
    }

    // DragHandler {
    //     target: null
    //     dragThreshold: 0
    //     cursorShape: Qt.SizeAllCursor
    //     grabPermissions: TapHandler.CanTakeOverFromAnything
    //     enabled: mainWindow.visibility === Window.Windowed
    //     onActiveChanged: {
    //         if(active){
    //             if(!mainWindow.startSystemMove()){
    //             }
    //         }
    //     }
    // }

    Rectangle{
        anchors.fill: parent
        color: cc.dark
    }

    Row{
        id: leftStatus
        height: parent.height
        CCButton{
            id: messageStatus
            width: parent.height
            height: width
            checked: 1 === panelIndex
            icon.source: "/icon/message.svg"
            onClicked: {
                if (1 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 1
                }
            }
        }
        CCButton{
            id: forwardStatus
            width: parent.height
            height: width
            checked: 2 === panelIndex
            icon.source: "/icon/forward.svg"
            onClicked: {
                if (2 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 2
                }
            }
        }
        CCButton{
            id: remoteIDStatus
            width: parent.height
            height: width
            checked: 3 === panelIndex
            icon.source: "/icon/rid.svg"
            onClicked: {
                if (3 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 3
                }
            }
        }
        CCButton{
            id: gimbalStatus
            width: parent.height
            height: width
            checked: 4 === panelIndex
            icon.source: "/icon/gimbal.svg"
            onClicked: {
                if (4 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 4
                }
            }
        }
    }

    CCMouseArea{
        id: linkStatus
        width: ui.fontWidth * 24
        height: parent.height
        anchors.centerIn: parent
        property string status: linkStatusText()
        property color color: cc.none
        Column{
            width: parent.width
            anchors.centerIn: parent
            CCText {
                id: vehicleStatus
                width: parent.width
                text: vehicle ? (qsTr("Vehicle: ") + vehicle.id) : linkStatus.status
                color: linkStatus.color
                alignMid: true
                font.pointSize: ui.lFontSize
                visible: vehicle
            }
            CCText {
                width: parent.width
                text: linkStatus.status
                color: linkStatus.color
                alignMid: true
                font.pointSize: ui.lFontSize
            }
        }
        onClicked: {
            if (5 === panelIndex) {
                panelIndex = 0
            } else {
                panelIndex = 5
            }
        }
        Rectangle{
            anchors.fill: parent
            color: cc.none
            border.color: cc.pressed
        }
    }

    Row{
        id: rightStatus
        height: parent.height
        anchors.right: parent.right
        CCButton{
            id: batteryStatus
            width: parent.height
            height: width
            checked: 6 === panelIndex
            icon.source: "/icon/battery.svg"
            onClicked: {
                if (6 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 6
                }
            }
        }
        CCButton{
            id: telemetryRSSIStatus
            width: parent.height
            height: width
            checked: 7 === panelIndex
            icon.source: "/icon/telemetry.svg"
            onClicked: {
                if (7 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 7
                }
            }
        }
        CCButton{
            id: gpsStatus
            width: parent.height
            height: width
            checked: 8 === panelIndex
            icon.source: "/icon/gps.svg"
            onClicked: {
                if (8 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 8
                }
            }
        }
        CCButton{
            id: rcStatus
            width: parent.height
            height: width
            checked: 9 === panelIndex
            icon.source: "/icon/rc.svg"
            onClicked: {
                if (9 === panelIndex) {
                    panelIndex = 0
                } else {
                    panelIndex = 9
                }
            }
        }
    }

    CCSeparator{
        width: parent.width
        anchors.bottom: parent.bottom
    }

    MouseArea{
        width: mainWindow.width
        height: mainWindow.height - parent.height
        anchors.top: parent.bottom
        visible: panelIndex
        onClicked: {
            panelIndex = 0
        }
    }

    Loader{
        id: panelLoader
        anchors.top: parent.bottom
        source: panelList[panelIndex]
        onLoaded: {
            x = 0
            if (5 === panelIndex) {
                x = (root.width - item.width) * 0.5
            } else if(panelIndex > 5){
                x = root.width - item.width
            }
        }
    }
}