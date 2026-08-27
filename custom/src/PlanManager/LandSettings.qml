
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
    property LandNode land: null

    Component.onCompleted: {
    }
    CCText{
        text: qsTr("RTL, Send the vehicle back to the launch position")
        visible: 1 === land.landMode
    }
    Column{
        id: col
        width: parent.width
        spacing: ui.spacing
        visible: 2 === land.landMode
        LabelSwitchButton {
            title: qsTr("Use loiter to altitude")
            stateOn: land.useLoiter
            onStateChanged: {
                land.useLoiter = !land.useLoiter
            }
        }
        LabelTextField {
            title: qsTr("Loiter to altitude")
            text: land.preAltitude
            unit: qsTr("m") + (land.relativeAlt ? "" : " (amsl)")
            onlyNumber: true
            enabled: land.useLoiter
            onValueChanged:
                (value)=>{
                    if(isNaN(value)){
                        text = land.preAltitude
                    }else{
                        land.preAltitude = value
                    }
                }
        }
        LabelTextField {
            title: qsTr("Loiter radius")
            text: land.radius
            unit: qsTr("m")
            onlyNumber: true
            enabled: land.useLoiter
            onValueChanged:
                (value)=>{
                    if(isNaN(value)){
                        text = land.radius
                    }else{
                        land.radius = value
                    }
                }
        }
        LabelSwitchButton {
            title: qsTr("Loiter clockwise")
            stateOn: land.clockwise
            enabled: land.useLoiter
            onStateChanged: {
                land.clockwise = !land.clockwise
            }
        }
        LabelSlider {
            title: qsTr("Land Heading")
            from: 0
            to: 359
            stepSize: 1
            value: land.head
            unit: qsTr("deg")
            onUpdateValue:
                (value)=>{
                    land.head = value
                }
        }
        LabelTextField {
            title: qsTr("Land Altitude")
            text: land.landAltitude
            unit: qsTr("m") + (land.relativeAlt ? "" : " (amsl)")
            onlyNumber: true
            onValueChanged:
                (value)=>{
                    if(isNaN(value)){
                        text = land.landAltitude
                    }else{
                        land.landAltitude = value
                    }
                }
        }
        LabelMultiSwitch {
            title: qsTr("Land Option")
            model: [qsTr("Distance"), qsTr("Deg")]
            selectIndex: land.useDeg
            singleLine: false
            onSwitchTo:
                (index)=>{
                    land.useDeg = index
                }
        }
        LabelTextField {
            title: qsTr("Land distance")
            text: land.distance
            unit: qsTr("m")
            onlyNumber: true
            enabled: !land.useDeg
            onValueChanged:
                (value)=>{
                    if(isNaN(value)){
                        text = land.distance
                    }else{
                        land.distance = value
                    }
                }
        }
        LabelTextField {
            title: qsTr("Land deg")
            text: land.deg.toFixed(1)
            unit: qsTr("deg")
            onlyNumber: true
            enabled: land.useDeg
            onValueChanged:
                (value)=>{
                    if(isNaN(value)){
                        text = land.deg
                    }else{
                        if(-0.1 < value && value < 0.1){
                            value = 1
                        }
                        land.deg = value
                    }
                }
        }
        LabelMultiSwitch {
            title: qsTr("Alt Mode")
            model: [qsTr("Relative To Launch"), qsTr("AMSL")]
            selectIndex: !land.relativeAlt
            singleLine: false
            onSwitchTo:
                (index)=>{
                    land.relativeAlt = !index
                }
        }
    }
}
