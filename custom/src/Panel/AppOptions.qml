
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Window
import QtQuick.Shapes

import QGroundControl
import QGroundControl.Controls

import Gises.Widget

CCMouseArea{
    id: root

    width: hide ? ui.fontWidth * 4 : ui.fontWidth * 6

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property bool hide: true
    property int optIndex: 0
    property var optUrls: ["",
                        "/qml/Gises/Panel/GeneralSet.qml",
                        "/qml/Gises/Panel/MapSet.qml",
                        "/qml/Gises/Panel/LinkSet.qml",
                        "/qml/Gises/Panel/VideoSet.qml",]

    onClicked: {
        if (hide) {
            hide = false
        }
    }

    Rectangle{
        anchors.fill: parent
        visible: !hide
        color: cc.normalBg
    }

    Rectangle{
        anchors.fill: parent
        visible: hide
        gradient: Gradient{
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: cc.none }
            GradientStop { position: 0.2; color: cc.none }
            GradientStop { position: 1.0; color: cc.normalBg }
        }
        IconLabel{
            width: parent.width
            height: width
            icon.source: "/icon/double_down.svg"
            defaultIconColor: cc.normal
            rotation: 90
            anchors.centerIn: parent
        }
    }

    Item{
        id: optionsArea
        anchors.fill: parent
        visible: !hide
        CCSeparator{
            height: parent.height
            visible: optIndex
        }
        Column{
            width: parent.width
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 1 === optIndex
                text: "Gen"
                onClicked: 1 === optIndex ? optIndex = 0 : optIndex = 1
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 2 === optIndex
                text: "Map"
                onClicked: 2 === optIndex ? optIndex = 0 : optIndex = 2
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 3 === optIndex
                text: "Lnk"
                onClicked: 3 === optIndex ? optIndex = 0 : optIndex = 3
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 4 === optIndex
                text: "Vid"
                onClicked: 4 === optIndex ? optIndex = 0 : optIndex = 4
            }
        }
        CCButton{
            width: parent.width
            height: width
            icon.source: "/icon/triple_left.svg"
            anchors.bottom: parent.bottom
            rotation: 180
            onClicked: { optIndex = 0; hide = true }
        }
    }

    Rectangle{
        id: contentArea
        width: ui.fontWidth * 40
        height: parent.height
        color: cc.normalBg
        anchors.right: parent.left
        visible: optIndex
        Loader{
            anchors.fill: parent
            anchors.margins: ui.margin
            source: optUrls[optIndex]
        }
    }
}
