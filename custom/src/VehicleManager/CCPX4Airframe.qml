
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controllers

import gises.base
import gises.widget

CCVehicleSetupContainer{
    id: root

    titleText: qsTr("Vehicle Airframe")

    property string curType: ctrl.currentAirframeType
    property string curVersion: ctrl.currentVehicleName
    property string curSource: ""
    property string newType: " "
    property string newVersion: " "
    property string newSource: ""
    property bool diff: newType !== " " && (newType !== curType || newVersion !== curVersion)
    property int typeIndex: -1
    property int versionIndex: 0

    AirframeComponentController {
        id: ctrl
    }
    Rectangle{
        id: curSetup
        width: curImg.width + curCol.width + ui.margin * 3
        height: newSetup.height
        color: cc.none
        border.color: cc.border
        anchors.top: contentArea.top
        anchors.topMargin: ui.margin
        Image{
            id: curImg
            x: ui.margin
            y: ui.margin
            width: newImg.height
            height: width
            source: curSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
        Column{
            id: curCol
            anchors.left: curImg.right
            anchors.leftMargin: ui.margin
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("Current Frame Type:\n") + curType
            }
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("Current Frame Version:\n") + curVersion
            }
        }
    }
    Rectangle{
        id: newSetup
        width: newImg.width + newCol.width + ui.margin * 3
        height: newCol.height + ui.x2margin
        color: cc.none
        border.color: cc.border
        anchors.left: curSetup.right
        anchors.top: contentArea.top
        anchors.margins: ui.margin
        Image{
            id: newImg
            x: ui.margin
            y: ui.margin
            width: newCol.height
            height: width
            source: newSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
        Column{
            id: newCol
            anchors.left: newImg.right
            anchors.leftMargin: ui.margin
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("New Frame Type:\n") + newType
                color: newType !== " " && newType !== curType ? cc.warnning : cc.enabled
            }
            CCText{
                height: contentHeight + ui.x2margin
                text: qsTr("New Frame Version:\n") + newVersion
                color: newVersion !== " " && newVersion !== curVersion ? cc.warnning : cc.enabled
            }
            CCButton{
                id: resBtn
                width: ui.fontWidth * 18
                text: qsTr("Apply and Restart")
                enabled: diff
                onClicked: {
                    dlg.visible = true
                }
            }
        }
    }
    Item{
        id: typeArea
        width: ui.fontWidth * 18
        anchors.top: curSetup.bottom
        anchors.bottom: contentArea.bottom
        anchors.margins: ui.margin
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    spacing: ui.margin
                    Repeater{
                        model: ctrl.airframeTypes
                        CCMouseArea{
                            width: parent.width
                            height: width + type.height
                            Component.onCompleted: {
                                if(modelData.name === ctrl.currentAirframeType){
                                    typeIndex = index
                                    curSource = ctrl.airframeTypes[index].imageResource
                                }
                            }
                            onClicked: {
                                typeIndex = index
                                versionIndex = 0
                                newType = modelData.name
                                newSource = modelData.imageResource
                                newVersion = ctrl.airframeTypes[index].airframes[0].text
                                ctrl.autostartId = modelData.airframes[0].autostartId
                            }
                            CCText{
                                id: type
                                height: contentHeight + ui.x2margin
                                text: modelData.name
                            }
                            Rectangle{
                                width: parent.width
                                height: width
                                color: cc.dark
                                anchors.bottom: parent.bottom
                                Image {
                                    id: image
                                    anchors.fill: parent
                                    source: modelData.imageResource
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                                Rectangle{
                                    anchors.fill: parent
                                    color: cc.none
                                    border.color: typeIndex === index ? cc.selected : cc.dark
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item{
        id: versionArea
        width: parent.width - typeArea.width
        anchors.top: curSetup.bottom
        anchors.bottom: contentArea.bottom
        anchors.right: contentArea.right
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    Repeater{
                        id: rep
                        model: typeIndex === -1 ? 0 : ctrl.airframeTypes[typeIndex].airframes
                        Rectangle{
                            width: parent.width
                            height: ver.height
                            color: index % 2 ? cc.dark : cc.none
                            CCText{
                                id: ver
                                x: ui.margin
                                height: contentHeight + ui.x2margin
                                text: modelData.text
                                color: versionIndex === index ? cc.selected : cc.enabled
                            }
                            CCMouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    versionIndex = index
                                    newType = ctrl.airframeTypes[typeIndex].name
                                    newSource = ctrl.airframeTypes[typeIndex].imageResource
                                    newVersion = modelData.text
                                }
                            }
                        }
                    }
                    Rectangle{
                        width: parent.width
                        height: ui.fontHeight + ui.x2margin
                        color: cc.dark
                        visible: rep.count % 2
                    }
                }
            }
        }
    }

    Rectangle{
        id: dlg
        width: parent.width / 2
        height: parent.height / 2
        radius: ui.radius
        color: cc.normalBg
        border.color: cc.border
        anchors.centerIn: parent
        visible: false
        CCText{
            width: parent.width
            height: contentHeight + ui.x2margin
            text: qsTr("Change Airframe")
            font.pointSize: ui.llFontSize
            alignMid: true
        }
        CCText{
            width: parent.width - ui.x2margin
            text: qsTr("Clicking 'Apply' will save the changes you have made to your airframe configuration.") +
                qsTr("All vehicle parameters other than Radio Calibration will be reset.") +
                qsTr("Your vehicle will also be restarted in order to complete the process.")
            alignMid: true
            wrapMode: Text.WordWrap
            anchors.centerIn: parent
        }
        Row{
            height: ui.fontHeight * 2
            spacing: height
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ui.margin
            anchors.horizontalCenter: parent.horizontalCenter
            CCButton{
                width: ui.fontWidth * 8
                height: ui.fontHeight * 2
                text: qsTr("Apply")
                onClicked: { dlg.visible = false; ctrl.changeAutostart() }
            }
            CCButton{
                width: ui.fontWidth * 8
                height: ui.fontHeight * 2
                text: qsTr("Cancel")
                onClicked: { dlg.visible = false }
            }
        }
    }
}
