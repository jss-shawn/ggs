
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

Item{
    id: root

    width: parent.width
    height: ui.fontHeight + ui.x2margin

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property var range: []
    property real value: 0
    property real base: 0.1
    property int cell: 3
    property int multiplier: 10
    property int decimal: 1

    signal updated(real v)

    Rectangle{
        id: bg
        anchors.fill: parent
        radius: ui.radius
        color: cc.none
        border.color: cc.border
    }
    CCTextField{
        id: editor
        text: value.toFixed(decimal)
        width: ui.fontWidth * 8
        height: parent.height
        anchors.centerIn: parent
        onEditingFinished: {
            var num = Number(text)
            if(range.length && (num < range[0] || num > range[1]) || isNaN(num)){
                text = value
            }else{
                updated(num)
            }
        }
    }
    RowLayout{
        id: larea
        anchors.left: parent.left
        anchors.right: editor.left
        height: parent.height
        layoutDirection: Qt.RightToLeft
        spacing: 0
        Repeater{
            model: cell
            CCMouseArea{
                Layout.fillWidth: true
                height: parent.height
                enabled: range.length ? value - val >= range[0] : true
                property real val: base * Math.pow(multiplier, index)
                CCText{
                    anchors.fill: parent
                    text: "-" + parent.val
                    alignMid: true
                    enabled: parent.enabled
                }
                CCSeparator{
                    height: parent.height
                    anchors.right: parent.right
                    visible: index
                }
                onClicked: {
                    updated(value - val)
                }
            }
        }
    }
    RowLayout{
        id: rarea
        anchors.left: editor.right
        anchors.right: parent.right
        height: parent.height
        spacing: 0
        Repeater{
            model: cell
            CCMouseArea{
                Layout.fillWidth: true
                height: parent.height
                enabled: range.length ? value + val <= range[1] : true
                property real val: base * Math.pow(multiplier, index)
                CCText{
                    anchors.fill: parent
                    text: "+" + parent.val
                    enabled: parent.enabled
                    alignMid: true
                }
                CCSeparator{
                    height: parent.height
                    visible: index
                }
                onClicked: {
                    updated(value + val)
                }
            }
        }
    }
}
