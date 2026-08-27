
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Window

import QGroundControl

import Gises.Widget

Item{
    id: root
    anchors.fill: parent

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property var leftArea: leftWindow
    property var rightArea: rightWindow

    property var bgLayer

    Item {
        id: leftWindow
        width: parent.width * 0.25
        height: parent.height * 0.25
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: QGroundControl.videoManager.isStreamSource || QGroundControl.videoManager.isUvc
        VideoDisplay{
            id: video1
            videoName: "videoContent"
            thermalName: "thermalVideo"
        }
    }

    CCMouseArea{
        anchors.fill: leftWindow
        enabled: leftWindow.visible
        onClicked: {
            var bgItem = bgLayer.children[0]
            var leftItem = leftWindow.children[0]
            leftItem.parent = bgLayer
            bgItem.parent = leftWindow
        }
        Rectangle{
            anchors.fill: parent
            color: cc.none
            border.color: cc.good
        }
    }

    Item {
        id: rightWindow
        width: parent.width * 0.25
        height: parent.height * 0.25
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: QGroundControl.videoManager.isStreamSource || QGroundControl.videoManager.isUvc
        VideoDisplay{
            id: video2
            videoName: "videoContent2"
            thermalName: "thermalVideo2"
        }
    }

    CCMouseArea{
        anchors.fill: rightWindow
        enabled: rightWindow.visible
        onClicked: {
            var bgItem = bgLayer.children[0]
            var rightItem = rightWindow.children[0]
            rightItem.parent = bgLayer
            bgItem.parent = rightWindow
        }
        Rectangle{
            anchors.fill: parent
            color: cc.none
            border.color: cc.error
        }
    }
}