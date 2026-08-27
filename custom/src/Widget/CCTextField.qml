
import QtQuick
import QtQuick.Controls

import QGroundControl

TextField{
    id: root

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property color borderColor: cc.border
    property real radius: 0
    property alias unit: unitText.text
    property bool alignLeft: false
    property bool alignRight: false

    width: parent.width
    height: contentHeight + ui.x2margin
    topPadding: 0
    bottomPadding: 0
    leftPadding: ui.margin
    rightPadding: unitText.width + leftPadding
    color: enabled ? cc.enabled : cc.disabled
    horizontalAlignment: alignLeft ? Text.AlignLeft :(alignRight ? Text.AlignRight : Text.AlignHCenter)
    verticalAlignment: Text.AlignVCenter
    font.family: ui.fontFamily
    font.pointSize: ui.fontSize

    background: Rectangle{
        radius: root.radius
        color: cc.none
        border.color: borderColor
    }
    onActiveFocusChanged: {
        if(activeFocus) {
            if(root.text !== ""){
                selectAll()
            }
        }
    }
    CCText{
        id: unitText
        width: text.length ? contentWidth + ui.margin : 0
        height: root.height
        color: root.color
        font.pointSize: root.font.pointSize
        anchors.right: root.right
    }
    onEditingFinished: {
        if(focus){
            //防止回车触发两次本事件
            focus = false
            return
        }
    }
}
