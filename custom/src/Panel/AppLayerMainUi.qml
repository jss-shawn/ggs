
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import QGroundControl

import Gises.Widget

Item{
    id: root
    anchors.fill: parent

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property string panel: ""

    CriticalStatusBar{
        id: statusBar
        width: parent.width
        height: ui.fontHeight * 3
        z: 1
    }

    LeftOption{
        id: leftOpt
        anchors.top: statusBar.bottom
        anchors.bottom: parent.bottom
    }

    AppOptions{
        id: appOpt
        anchors.right: parent.right
        anchors.top: statusBar.bottom
        anchors.bottom: parent.bottom
    }

    Rectangle{
        anchors.top: statusBar.bottom
        anchors.left: leftOpt.right
        anchors.right: appOpt.left
        anchors.bottom: parent.bottom
        color: cc.none
        border.color: cc.border
        visible: panel !== ""
        Loader{
            anchors.fill: parent
            source: panel
        }
    }

}