import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea {
    id: root
    width: parent.width
    height: parent.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property bool shapeActive: false
    property GeoShape geoShape: null
    property GeoPoint current: geoShape ? geoShape.current : null
    property int type: geoShape ? geoShape.type : 0
    property var shapeName: [qsTr("Polygon"), qsTr("Circle"), qsTr("Road")]

    Rectangle {
        anchors.fill: parent
        color: cc.normalBg
    }
    CCFlickable{
        id: flk
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
                        text: shapeName[type] + qsTr("Settings")
                        font.pointSize: ui.lFontSize
                    }
                }
                LabelValueBox {
                    id: expand
                    title: qsTr("Expand Margin (m)")
                    range: [0, 500]
                    value: visible && geoShape ? geoShape.expand : 0
                    base: 1
                    cell: 3
                    multiplier: 10
                    decimal: 0
                    visible: type === GeoShape.POLYGON
                    onUpdated:
                        (number)=>{
                            if(visible){
                                geoShape.expand = number
                            }
                        }
                }
                LabelValueBox {
                    id: leftWid
                    title: qsTr("Left Width")
                    range: [0, 500]
                    value: visible && geoShape ? geoShape.leftWidth : 0
                    base: 1
                    cell: 3
                    multiplier: 10
                    decimal: 0
                    visible: type === GeoShape.CORRIDOR
                    onUpdated:
                        (number)=>{
                            if(visible){
                                geoShape.leftWidth = number
                            }
                        }
                }
                LabelValueBox {
                    id: rightWid
                    title: qsTr("Right Width")
                    range: [0, 500]
                    value: visible && geoShape ? geoShape.rightWidth : 0
                    base: 1
                    cell: 3
                    multiplier: 10
                    decimal: 0
                    visible: type === GeoShape.CORRIDOR
                    onUpdated:
                        (number)=>{
                            if(visible){
                                geoShape.rightWidth = number
                            }
                        }
                }
                LabelValueBox {
                    id: rad
                    title: qsTr("Radius")
                    range: [0, 500]
                    value: visible && geoShape ? geoShape.radius : 0
                    base: 1
                    cell: 3
                    multiplier: 10
                    decimal: 0
                    visible: type === GeoShape.CIRCLE
                    onUpdated:
                        (number)=>{
                            if(visible){
                                geoShape.radius = number
                            }
                        }
                }
                Repeater{
                    model: geoShape? geoShape.keypointModel : 0
                    delegate: CCMouseArea{
                        width: parent.width
                        height: ui.fontHeight * 2 + ui.x2margin
                        enabled: shapeActive
                        CCText{
                            id: ver
                            height: parent.height
                            text: index + 1
                            color: shapeActive ? current === object ? cc.selected : cc.enabled : cc.disabled
                        }
                        LabelTextField {
                            id: lat
                            width: (parent.width - ver.width - del.width - ui.margin * 6) / 2
                            title: "Lat"
                            near: true
                            text: object.coord.latitude.toFixed(8)
                            color: enabled ? current === object ? cc.selected : cc.enabled : cc.disabled
                            anchors.left: ver.right
                            anchors.leftMargin: ui.x2margin
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: parent.enabled
                            onValueChanged:
                                (value)=>{
                                    //object.coord = QtPositioning.coordinate(value, object.coord.longitude)
                                    object.coord.latitude = value
                                }
                        }
                        LabelTextField {
                            id: lon
                            width: (parent.width - ver.width - del.width - ui.margin * 6) / 2
                            title: "Lon"
                            near: true
                            text: object.coord.longitude.toFixed(8)
                            color: enabled ? current === object ? cc.selected : cc.enabled : cc.disabled
                            anchors.right: del.left
                            anchors.rightMargin: ui.x2margin
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: shapeActive
                            onValueChanged:
                                (value)=>{
                                    //object.coord = QtPositioning.coordinate(object.coord.latitude, value)
                                    object.coord.longitude = value
                                }
                        }
                        CCButton{
                            id: del
                            width: ui.fontHeight * 2
                            height: width
                            icon.source: "/icon/remove.svg"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: parent.enabled
                            onClicked: {
                                if(shapeActive)
                                    geoShape.remove(object)
                            }
                        }
                        onClicked:{
                            geoShape.current = object
                        }
                    }
                }
            }
        }
    }
}
