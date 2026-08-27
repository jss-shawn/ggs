
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs

import QGroundControl

import Gises.Widget

Item{
    id: root
    width: parent.width
    height: parent.height

    property ColorConfig cc: gises.colorConfig
    property Ui ui: Ui
    property GisesPlan planManager: gises.planManager
    property Vehicle vehicle: gises.vehicle
    property var appSettings: QGroundControl.settingsManager.appSettings
    property int state: 0	//0:routeLib 1: routeType 2: createType
    property var routeType: ["WaypointMode", "SurveyMode", "CorridorMode", "BevelMode", "StructureMode", "MixedMode"]
    property var routeIcon: ["way", "survey", "corridor", "", "", ""]
    property var routeSrc: [
        "",
        ""]
    property var createWay: ["AddFromTheMap", "CreateFromMission"]
    property int btnHeight: ui.fontHeight * 5

    Component.onCompleted: {
        showPlanView = false
        if(vehicle.isOfflineEditingVehicle){
        }else{
        }
    }

    function reset(){
        root.state = 0
    }

    Rectangle{
        anchors.fill: parent
        color: cc.normalBg
    }
    Item{
        id: head
        height: ui.fontHeight * 3
        width: parent.width
        CCButton{
            id: addOrBack
            width: ui.fontHeight * 2
            height: width
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "/icon/add.svg"
            //icon.source: root.state ? "/icon/add.svg" : "/classic/CCAddIcon.svg"
            onClicked:{
                if(1 === root.state){
                    root.state = 0
                }else{
                    root.state = 1
                }
            }
        }
        CCText{
            id:headText
            text: root.state ? "Create Route" : "Route Library"
            anchors.centerIn: parent
        }
        CCButton{
            width: ui.fontWidth * 8
            anchors.right: parent.right
            anchors.rightMargin: ui.x2margin
            anchors.verticalCenter: parent.verticalCenter
            text: "Refresh"
            visible: !root.state
            Timer{
                id: disTimer
                interval: 1000
                repeat: false
                running: false
                onTriggered: {
                    parent.enabled = true
                }
            }
            onClicked: {
                planManager.loadPlans()
                enabled = false
                disTimer.start()
            }
        }
    }
    Item{
        id: contentArea
        width: parent.width
        height: parent.height - head.height
        anchors.top: head.bottom
        CCFlickable{
            anchors.fill: parent
            anchors.margins: ui.margin
            fixedWidth: true
            CCMouseArea{
                width: parent.width
                height: children[0].height
                Loader{
                    width: parent.width
                    sourceComponent: root.state ? mode : lib
                }
            }
        }
    }

    Component{
        id: lib
        Column{
            spacing: ui.margin
            property double infoHeight: ui.fontHeight * 1.5 * 3 + ui.fontHeight
            LabelSwitchButton{
                id: loadFence
                title: qsTr("Load geoFence")
                stateOn: false
                onStateChanged: {
                    stateOn = !stateOn
                }
            }
            LabelSwitchButton{
                id: loadRally
                title: qsTr("Load Rally Point")
                stateOn: false
                onStateChanged: {
                    stateOn = !stateOn
                }
            }
            Repeater{
                id: fileRep
                model: planManager.planModel
                CCMouseArea{
                    width: parent.width
                    height: flow.height
                    onClicked: {
                        reset();
                        if(vehicle.isOfflineEditingVehicle){
                            planManager.initHome(defaultMap.center)
                        }else{
                            planManager.initHome(vehicle.homePosition)
                        }

                        //gcsManager.state = GCSManager.Planning
                        showPlanView = true
                        gises.loadFromFile(object.name + object.suffix)
                        root.parent.closeItem()
                    }
                    Rectangle{
                        anchors.fill: parent
                        radius: ui.radius
                        color: cc.disabled
                        border.color: cc.border
                    }
                    Flow{
                        id: flow
                        width: parent.width - ui.x2margin
                        anchors.horizontalCenter: parent.horizontalCenter
                        CCText{
                            id: name
                            width: parent.width
                            height: contentHeight + ui.x2margin
                            text: object.name
                        }
                        CCText{
                            width: contentWidth + ui.margin
                            height: contentHeight + ui.x2margin
                            text: "D: "+object.totalDistance.toFixed(2) + " m"
                        }
                        CCText{
                            width: contentWidth + ui.margin
                            height: contentHeight + ui.x2margin
                            text: "A: "+object.totalArea.toFixed(2) + " m²"
                        }
                        CCText{
                            width: contentWidth + ui.margin
                            height: contentHeight + ui.x2margin
                            text: "T: " + h + ":" + m + ":" + s
                            property int t: object.flyTime
                            property int h: t / 3600
                            property int m: t / 60
                            property int s: t % 60
                        }
                        CCText{
                            width: contentWidth + ui.margin
                            height: contentHeight + ui.x2margin
                            text: "F: "+object.firmware
                        }
                        CCText{
                            width: contentWidth + ui.margin
                            height: contentHeight + ui.x2margin
                            text: "P: "+object.photoShot
                        }
                    }
                }
            }
        }
    }
    Component{
        id: mode
        Column{
            id: frame
            spacing: ui.margin
            Repeater{
                id: modeRep
                model: root.state === 1 ? routeType : createWay
                MouseArea{
                    height: btnHeight
                    width: frame.width
                    property string src: routeIcon[index] === "" ? "" :
                                             "/icon/"+routeIcon[index]+".svg"
                    Rectangle{
                        anchors.fill: parent
                        radius: ui.radius
                        color: cc.disabled
                    }
                    IconLabel{
                        width: ui.fontWidth * 20
                        height: ui.fontHeight * 2
                        icon.source: src
                        text: modelData
                        defaultIconColor: cc.normal
                        color: defaultIconColor
                        anchors.centerIn: parent
                    }
                    onClicked: {
                        planManager.planMode = index
                        if(vehicle.isOfflineEditingVehicle){
                            planManager.home = planMap.center
                        }else{
                            planManager.home = vehicle.homePosition
                        }
                        reset()
                        root.parent.setSrc("/qml/Gises/Plan/PlanSettings.qml")
                    }
                }
            }
        }
    }

    PropertyAnimation{
        id: show
        target:         root
        property:       "anchors.rightMargin"
        from:           -root.width
        to:             0
        duration:       100
    }
    PropertyAnimation{
        id: hide
        target:         root
        property:       "anchors.rightMargin"
        from:           0
        to:             -root.width
        duration:       100
    }
    onVisibleChanged: {
        visible ? show.start() : hide.start()
    }
}
