
import QtQuick
import QtQuick.Controls

Rectangle{
    id:    root
    width: ui.fontWidth * 8
    height: ui.fontHeight + ui.x2margin
    radius: ui.radius
    color: cc.normalBg
    border.color: selected ? cc.selected : noborder ? cc.none : cc.border

    property string icon: ""
    property bool selected: false
    property bool noborder: false
    property alias text: name.text

    signal clicked()

    Item{
        id: img
        width: icon === "" ? 0 : Math.min(parent.width, parent.height)
        height: width
        CCImage{
            width: parent.width - ui.margin
            source: icon
            anchors.centerIn: parent
        }
    }
    CCText{
        id: name
        width: parent.width - img.width
        height: parent.height
        color: root.enabled ? cc.enabled : cc.disabled
        alignMid: icon === ""
        enabled: root.enabled
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
    CCMouseArea{
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
