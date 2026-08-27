
import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import QGroundControl

import Gises.Widget

MapQuickItem{
    id: root
    anchorPoint: Qt.point(sourceItem.width / 2,sourceItem.height / 2)
    opacity: 0.99
    z: active + 1

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Map map: null
    property MissionNode node: null
    property Waypoint waypoint: null
    property GeoPoint geoPoint: null
    property string sign: geoPoint ? (geoPoint.index + node.sequence) : ""
    property bool active: false
    property bool canDrag: map.touchable && showPlanView &&
                           (node ? (!node.isHome || node.isHome && gises.vehicle.isOfflineEditingVehicle) : true)
    property bool disYChange: false
    property bool showTakeoff: waypoint && (waypoint.isTakeoff || waypoint.isHome && !waypoint.active)
    property bool showHome: waypoint && waypoint.isHome && waypoint.active
    property bool isLoiter: waypoint && waypoint.isLoiter
    property bool recalc: false
    property var tmpVisual: tmpLoader.item
    property double loiterRadius: waypoint && waypoint.isLoiter ? waypoint.loiterRadius : 0
    property var lotCoord: waypoint && waypoint.isLoiter ? root.coordinate : QtPositioning.coordinate()

    signal tmpCoordChanged()

    Component.onCompleted: {
        map.addMapItem(this)
    }

    signal clicked()

    sourceItem:
        Rectangle{
        width: ui.fontWidth * 3
        height: width
        radius: width / 2
        color: active ? cc.selected : cc.enabled
        border.color: cc.normalBg
        border.width: 1
        CCText{
            anchors.fill: parent
            alignMid: true
            text: showHome ? qsTr("H") : showTakeoff ? qsTr("T") : sign
            color: "black"
        }
        CCMouseArea{
            anchors.fill: parent
            onClicked: {
                root.clicked()
            }
        }
        Loader{
            id: tmpLoader
            sourceComponent: recalc ? tmpComponent : null
        }
        Loader{
            id: radiusLoader
            sourceComponent: waypoint && waypoint.isLoiter ? radiusComponent : null
        }
        Loader{
            id: circleLoader
            sourceComponent: isLoiter ? circleComponent : null
        }
    }
    DragHandler{
        xAxis.minimum: 0
        yAxis.minimum: 0
        xAxis.maximum: map.width - width
        yAxis.maximum: map.height - height
        yAxis.enabled: !disYChange
        target: canDrag ? (recalc ? tmpVisual : root) : null
        dragThreshold: 0
        grabPermissions: TapHandler.CanTakeOverFromItems
        onActiveChanged: {
            if(recalc){
                if(active){
                    map.addMapItem(tmpVisual)
                    tmpVisual.coordinate = tmpVisual.coordinate
                }else{
                    map.removeMapItem(tmpVisual)
                    tmpVisual.coordinate = root.coordinate
                }
            }
        }
    }
    Component{
        id: tmpComponent
        MapQuickItem{
            coordinate: lotCoord
            anchorPoint: Qt.point(sourceItem.width / 2,sourceItem.height / 2)
            opacity: 0.99
            sourceItem:
                Item{
                width: ui.fontWidth * 3
                height: width
                // CCText{
                //     anchors.fill: parent
                //     alignMid: true
                //     text: "tmp"
                //     color: "black"
                // }
            }
            onCoordinateChanged: {
                root.tmpCoordChanged()
            }
        }
    }

    Component{
        id: circleComponent
        MapCircle{
            color: cc.none
            border.color: cc.good
            border.width: 1
            center: lotCoord
            radius: loiterRadius
            Component.onCompleted: {
                map.addMapItem(this)
            }
            Component.onDestruction: {
                map.removeMapItem(this)
            }
        }
    }
    Component{
        id: radiusComponent
        MapQuickItem{
            coordinate: root.coordinate.atDistanceAndAzimuth(loiterRadius, 90)
            anchorPoint: Qt.point(sourceItem.width / 2,sourceItem.height / 2)
            opacity: 0.99
            sourceItem:
                Rectangle{
                width: ui.fontWidth * 2
                height: width
                radius: width / 2
            }
            DragHandler{
                xAxis.minimum: 0
                xAxis.maximum: map.width - width
                yAxis.enabled: false
                target: canDrag ? parent : null
                dragThreshold: 0
                grabPermissions: TapHandler.CanTakeOverFromItems
            }
            Component.onCompleted: {
                map.addMapItem(this)
            }
            Component.onDestruction: {
                map.removeMapItem(this)
            }
            onCoordinateChanged: {
                if(waypoint && waypoint.isLoiter){
                    var dist = coordinate.distanceTo(root.coordinate)
                    waypoint.loiterRadius = dist
                }
            }
        }
    }
}
