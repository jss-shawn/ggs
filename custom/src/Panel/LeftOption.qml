
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Window
import QtQuick.Shapes

import QGroundControl
import QGroundControl.Controls

import Gises.Widget
import Gises.Plan

CCMouseArea{
    id: root

    width: hide ? ui.fontWidth * 4 : ui.fontWidth * 6

    property ColorConfig cc: clcfg
    property bool hide: true
    property int optIndex: 0
    property var optUrls: ["",
                        "/qml/Gises/Plan/RouteLibrary.qml",
                        "/qml/Gises/Plan/FenceSettings.qml",
                        "/qml/Gises/Plan/RallySettings.qml",
                        "/qml/Gises/Plan/PlanSettings.qml",
                        "/qml/Gises/Plan/FenceSettings.qml",
                        "/qml/Gises/Plan/RallySettings.qml"]

    onClicked: {
        if (hide) {
            hide = false
        }
    }

    function showPanel(index) {
        root.parent.panel = ""
        if (1 === index && optIndex > 3 || index === optIndex) {
            optIndex = 0
            showPlanView = false
        } else {
            optIndex = index
            // if (index === optIndex) {
            //     optIndex = 0
            //     showPlanView = false
            // } else {
            //     optIndex = index
            // }
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
            GradientStop { position: 0.0; color: cc.normalBg}
            GradientStop { position: 0.8; color: cc.none }
            GradientStop { position: 1.0; color: cc.none}
        }
        IconLabel{
            width: parent.width
            height: width
            icon.source: "/icon/double_down.svg"
            defaultIconColor: cc.normal
            rotation: -90
            anchors.centerIn: parent
        }
    }

    Item{
        id: optionsArea
        anchors.fill: parent
        visible: !hide
        CCSeparator{
            height: parent.height
            anchors.right: parent.right
            visible: optIndex
        }
        Column{
            width: parent.width
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 1 === optIndex || optIndex > 3
                icon.source: "/icon/plan.svg"
                onClicked: {
                    showPanel(1)
                    // if (1 === optIndex || optIndex > 3) {
                    //     optIndex = 0
                    //     showPlanView = false
                    // } else {
                    //     optIndex = 1
                    // }
                }
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 2 === optIndex
                icon.source: "/icon/fence.svg"
                onClicked: {
                    if (2 === optIndex) {
                        optIndex = 0
                        showPlanView = false
                    } else {
                        optIndex = 2
                    }
                }
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: 3 === optIndex
                icon.source: "/icon/rally.svg"
                onClicked: {
                    if (3 === optIndex) {
                        optIndex = 0
                        showPlanView = false
                    } else {
                        optIndex = 3
                    }
                }
            }
            CCButton{
                width: parent.width
                height: width
                checkable: false
                checked: root.parent.panel === "/qml/Gises/Vehicle/VehicleConfig.qml"
                icon.source: "/icon/vehicle_setup.svg"
                onClicked: {
                    optIndex = 0
                    showPlanView = false
                    if (root.parent.panel === "/qml/Gises/Vehicle/VehicleConfig.qml") {
                        root.parent.panel = ""
                    } else {
                        root.parent.panel = "/qml/Gises/Vehicle/VehicleConfig.qml"
                    }
                }
            }
        }
        CCButton{
            width: parent.width
            height: width
            icon.source: "/icon/triple_left.svg"
            anchors.bottom: parent.bottom
            onClicked: { optIndex = 0; hide = true }
        }
    }

    Rectangle{
        id: contentArea
        width: ui.fontWidth * 40
        height: parent.height
        color: cc.normalBg
        anchors.left: parent.right
        visible: optIndex
        Loader{
            anchors.fill: parent
            anchors.margins: ui.margin
            source: optUrls[optIndex]
            function setSrc(url) {
                var idx = optUrls.indexOf(url)
                if (-1 !== idx) {
                    optIndex = idx
                }
            }
        }
    }

}
