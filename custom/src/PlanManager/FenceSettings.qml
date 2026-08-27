
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id:             root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property FenceManager fence: gises.fenceManager
    property GeoFence current: fence.currentFence

    Component.onCompleted: {
        showPlanView = true
        gises.currentManager = fence
    }

    Component.onDestruction: {
        gises.currentManager = null
        fence.currentFence = null
    }

    Rectangle{
        anchors.fill: parent
        color: cc.normalBg
    }
    CCText{
        id: head
        width: parent.width
        height: contentHeight + ui.x2margin
        text: qsTr("GeoFence")
        alignMid: true
        font.pointSize: ui.llFontSize
    }
    Item{
        id: create
        width: parent.width - ui.x2margin
        height: row.height + ui.x2margin
        anchors.top: head.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        Row{
            id: row
            height: custom.height
            spacing: ui.margin
            anchors.verticalCenter: parent.verticalCenter
            CCText {
                height: parent.height
                text: qsTr("Create")
            }
            CCButton {
                id: custom
                width: ui.fontWidth * 8
                text: qsTr("Custom")
                border.color: cc.border
                onClicked: fence.addCustom()
            }
            CCButton {
                width: ui.fontWidth * 12
                text: qsTr("Simple Rect")
                border.color: cc.border
                onClicked: {
                    var w = mainWindow.width * 0.5
                    var h = mainWindow.height * 0.5
                    var offsetw = mainWindow.width * 0.2
                    var offseth = mainWindow.height * 0.2
                    var ce = planMap.toCoordinate(Qt.point(w, h), false /* clipToViewPort */)
                    var lt = planMap.toCoordinate(Qt.point(w-offsetw, h-offseth), false /* clipToViewPort */)
                    var lb = planMap.toCoordinate(Qt.point(w-offsetw, h+offseth), false /* clipToViewPort */)
                    var rb = planMap.toCoordinate(Qt.point(w+offsetw, h+offseth), false /* clipToViewPort */)
                    var rt = planMap.toCoordinate(Qt.point(w+offsetw, h-offseth), false /* clipToViewPort */)
                    fence.addSimpleRect(ce, lt, lb, rb, rt)
                }
            }
            CCButton {
                width: ui.fontWidth * 6
                text: qsTr("Cicle")
                border.color: cc.border
                onClicked: {
                    var w = mainWindow.width * 0.5
                    var h = mainWindow.height * 0.5
                    var center = planMap.center
                    var radius = planMap.toCoordinate(Qt.point(w*1.5, h), false /* clipToViewPort */)
                    fence.addCircle(center, radius)
                }
            }
        }
    }
    Item{
        width: parent.width
        anchors.top: create.bottom
        anchors.bottom: btns.top
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
                        model: fence.polygonFenceModel
                        CCMouseArea{
                            width: parent.width
                            height: polygon.height
                            property bool selected: object === current
                            onClicked: {
                                if(current && current === object){
                                    fence.currentFence = null
                                    return
                                }
                                fence.currentFence = object
                            }
                            Rectangle{
                                anchors.fill: parent
                                color: cc.none
                                border.color: cc.selected
                                visible: current === object
                            }
                            Item{
                                id: polygon
                                width: parent.width - ui.x2margin
                                height: ui.fontHeight * 2
                                anchors.centerIn: parent
                                Rectangle{
                                    id: plgType
                                    width: parent.height - ui.x2margin
                                    height: width
                                    radius: object.radius > 0.001 ? width/2 : 0
                                    color: object.inner ? "green" : "red"
                                    anchors.verticalCenter: parent.verticalCenter
                                    CCMouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            object.inner = !object.inner
                                        }
                                    }
                                }
                                CCText{
                                    id: vertex
                                    width: ui.fontWidth * 16
                                    height: parent.height
                                    text: qsTr("Vertex: ") + object.points.length
                                    anchors.left: plgType.right
                                    anchors.leftMargin: ui.margin
                                    visible: object.radius < 0.01
                                }
                                CCButton{
                                    width: parent.height
                                    height: width
                                    color: cc.none
                                    icon.source: "/icon/remove.svg"
                                    anchors.right: plgDel.left
                                    enabled: object === current
                                    visible: object.radius < 0.01
                                    onClicked: {
                                        object.removeOne()
                                    }
                                }
                                CCButton{
                                    id: plgDel
                                    width: parent.height
                                    height: width
                                    icon.source: "/icon/trash.svg"
                                    color: cc.none
                                    anchors.right: parent.right
                                    onClicked: {
                                        fence.removeFence(object)
                                    }
                                }
                            }
                        }
                    }
                    Repeater{
                        model: fence.circleFenceModel
                        CCMouseArea{
                            width: parent.width
                            height: circle.height
                            property bool selected: object === current
                            onClicked: {
                                if(current && current === object){
                                    fence.currentFence = null
                                    return
                                }
                                fence.currentFence = object
                            }
                            Rectangle{
                                anchors.fill: parent
                                color: cc.none
                                border.color: cc.selected
                                visible: current === object
                            }
                            Item{
                                id: circle
                                width: parent.width - ui.x2margin
                                height: radius.height
                                anchors.centerIn: parent
                                Rectangle{
                                    id: cicType
                                    width: parent.height - ui.x2margin
                                    height: width
                                    radius: object.radius > 0.001 ? width/2 : 0
                                    color: object.inner ? "green" : "red"
                                    anchors.verticalCenter: parent.verticalCenter
                                    CCMouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            object.inner = !object.inner
                                        }
                                    }
                                }
                                LabelTextField {
                                    id: radius
                                    width: ui.fontWidth * 16
                                    title: qsTr("radius")
                                    text: object.radius.toFixed(2)
                                    near: true
                                    anchors.left: cicType.right
                                    anchors.leftMargin: ui.margin
                                    visible: object.radius > 0.01
                                    onValueChanged:
                                        (value)=>{
                                            var v = Number(value)
                                            if(!isNaN(v) && v >= 0.001){
                                                object.radius = v
                                            } else {
                                                radius.text = object.radius.toFixed(2)
                                            }
                                        }
                                }
                                CCButton{
                                    width: parent.height
                                    height: width
                                    color: cc.none
                                    icon.source: "/icon/remove.svg"
                                    anchors.right: cicDel.left
                                    enabled: object === current
                                    visible: object.radius < 0.01
                                    onClicked: {
                                        object.removeOne()
                                    }
                                }
                                CCButton{
                                    id: cicDel
                                    width: parent.height
                                    height: width
                                    icon.source: "/icon/trash.svg"
                                    color: cc.none
                                    anchors.right: parent.right
                                    onClicked: {
                                        fence.removeFence(object)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item{
        id: btns
        width: parent.width
        height: ui.fontWidth * 4
        anchors.bottom: parent.bottom
        CCButton{
            width: parent.height
            height: width
            icon.source: "/icon/upload.svg"
            border.width: 0
            anchors.centerIn: parent
            onClicked: {
                gises.sendToVehicle()
            }
        }
    }
}
