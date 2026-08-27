
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
    coordinate: coord

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Map map: null
    property GeoPoint geoPoint: null
    property GeoShape shape: null
    property bool shapeActive: false
    property var coord: geoPoint ? geoPoint.coord : QtPositioning.coordinate()
    property bool canDrag: map.touchable && shapeActive && showPlanView
    property bool isHome: false

    Component.onCompleted: {
        map.addMapItem(this)
    }

    sourceItem:
        Rectangle{
        width: ui.fontHeight + 4
        height: width
        radius: height / 2
        color: shapeActive ? shape.current === geoPoint ? cc.selected : cc.enabled : cc.none
        border.color: cc.normalBg
        border.width: 1
        CCText{
            anchors.fill: parent
            alignMid: true
            text: isHome ? "H" : ""
            color: "black"
        }
        CCMouseArea{
            anchors.fill: parent
            enabled: shapeActive
            onClicked: {
                shape.current = geoPoint
            }
        }
    }
    DragHandler{
        xAxis.minimum: 0
        yAxis.minimum: 0
        xAxis.maximum: map.width - width
        yAxis.maximum: map.height - height
        target: canDrag ? root : null
        dragThreshold: 0
        grabPermissions: TapHandler.CanTakeOverFromItems
    }
    onCoordinateChanged: {
        geoPoint.coord = coordinate
    }
}
