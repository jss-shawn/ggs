
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Vehicle
import QGroundControl.FactSystem
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Flight Mode")

    readonly property var pwmStrings: [ "PWM 0 - 1230", "PWM 1231 - 1360", "PWM 1361 - 1490",
                                        "PWM 1491 - 1620", "PWM 1621 - 1749", "PWM 1750+"]
    property Fact nullFact
    property Fact fltmodeCh: ctrl.modeChannelParam ? ctrl.getParameterFact(-1, ctrl.modeChannelParam) :
                                                     nullFact
    property bool ch7OptAvailable: ctrl.parameterExists(-1, "CH7_OPT")
    property int rcOptionStart: ch7OptAvailable ? 7 : 6
    property int rcOptionStop: ch7OptAvailable ? 12 : 16

    APMFlightModesComponentController{ id: ctrl }

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
                    width: stcol.width
                    height: stcol.height + settings.height + channel.height + simple.height
                    color: cc.none
                    border.color: cc.border
                    CCText{
                        id: settings
                        width: parent.width
                        height: contentHeight + ui.x2margin
                        text: qsTr("Fligth Mode Settings")
                        alignMid: true
                        font.pointSize: ui.lFontSize
                    }
                    CCComboBoxEditor{
                        id: channel
                        width: ui.fontWidth * 36
                        title: qsTr("Flight mode channel")
                        fact: fltmodeCh
                        anchors.left: parent.left
                        anchors.leftMargin: ui.margin
                        anchors.top: settings.bottom
                    }
                    Column{
                        id: stcol
                        width: ui.fontWidth * 48
                        anchors.left: channel.left
                        anchors.top: channel.bottom
                        Repeater{
                            model: 6
                            Row{
                                id: row
                                height: mode.height
                                spacing: ui.margin
                                property int idx: index
                                CCComboBoxEditor{
                                    id: mode
                                    width: ui.fontWidth * 24
                                    title: qsTr("Flight mode ") + (row.idx+1)
                                    fact: ctrl.getParameterFact(-1, ctrl.modeParamPrefix + (row.idx+1))
                                }
                                CCText{
                                    id:pwm
                                    width: ui.fontWidth * 12
                                    height: mode.height
                                    text: pwmStrings[row.idx]
                                }
                            }
                        }
                    }
                    CCComboBoxEditor{
                        id: simple
                        width: ui.fontWidth * 22
                        title: qsTr("Simple Mode")
                        model: ctrl.simpleModeNames
                        currentIndex: ctrl.simpleMode
                        anchors.left: channel.left
                        anchors.top: stcol.bottom
                        onUpdateResult:
                            (index)=>{
                                ctrl.simpleMode = index
                            }
                    }
                }
                Rectangle{
                    width: ui.fontWidth * 36
                    height: swt.height + opcol.height
                    color: cc.none
                    border.color: cc.border
                    CCText{
                        id: swt
                        width: parent.width
                        height: contentHeight + ui.x2margin
                        text: qsTr("Switch Options")
                        alignMid: true
                        font.pointSize: ui.lFontSize
                    }
                    Column{
                        id: opcol
                        width: parent.width - ui.x2margin
                        spacing: ui.margin
                        anchors.left: parent.left
                        anchors.leftMargin: ui.margin
                        anchors.top: swt.bottom
                        Repeater{
                            model: (rcOptionStop-rcOptionStart+1)
                            CCComboBoxEditor{
                                title: qsTr("Channel option ") + (index+rcOptionStart)
                                fact: ctrl.getParameterFact(-1, "r.RC"+(index+rcOptionStart)+"_OPTION")
                            }
                        }
                    }
                }
            }
        }
    }
}
