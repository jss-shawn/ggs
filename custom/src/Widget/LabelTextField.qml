
import QtQuick
import QtQuick.Controls

import QGroundControl

import Gises.Widget

Item{
    id: root
    width: parent.width
    height: editor.height + ui.x2margin

    signal valueChanged(var value)

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Fact fact: null
    property bool near: false
    property var color: cc.enabled
    property bool onlyNumber: fact ? !fact.typeIsString : false
    property real editorWidth: near ? (root.width - name.width - ui.margin) : Math.min(root.width/2, root.width - name.width - ui.x2margin)

    property string title: ""
    property string text: ""
    property string unit: ""
    property alias validator: editor.validator

    CCText{
        id: name
        text: title
        anchors.verticalCenter: parent.verticalCenter
        color: root.enabled ? root.color : cc.disabled
    }
    CCTextField{
        id: editor
        width: editorWidth
        radius: ui.radius
        text: fact ? fact.valueString : root.text
        unit: fact ? fact.units : root.unit
        color: root.enabled ? root.color : cc.disabled
        //inputMethodHints: onlyNumber ? Qt.ImhDigitsOnly : Qt.ImhNone
        inputMethodHints: onlyNumber && !ui.isiOS ? Qt.ImhFormattedNumbersOnly:  // Forces use of virtual numeric keyboard instead of full keyboard
                                                    Qt.ImhNone
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onEditingFinished: {
            if(fact){
                var error = fact.validate(text, false)
                console.log(text, error)
                if(error === ""){
                    fact.rawValue = text
                }else{
                    text = fact.valueString
                }
            }else{
                if(onlyNumber){
                    valueChanged(Number(text))
                }else{
                    valueChanged(text)
                }
            }
        }
    }
}
