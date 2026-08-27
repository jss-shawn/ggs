
import QtQuick
import QtQuick.Controls

import gises

Rectangle{
    id: root
    radius: ui.radius
    width: clickArea.width + promptArea.width

    property GCSColorConfig cc: gcsManager.colorConfig
    property string text: ""
    property alias confirmPrompt: confirmText.text
    property int clickTimes: 0
    property var mutexGroup: undefined

    signal confirmed()
    signal clicked()

    Rectangle{
        id: promptArea
        height: parent.height
        radius: ui.radius
        clip: true
        CCText{
            id: confirmText
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea{
        id: clickArea
        height: parent.height
        width: height
        anchors.right: parent.right
        Rectangle{
            id: clickBg
            height: parent.height
            width: parent.width
            radius: clickTimes ? height/2 : ui.radius
            border.color: clickTimes ? cc.selected : cc.border
            CCText{
                id: nameText
                text: clickTimes ? qsTr("Confirm") : root.text
                anchors.centerIn: parent
            }
        }
        onClicked: {
            enabled = false
            root.clicked()
        }
    }
    Timer{
        id: timer
        interval: 300
        repeat: false
        running: false
        onTriggered: {
            clickArea.enabled = true
        }
    }
    PropertyAnimation{
        id: spread
        target: promptArea
        property: "width"
        from: 0
        to: confirmText.contentWidth
        duration: 200
        onStopped: {
            timer.restart()
        }
    }
    PropertyAnimation{
        id: shrink
        target: promptArea
        property: "width"
        from: confirmText.contentWidth
        to: 0
        duration: 200
        onStopped: {
            timer.restart()
        }
    }
    onClickTimesChanged: {
        clickTimes ? spread.start() : shrink.start()
    }
}
