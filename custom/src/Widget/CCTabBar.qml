
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

Rectangle{
    id: root
    width: parent.width
    height: ui.fontHeight + ui.x2margin
    radius: ui.radius
    color: cc.none
    border.color: cc.border

    property GCSColorConfig cc: gcsManager.colorConfig
    property var ui: CCUiTool
    property var options: [1,2,3,4,5,6]
    property int selectIndex: 0

    signal switchTo(int idx)

    RowLayout{
        anchors.fill: parent
        spacing: 0
        Repeater{
            model: options
            CCMouseArea{
                Layout.fillWidth: true
                height: parent.height
                clip: true
                property bool mid: index && index < options.length - 1
                property bool last: index === options.length - 1
                Rectangle{
                    width: parent.width + ui.fontHeight
                    height: parent.height
                    radius: root.radius
                    color: cc.selected
                    border.color: cc.border
                    anchors.horizontalCenter: parent.mid ? parent.horizontalCenter : undefined
                    anchors.right: parent.last ? parent.right : undefined
                    visible: index === selectIndex
                }
                CCText{
                    width: parent.width
                    height: parent.height
                    text: modelData
                    alignMid: true
                    color: index === selectIndex ? cc.normalBg : cc.enabled
                }
                CCSeparator{
                    height: parent.height
                    visible: index
                }
                onClicked: {
                    switchTo(index)
                }
            }
        }
    }
}
