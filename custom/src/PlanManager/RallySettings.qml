
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property RallyManager rally: gises.rallyManager

    Component.onCompleted: {
        showPlanView = true
        gises.currentManager = rally
    }

    Component.onDestruction: {
        gises.currentManager = null
    }

    Rectangle{
        anchors.fill: parent
        color: cc.normalBg
    }
    CCText{
        id: head
        width: parent.width
        height: contentHeight + ui.x2margin
        text: qsTr("Rally Points")
        alignMid: true
        font.pointSize: ui.llFontSize
    }
    Item{
        width: parent.width
        height: parent.height - head.height - btns.height
        anchors.top: head.bottom
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
                        model: rally.points
                        Row{
                            width: parent.width
                            height: lat.height
                            spacing: ui.margin
                            CCText{
                                width: ui.fontWidth * 4
                                height: contentHeight + ui.x2margin
                                text: qsTr(" P") + modelData.index
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle{
                                    anchors.fill: parent
                                    color: cc.none
                                    border.color: cc.selected
                                    visible: modelData === rally.current
                                }
                                CCMouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        rally.current = modelData
                                    }
                                }
                            }
                            LabelTextField {
                                id: lat
                                width: ui.fontWidth * 16
                                title: qsTr("lat")
                                text: modelData.coord.latitude.toFixed(7)
                                near: true
                            }
                            LabelTextField {
                                width: ui.fontWidth * 16
                                title: qsTr("lon")
                                text: modelData.coord.longitude.toFixed(7)
                                near: true
                            }
                            CCButton{
                                width: parent.height
                                height: width
                                icon.source: "/icon/remove.svg"
                                color:cc.none
                                onClicked: {
                                    rally.removePoint(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Row{
        id: btns
        width: height * 3
        height: ui.fontWidth * 4
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: height
        CCButton{
            width: parent.height
            height: width
            icon.source: "/icon/trash.svg"
            color:cc.none
            onClicked: {
                rally.clear()
            }
        }
        CCButton{
            width: parent.height
            height: width
            icon.source: "/icon/upload.svg"
            color:cc.none
            onClicked: {
                gises.sendToVehicle()
            }
        }
    }
}
