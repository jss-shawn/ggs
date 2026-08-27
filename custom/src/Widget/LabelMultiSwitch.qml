
import QtQuick
import QtQuick.Controls

import Gises.Widget

CCMouseArea{
    id: root
    width: parent.width
    height: cont.height + ui.x2margin

    property Ui ui: Ui
    property string title: ""
    property bool singleLine: true
    property var model: []
    property string dataName: ""
    property int selectIndex: 0
    property alias nm: name

    signal switchTo(int idx)

    Item{
        id: cont
        width: parent.width
        height: multi.height + (singleLine ? 0 : name.height)
        anchors.verticalCenter: parent.verticalCenter
        CCText {
            id: name
            height: singleLine ? multi.height : contentHeight
            rightPadding: title.length ? ui.fontHeight : 0
            text: title
        }
        CCMultiSwitch{
            id: multi
            width: parent.width - (singleLine ? name.width : 0)
            model: root.model
            dataName: root.dataName
            selectIndex: root.selectIndex
            anchors.top: singleLine ? name.top : name.bottom
            anchors.right: parent.right
            enabled: root.enabled
            onSwitchTo:
                (index)=>{
                    root.switchTo(index)
                }
        }
    }
}
