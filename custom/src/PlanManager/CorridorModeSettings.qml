
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property CorridorRoute cRoute: gcsManager.planManager.route
    property CorridorArea curArea: cRoute.surverArea
    property GeoCorridor corridor: curArea.gCorridor
    property SurveySetup setup: curArea.setup
    property bool activeArea: curArea.active
    property int panelMode: 0

    Rectangle{
        anchors.fill: parent
        color: cc.normalBg
    }
    Column{
        id: col
        width: parent.width - ui.margin * 2
        anchors.horizontalCenter: parent.horizontalCenter
        CCText{
            id: head
            width: parent.width
            height: contentHeight + ui.x2margin
            text: qsTr("Corridor Route")
            alignMid: true
            font.pointSize: ui.llFontSize
        }
        Item{
            width: parent.width
            height: ui.fontHeight * 2 + ui.x2margin
            CCText{
                width: root.width - ui.fontWidth * 30
                height: parent.height
                text: "New Surver Area"
            }
            CCButton{
                width: ui.fontWidth * 16
                text: "Add Corridor Area"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    cRoute.addArea([])
                    panelMode = 0
                }
            }
        }
        Item{
            width: parent.width
            height: ui.fontHeight * 2 + ui.x2margin
            CCButton{
                id: forward
                width: ui.fontHeight * 2
                height: width
                image: "/icon/move.svg"
                anchors.verticalCenter: parent.verticalCenter
                visible: activeArea && cRoute.areaIndex
                onClicked:{
                    cRoute.moveArea(true)
                }
            }
            CCButton{
                id: prev
                width: ui.fontHeight * 2
                height: width
                image: "/icon/arrow_down.svg"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: forward.right
                anchors.leftMargin: ui.fontHeight * 2
                visible: activeArea && cRoute.areaIndex
                onClicked:{
                    cRoute.switchArea(-1)
                }
            }
            CCText{
                height: parent.height
                anchors.left: prev.right
                anchors.leftMargin: ui.margin
                anchors.right: next.left
                anchors.rightMargin: ui.margin
                text: curArea ? curArea.name : ""
                color: activeArea ? cc.enabled : cc.disabled
                alignMid: true
            }
            CCButton{
                id: next
                width: ui.fontHeight * 2
                height: width
                image: "/icon/arrow_down.svg"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: backward.left
                anchors.rightMargin: ui.fontHeight * 2
                visible: activeArea && cRoute.areaIndex < cRoute.surverModel.count-1
                onClicked:{
                    cRoute.switchArea(1)
                }
            }
            CCButton{
                id: backward
                width: ui.fontHeight * 2
                height: width
                image: "/icon/move.svg"
                rotation: 180
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible: activeArea && cRoute.areaIndex < cRoute.surverModel.count-1
                onClicked:{
                    cRoute.moveArea(false)
                }
            }
        }
        CCMultiSwitchEditor{
            id: sw
            model: ["Corridor Editing", "Survey Settings"]
            selectIndex: panelMode
            enabled: activeArea
            onSwitchTo:
                (index)=>{
                    panelMode = index
                }
        }
    }
    Item{
        id: polygonEdit
        width: parent.width
        height: parent.height - col.height
        anchors.top: col.bottom
        visible: !panelMode
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column {
                    width: parent.width
                    Item{
                        width: parent.width
                        height: ui.fontHeight * 2 + ui.x2margin
                        CCText{
                            height: parent.height
                            text:"Settings"
                            font.pointSize: ui.lFontSize
                        }
                    }
                    CCValueBoxEditor{
                        title: qsTr("Left Width")
                        range: [0, 50]
                        value: corridor.leftWidth
                        base: 1
                        cell: 3
                        multiplier: 10
                        decimal: 0
                        onUpdated:
                            (number)=>{
                                corridor.leftWidth = number
                            }
                    }
                    CCValueBoxEditor{
                        title: qsTr("Right Width")
                        range: [0, 50]
                        value: corridor.rightWidth
                        base: 1
                        cell: 3
                        multiplier: 10
                        decimal: 0
                        onUpdated:
                            (number)=>{
                                corridor.rightWidth = number
                            }
                    }
                    Repeater{
                        model: curArea? curArea.keypointModel : 0
                        delegate: CCMouseArea{
                            width: parent.width
                            height: ui.fontHeight * 2 + ui.x2margin
                            enabled: activeArea
                            CCText{
                                id: ver
                                height: parent.height
                                text: index + 1
                                color: parent.enabled ? curArea.current === object ?
                                                     cc.selected : cc.enabled : cc.disabled
                            }
                            CCTextEditor{
                                id: lat
                                width: (parent.width - ver.width - del.width - ui.margin * 6) / 2
                                title: "Lat"
                                near: true
                                text: object.coord.latitude.toFixed(8)
                                color: enabled ? curArea.current === object ?
                                                     cc.selected : cc.enabled : cc.disabled
                                anchors.left: ver.right
                                anchors.leftMargin: ui.x2margin
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: parent.enabled
                            }
                            CCTextEditor{
                                id: lon
                                width: (parent.width - ver.width - del.width - ui.margin * 6) / 2
                                title: "Lon"
                                near: true
                                text: object.coord.longitude.toFixed(8)
                                color: enabled ? curArea.current === object ?
                                                     cc.selected : cc.enabled : cc.disabled
                                anchors.right: del.left
                                anchors.rightMargin: ui.x2margin
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: parent.enabled
                            }
                            CCButton{
                                id: del
                                width: ui.fontHeight * 2
                                height: width
                                image: "/classic/CCWhiteIconRemoveOne.svg"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: parent.enabled
                                onClicked: {
                                    if(activeArea)
                                        curArea.remove(object)
                                }
                            }
                            onClicked:{
                                curArea.current = object
                            }
                        }
                    }
                }
            }
        }
    }
    Item{
        id: contentArea
        width: parent.width
        height: parent.height - col.height
        anchors.top: col.bottom
        visible: panelMode
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Column{
                    width: parent.width
                    CCVehicleInfo{
                        showImage: false
                    }
                    CCCameraParamSettings{
                        cameraInfo: setup.camera
                        altModeName: cRoute.altModeName[cRoute.altitudeModeIndex]
                    }
                }
            }
        }
    }
}
