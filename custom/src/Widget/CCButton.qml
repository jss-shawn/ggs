import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import QGroundControl

Button {
    id: root

    implicitHeight: ui.fontHeight + ui.x2margin
    implicitWidth: implicitHeight
    padding: 0
    horizontalPadding: 0

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    //background
    property color color: cc.none
    property real radius: ui.radius
    property alias border: bg.border
    property color iconColor: cc.none

    background: Rectangle {
        id: bg
        width: parent.width
        height: parent.height
        radius: ui.radius
        color: root.color
    }
    contentItem: IconLabel {
        spacing: root.spacing
        mirrored: root.mirrored
        display: root.display

        icon: root.icon
        defaultIconColor: iconColor === cc.none ? (root.checked ? cc.selected : root.down ? cc.pressed : cc.normal) :
                                                     iconColor
        text: root.text
        font: root.font
        color: defaultIconColor
    }
}