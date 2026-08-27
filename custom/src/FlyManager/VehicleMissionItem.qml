
import QtQuick
import QtLocation
import QtPositioning

import QGroundControl

import Gises.Widget

MapQuickItem{
    id: root
    anchorPoint: Qt.point(sourceItem.width / 2,sourceItem.height / 2)
    opacity: 0.99
    coordinate: item.coord
    visible: item.visible

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Map map: null
    property VehicleMissionItem item: null

    Component.onCompleted: {
        map.addMapItem(this)
    }

    sourceItem:
        Rectangle{
        width: ui.fontHeight + 4
        height: width
        radius: width / 2
        color: gises.currentPoint === item ? cc.selected : cc.enabled
        border.color: cc.normalBg
        border.width: 1
        CCText{
            anchors.fill: parent
            alignMid: true
            text: item.isTakeoff ? "T" : item.isLand ? "L" : item.sequence
            color: "black"
        }
        CCMouseArea{
            anchors.fill: parent
            onClicked: {
                item.clicked()
            }
        }
    }
}
