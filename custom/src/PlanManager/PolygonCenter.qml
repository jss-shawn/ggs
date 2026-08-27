
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
    property GisesPlan plan: gises.planManager
    property SurveyArea area: null
    property GeoShape shape: area ? area.shape : null
    property var coord: shape ? shape.center : QtPositioning.coordinate()
    property bool canDrag: map.touchable && showPlanView
    property point scPoint: map.fromCoordinate(coordinate, false)

    Component.onCompleted: {
        map.addMapItem(this)
    }

    sourceItem:
        CCText{
        width: contentWidth + ui.x2margin
        height: ui.fontHeight + 4
        //text: ccs
        text: shape ? shape.name : ""
        color: area.active ? cc.selected : cc.border
        alignMid: true
        font.pointSize: ui.llFontSize
        font.weight: Font.Bold
        //style: polygon.selected ? Text.Outline : Text.Normal
        //styleColor: polygon.selected ? cc.normalBg : cc.none
        style: Text.Outline
        styleColor: cc.normalBg
        CCMouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                plan.onNodeClicked(area)
            }
        }
    }
    DragHandler{
        id: dragger
        xAxis.minimum: 0
        yAxis.minimum: 0
        xAxis.maximum: map.width - width
        yAxis.maximum: map.height - height
        target: canDrag ? root : null
        dragThreshold: 0
        grabPermissions: TapHandler.CanTakeOverFromItems
        onActiveChanged: {
            if(shape){
                shape.draging = active
            }
        }
    }
    onCoordinateChanged: {
        if(shape && shape.draging){
            shape.center = coordinate
        }
    }
}
