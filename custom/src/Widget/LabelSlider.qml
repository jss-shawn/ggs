
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.FactControls

CCMouseArea{
    id: root
    width: parent.width
    height: cont.height + ui.x2margin

    property ColorConfig cc: clcfg
    property Fact fact
    property double value: 0
    property double from: 0
    property double to: 20
    property double stepSize: 1
    property alias title: name.text
    property alias unit: edit.unit
    property int decim: 0
    property bool simple: false
    property bool realTime: true
    property bool deloop: false

    signal updateValue(double value)

    // Rectangle{
    //     anchors.fill: parent
    //     color: cc.normalBg
    // }
    Item{
        id: cont
        width: parent.width
        height: operation.height + (simple ? 0 : name.height)
        anchors.verticalCenter: parent.verticalCenter
        CCText{
            id: name
            height: simple ? operation.height : contentHeight
            rightPadding: text.length ? ui.fontHeight : 0
            text: "slider"
            enabled: root.enabled
        }
        Item{
            id: operation
            width: parent.width - (simple ? name.width : 0)
            height: slider.height + minim.visible * minim.height
            anchors.top: simple ? name.top : name.bottom
            anchors.right: parent.right
            CCButton{
                id: sub
                width: simple ? 0 : parent.height
                height: width
                icon.source: "/icon/add.svg"
                color: cc.none
                enabled: root.enabled
                visible: !simple
                onClicked: {
                    if(fact){
                        fact.rawValue -= slider.stepSize
                    }
                    deloop = true
                    updateValue(root.value - root.stepSize)
                }
            }
            CCText{
                id:minim
                text: slider.from.toFixed(fact ? fact.decimalPlaces : decim)
                font.pointSize: ui.ssFontSize
                anchors.left: slider.left
                anchors.bottom: parent.bottom
                enabled: root.enabled
                visible: !simple && text.length
            }
            CCSlider{
                id: slider
                from: fact ? fact.min : root.from
                to: fact ? fact.max : root.to
                stepSize: fact ? fact.increment : root.stepSize
                value: fact ? fact.rawValue : root.value
                anchors.left: sub.right
                anchors.right: add.left
                anchors.margins: ui.margin
                enabled: root.enabled
                onPressedChanged: {
                    if(!realTime && !pressed){
                        if(fact){
                            fact.rawValue = value
                        }
                        updateValue(value)
                    }
                }
                onValueChanged: {
                    if(realTime){
                        if(fact){
                            fact.rawValue = value
                        }
                        if(deloop){
                            deloop = false
                        }else{
                            updateValue(value)
                        }
                    }
                }
            }
            CCText{
                id: maxim
                text: slider.to.toFixed(fact ? fact.decimalPlaces : decim)
                font.pointSize: ui.ssFontSize
                anchors.right: slider.right
                anchors.bottom: parent.bottom
                enabled: root.enabled
                visible: !simple && text.length
            }
            CCButton{
                id: add
                width: simple ? 0 : parent.height
                height: width
                icon.source: "/icon/add.svg"
                color: cc.none
                anchors.right: edit.left
                enabled: root.enabled
                visible: !simple
                onClicked: {
                    if(fact){
                        fact.rawValue += slider.stepSize
                    }
                    deloop = true
                    updateValue(root.value + root.stepSize)
                }
            }
            CCTextField{
                id: edit
                width: simple ? 0 : ui.fontWidth * 8
                height: parent.height
                text: slider.value.toFixed(fact ? fact.decimalPlaces : decim)
                anchors.right: parent.right
                enabled: root.enabled
                visible: !simple
                onEditingFinished: {
                    var val = Number(text)
                    if(!isNaN(val)){
                        if(fact){
                            fact.rawValue = val
                        }
                        deloop = true
                        updateValue(val)
                    }
                }
            }
        }
    }
}
