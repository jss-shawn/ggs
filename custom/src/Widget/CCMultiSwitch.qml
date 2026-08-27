
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

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property alias model: rep.model
    property string dataName: ""
    property int selectIndex: 0

    signal switchTo(int idx)

    RowLayout{
        anchors.fill: parent
        spacing: 0
        Repeater{
            id: rep
            CCMouseArea{
                Layout.fillWidth: true
                height: parent.height
                clip: true
                property bool mid: index && index < rep.count - 1
                property bool last: index === rep.count - 1
                Rectangle{
                    width: parent.width + ui.fontHeight
                    height: parent.height
                    radius: root.radius
                    color: root.enabled ? index === selectIndex ? cc.selected : cc.dark : cc.separator
                    border.color: cc.border
                    anchors.horizontalCenter: parent.mid ? parent.horizontalCenter : undefined
                    anchors.right: parent.last ? parent.right : undefined
                    visible: index === selectIndex
                }
                CCText{
                    width: parent.width
                    height: parent.height
                    text: dataName.length ? modelData[dataName] : modelData
                    alignMid: true
                    color: !root.enabled ? cc.disabled : index === selectIndex ? cc.normalBg : cc.enabled
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
