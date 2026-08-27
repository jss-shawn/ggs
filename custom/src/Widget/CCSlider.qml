
import QtQuick
import QtQuick.Controls

import QGroundControl

Slider{
    id: root
    implicitWidth: ui.fontWidth * 5
    implicitHeight: ui.fontHeight
    padding: 0
    from: 0
    to: 20
    value: 0
    stepSize: 1
    snapMode: Slider.SnapAlways

    property ColorConfig cc: clcfg
    property Ui ui: Ui

    background: Rectangle{
        width: parent.width
        height: parent.height * 0.3
        radius: height / 2
        color: cc.disabled
        anchors.verticalCenter: parent.verticalCenter
        Rectangle{
            width: visualPosition * (parent.width - handle.width) + handle.width/2
            height: parent.height
            radius: height / 2
            color: root.enabled ? cc.enabled : cc.disabled
        }
    }
    handle: Rectangle{
        x: visualPosition * (parent.width - width)
        implicitWidth: parent.height
        implicitHeight: implicitWidth
        radius: width / 2
        color: root.enabled ? pressed ? cc.pressed : cc.enabled : cc.disabled
        anchors.verticalCenter: parent.verticalCenter
    }
}
