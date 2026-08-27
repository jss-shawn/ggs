import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea {
    id: root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property GisesPlan plan: gises.planManager
    property int planMode: plan.planMode
    property LandNode curLand: plan.currentLand
    property Waypoint curWp: plan.currentWp
    property SurveyArea curArea: plan.currentArea
    property int nodeSize: plan.waypointModel.count + plan.surveyAreaModel.count
    property bool showPlanarBtn: planMode === GisesPlan.PLANAR || planMode === GisesPlan.STRUCTURE || planMode === GisesPlan.MIXED
    property bool showRoadBtn: planMode === GisesPlan.ROAD || planMode === GisesPlan.WALL|| planMode === GisesPlan.MIXED
    property var planModeName: ["Waypoint", "Planar", "Road", "Wall", "Structure", "Mixed"]
    property int panelMode: 0

    Component.onCompleted: {
        showPlanView = true
        gises.currentManager = plan
    }

    Component.onDestruction: {
        gises.currentManager = null
    }

    Rectangle {
        anchors.fill: parent
        color: cc.normalBg
    }
    Column{
        id: col
        width: parent.width - ui.margin * 2
        anchors.horizontalCenter: parent.horizontalCenter
        // CCVehicleInfo{

        // }
        CCText {
            id: head
            width: parent.width
            height: contentHeight + ui.x2margin
            text: planModeName[plan.planMode]
            alignMid: true
            font.pointSize: ui.lFontSize
        }
        LabelComboBox{
            id: landMode
            title: qsTr("Land Mode")
            model: [qsTr("None"), qsTr("Multi-Rotor"), qsTr("Fixed-Wing")]
            currentIndex: plan.land ? plan.land.landMode : 0
            visible: plan.land
            onUpdateResult:
                (index)=>{
                    plan.land.landMode = index
                }
        }
        Item{
            id: quickArea
            width: parent.width
            height: btnCol.height
            visible: plan.planMode !== GisesPlan.WAYPOINT
            CCText{
                id: newAreaText
                width: contentWidth + ui.fontHeight
                height: ui.fontHeight + ui.x2margin
                text: "New Area"
            }
            Column{
                id: btnCol
                width: planarRow.width
                anchors.right: parent.right
                spacing: ui.margin
                Row{
                    id: planarRow
                    height: ui.fontHeight + ui.x2margin
                    spacing: ui.margin
                    anchors.right: parent.right
                    visible: showPlanarBtn
                    CCButton{
                        width: ui.fontWidth * 10
                        text: "Polygon"
                        border.color: cc.border
                        onClicked: {
                            plan.addPolygon([])
                            panelMode = 0
                        }
                    }
                    CCButton{
                        width: ui.fontWidth * 10
                        text: "Rectangle"
                        border.color: cc.border
                        onClicked: {
                            var wid = mainWindow.width / 8
                            var hei = mainWindow.height / 8
                            var lt = planMap.toCoordinate(Qt.point(wid*3, hei*3))
                            var lb = planMap.toCoordinate(Qt.point(wid*3, hei*5))
                            var rb = planMap.toCoordinate(Qt.point(wid*5, hei*5))
                            var rt = planMap.toCoordinate(Qt.point(wid*5, hei*3))
                            plan.addPolygon([lt, lb, rb, rt])
                            panelMode = 0
                        }
                    }
                    CCButton{
                        width: ui.fontWidth * 8
                        text: "Circle"
                        border.color: cc.border
                        onClicked: {
                            plan.addCicle(planMap.center)
                            panelMode = 0
                        }
                    }
                }
                Row{
                    height: ui.fontHeight + ui.x2margin
                    spacing: ui.margin
                    anchors.right: parent.right
                    visible: showRoadBtn
                    CCButton{
                        width: ui.fontWidth * 8
                        text: "Corridor"
                        border.color: cc.border
                        onClicked: {
                            plan.addCorridor([])
                            panelMode = 0
                        }
                    }
                    CCButton{
                        width: ui.fontWidth * 6
                        text: "Wall"
                        border.color: cc.border
                        onClicked: {
                        }
                    }
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
                icon.source: "/icon/move.svg"
                anchors.verticalCenter: parent.verticalCenter
                visible: plan.currentIndex > 0 && plan.currentNode != plan.land
                onClicked:{
                    plan.moveTo(true)
                }
            }
            CCButton{
                id: prev
                width: ui.fontHeight * 2
                height: width
                icon.source: "/icon/arrow_down.svg"
                rotation: 90
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: forward.right
                anchors.leftMargin: ui.fontHeight * 2
                visible: plan.currentIndex > 0
                onClicked:{
                    plan.getNode(-1)
                }
            }
            CCText{
                height: parent.height
                anchors.left: prev.right
                anchors.leftMargin: ui.margin
                anchors.right: next.left
                anchors.rightMargin: ui.margin
                text: curArea ? curArea.shape.name : curWp ? qsTr("Waypoint") : curLand ? qsTr("Land") : qsTr("Empty")
                color: curArea && !curArea.active ? cc.disabled : cc.enabled
                alignMid: true
            }
            CCButton{
                id: next
                width: ui.fontHeight * 2
                height: width
                icon.source: "/icon/arrow_down.svg"
                rotation: -90
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: backward.left
                anchors.rightMargin: ui.fontHeight * 2
                visible: nodeSize && plan.currentIndex < nodeSize - (plan.land.landMode ? 0 : 1)
                onClicked:{
                    plan.getNode(1)
                }
            }
            CCButton{
                id: backward
                width: ui.fontHeight * 2
                height: width
                icon.source: "/icon/move.svg"
                rotation: 180
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible: plan.currentIndex && plan.currentIndex < nodeSize - 1
                onClicked:{
                    plan.moveTo(false)
                }
            }
        }
    }
    Loader{
        width: parent.width
        height: parent.height - col.height
        anchors.top: col.bottom
        sourceComponent: curWp ? waypointPanel : curArea ? areaPanel : curLand ? landPanel : null
        //sourceComponent: landPanel
    }
    Component{
        id: landPanel
        LandSettings{
            land: plan.land
        }
    }
    Component{
        id: waypointPanel
        WaypointSettings{
            waypoint: curWp
        }
    }
    Component{
        id: areaPanel
        Item{
            Column{
                id: areaCol
                width: parent.width
                LabelSwitchButton{
                    id: showWaypoint
                    width: parent.width - ui.x2margin
                    title: qsTr("Show All Waypoint")
                    stateOn: curArea.showAllWaypoint
                    anchors.horizontalCenter: parent.horizontalCenter
                    onStateChanged: {
                        curArea.showAllWaypoint = !curArea.showAllWaypoint
                    }
                }
                LabelMultiSwitch {
                    id: sw
                    width: parent.width - ui.x2margin
                    model: ["Polygon Editing", "Survey Settings"]
                    selectIndex: panelMode
                    enabled: curArea.active
                    anchors.horizontalCenter: parent.horizontalCenter
                    onSwitchTo:
                        (index)=>{
                            panelMode = index
                        }
                }
            }
            ShapeSettings{
                id: shpSetup
                width: parent.width
                height: parent.height - areaCol.height
                geoShape: curArea.shape
                shapeActive: curArea.active
                anchors.top: areaCol.bottom
                visible: !panelMode
            }
            CCFlickable {
                anchors.fill:shpSetup
                anchors.margins: ui.margin
                fixedWidth: true
                visible: panelMode
                CCMouseArea{
                    width: parent.width
                    height: children[0].height
                    Column {
                        width: parent.width
                        VehicleInfo {
                            showImage: false
                        }
                        CameraParamSettings {
                            id: camera
                            cameraInfo: curArea.setup.camera
                            //altModeName: plan.altModeName[plan.altitudeModeIndex]
                        }
                        LabelSlider {
                            id: routeAngle
                            title: qsTr("Route Angle")
                            from: 0
                            to: 359
                            value: curArea.setup.routeAzimuth
                            realTime: true
                            visible: curArea.shape.type === GeoShape.POLYGON
                            onUpdateValue:
                                (value)=>{
                                    //不加visible判断会导致一次循环绑定报错提示
                                    if(!isNaN(value) && visible){
                                        curArea.setup.routeAzimuth = value
                                    }
                                }
                        }
                        LabelComboBox{
                            id: altitudeMode
                            title: qsTr("Altitude Mode")
                            fact: curArea.setup.camera.altMode
                        }
                        // Item {
                        //     id: terrain
                        //     width: parent.width
                        //     height: altitudeMode.height + tolerance.height + climb.height + descent.height
                        //     CCComboBoxEditor {
                        //         id: altitudeMode
                        //         title: "Altitude Mode"
                        //         model: plan.altModeName
                        //         currentIndex: plan.altitudeModeIndex
                        //         onCurrentIndexChanged: {
                        //             plan.altitudeModeIndex = currentIndex
                        //         }
                        //     }
                        //     CCTextEditor {
                        //         id: tolerance
                        //         title: qsTr("Tolerance")
                        //         onlyNumber: true
                        //         text: plan.tolerance
                        //         unit: qsTr("m")
                        //         enabled: 0 !== altitudeMode.currentIndex
                        //         onValueChanged:
                        //             (value)=>{
                        //                 if (!isNaN(value)){
                        //                     plan.tolerance = value
                        //                 }
                        //             }
                        //     }
                        //     CCTextEditor {
                        //         id: climb
                        //         title: qsTr("Max Climb Rate")
                        //         text: plan.climbRate
                        //         unit: qsTr("m/s")
                        //         onlyNumber: true
                        //         enabled: 0 !== altitudeMode.currentIndex
                        //         onValueChanged:
                        //             (value)=>{
                        //                 if (!isNaN(value)){
                        //                     plan.climbRate = value
                        //                 }
                        //             }
                        //     }
                        //     CCTextEditor {
                        //         id: descent
                        //         title: qsTr("Max Descent Rate")
                        //         text: plan.descentRate
                        //         unit: qsTr("m/s")
                        //         onlyNumber: true
                        //         enabled: 0 !== altitudeMode.currentIndex
                        //         onValueChanged:
                        //             (value)=>{
                        //                 if (!isNaN(value)){
                        //                     plan.climbRate = value
                        //                 }
                        //             }
                        //     }
                        // }
                    }
                }
            }
        }
    }
}
