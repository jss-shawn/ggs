
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    width: parent.width
    height: cont.height + ui.x2margin

    property Ui ui: Ui
    property Fact fact
    property string title: "title"
    property var model: []
    property int currentIndex: 0
    property alias currentText: box.currentText
    property alias textRole: box.textRole
    property alias displayText: box.displayText
    property bool singleLine: true
    property bool near: false

    signal updateResult(int index)

    Item{
        id: cont
        width: parent.width
        height: box.height + (singleLine ? 0 : name.height)
        anchors.verticalCenter: parent.verticalCenter
        CCText {
            id: name
            height: singleLine ? box.height : contentHeight + ui.x2margin
            rightPadding: title.length ? ui.x2margin : 0
            text: title
            color: clcfg.enabled
        }
        CCComboBox{
            id: box
            width: near ? parent.width - name.width - ui.x2margin : singleLine ? Math.min(parent.width / 2, parent.width - name.width) : parent.width
            model: fact ? fact.enumStrings : root.model
            currentIndex: fact ? fact.enumIndex : root.currentIndex
            anchors.top: singleLine ? name.top : name.bottom
            anchors.right: parent.right
            enabled: root.enabled
            onActivated: {
                if(fact){
                    fact.enumIndex = currentIndex
                }
                updateResult(currentIndex)
            }
        }
    }
}
