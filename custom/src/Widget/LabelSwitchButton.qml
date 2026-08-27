
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

import Gises.Widget

CCMouseArea{
    id:    root
    width: parent.width
    height: col.height + ui.x2margin

    property Ui ui: Ui
    property Fact fact
    property string title: "title"
    property string instruction: fact ? (fact.shortDescription.length ? fact.shortDescription :
                                                                        fact.longDescription) : ""
    property alias color: name.color
    property bool showInstruction: false
    property alias stateOn: btn.stateOn

    signal switched()

    Column{
        id: col
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        Item{
            width: parent.width
            height: name.height
            CCText{
                id: name
                width: parent.width - btn.width - ui.margin
                text: title
                enabled: root.enabled
                wrapMode: Text.WordWrap
            }
            CCSwitchButton{
                id: btn
                stateOn: fact ? fact.rawValue : false
                enabled: root.enabled
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if(fact){
                        fact.rawValue = !fact.rawValue
                    }
                    switched()
                }
            }
        }
        CCText{
            id: instruct
            width: parent.width
            text: instruction
            font.pointSize: ui.sFontSize
            enabled: root.enabled
            visible: showInstruction
        }
    }
}
