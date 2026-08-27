
import QtQuick
import QtQuick.Controls

import QGroundControl

CCMouseArea{
    id: root

    width: height * 2
    height: ui.fontHeight

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property bool stateOn: false

    Rectangle{
        id: off
        anchors.fill: root
        radius: height / 2
        color: cc.disabled
    }
    Rectangle{
        id: on
        width: root.width / 2
        height: root.height
        radius: height / 2
        color: cc.selected
    }
    Rectangle{
        id: indicator
        width: root.height
        height: width
        radius: height / 2
        color: root.enabled ? cc.enabled : cc.separator
        anchors.right: on.right
    }
    PropertyAnimation{
        id: checkOn
        target: on
        property: "width"
        from: root.width / 2
        to: root.width
        duration: 100
    }
    PropertyAnimation{
        id: checkOff
        target: on
        property: "width"
        from: root.width
        to: root.width / 2
        duration: 100
    }
    onStateOnChanged: {
        stateOn ? checkOn.start() : checkOff.start()
    }
}
