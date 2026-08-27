
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Flight Mode")

    property var switchNameList: [ "RC_MAP_ARM_SW", "RC_MAP_GEAR_SW", "RC_MAP_KILL_SW", "RC_MAP_LOITER_SW", "RC_MAP_OFFB_SW", "RC_MAP_RETURN_SW" ]
    property var switchTHList: [ "RC_ARMSWITCH_TH", "RC_GEAR_TH", "RC_KILLSWITCH_TH", "RC_LOITER_TH", "RC_OFFB_TH", "RC_RETURN_TH" ]
    readonly property int rcPwmMin: 800
    readonly property int rcPwmMax: 2200
    readonly property int rcPwmRange: rcPwmMax - rcPwmMin

    Component.onCompleted: {
        if (vehicle.vtol) {
            switchNameList.push("RC_MAP_TRANS_SW")
            switchTHList.push("RC_TRANS_TH")
        }
        if (vehicle.fixedWing) {
            switchNameList.push("RC_MAP_FLAPS")
            switchTHList.push("")
        }
        switchRep.model = switchNameList
    }
    PX4SimpleFlightModesController {
        id: ctrl
    }
    RCChannelMonitorController {
        id: rcCtrl
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
                    width: ui.fontWidth * 32
                    height: modeHead.height + modeChannel.height + modeCol.height
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    CCText{
                        id: modeHead
                        height: contentHeight + ui.x2margin
                        text: qsTr("Flight Mode Settings")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    CCComboBoxEditor{
                        id: modeChannel
                        x: ui.margin
                        width: parent.width - ui.x2margin
                        title: qsTr("Mode Channel")
                        fact: ctrl.getParameterFact(-1, "RC_MAP_FLTMODE")
                        anchors.top: modeHead.bottom
                    }
                    Column{
                        id: modeCol
                        x: ui.margin
                        width: parent.width - ui.x2margin
                        anchors.top: modeChannel.bottom
                        Repeater{
                            id: modeRep
                            model: 6
                            CCComboBoxEditor{
                                width: parent.width
                                title: qsTr("Flight Mode %1").arg(modelData + 1)
                                fact: ctrl.getParameterFact(-1, "COM_FLTMODE" + (modelData + 1))
                            }
                        }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 48
                    height: switchHead.height + switchCol.height + rcCol.height + ui.margin
                    radius: ui.radius
                    color: cc.none
                    border.color: cc.border
                    CCText{
                        id: switchHead
                        height: contentHeight + ui.x2margin
                        text: qsTr("Switch Settings")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Column{
                        id: switchCol
                        x: ui.margin
                        width: parent.width - ui.x2margin
                        anchors.top: switchHead.bottom
                        Repeater{
                            id: switchRep
                            CCComboBoxEditor{
                                width: parent.width
                                title: swFact.shortDescription
                                fact: swFact
                                property string thFactName: switchTHList[index]
                                property Fact swFact: ctrl.getParameterFact(-1, modelData)
                                property bool thFactExists: thFactName !== ""
                                property Fact thFact: thFactExists ? ctrl.getParameterFact(-1, thFactName) : null
                                property real thValue: thFactExists ? thFact.rawValue : 0.5
                                property real thPWM: 1000 + (1000 * thValue)
                                property int swChannel: swFact.rawValue - 1
                                property bool swActive: swChannel < 0 ? false :
                                                        (thValue >= 0 ? (ctrl.rcChannelValues[swChannel] > thPWM) :
                                                                        (ctrl.rcChannelValues[swChannel] <= thPWM))
                            }
                        }
                    }
                    Column{
                        id: rcCol
                        x: ui.margin
                        width: parent.width - ui.x2margin
                        anchors.top: switchCol.bottom
                        CCText{
                            id: rcHead
                            height: contentHeight + ui.x2margin
                            text: qsTr("Channel Monitor")
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Grid{
                            id: grid
                            columns: 2
                            spacing: ui.margin
                            Repeater{
                                model: rcCtrl.channelCount
                                CCText{
                                    id: rcText
                                    width: ui.width * 23
                                    text: (modelData + 1)
                                    Item{
                                        width: ui.width * 20
                                        height: ui.fontHeight
                                        anchors.right: parent.right
                                        property int rcValue: 1500//index ? 700 + index*100 : 800
                                        property int lastValue: 1500
                                        Rectangle{
                                            width: ui.width * 20 - ind.width
                                            height: ui.fontHeight / 2
                                            color: cc.dark
                                            anchors.centerIn: parent
                                            Rectangle{
                                                width: ui.margin
                                                height: parent.height
                                                color: cc.normalBg
                                                anchors.centerIn: parent
                                            }
                                        }
                                        Rectangle{
                                            id: ind
                                            width: ui.fontHeight
                                            height: width
                                            radius: width / 2
                                            x: ((parent.rcValue - rcPwmMin) / rcPwmRange) * (parent.width - width)
                                        }
                                        CCText{
                                            text: qsTr("Not Mapped")
                                            font.pointSize: ui.sFontSize
                                            visible: !ind.visible
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
