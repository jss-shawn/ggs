
import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import QGroundControl

import Gises.Widget

MapQuickItem{
    id: root
    anchorPoint: Qt.point(sourceItem.width / 2,sourceItem.height / 2)
    coordinate: landNode.last.coord
    opacity: 0.99
    z: landNode.active + 1

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Map map: null
    property LandNode landNode: null
    property bool canDrag: map.touchable && showPlanView

    property int landMeter: 100
    property var landAreaLT: landNode.last.coord.atDistanceAndAzimuth(landMeter/10, landNode.head-90).atDistanceAndAzimuth(landMeter/2, landNode.head)
    property var landAreaRT: landAreaLT.atDistanceAndAzimuth(landMeter/5, landNode.head+90)
    property var landAreaRB: landAreaRT.atDistanceAndAzimuth(landMeter, landNode.head+180)
    property var landAreaLB: landAreaRB.atDistanceAndAzimuth(landMeter/5, landNode.head-90)

    Component.onCompleted: {
        map.addMapItem(this)
    }

    sourceItem:
        Item{
        width: ui.fontWidth * 3
        height: width
        Rectangle{
            radius: width / 2
            color: landNode.active ? cc.selected : cc.enabled
            border.color: cc.normalBg
            border.width: 1
            anchors.fill: parent
        }
        CCText{
            anchors.fill: parent
            alignMid: true
            text: landNode.fixedWingLand ? qsTr("L") : qsTr("RTL")
            color: "black"
        }
        CCMouseArea{
            anchors.fill: parent
            onClicked: {
                plan.onNodeClicked(landNode)
            }
        }
        Loader{
            id: landAreaLoader
            sourceComponent: 2 === landNode.landMode && landNode.lastPoint ? landAreaComponent : null
        }
        Loader{
            id: lastPathLoader
            sourceComponent: landNode.landMode && landNode.lastPoint ? lastPathComponent : null
        }
        Loader{
            id: landPathLoader
            sourceComponent: 2 === landNode.landMode && landNode.lastPoint ? landPathComponent : null
        }
    }
    DragHandler{
        id: drager
        xAxis.minimum: 0
        yAxis.minimum: 0
        xAxis.maximum: map.width - width
        yAxis.maximum: map.height - height
        target: canDrag ? root : null
        dragThreshold: 0
        grabPermissions: TapHandler.CanTakeOverFromItems
    }
    Component{
        id: landAreaComponent
        MapPolygon{
            path: [landAreaLT, landAreaRT, landAreaRB, landAreaLB]
            border.color: cc.enabled
            color: cc.good
            opacity: 0.2
            z: 0
            Component.onCompleted: {
                map.addMapItem(this)
            }
            Component.onDestruction: {
                map.removeMapItem(this)
            }
        }
    }
    Component{
        id: lastPathComponent
        MapPolyline{
            path: landNode.lastPoint ? [landNode.lastPoint.coord, landNode.first.coord] : []
            line.color: -1 === landNode.lastPathSafety ? cc.disabled : 1 === landNode.lastPathSafety ? cc.good : cc.error
            z: 0
            Component.onCompleted: {
                map.addMapItem(this)
            }
            Component.onDestruction: {
                map.removeMapItem(this)
            }
        }
    }
    Component{
        id: landPathComponent
        MapPolyline{
            path: 2 === landNode.landMode ? [landNode.last.coord.atDistanceAndAzimuth(landNode.distance, landNode.head),
                                            landNode.last.coord] : []
            line.color: -1 === landNode.landPathSafety ? cc.disabled : 1 === landNode.landPathSafety ? cc.good : cc.error
            z: 0
            Component.onCompleted: {
                map.addMapItem(this)
            }
            Component.onDestruction: {
                map.removeMapItem(this)
            }
        }
    }
}
