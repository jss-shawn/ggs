
import QtQuick
import QtQuick.Controls

import QGroundControl

CCMouseArea{
    id: root
    width: parent.width
    height: col.height + ui.x2margin

    property ColorConfig cc: clcfg
    property Ui ui: Ui
    property Fact fact
    property real value: 0
    property string title: "defalut name"
    property var range: []
    property real base: 0.1
    property int cell: 3
    property int multiplier: 10
    property int decimal: 1

    signal updated(real v)

    Column{
        id: col
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        CCText{
            id: name
            text: title +(range.length ? " [" + range[0] + "~" + range[1] + "]" : "")
        }
        CCValueBox{
            id: box
            value: fact ? fact.rawValue : root.value
            range: root.range
            base: root.base
            cell: root.cell
            multiplier: root.multiplier
            decimal: root.decimal
            onUpdated:
                (number)=>{
                    if(fact){
                        fact.rawValue = number
                    }else{
                        root.updated(number)
                    }
                }
        }
    }

}
