
import QtQuick

import QGroundControl

import Gises.Widget

CCMouseArea{
    id: root
    anchors.fill: parent
    visible: false

    property ColorConfig cc: clcfg
    property Ui ui: Ui

    Loader{
        id: panelLoader

        property int panelId: 0

        onLoaded: {
            x = 0
            if (5 === panelId) {
                x = (parent.width - item.width) * 0.5
            } else if (5 < panelId) {
                x = parent.width - item.width
            }
        }
    }
}