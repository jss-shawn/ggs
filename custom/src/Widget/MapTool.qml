
import QtQuick
import QtQuick.Controls
import QtLocation

import QGroundControl

Rectangle{
    id: root
    width: ui.fontHeight * 1.5 * 6
    height: ui.fontHeight * 3
    color: clcfg.normalBg

    property Ui ui: Ui
    property real zoomLevel

    Column{
        width: parent.width
        CCText{
            width: parent.width
            height: ui.fontHeight * 1.5
            text: "Map Level: " + zoomLevel.toFixed(1)
            alignMid: true
        }
        Row{
            height: ui.fontHeight * 1.5
            CCText{
                width: ui.fontHeight * 1.5
                height: width
                text: "RC"
                alignMid: true
            }
            CCText{
                width: ui.fontHeight * 1.5
                height: width
                text: "VC"
                alignMid: true
            }
        }
    }
}