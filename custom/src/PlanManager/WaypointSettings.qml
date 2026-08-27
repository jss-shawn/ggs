
import QtQuick
import QtQuick.Controls
import QtPositioning

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    width: parent.width
    height: col.height

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Waypoint waypoint: null
    property Waypoint takeoff: plan.takeoff
    property var widgetType: [textfieldCom, sliderCom, switchCom, valueboxCom, comboboxCom]
    property bool rawMode: waypoint.rawMode || !waypoint.showFriendly
    property bool isWaypoint: waypoint.commandFact.rawValue === 16
    property bool isTakeoff: waypoint.commandFact.rawValue === 22
    property var cmd: waypoint.commandFact.rawValue

    function updateParamUi(){
        var i = 0
        for(i = 0;i < styleColumn.children.length;++i){
            styleColumn.children[i].destroy()
        }
        for(i = 0; i < waypoint.allParams.length; ++i){
            widgetType[waypoint.paramsUiType[i]].createObject(styleColumn, {title: waypoint.allParams[i].name, fact: waypoint.allParams[i]})
        }
    }
    Connections{
        target: waypoint
        onMissionUiChanged:{
                updateParamUi()
            }
    }
    Component.onCompleted: {
    }

    Column{
        id: col
        width: parent.width - ui.x2margin
        anchors.horizontalCenter: parent.horizontalCenter
        visible: waypoint
        LabelSwitchButton {
            id: adv
            title: qsTr("All Parameter Mode")
            instruction: qsTr("Provides advanced access to all commands/parameters. Be very careful!")
            showInstruction: rawMode
            stateOn: rawMode
            onStateChanged: {
                if(waypoint.rawMode && !waypoint.showFriendly){
                    return
                }
                waypoint.rawMode = !waypoint.rawMode
            }
        }
        LabelComboBox {
            id: command
            title: qsTr("Command")
            fact: waypoint.commandFact
            singleLine: false
            //enabled: false
        }
        LabelComboBox {
            id: frame
            title: qsTr("Frame")
            fact: waypoint.frameFact
            singleLine: false
            enabled: command.enabled
            visible: rawMode
        }
        Column{
            id: styleColumn
            width: parent.width
        }
        // CCTextEditor {
        //     id:flightSpeed
        //     title: qsTr("Flight Speed")
        //     onlyNumber: true
        //     text: waypoint.flightSpeed.toFixed(2)
        //     unit: qsTr("m/s")
        //     visible: isWaypoint
        //     onValueChanged:
        //         (value)=>{
        //             if(waypoint){
        //                 waypoint.flightSpeed = value
        //             }
        //         }
        // }
        WaypointCameraSettings {
            id: camera
            camera: waypoint.camera
            visible: isWaypoint && !rawMode
        }
        LabelComboBox {
            id: altitudeMode
            title: qsTr("Altitude Mode")
            fact: waypoint.altModeFact
            enabled: !isTakeoff
            visible: waypoint.showAlt && !rawMode
            onUpdateResult: {
                if(-1 === waypoint.altModeFact.rawValue){
                    waypoint.frameFact.rawValue = 0
                    waypoint.calcAboveTerrain = true
                }else{
                    waypoint.calcAboveTerrain = false
                    waypoint.frameFact.rawValue = waypoint.altModeFact.rawValue
                }
            }
        }
        LabelValueBox {
            title: qsTr("Altitude:(m)")
            range: [0, 1500]
            value: waypoint.altitude
            base: 1
            cell: 3
            multiplier: 10
            decimal: 0
            enabled: !isTakeoff
            visible: waypoint.showAlt && !rawMode
            onUpdated:
            (number)=>{
                    waypoint.altitude = number
            }
        }
        CCText{
            width: parent.width
            text: qsTr("Terrain: ") + terrAlt +
                  qsTr("  Amsl: ") + (waypoint.altitude + terrAlt)
            font.pointSize: ui.sFontSize
            property double terrAlt: 0 === waypoint.altModeFact.rawValue ? 0 :
                                    (3 === waypoint.altModeFact.rawValue ? (takeoff ? takeoff.first.terrain : 0) :
                                                                           waypoint.coord.altitude)
            //visible: -1 === waypoint.altModeFact.rawValue
        }
        LabelTextField {
            id:latitude
            title: qsTr("Latitude")
            text: waypoint.p5Fact.rawValue
            unit: waypoint.p5Fact.units
            visible: waypoint.showCoord && !rawMode
            onValueChanged:
                (value)=>{
                    var coord = QtPositioning.coordinate(value, waypoint.p6Fact.rawValue)
                    waypoint.coord = coord
                }
        }
        LabelTextField {
            id:longitude
            title: qsTr("Longitude")
            text: waypoint.p6Fact.rawValue
            unit: waypoint.p6Fact.units
            visible: waypoint.showCoord && !rawMode
            onValueChanged:
                (value)=>{
                    var coord = QtPositioning.coordinate(waypoint.p5Fact.rawValue, value)
                    waypoint.coord = coord
                }
        }
    }
    Component{
        id: textfieldCom
        LabelTextField {
        }
    }
    Component{
        id: sliderCom
        LabelSlider {
        }
    }
    Component{
        id: valueboxCom
        LabelValueBox {
        }
    }
    Component{
        id: comboboxCom
        LabelComboBox {
        }
    }
    Component{
        id: switchCom
        LabelSwitchButton {
        }
    }
}
